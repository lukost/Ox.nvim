local M={}
local reloader = require('plenary.reload')
M.u_buf = reloader.reload_module('Ox.bufutils')
M.u_xxd = reloader.reload_module('Ox.xxdutils')
M.u_xxd = reloader.reload_module('Ox')
--reloader.reload_module('libmodal')
M.u_buf = require('Ox.bufutils')
M.u_xxd = require('Ox.xxdutils')
--M.libmodal = require('libmodal')

M.conf = {
	view = {
		keep_position = true,
		highlight_cursor = true,
	},
	xxd = {
		command = 'xxd',
   	cols = 16,
   	group = 2,
   	binary = false,
   	EBCDIC = false,
   	endianness = "big",
   	uppercase = "false",
   	addrlen = 8,
   },
   keys = {
		h = 'norm h',
		j = 'norm j',
		k = 'norm k',
		l = 'norm l',
   }
}

M.switch_from_hex = function(offset)
	local cmd = M.u_xxd.get_cmd_params_to_text(M.conf.xxd)
	local offset = M.u_buf.get_text_offset(M.conf.xxd)
	vim.cmd(cmd)
	vim.bo.bin = false
	local bufnum = vim.api.nvim_get_current_buf()
	vim.bo.filetype = M.FTs[bufnum]
	vim.cmd("goto " .. offset)
end

M.switch_to_hex = function(offset)
	local cmd = M.u_xxd.get_cmd_params_to_hex(M.conf.xxd)
	local row, col = unpack(M.u_buf.get_hex_position(offset, M.conf.xxd))
	vim.cmd(cmd)
	vim.api.nvim_win_set_cursor(0,{row,col})
	local bufnum = vim.api.nvim_get_current_buf()

	M.FTs[bufnum] = vim.bo.filetype
	vim.bo.filetype="xxd"
end

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

M.setup = function(args)
	M.conf = vim.tbl_deep_extend("force", M.conf, args or {})
--	M.hexmode = M.libmodal.mode.new('HEX', {})
	
	M.cur_offset = 0
	M.in_hex = {} 
	M.FTs = {}

	M.u_xxd.config_sanity_check(M.conf.xxd)
	vim.api.nvim_create_user_command('OxToggle', M.toggle, {})
end

M.setup({})
return M
