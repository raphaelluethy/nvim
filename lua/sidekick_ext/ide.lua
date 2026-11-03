-- Editor context for opencode's TUI, which shows the current file / selection
-- next to the prompt and sends it along with the next message.
--
-- opencode speaks the Claude Code IDE protocol: JSON-RPC over a WebSocket on
-- 127.0.0.1, with `selection_changed` notifications from the editor. It finds
-- the server through $OPENCODE_EDITOR_SSE_PORT, which agents.lua sets when it
-- launches opencode. The server starts on the first launch and only serves
-- the file / selection from sidekick_ext.context (focus in the agent terminal
-- keeps reporting the file window you came from).
local M = {}

local uv = vim.uv
local bit = require("bit")

M.config = {
	debounce_ms = 150,
	max_text_chars = 50000,
}

---------------------------------------------------------------------------
-- SHA-1 (WebSocket handshake only)
---------------------------------------------------------------------------

local function be32(s, i)
	local a, b, c, d = s:byte(i, i + 3)
	return bit.tobit(a * 0x1000000 + b * 0x10000 + c * 0x100 + d)
end

local function bytes32(n)
	return string.char(
		bit.band(bit.rshift(n, 24), 0xff),
		bit.band(bit.rshift(n, 16), 0xff),
		bit.band(bit.rshift(n, 8), 0xff),
		bit.band(n, 0xff)
	)
end

