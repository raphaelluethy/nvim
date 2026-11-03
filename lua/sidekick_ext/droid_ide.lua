-- Droid's IDE protocol: Streamable HTTP MCP, with editor notifications on SSE.
-- No prompt hooks, external server, Node dependencies, or VS Code installation.
local M = {}
local uv = vim.uv

M.config = { debounce_ms = 150, max_selection_chars = 50000 }

local server, timer, debounce, port, lock
local connections, sessions = {}, {}
local previous_env
local max_body = 1024 * 1024

local function close(conn)
	connections[conn] = nil
	if conn.session and conn.session.stream == conn then
		conn.session.stream = nil
	end
	if not conn.tcp:is_closing() then
		conn.tcp:close()
	end
end

local function response(conn, status, body, headers)
	body = body or ""
	conn.tcp:write(
		("HTTP/1.1 %s\r\nConnection: close\r\nContent-Length: %d\r\n%s\r\n%s"):format(
			status,
			#body,
			headers or "",
			body
		),
		function()
			close(conn)
		end
	)
end

local function json(conn, value, session)
	response(
		conn,
		"200 OK",
		vim.json.encode(value),
		"Content-Type: application/json\r\n" .. (session and "Mcp-Session-Id: " .. session.id .. "\r\n" or "")
	)
end

local function notify(session, method, params)
	local conn = session.stream
	if conn and not conn.tcp:is_closing() then
		conn.tcp:write("event: message\ndata: " .. vim.json.encode({
			jsonrpc = "2.0",
			method = "notifications/" .. method,
			params = params,
		}) .. "\n\n")
	end
end

local function is_file(buf)
	return vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) ~= ""
end

