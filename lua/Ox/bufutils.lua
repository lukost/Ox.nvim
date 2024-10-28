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
   local line_length = 2* config.cols * config.group + config.cols/config.group
   local offset_row = 1 + math.floor(offset/config.cols)
   local ofc = offset%config.cols
   local offset_col = config.addrlen + 2
	offset_col = offset_col + ofc * 2 + math.floor(ofc/config.group)
   return {offset_row, offset_col}
end

-- gets target PREVIEW cursor position for given byte offset and xxd config
-- returns: {row, column}
M.get_hex_preview_position = function(offset, config)
   local line_length = 2* config.cols * config.group + config.cols/config.group
   local offset_row = math.floor(offset/config.cols)
   local ofc = offset%config.cols
   local offset_col = ofc+config.addrlen + 2 + config.cols*2 + math.floor(config.cols/config.group) + 2
   return {offset_row, offset_col}
end

-- gets target byte offset of cursor position for given offset (in hex view) and xxd config 
M.get_text_offset = function(offset, config)
	-- TODO: implement the meat
	return -1
end

return M


