local M = {}

-- Function to update highlight based on cursor position
M.update_highlight = function(bufnum)
	local cursor = vim.api.nvim_win_get_cursor(0)
	local row, col = cursor[1] - 1, cursor[2] -- Convert to 0-based index
	local config = M.config[bufnum]
	local group_size = config.group
	local cols = config.cols
	local addr_offset = config.addrlen + 2

	local hex_start = addr_offset + 1
	local hex_width = (cols*2)+(cols/group_size)-1
	local hex_end = hex_start + hex_width
	
	local preview_start = hex_end + 1

	if (col < hex_start) or (col > hex_end) then
		vim.api.nvim_buf_clear_namespace(bufnum, M.h_ns, 0, -1)
		return
	end

	local byte_index = (col - hex_start) - math.floor((col - hex_start) / (2 * group_size + 1))
	local char_col = preview_start + math.floor(byte_index / 2)

	-- Clear previous highlights and apply new one
	vim.api.nvim_buf_clear_namespace(bufnum, M.h_ns, 0, -1)
	vim.api.nvim_buf_add_highlight(bufnum, M.h_ns, "Cursor", row, char_col, char_col + 1)
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