local function character(buf, row, col)
	local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
	return vim.str_utfindex(line, "utf-16", math.min(col, #line), false)
end

local function snapshot()
	local files, diagnostics = {}, {}
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if is_file(buf) and vim.bo[buf].buflisted then
			local path = vim.api.nvim_buf_get_name(buf)
			files[#files + 1] = {
				path = path,
				fileName = vim.fs.basename(path),
				isDirty = vim.bo[buf].modified,
				languageId = vim.bo[buf].filetype,
			}
			local items = {}
			for _, d in ipairs(vim.diagnostic.get(buf)) do
				items[#items + 1] = {
					severity = (d.severity or vim.diagnostic.severity.ERROR) - 1,
					message = d.message,
					source = d.source,
					range = {
						start = { line = d.lnum, character = character(buf, d.lnum, d.col) },
						["end"] = {
							line = d.end_lnum or d.lnum,
							character = character(buf, d.end_lnum or d.lnum, d.end_col or d.col),
						},
					},
					code = d.code and tostring(d.code) or nil,
				}
			end
			diagnostics[path] = items
		end
	end
	local active = { path = "", fileName = "", isDirty = false, lineCount = 0 }
	local sel = require("sidekick_ext.context").selection()
	active.selection = { startLine = 0, startCharacter = 0, endLine = 0, endCharacter = 0, selectedText = "" }
	if sel then
		local buf = vim.fn.bufnr(sel.filePath)
		if is_file(buf) then
			active.path, active.fileName = sel.filePath, vim.fs.basename(sel.filePath)
			active.isDirty, active.lineCount = vim.bo[buf].modified, vim.api.nvim_buf_line_count(buf)
			local a, b = sel.selection.start, sel.selection["end"]
			active.selection = {
				startLine = a.line,
				startCharacter = character(buf, a.line, a.character),
				endLine = b.line,
				endCharacter = character(buf, b.line, b.character),
				selectedText = #sel.text <= M.config.max_selection_chars and sel.text or "",
			}
		end
	end
	return { activeFile = active, openFiles = { files = files }, diagnostics = diagnostics }
end

local function publish(session, state)
	for _, name in ipairs({ "activeFile", "openFiles" }) do
		local encoded = vim.json.encode(state[name])
		if session.last[name] ~= encoded then
			session.last[name] = encoded
			notify(session, name, state[name])
		end
	end
	for path in pairs(session.diagnostics) do
		if not state.diagnostics[path] then
			notify(session, "diagnostics", { filePath = path, diagnostics = {} })
			session.diagnostics[path] = nil
		end
	end
	for path, items in pairs(state.diagnostics) do
		local encoded = vim.json.encode(items)
		if session.diagnostics[path] ~= encoded then
			session.diagnostics[path] = encoded
			notify(session, "diagnostics", { filePath = path, diagnostics = items })
		end
	end
end

local function broadcast()
	if next(sessions) == nil then
		return
	end
	local state = snapshot()
	for _, session in pairs(sessions) do
		if session.stream then
			publish(session, state)
		end
	end
end

local function schedule()
	if debounce and not debounce:is_closing() then
		debounce:stop()
		debounce:start(M.config.debounce_ms, 0, vim.schedule_wrap(broadcast))
	end
end

local tools = {
	{
		name = "openFile",
		description = "Open a file in Neovim without changing or saving its contents.",
		inputSchema = {
			type = "object",
			properties = { filePath = { type = "string" }, waitForSave = { type = "boolean" } },
			required = { "filePath" },
		},
	},
}

local function call_tool(params)
	if params.name ~= "openFile" then
		error("Unknown tool: " .. tostring(params.name))
	end
	local args = params.arguments
	assert(type(args) == "table" and type(args.filePath) == "string", "filePath is required")
	assert(not args.waitForSave, "Waiting for a save is not supported by this bridge")
	assert(vim.startswith(args.filePath, "/") and not args.filePath:find("\0", 1, true), "Use an absolute file path")
	-- nvim_cmd keeps paths containing |, quotes, and spaces out of Ex parsing.
	vim.cmd.tabedit({ args.filePath })
	return { content = { { type = "text", text = vim.json.encode({ success = true }) } } }
end

local function rpc(conn, msg, session)
	if type(msg) ~= "table" or msg.jsonrpc ~= "2.0" or type(msg.method) ~= "string" then
		return response(conn, "400 Bad Request")
	end
	if msg.method == "initialize" and msg.id ~= nil then
		if session then
			return response(conn, "400 Bad Request")
		end
		local id = vim.fn.sha256(uv.random(32))
		session = { id = id, last = {}, diagnostics = {}, touched = uv.now() }
		sessions[id] = session
		return json(conn, {
			jsonrpc = "2.0",
			id = msg.id,
			result = {
				protocolVersion = "2025-03-26",
				capabilities = { tools = vim.empty_dict() },
				serverInfo = { name = "Neovim", version = "0.1.0" },
			},
		}, session)
	end
	if not session then
		return response(conn, "404 Not Found")
	end
	session.touched = uv.now()
	if msg.id == nil then
		return response(conn, "202 Accepted")
	end
	local result, err
	if msg.method == "ping" then
		result = vim.empty_dict()
	elseif msg.method == "tools/list" then
		result = { tools = tools }
	elseif msg.method == "tools/call" then
		local ok, value = pcall(call_tool, msg.params or {})
		result = ok and value or { isError = true, content = { { type = "text", text = tostring(value) } } }
	else
		err = { code = -32601, message = "Method not found" }
	end
	json(conn, { jsonrpc = "2.0", id = msg.id, result = result, error = err })
end

local function request(conn, head, body)
	local method, path = head:match("^(%u+) ([^ ]+) HTTP/1%.[01]\r\n")
	local headers = {}
	for key, value in head:gmatch("\r\n([^:%s]+): *([^\r\n]*)") do
		key = key:lower()
		if headers[key] then
			return response(conn, "400 Bad Request")
		end
		headers[key] = vim.trim(value)
	end
	-- No browser access, CORS, DNS rebinding, or non-loopback listeners.
	if headers.origin or headers.host ~= "127.0.0.1:" .. port then
		return response(conn, "403 Forbidden")
	end
	if path ~= "/mcp" then
		return response(conn, "404 Not Found")
	end
	local session = sessions[headers["mcp-session-id"]]
	if method == "POST" then
		if not (headers["content-type"] or ""):match("^application/json") then
			return response(conn, "415 Unsupported Media Type")
		end
		local ok, msg = pcall(vim.json.decode, body)
		if not ok then
			return response(conn, "400 Bad Request")
		end
		rpc(conn, msg, session)
	elseif method == "GET" and session then
		if session.stream then
			close(session.stream)
		end
		conn.session, session.stream = session, conn
		session.last, session.diagnostics = {}, {}
		conn.tcp:write(
			"HTTP/1.1 200 OK\r\nContent-Type: text/event-stream\r\nCache-Control: no-cache\r\nConnection: keep-alive\r\n\r\n"
		)
		publish(session, snapshot())
		notify(session, "heartbeat", { timestamp = os.time() * 1000 })
	elseif method == "DELETE" and session then
		if session.stream then
			close(session.stream)
		end
		sessions[session.id] = nil
		response(conn, "200 OK")
	else
		response(conn, session and "405 Method Not Allowed" or "404 Not Found")
	end
end

local function receive(conn, chunk)
	if conn.handled then
		return
	end
	conn.buf = conn.buf .. chunk
	local ending = conn.buf:find("\r\n\r\n", 1, true)
	if not ending then
		if #conn.buf > 16384 then
			close(conn)
		end
		return
	end
	local head = conn.buf:sub(1, ending + 1)
	local length = tonumber(head:lower():match("\r\ncontent%-length: *(%d+)\r\n")) or 0
	if ending > 16384 or length > max_body or #conn.buf > max_body + 16384 then
		return close(conn)
	end
	if head:lower():find("\r\ntransfer%-encoding:") then
		return response(conn, "400 Bad Request")
	end
	if #conn.buf < ending + 3 + length then
		return
	end
	conn.handled = true
	request(conn, head, conn.buf:sub(ending + 4, ending + 3 + length))
	conn.buf = ""
end

local function write_lock()
	if lock then
		vim.fn.writefile({
			vim.json.encode({
				pid = vim.fn.getpid(),
				ideName = "Neovim",
				workspaceFolders = { uv.cwd() },
			}),
		}, lock)
		uv.fs_chmod(lock, 384)
	end
end

function M.stop()
	for conn in pairs(connections) do
		close(conn)
	end
	for _, handle in pairs({ server, timer, debounce }) do
		if not handle:is_closing() then
			handle:close()
		end
	end
	if lock then
		vim.fn.delete(lock)
	end
	if port and vim.env.FACTORY_VSCODE_MCP_PORT == tostring(port) then
		vim.env.FACTORY_VSCODE_MCP_PORT = previous_env
	end
	server, timer, debounce, port, lock = nil, nil, nil, nil, nil
	connections, sessions = {}, {}
	pcall(vim.api.nvim_del_augroup_by_name, "sidekick_ext.droid_ide")
end

function M.port()
	if port then
		return port
	end
	local tcp = assert(uv.new_tcp())
	local ok, err = pcall(function()
		assert(tcp:bind("127.0.0.1", 0))
		assert(tcp:listen(16, function(listen_err)
			if listen_err then
				return
			end
			local conn = { tcp = assert(uv.new_tcp()), buf = "", created = uv.now() }
			if tcp:accept(conn.tcp) ~= 0 then
				return close(conn)
			end
			connections[conn] = true
			conn.tcp:read_start(function(read_err, chunk)
				vim.schedule(function()
					if conn.tcp:is_closing() then
						return
					end
					if read_err or not chunk then
						return close(conn)
					end
					local success = pcall(receive, conn, chunk)
					if not success then
						close(conn)
					end
				end)
			end)
		end))
	end)
	if not ok then
		tcp:close()
		vim.notify("Droid IDE: " .. tostring(err), vim.log.levels.WARN)
		return
	end
	server, port = tcp, tcp:getsockname().port
	previous_env = vim.env.FACTORY_VSCODE_MCP_PORT
	vim.env.FACTORY_VSCODE_MCP_PORT = tostring(port)
	local dir = vim.fn.expand("~/.factory/ide")
	local registered, register_err = pcall(function()
		vim.fn.mkdir(dir, "p", 448)
		lock = dir .. "/" .. port .. ".lock"
		write_lock()
	end)
	if not registered then
		M.stop()
		vim.notify("Droid IDE: " .. tostring(register_err), vim.log.levels.WARN)
		return
	end
	debounce, timer = assert(uv.new_timer()), assert(uv.new_timer())
	timer:start(
		15000,
		15000,
		vim.schedule_wrap(function()
			for _, session in pairs(sessions) do
				notify(session, "heartbeat", { timestamp = os.time() * 1000 })
				if not session.stream and uv.now() - session.touched > 90000 then
					sessions[session.id] = nil
				end
			end
			for conn in pairs(connections) do
				if not conn.session and uv.now() - conn.created > 30000 then
					close(conn)
				end
			end
		end)
	)
	local group = vim.api.nvim_create_augroup("sidekick_ext.droid_ide", { clear = true })
	vim.api.nvim_create_autocmd({
		"CursorMoved",
		"CursorMovedI",
		"BufEnter",
		"WinEnter",
		"ModeChanged",
		"TextChanged",
		"TextChangedI",
		"BufWritePost",
		"BufDelete",
		"DiagnosticChanged",
	}, { group = group, callback = schedule })
	vim.api.nvim_create_autocmd("DirChanged", { group = group, callback = write_lock })
	vim.api.nvim_create_autocmd("VimLeavePre", { group = group, callback = M.stop })
	return port
end

function M.setup()
	vim.api.nvim_create_user_command("DroidIDE", function(opts)
		if opts.args == "stop" then
			M.stop()
		else
			local value = M.port()
			if value then
				vim.notify("Droid IDE listening on 127.0.0.1:" .. value .. ". Start a new Droid session to connect.")
			end
		end
	end, {
		nargs = "?",
		complete = function()
			return { "start", "stop" }
		end,
	})
end

return M
