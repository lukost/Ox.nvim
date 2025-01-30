-- Function to highlight a character at (x2, y2)
local function highlight_char_at(x2, y2)
    -- Clear any existing highlights in the namespace
    local ns_id = vim.api.nvim_create_namespace('single_char_highlight')
    vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)

    -- Get the line at x2, which is the row
    local line = vim.api.nvim_buf_get_lines(0, x2 - 1, x2, false)[1]
    if line and y2 <= #line then
        -- Highlight the character at (x2, y2)
        vim.api.nvim_buf_add_highlight(0, ns_id, 'Visual', x2 - 1, y2 - 1, y2)
    end
end

-- Function to calculate x2 and y2 and apply highlighting
local function update_highlight()
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local x1 = cursor_pos[1]
    local y1 = cursor_pos[2] + 1 -- Adjust for 1-based indexing

    -- Calculate x2 and y2
    local x2 = 2 * x1
    local y2 = y1

    -- Highlight the character at (x2, y2)
    highlight_char_at(x2, y2)
end

-- Set up an autocommand to trigger on CursorMoved
vim.api.nvim_exec([[
  augroup HighlightSingleChar
    autocmd!
    autocmd CursorMoved * lua update_highlight()
  augroup END
]], false)
