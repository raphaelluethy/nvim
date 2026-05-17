local plugin_dir = vim.fn.stdpath("config") .. "/lua/plugins"

local pack_specs = {}
local setup_specs = {}
local setup_order = {}
local build_hooks = {}
local seen_sources = {}

local function is_spec(value)
	return type(value) == "table" and (type(value[1]) == "string" or value.src or value.url or value.dir)
end

local function repo_name(src)
	return src:gsub("%.git$", ""):match("([^/]+)$")
end

local function normalize_source(src)
	if src:match("^https?://") or src:match("^git@") or src:match("^/") then
		return src
	end

	return "https://github.com/" .. src
end

local function enabled(spec)
	if spec.enabled == false or spec.cond == false then
		return false
	end

	if type(spec.enabled) == "function" and not spec.enabled() then
		return false
	end

	if type(spec.cond) == "function" and not spec.cond() then
		return false
	end

	return true
end

local function spec_score(spec)
	local score = 0
	for _, key in ipairs({ "config", "opts", "keys", "main", "build" }) do
		if spec[key] ~= nil then
			score = score + 1
		end
	end
	return score
end

local function pack_spec_for(spec)
	local src = spec.src or spec.url or spec[1] or spec.dir
	if not src then
		return nil
	end

	src = normalize_source(src)
	local version = spec.version
	if version == false then
		version = nil
	end
	version = spec.tag or spec.branch or version

	return {
		src = src,
		name = spec.name or repo_name(src),
		version = version,
	}
end

local function remember_setup(name, spec)
	local previous = setup_specs[name]
	if not previous then
		table.insert(setup_order, name)
	end

	if not previous or spec_score(spec) >= spec_score(previous) then
		setup_specs[name] = spec
	end
end

local add_spec

local function add_dependency(dep)
	if type(dep) == "string" then
		add_spec({ dep })
	elseif is_spec(dep) then
		add_spec(dep)
	end
end

function add_spec(spec)
	if not enabled(spec) then
		return
	end

	if type(spec.dependencies) == "string" then
		add_dependency(spec.dependencies)
	elseif type(spec.dependencies) == "table" then
		for _, dep in ipairs(spec.dependencies) do
			add_dependency(dep)
		end
	end

	local pack_spec = pack_spec_for(spec)
	if not pack_spec then
		return
	end

	if not seen_sources[pack_spec.name] then
		table.insert(pack_specs, pack_spec)
		seen_sources[pack_spec.name] = true
	end

	if spec.build then
		build_hooks[pack_spec.name] = spec.build
	end

	remember_setup(pack_spec.name, spec)
end

local function load_plugin_modules()
	local files = vim.fn.glob(plugin_dir .. "/*.lua", false, true)
	table.sort(files)

	for _, file in ipairs(files) do
		local module = "plugins." .. vim.fn.fnamemodify(file, ":t:r")
		local ok, result = pcall(require, module)
		if ok and is_spec(result) then
			add_spec(result)
		elseif ok and type(result) == "table" then
			for _, spec in ipairs(result) do
				if is_spec(spec) then
					add_spec(spec)
				end
			end
		elseif not ok then
			vim.notify(("Failed to load %s: %s"):format(module, result), vim.log.levels.ERROR)
		end
	end
end

local function run_build_hook(event)
	local name = event.data.spec.name
	local build = build_hooks[name]
	if not build then
		return
	end

	if type(build) == "function" then
		build(event)
		return
	end

	if type(build) ~= "string" then
		return
	end

	if build:sub(1, 1) == ":" then
		if not event.data.active then
			vim.cmd.packadd(name)
		end
		vim.cmd(build:sub(2))
		return
	end

	vim.system(vim.split(build, " "), { cwd = event.data.path }):wait()
end

local function resolve_opts(spec)
	if type(spec.opts) == "function" then
		local opts = {}
		return spec.opts(spec, opts) or opts
	end

	return spec.opts or {}
end

local function infer_module(spec, name)
	if spec.main then
		return spec.main
	end

	return name:gsub("%.nvim$", "")
end

local function setup_plugin(name, spec)
	local opts = resolve_opts(spec)

	if spec.config then
		spec.config(spec, opts)
		return
	end

	if spec.opts ~= nil then
		local module = infer_module(spec, name)
		local ok, plugin = pcall(require, module)
		if not ok then
			vim.notify(("Failed to configure %s: %s"):format(name, plugin), vim.log.levels.ERROR)
			return
		end

		if type(plugin.setup) == "function" then
			plugin.setup(opts)
		end
	end
end

local function keymap_opts(mapping)
	local opts = {}
	for key, value in pairs(mapping) do
		if type(key) ~= "number" and key ~= "mode" then
			opts[key] = value
		end
	end
	return opts
end

local function setup_keys(spec)
	local keys = spec.keys
	if type(keys) == "function" then
		keys = keys(spec, resolve_opts(spec))
	end

	if type(keys) ~= "table" then
		return
	end

	for _, mapping in ipairs(keys) do
		if type(mapping) == "table" and mapping[1] and mapping[2] then
			vim.keymap.set(mapping.mode or "n", mapping[1], mapping[2], keymap_opts(mapping))
		end
	end
end

load_plugin_modules()

vim.api.nvim_create_autocmd("PackChanged", {
	callback = run_build_hook,
})

vim.pack.add(pack_specs, {
	load = true,
	confirm = false,
})

for _, name in ipairs(setup_order) do
	local spec = setup_specs[name]
	if spec then
		setup_plugin(name, spec)
	end
end

for _, name in ipairs(setup_order) do
	local spec = setup_specs[name]
	if spec then
		setup_keys(spec)
	end
end

vim.api.nvim_create_user_command("PackUpdate", function()
	vim.pack.update(nil, { force = true })
end, { desc = "Update vim.pack plugins" })

vim.api.nvim_create_user_command("PackClean", function()
	local inactive = vim.iter(vim.pack.get(nil, { info = false }))
		:filter(function(plugin)
			return not plugin.active
		end)
		:map(function(plugin)
			return plugin.spec.name
		end)
		:totable()

	if #inactive > 0 then
		vim.pack.del(inactive)
	end
end, { desc = "Delete inactive vim.pack plugins" })
