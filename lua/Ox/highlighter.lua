local M = {}
M.u_buf = require('Ox.bufutils')

-- Function to update highlight based on cursor position
M.update_highlight = function(bufnum)
	local cursor = vim.api.nvim_win_get_cursor(0)
	local row, col = cursor[1] - 1, cursor[2] -- Convert to 0-based index
	local ccol = M.u_buf.get_hex_preview_position(col, M.config[bufnum])
	
	-- Clear previous highlights and apply new one
	vim.api.nvim_buf_clear_namespace(bufnum, M.h_ns, 0, -1)
	if (ccol >= 0) then
		vim.api.nvim_buf_add_highlight(bufnum, M.h_ns, "Cursor", row, ccol, ccol + 1)
	end
end

-- Function to set up autocmd for cursor movement
M.setupHighlighter = function(config, augroup, namespace)
	M.config = config
	M.augroup = augroup
	M.h_ns = namespace
end

-- Function to disable highlighter when exiting hex mode
M.disableHighlighter = function()
	vim.api.nvim_clear_autocmds({ group = M.augroup })
	vim.api.nvim_buf_clear_namespace(0, M.h_ns, 0, -1)
end
return M
