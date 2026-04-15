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
M.get_hex_preview_position = function(col, config)
	local group_size = config.group
	local cols = config.cols
	local addr_offset = config.addrlen + 2

	local hex_start = addr_offset 
	local hex_width = (cols*2)+(cols/group_size)-1
	local hex_end = hex_start + hex_width
	
	if (col < hex_start) or (col > hex_end) then
		return -1
	end
	
	local offed = col - hex_start
	-- first calculate which group the cursor is in, 1-based
	local group_no = math.floor((offed)/(2*group_size+1)) + 1 
	-- next identify which character within the group the cursor is on
	local ccol = (offed - (group_no - 1)*(2*group_size+1))
	
	if (ccol >= group_size*2) then
		return -1
	end

	ccol = math.floor(ccol/2) + group_no*group_size + hex_end
	return (ccol)
end

M.get_hex_cursor_substring = function(len, config)
	local bufnum = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local row, col = cursor[1] - 1, cursor[2]
	local line = vim.api.nvim_buf_get_lines(bufnum, row, row + 1, false)[1] or ""
	if #line < 2 then return nil end

	local group_size = config.group
	local cols = config.cols
	local addr_offset = config.addrlen + 2

	local hex_start = addr_offset
	local hex_width = (cols * 2) + (cols / group_size) - 1
	local hex_end = hex_start + hex_width

	if (col < hex_start) or (col > hex_end) then
		return nil
	end

	local offed = col - hex_start
	local group_no = math.floor(offed / (2 * group_size + 1)) + 1
	local ccol = offed - (group_no - 1) * (2 * group_size + 1)

	if ccol >= group_size * 2 then
		return nil -- cursor is on the space between groups
	end

	-- byte index within the line (0-based)
	local byte_in_line = (group_no - 1) * group_size + math.floor(ccol / 2)

	local result = ""
	for i = 0, len - 1 do
		local b = byte_in_line + i
		if b >= cols then break end
		local bg = math.floor(b / group_size)  -- group index (0-based)
		local bb = b % group_size              -- byte index within group (0-based)
		local byte_col = hex_start + bg * (2 * group_size + 1) + bb * 2 + 1  -- 1-based
		local hex = line:sub(byte_col, byte_col + 1)
		if #hex == 2 and tonumber(hex, 16) then
			result = result .. hex
		else
			break
		end
	end

	return result ~= "" and result or nil
end
-- gets target byte offset of cursor position for given offset (in hex view) and xxd config 
M.get_text_offset = function(config)
	local group_size, cols = config.group, config.cols
	local addr_offset = config.addrlen + 2
	local cursor = vim.api.nvim_win_get_cursor(0)
	local row, col = cursor[1] - 1, cursor[2]

	-- Address column width in xxd mode
	local hex_start = addr_offset
	local hex_width = (cols * 2) + (cols / group_size) - 1
	local hex_end = hex_start + hex_width

	-- Ensure cursor is in the hex column
	if col < hex_start then
		return row * cols
	end
	if col > hex_end then
		return row * cols + cols - 1
	end
	
	local offed = col - hex_start
	local group_no = math.floor((offed)/(2*group_size+1)) + 1 
	local ccol = (offed - (group_no - 1)*(2*group_size+1))
	
	local global_offset = (row * cols) + group_no*group_size + math.floor(ccol/2)
	return global_offset - 1 
end

return M


