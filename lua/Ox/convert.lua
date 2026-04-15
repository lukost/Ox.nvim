local M = {}

function M.convert_from_hex(bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local text_lines = {}
	local dos_le_step = 0
	local text_data = {}
	local do_insert = false
	local do_newline = false

	for _, line in ipairs(lines) do
		local hex_part = line:match("^[0-9A-Fa-f ]+ |") or ""
		for hex in hex_part:gmatch("%x%x") do
			local bt = string.char(tonumber(hex, 16))
			if vim.bo.fileformat == 'unix' then
				if bt == '\n' then
					do_insert = false
					do_newline = true
				else
					do_insert = true
					do_newline = false
				end
			elseif vim.bo.fileformat == 'mac' then
				if bt == '\r' then
					do_insert = false
					do_newline = true
				else
					do_insert = true
					do_newline = false
				end
			elseif vim.bo.fileformat == 'dos' then
				if bt == '\n' then -- end-of-line sequence spotted
					if dos_le_step == 1 then
						do_insert = false
						do_newline = true
					else
						do_insert = true
						do_newline = false
					end
					dos_le_step = 0 -- reset end-of-line sequence
				elseif bt == '\r' then -- start end-of-line sequence
					if dos_le_step == 0 then
						do_insert = false
						do_newline = false
					else
						do_insert = true -- previeous character was '\r' and not inserted, so insert
						do_newline = false
					end
					dos_le_step = 1 -- initiate end_of_line_sequence
				else -- normal character
					dos_le_step = 0 -- reset end_of_line sequence
					if dos_le_step >0 then
						table.insert(text_data, '\r') -- insert \r from previous iteration of '\r'
					end
					do_insert = true
					do_newline = false
				end
			end
			if do_insert then
				table.insert(text_data, bt )
			end
			if do_newline then
				table.insert(text_lines, table.concat(text_data, ""))
				text_data = {}
			end
		end
	end
	table.insert(text_lines, table.concat(text_data, ""))
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, text_lines)
end

function M.convert_to_hex(bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local hex_view = {}
	local hex_liner, hex_pv = {}, {}
	local liner_counter = 0
	local group_size = M.config.conversion.groups
	local cols = M.config.conversion.cols

	for _, line in ipairs(lines) do
		if _ ~= #lines then
			if (vim.bo.fileformat == 'dos') then
				line = line .. '\r\n'
			elseif vim.bo.fileformat == 'mac' then
				line = line .. '\r'
			else
				line = line .. '\n'
			end
		end
		for i = 1, #line do
			local byte = line:byte(i) or 0
			table.insert(hex_liner, string.format("%02X", byte))
			liner_counter = liner_counter + 1

			if liner_counter % group_size == 0 and liner_counter < cols then
				table.insert(hex_liner, " ")
			end

			table.insert(hex_pv, (byte >= 32 and byte <= 126) and string.char(byte) or ".")

			if liner_counter >= cols then
				table.insert(hex_view, table.concat(hex_liner, "") .. " | " .. table.concat(hex_pv, ""))
				hex_liner, hex_pv = {}, {}
				liner_counter = 0
			end
		end
	end

	if liner_counter > 0 then
		while liner_counter < cols do
			table.insert(hex_liner, "  ")
			liner_counter = liner_counter + 1
			if liner_counter % group_size == 0 and liner_counter < cols then
				table.insert(hex_liner, " ")
			end
		end
		table.insert(hex_view, table.concat(hex_liner, "") .. " | " .. table.concat(hex_pv, ""))
	end

	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, hex_view)
end

function MyStatusColumn()
	local bufnr = vim.api.nvim_get_current_buf()
	local lnum = vim.v.lnum
	return M.address_map and M.address_map[bufnr] and M.address_map[bufnr][lnum] or ""
end

function M.update_address_column(bufnr)
	local config = M.config.conversion
	if not config then return end

	M.address_map = M.address_map or {}
	M.address_map[bufnr] = {}

	local lines = vim.api.nvim_buf_line_count(bufnr)
	for i = 1, lines do
		local addr = string.format("%0" .. config.addrlen .. "X" .. " ", (i - 1) * config.cols)
		M.address_map[bufnr][i] = addr
	end

	vim.o.statuscolumn = "%!v:lua.MyStatusColumn()"
end

function M.update_preview_column(bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	for lnum, line in ipairs(lines) do
		local hex_part = line:match("^[0-9A-Fa-f ]+") or ""
		local preview_start = #hex_part + 3 -- Account for " |"
		local preview_part = line:sub(preview_start)

		local new_preview = ""
		local hex_values = {}
		for hex in hex_part:gmatch("%x%x") do
			table.insert(hex_values, tonumber(hex, 16) or 0)
		end

		for _, byte in ipairs(hex_values) do
			if byte >= 32 and byte <= 126 then
				new_preview = new_preview .. string.char(byte)
			else
				new_preview = new_preview .. "."
			end
		end

		if preview_part ~= new_preview then
			vim.api.nvim_buf_set_text(bufnr, lnum - 1, preview_start, lnum - 1, #line, {" | " .. new_preview})
		end
	end
end

function M.setup_keymaps()
	if not M.config.keymaps.enabled then return end
	for cmd, mapping in pairs(M.config.keymaps) do
		if cmd ~= "enabled" then
			vim.api.nvim_set_keymap("n", mapping, ":" .. cmd .. "<CR>", { noremap = true, silent = true })
		end
	end
end

function M.setup()
	M.setup_keymaps()

	vim.api.nvim_create_user_command("OxEnterHex", function()
		M.enter_hex_mode(vim.api.nvim_get_current_buf())
	end, {})

	vim.api.nvim_create_user_command("OxLeaveHex", function()
		M.exit_hex_mode(vim.api.nvim_get_current_buf())
	end, {})

	vim.api.nvim_create_user_command("OxToggle", function()
		local bufnr = vim.api.nvim_get_current_buf()
		if M.configs[bufnr] then
			M.exit_hex_mode(bufnr)
		else
			M.enter_hex_mode(bufnr)
		end
	end, {})

	return M
end
