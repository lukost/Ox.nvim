local M = {}

M.sidebar = nil
M.selection_info = nil

local function as_int(bytes, little_endian, signed)
	if #bytes == 0 then return "N/A" end
	local value = 0
	if little_endian then
		for i = #bytes, 1, -1 do
			value = (value << 8) + bytes[i]
		end
	else
		for i = 1, #bytes do
			value = (value << 8) + bytes[i]
		end
	end
	if signed and bytes[1] and bytes[1] >= 0x80 then
		value = value - (1 << (#bytes * 8))
	end
	return value
end

local function extract_bytes(bufnum, start_col, end_col, start_row, end_row, group, cols)
	local bytes = {}
	for row = start_row, end_row do
		local line = vim.api.nvim_buf_get_lines(bufnum, row, row + 1, false)[1] or ""
		local hex_start = line:find("%x%x ")
		if not hex_start then return bytes end
		
		local row_start_col = (row == start_row) and start_col or hex_start
		local row_end_col = (row == end_row) and end_col or (#line - 1)
		row_start_col = math.max(row_start_col - hex_start + 1, 0)
		row_end_col = math.min(row_end_col - hex_start + 1, #line)
		
		local byte_count = #bytes
		for i = row_start_col, row_end_col, 3 do
			if byte_count >= 8 then break end
			local hex_byte = line:sub(i + 1, i + 2)
			local num = tonumber(hex_byte, 16)
			if num then 
				table.insert(bytes, num) 
				byte_count = byte_count + 1
			end
		end
	end
	return bytes
end

local function get_selection_values(bufnum, group, cols)
	local mode = vim.fn.mode()
	if mode ~= "v" and mode ~= "V" then
		M.selection_info = nil
		return
	end

	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")
	local start_row, start_col = start_pos[2] - 1, start_pos[3]
	local end_row, end_col = end_pos[2] - 1, end_pos[3]

	local selected_bytes = extract_bytes(bufnum, start_col, end_col, start_row, end_row, group, cols)
	local selection_size = #selected_bytes
	local values = {
		string.format("", ""),
		string.format("Selection %X bytes", selection_size)
	}

	if selection_size >= 1 then
		table.insert(values, string.format("INT8 LE: %d", as_int({selected_bytes[1]}, true, true)))
		table.insert(values, string.format("UINT8 LE: %d", as_int({selected_bytes[1]}, true, false)))
	end
	if selection_size >= 2 then
		table.insert(values, string.format("INT16 LE: %d", as_int({selected_bytes[1], selected_bytes[2]}, true, true)))
		table.insert(values, string.format("UINT16 LE: %d", as_int({selected_bytes[1], selected_bytes[2]}, true, false)))
		table.insert(values, string.format("INT16 BE: %d", as_int({selected_bytes[1], selected_bytes[2]}, false, true)))
		table.insert(values, string.format("UINT16 BE: %d", as_int({selected_bytes[1], selected_bytes[2]}, false, false)))
	end
	if selection_size >= 4 then
		table.insert(values, string.format("INT32 LE: %d", as_int(selected_bytes, true, true)))
		table.insert(values, string.format("UINT32 LE: %d", as_int(selected_bytes, true, false)))
		table.insert(values, string.format("INT32 BE: %d", as_int(selected_bytes, false, true)))
		table.insert(values, string.format("UINT32 BE: %d", as_int(selected_bytes, false, false)))
	end
	if selection_size == 8 then
		table.insert(values, string.format("INT64 LE: %d", as_int(selected_bytes, true, true)))
		table.insert(values, string.format("UINT64 LE: %d", as_int(selected_bytes, true, false)))
		table.insert(values, string.format("INT64 BE: %d", as_int(selected_bytes, false, true)))
		table.insert(values, string.format("UINT64 BE: %d", as_int(selected_bytes, false, false)))
	end
	
	M.selection_info = values
end

local function update_sidebar()
	if M.sidebar then
		local bufnum = vim.api.nvim_get_current_buf()
		local config = M.config[bufnum] or { group = 1, cols = 16 }
		get_selection_values(bufnum, config.group, config.cols)

		if M.selection_info then
			M.sidebar:update(M.selection_info)
		end
	end
end

function M.show_sidebar()
	if M.sidebar then return end

	M.sidebar = require("ox_sidebar").create({ position = "right" })

	vim.api.nvim_create_autocmd({"CursorMoved", "CursorMovedI", "VisualLeave"}, {
		callback = update_sidebar,
		group = vim.api.nvim_create_augroup("OxHexSidebar", { clear = true })
	})

	update_sidebar()
end

function M.hide_sidebar()
	if M.sidebar then
		M.sidebar:delete()
		M.sidebar = nil
	end
	vim.api.nvim_del_augroup_by_name("OxHexSidebar")
end

return M
