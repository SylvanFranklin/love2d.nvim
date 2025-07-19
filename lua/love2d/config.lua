local config = {}

config.defaults = {
    path_to_love_bin = "love",
    path_to_love_library = vim.fn.globpath(vim.o.runtimepath, "love2d/library"),
    path_to_luasocket_library = vim.fn.globpath(vim.o.runtimepath, "luasocket/library"),
    restart_on_save = false,
    debug_window_opts = nil,
}

---@class options
---@field path_to_love_bin? string: The path to the Love2D executable
---@field path_to_love_library? string: The path to the Love2D library. Set to "" to disable LSP
---@field path_to_luasocket_library? string: The path to the LuaSocket library. Set to "" to disable LuaSocket LSP
---@field restart_on_save? boolean: Restart Love2D when a file is saved
---@field debug_window_opts? vim.api.keyset.win_config: Create split window with Love2D terminal output
config.options = {}

---Setup the LSP for love2d using lspconfig
---@param love_library_path string: Path to the Love2D library
---@param luasocket_library_path? string: Path to the LuaSocket library
local function setup_lsp(love_library_path, luasocket_library_path)
    -- Set up library configuration for lua_ls
    local settings = {
        Lua = {
            workspace = { library = {} },
        },
    }

    -- Add Love2D library path
    settings.Lua.workspace.library[love_library_path] = true

    -- Add LuaSocket library path if provided
    if luasocket_library_path then
        settings.Lua.workspace.library[luasocket_library_path] = true
    end

    vim.lsp.config.lua_ls = {
        settings = settings,
    }
end

---Create auto commands for love2d:
--- - Restart on save: Restart Love2D when a file is saved.
local function create_auto_commands()
    if config.options.restart_on_save then
        vim.api.nvim_create_autocmd("BufWritePost", {
            group = vim.api.nvim_create_augroup("love2d_restart_on_save", { clear = true }),
            pattern = { "*.lua" },
            callback = function()
                local love2d = require("love2d")
                local path = love2d.find_src_path("")
                if path then
                    love2d.stop()
                    vim.defer_fn(function()
                        love2d.run(path)
                    end, 500)
                end
            end,
        })
    end
    -- add here other auto commands ...
end

---Setup the love2d configuration.
---It must be called before running a love2d project.
---@param opts? options: config table
config.setup = function(opts)
    config.options = vim.tbl_deep_extend("force", {}, config.defaults, opts or {})

    local valid_love_path = nil
    local valid_luasocket_path = nil

    -- Process Love2D library path
    if config.options.path_to_love_library ~= "" then
        local love_library_path = vim.fn.split(vim.fn.expand(config.options.path_to_love_library), "\n")[1]
        if vim.fn.isdirectory(love_library_path) == 0 then
            vim.notify("The library path " .. love_library_path .. " does not exist.", vim.log.levels.ERROR)
        else
            valid_love_path = love_library_path
        end
    end

    -- Process LuaSocket library path
    if config.options.path_to_luasocket_library ~= "" then
        local luasocket_library_path = vim.fn.split(vim.fn.expand(config.options.path_to_luasocket_library), "\n")[1]
        if vim.fn.isdirectory(luasocket_library_path) == 0 then
            vim.notify("The LuaSocket library path " .. luasocket_library_path .. " does not exist.",
                vim.log.levels.ERROR)
        else
            valid_luasocket_path = luasocket_library_path
        end
    end

    -- Set up LSP if we have a valid Love2D library path
    if valid_love_path then
        setup_lsp(valid_love_path, valid_luasocket_path)
    end

    create_auto_commands()
end

return config
