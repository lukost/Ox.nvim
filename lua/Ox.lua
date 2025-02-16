local M={}

local reloader = require('plenary.reload')
M.u_xxd = reloader.reload_module('Ox')
M.u_buf = reloader.reload_module('Ox.bufutils')
M.u_xxd = reloader.reload_module('Ox.xxdutils')
M.u_hig = reloader.reload_module('Ox.highlighter')
M.u_buf = require('Ox.bufutils')
M.u_hig = require('Ox.highlighter')
M.u_xxd = require('Ox.xxdutils')

-- NOTE: This could create some issues with multiple buffers switching
M.highlight_ns = vim.api.nvim_create_namespace("OxHexHighlight")
M.augroup = vim.api.nvim_create_augroup("OxHexHighlighter", { clear = true })

-- configuration
M.conf = {
	view = {
		keep_position = true, -- keep cursor position when switching from and to xxd
		highlight_cursor = true, -- use preview highlight when in hex mode
	},
	xxd = { -- xxd configuration
		command = 'xxd',
		cols = 16,
		group = 2,
		binary = false,
		EBCDIC = false,
		endianness = "big",
		uppercase = "false",
		addrlen = 8,
	},
	keys = { -- keymappings
		register = true, -- register basic keymaps
		map = {
			toggle = "<Leader>x",
		},
	}
}

-- various runtime states, mostly buffer-specific
M.state = {
	FTs = {},     -- filetype to restore when switching from hex mode
	Modes = {},   -- not sure if needed anymore ...
	Configs = {}, -- buffer specific xxd config in case global config changed while in hex mode
}

-- Function to set up key remaps
M.setupKeymaps = function(config)
	if (M.conf.keys.register ~= true) then
		return
	end
	vim.api.nvim_set_keymap("n",M.conf.keys.map.toggle,":OxToggle<CR>", { noremap = true, silent = true })
end

-- Function to set up autocmd for cursor movement
M.initHighlighter = function()
	if( M.conf.view.highlight_cursor ~= true ) then
		return
	end
	vim.api.nvim_create_autocmd({"CursorMoved", "CursorMovedI"}, {
	group = M.augroup,
	buffer = 0,
	callback = function()
	  local bufnum = vim.api.nvim_get_current_buf()
	  M.u_hig.update_highlight(bufnum)
	end,
	})
end

-- Function to disable highlighter when exiting hex mode
M.disableHighlighter = function()
	vim.api.nvim_clear_autocmds({ buffer = 0, group = M.augroup })
	vim.api.nvim_buf_clear_namespace(0, M.highlight_ns, 0, -1)
end

-- Function to switch from hex mode to normal mode
M.switch_from_hex = function(offset)
	M.disableHighlighter()
	local cmd = M.u_xxd.get_cmd_params_to_text(M.conf.xxd)
	local offset = M.u_buf.get_text_offset(M.conf.xxd)
	vim.cmd(cmd)

	vim.bo.bin = false
	local bufnum = vim.api.nvim_get_current_buf()
	vim.bo.filetype = M.state.FTs[bufnum]
	M.state.Configs[bufnum] = { mode='' }
	vim.cmd("goto " .. offset)
end

-- Function to switch from normal mode to hex mode
M.switch_to_hex = function(offset)
	local cmd = M.u_xxd.get_cmd_params_to_hex(M.conf.xxd)
	local row, col = unpack(M.u_buf.get_hex_position(offset, M.conf.xxd))
	vim.cmd(cmd)

	vim.api.nvim_win_set_cursor(0,{row,col})

	local bufnum = vim.api.nvim_get_current_buf()
	M.state.FTs[bufnum] = vim.bo.filetype
	M.state.Configs[bufnum] = {}
	M.state.Configs[bufnum].group = M.conf.xxd.group
	M.state.Configs[bufnum].cols = M.conf.xxd.cols
	M.state.Configs[bufnum].addrlen = M.conf.xxd.addrlen
	M.state.Configs[bufnum].mode = 'xxd'
	vim.bo.filetype="xxd"
	M.initHighlighter(M.state.Configs)
end

-- Function to toggle hex mode
M.toggle = function()
	local offset = M.u_buf.get_current_buf_offset()
	local bufnum = vim.api.nvim_get_current_buf()
	if(M.in_hex[bufnum]) then
		M.switch_from_hex(offset)
		M.in_hex[bufnum] = false
	else
		M.switch_to_hex(offset)
		M.in_hex[bufnum] = true
	end
end

-- initialize "plugin"
M.setup = function(args)
	M.conf = vim.tbl_deep_extend("force", M.conf, args or {})
	M.cur_offset = 0
	M.in_hex = {} 
	M.FTs = {}

	M.u_xxd.config_sanity_check(M.conf.xxd)
	vim.api.nvim_create_user_command('OxToggle', M.toggle, {})
	
	M.setupKeymaps()
	M.u_hig.setupHighlighter(M.state.Configs,M.augroup, M.highlight_ns)
end

M.setup({})
return M
