local M={}
local reloader = require('plenary.reload')
M.u_buf = reloader.reload_module('Ox.bufutils')
M.u_xxd = reloader.reload_module('Ox.xxdutils')
M.u_buf = require('Ox.bufutils')
M.u_xxd = require('Ox.xxdutils')


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
}

M.toggle = function()
	local cmd = ""
	local row = 1
	local col = 0
	local offset = M.u_buf.get_current_buf_offset()
	if(M.in_hex) then
		cmd = M.u_xxd.get_cmd_params_to_text(M.conf.xxd)
		M.in_hex = false
		vim.bo.bin = false
	else
		cmd = M.u_xxd.get_cmd_params_to_hex(M.conf.xxd)
		row, col = unpack(M.u_buf.get_hex_position(offset, M.conf.xxd))
		M.in_hex = true
		vim.bo.bin = true
	end
	vim.cmd(cmd)
	vim.api.nvim_win_set_cursor(0,{row,col})
end

M.setup = function(args)
	M.cur_offset = 0
	M.in_hex = false
	M.conf = vim.tbl_deep_extend("force", M.conf, args or {})
	M.u_xxd.config_sanity_check(M.conf.xxd)
	vim.api.nvim_create_user_command('OxToggle', M.toggle, {})
end

M.setup({})
return M