local function sha1(msg)
	local band, bor, bxor, bnot, rol, tobit = bit.band, bit.bor, bit.bxor, bit.bnot, bit.rol, bit.tobit
	local h0, h1, h2, h3, h4 =
		tobit(0x67452301), tobit(0xEFCDAB89), tobit(0x98BADCFE), tobit(0x10325476), tobit(0xC3D2E1F0)
	local bits = #msg * 8
	msg = msg
		.. "\128"
		.. string.rep("\0", (55 - #msg) % 64)
		.. bytes32(math.floor(bits / 0x100000000))
		.. bytes32(bits % 0x100000000)
	local w = {}
	for chunk = 1, #msg, 64 do
		for i = 0, 15 do
			w[i] = be32(msg, chunk + i * 4)
		end
		for i = 16, 79 do
			w[i] = rol(bxor(w[i - 3], w[i - 8], w[i - 14], w[i - 16]), 1)
		end
		local a, b, c, d, e = h0, h1, h2, h3, h4
		for i = 0, 79 do
			local f, k
			if i < 20 then
				f, k = bor(band(b, c), band(bnot(b), d)), 0x5A827999
			elseif i < 40 then
				f, k = bxor(b, c, d), 0x6ED9EBA1
			elseif i < 60 then
				f, k = bor(band(b, c), band(b, d), band(c, d)), 0x8F1BBCDC
			else
				f, k = bxor(b, c, d), 0xCA62C1D6
			end
			a, b, c, d, e = tobit(rol(a, 5) + f + e + k + w[i]), a, rol(b, 30), c, d
		end
		h0, h1, h2, h3, h4 = tobit(h0 + a), tobit(h1 + b), tobit(h2 + c), tobit(h3 + d), tobit(h4 + e)
	end
	return bytes32(h0) .. bytes32(h1) .. bytes32(h2) .. bytes32(h3) .. bytes32(h4)
end
M._sha1 = sha1

---------------------------------------------------------------------------
-- WebSocket framing (RFC 6455, server side)
---------------------------------------------------------------------------

local function frame(payload, opcode)
	local len = #payload
	local head
	if len < 126 then
		head = string.char(0x80 + opcode, len)
	elseif len < 0x10000 then
		head = string.char(0x80 + opcode, 126, math.floor(len / 256), len % 256)
	else
		head = string.char(0x80 + opcode, 127) .. bytes32(0) .. bytes32(len)
	end
	return head .. payload
end

--- Parse one frame from the start of buf.
---@return { fin: boolean, op: integer, data: string }?, string rest
local function parse(buf)
	if #buf < 2 then
		return nil, buf
	end
	local b1, b2 = buf:byte(1, 2)
	local len, pos = bit.band(b2, 0x7f), 3
	if len == 126 then
		if #buf < 4 then
			return nil, buf
		end
		len, pos = buf:byte(3) * 256 + buf:byte(4), 5
	elseif len == 127 then
		if #buf < 10 then
			return nil, buf
		end
		len = 0
		for i = 3, 10 do
			len = len * 256 + buf:byte(i)
		end
		pos = 11
	end
	local mask
	if bit.band(b2, 0x80) ~= 0 then
		if #buf < pos + 3 then
			return nil, buf
		end
		mask = { buf:byte(pos, pos + 3) }
		pos = pos + 4
	end
	if #buf < pos + len - 1 then
		return nil, buf
	end
	local data = buf:sub(pos, pos + len - 1)
	if mask then
		local out = {}
		for i = 1, #data do
			out[i] = string.char(bit.bxor(data:byte(i), mask[(i - 1) % 4 + 1]))
		end
		data = table.concat(out)
	end
	return { fin = bit.band(b1, 0x80) ~= 0, op = bit.band(b1, 0x0f), data = data }, buf:sub(pos + len)
end

---------------------------------------------------------------------------
-- Server
---------------------------------------------------------------------------

---@class sidekick_ext.ide.Client
---@field tcp uv.uv_tcp_t
---@field buf string
---@field open boolean handshake done
---@field msg? string fragmented message so far

local server ---@type uv.uv_tcp_t?
local port ---@type integer?
local clients = {} ---@type table<sidekick_ext.ide.Client, true>
local last ---@type string? last selection sent (JSON)

local function close(client)
	clients[client] = nil
	if not client.tcp:is_closing() then
		client.tcp:close()
	end
end

local function send(client, payload, opcode)
	if client.open and not client.tcp:is_closing() then
		client.tcp:write(frame(payload, opcode or 1))
	end
end

local function rpc(client, msg)
	msg.jsonrpc = "2.0"
	send(client, vim.json.encode(msg))
end

local function current()
	local ok, sel = pcall(require("sidekick_ext.context").selection)
	if not ok or not sel then
		return
	end
	if #sel.text > M.config.max_text_chars then
		sel.text = sel.text:sub(1, M.config.max_text_chars) .. "\n…(truncated)"
	end
	return vim.json.encode({ jsonrpc = "2.0", method = "selection_changed", params = sel })
end

local function on_message(client, text)
	local ok, msg = pcall(vim.json.decode, text, { luanil = { object = true } })
	if not ok or type(msg) ~= "table" or msg.id == nil then
		return -- notifications (notifications/initialized) need no answer
	end
	if msg.method == "initialize" then
		rpc(client, {
			id = msg.id,
			result = {
				protocolVersion = type(msg.params) == "table" and msg.params.protocolVersion or "2025-11-25",
				capabilities = vim.empty_dict(),
				serverInfo = { name = "neovim", version = tostring(vim.version()) },
			},
		})
		-- Show the file right away, not only after the next cursor move.
		local sel = current()
		if sel then
			send(client, sel)
		end
	else
		rpc(client, { id = msg.id, error = { code = -32601, message = "Method not found: " .. tostring(msg.method) } })
	end
end

local function handshake(client)
	local head_end = client.buf:find("\r\n\r\n", 1, true)
	if not head_end then
		if #client.buf > 16384 then
			close(client)
		end
		return false
	end
	local head = client.buf:sub(1, head_end)
	client.buf = client.buf:sub(head_end + 4)
	local key = head:match("\n[Ss]ec%-[Ww]eb[Ss]ocket%-[Kk]ey:%s*([^\r\n]+)")
	-- Browsers send an Origin; opencode doesn't. Keeps web pages from reading the editor.
	if not key or head:lower():find("\norigin:") then
		client.tcp:write("HTTP/1.1 400 Bad Request\r\nContent-Length: 0\r\n\r\n")
		return close(client)
	end
	local accept = vim.base64.encode(sha1(vim.trim(key) .. "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"))
	client.tcp:write(
		"HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: "
			.. accept
			.. "\r\n\r\n"
	)
	client.open = true
	return true
end

local function on_data(client, chunk)
	client.buf = client.buf .. chunk
	if not client.open and not handshake(client) then
		return
	end
	while client.open do
		local f
		f, client.buf = parse(client.buf)
		if not f then
			return
		end
		if f.op == 8 then -- close
			send(client, f.data:sub(1, 2), 8)
			return close(client)
		elseif f.op == 9 then -- ping
			send(client, f.data, 10)
		elseif f.op == 1 or f.op == 0 then -- text / continuation
			client.msg = (f.op == 0 and client.msg or "") .. f.data
			if f.fin then
				local text = client.msg
				client.msg = nil
				on_message(client, text)
			end
		end
	end
end

local timer ---@type uv.uv_timer_t?

local function broadcast()
	if next(clients) == nil then
		return
	end
	local sel = current()
	if not sel or sel == last then
		return
	end
	last = sel
	for client in pairs(clients) do
		send(client, sel)
	end
end

local function schedule_broadcast()
	if next(clients) == nil or not timer then
		return
	end
	timer:stop()
	timer:start(M.config.debounce_ms, 0, vim.schedule_wrap(broadcast))
end

function M.stop()
	for client in pairs(clients) do
		close(client)
	end
	if server and not server:is_closing() then
		server:close()
	end
	if timer and not timer:is_closing() then
		timer:close()
	end
	server, port, timer, last = nil, nil, nil, nil
	pcall(vim.api.nvim_del_augroup_by_name, "sidekick_ext.ide")
end

--- Port of the editor-context server, started on first use.
---@return integer?
function M.port()
	if port then
		return port
	end
	local tcp = assert(uv.new_tcp())
	local ok, err = pcall(function()
		assert(tcp:bind("127.0.0.1", 0))
		assert(tcp:listen(16, function(lerr)
			if lerr then
				return
			end
			local conn = uv.new_tcp()
			if not conn or tcp:accept(conn) ~= 0 then
				return conn and conn:close()
			end
			local client = { tcp = conn, buf = "", open = false }
			clients[client] = true
			conn:read_start(function(rerr, chunk)
				vim.schedule(function()
					if rerr or not chunk then
						return close(client)
					end
					on_data(client, chunk)
				end)
			end)
		end))
	end)
	if not ok then
		tcp:close()
		vim.notify("sidekick: editor context server failed: " .. tostring(err), vim.log.levels.WARN)
		return
	end
	server, port = tcp, tcp:getsockname().port
	timer = uv.new_timer()

	local group = vim.api.nvim_create_augroup("sidekick_ext.ide", { clear = true })
	vim.api.nvim_create_autocmd(
		{ "CursorMoved", "CursorMovedI", "BufEnter", "WinEnter", "ModeChanged", "TextChanged", "BufWritePost" },
		{ group = group, callback = schedule_broadcast }
	)
	vim.api.nvim_create_autocmd("VimLeavePre", { group = group, callback = M.stop })
	return port
end

return M
