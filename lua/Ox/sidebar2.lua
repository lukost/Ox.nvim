local M = {}
M.sidebar_win = nil
M.sidebar_buf = nil
M.config = nil
M.u_buf = require('Ox.bufutils')

-- Function to create a floating window
local function create_sidebar()
    if M.sidebar_win then return end  -- Prevent duplicate windows

    local buf = vim.api.nvim_create_buf(false, true)
    local opts = {
        relative = "editor",
        width = 30,
        height = 6,
        row = 1,
        col = vim.o.columns - 31,
        style = "minimal",
        border = "rounded"
    }
    local win = vim.api.nvim_open_win(buf, false, opts)
    vim.api.nvim_win_set_option(win, "winblend", 10)

    M.sidebar_buf = buf
    M.sidebar_win = win
end

-- Function to read bytes and compute integer values
local function get_cursor_values(bufnum)
    if not M.config then return nil end

    local bit = require("bit")
    local function as_int(bytes, little_endian, signed)
        if #bytes == 0 then return "N/A" end
        local value = 0
        if little_endian then
            for i = #bytes, 1, -1 do
                value = bit.bor(bit.lshift(value, 8), bytes[i])
            end
        else
            for i = 1, #bytes do
                value = bit.bor(bit.lshift(value, 8), bytes[i])
            end
        end
        if signed then
            local msb = little_endian and bytes[#bytes] or bytes[1]
            if msb and msb >= 0x80 then
                value = value - (1 << (#bytes * 8))
            end
        end
        return value
    end

    local hex_str = M.u_buf.get_hex_cursor_substring(4, M.config)
    if not hex_str then return nil end

    local byte_values = {}
    for i = 1, #hex_str, 2 do
        local b = tonumber(hex_str:sub(i, i + 1), 16)
        if b then table.insert(byte_values, b) end
    end
    if #byte_values == 0 then return nil end

    local offset = M.u_buf.get_text_offset(M.config)

    return {
        string.format("Offset: 0x%X", offset),
        string.format("INT8:    %d", as_int({byte_values[1]}, false, true)),
        string.format("INT16 BE:%d", as_int({byte_values[1], byte_values[2]}, false, true)),
        string.format("INT16 LE:%d", as_int({byte_values[1], byte_values[2]}, true, true)),
        string.format("INT32 BE:%d", as_int({byte_values[1], byte_values[2], byte_values[3], byte_values[4]}, false, true)),
        string.format("INT32 LE:%d", as_int({byte_values[1], byte_values[2], byte_values[3], byte_values[4]}, true, true)),
    }
end

-- Function to update sidebar content
local function update_sidebar()
    if not M.sidebar_win then return end
    local bufnum = vim.api.nvim_get_current_buf()
    local values = get_cursor_values(bufnum)
    if values then
        vim.api.nvim_buf_set_lines(M.sidebar_buf, 0, -1, false, values)
    end
end

function M.show_sidebar(config)
    M.config = config
    local bufnum = vim.api.nvim_get_current_buf()
    if not M.sidebar_win then create_sidebar() end

    vim.api.nvim_create_autocmd({"CursorMoved", "CursorMovedI"}, {
        buffer = bufnum, -- Restrict to the current buffer only
        callback = update_sidebar,
        group = vim.api.nvim_create_augroup("OxHexSidebar_" .. bufnum, { clear = true })
    })

    update_sidebar()
end

function M.hide_sidebar()
    if M.sidebar_win then
        vim.api.nvim_win_close(M.sidebar_win, true)
        M.sidebar_win = nil
        M.sidebar_buf = nil
    end
    M.config = nil

    local bufnum = vim.api.nvim_get_current_buf()
    pcall(vim.api.nvim_del_augroup_by_name, "OxHexSidebar_" .. bufnum)
end

return M
