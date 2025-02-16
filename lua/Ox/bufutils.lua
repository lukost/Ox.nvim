--local augroup_hexmode_editor = vim.api.nvim_create_agroup('
local M = {}

-- gets byte offset of current buffer position
-- returns: single integer with offset position of cursor calculated from buffer beginning
M.get_current_buf_offset= function()
	local current_line = vim.fn.line2byte(vim.fn.line("."))
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local current_offset = current_line + col -1
	return current_offset
end


-- gets target HEX code cursor position for given byte offset and xxd config
-- returns: {row, column}
M.get_hex_position = function(offset, config)
	local offset_row = 1 + math.floor(offset/config.cols)
	local ofc = offset%config.cols
	local offset_col = config.addrlen + 2
	offset_col = offset_col + ofc * 2 + math.floor(ofc/config.group)
	return {offset_row, offset_col}
end

-- gets target PREVIEW cursor position for given byte offset and xxd config
-- returns: {row, column}
M.get_hex_preview_position = function(offset, config)
	local offset_row = math.floor(offset/config.cols)
	local ofc = offset%config.cols
	local offset_col = ofc+config.addrlen + 2 + config.cols*2 + math.floor(config.cols/config.group) + 2
	return {offset_row, offset_col}
end

-- gets target byte offset of cursor position for given offset (in hex view) and xxd config 
M.get_text_offset = function(config)
	local group_size, cols = config.group, config.cols
	local addr_offset = config.addrlen + 2
	local cursor = vim.api.nvim_win_get_cursor(0)
	local row, col = cursor[1] - 1, cursor[2]

	-- Address column width in xxd mode
	local hex_start = addr_offset + 1
	local hex_width = (cols * 2) + (cols / group_size) - 1
	local hex_end = hex_start + hex_width

	-- Ensure cursor is in the hex column
	if col < hex_start then
		return row * cols
	end
	if col > hex_end then
		return row * cols + col
	end

	-- Compute byte index within the row
	local byte_index = (col - hex_start) - math.floor((col - hex_start) / (2 * group_size + 1))
	byte_index = math.floor(byte_index / 2)  -- Convert hex position to byte index

	local global_offset = (row * cols) + byte_index + 1
	return global_offset
end

return M


