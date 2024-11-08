--local augroup_hexmode_editor = vim.api.nvim_create_agroup('
local M = {}

-- gets byte offset of current file position
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
	local r_col = 0
	local r_row = 1
   local line_length = 2* config.cols + (2*config.cols)/config.group
   local c_row, c_col = unpack(vim.api.nvim_win_get_cursor(0))
   local bIsInHex = (c_col >= (config.addrlen + 2)) and ((c_col - config.addrlen+2) < line_length)
   local current_line = (vim.fn.line("."))
	r_row = r_row + (current_line - 1) * config.cols 
   if (bIsInHex) then
		c_col = c_col - config.addrlen - 1 -- -2 for ": " + 1 for base-0
		r_col = c_col - math.floor( c_col / (2 * config.group) ) --remove trailing spaces
		r_col = math.floor((r_col)/ 2) -- return to base-0
	else
		if(c_col < (config.addrlen + 2)) then
			r_col = 0
		else
			r_col = c_col - line_length - config.addrlen - 2
		end
   end

	return r_row + r_col
end

return M


