# Ox.nvim

Enhanced hex/binary editing for Neovim. Wraps `xxd` to toggle any buffer between its raw content and a hex view, while keeping the cursor on the same byte, highlighting the ASCII preview column in real time, and showing a floating sidebar with signed integer interpretations at the cursor.

## Features

- Toggle hex view on any buffer with `:OxToggle` or `<Leader>x`
- Cursor lands on the correct byte when entering and exiting hex mode
- Real-time highlight syncing between the hex column and the ASCII preview
- Floating sidebar showing offset and INT8/INT16/INT32 (LE & BE, signed) at the cursor

## Requirements

- Neovim 0.9+
- `xxd` (ships with Vim; available via most package managers)
- [`plenary.nvim`](https://github.com/nvim-lua/plenary.nvim) (used for hot-reloading during development)

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "lukost/Ox2.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("Ox").setup()
  end,
}
```

## Usage

| Command | Default key | Action |
|---|---|---|
| `:OxToggle` | `<Leader>x` | Toggle hex mode on the current buffer |

Enter hex mode on any buffer — including binary files. Exit returns the buffer to its original content with the cursor restored to the same byte.

## Configuration

Pass a table to `setup()` to override defaults:

```lua
require("Ox").setup({
  view = {
    keep_position   = true,   -- restore cursor byte position on toggle
    highlight_cursor = true,  -- highlight ASCII preview column at cursor
  },
  xxd = {
    command  = "xxd",  -- xxd binary
    cols     = 16,     -- bytes per row
    group    = 2,      -- bytes per hex group
    addrlen  = 8,      -- address column width (hex digits)
    binary   = false,
    EBCDIC   = false,
    endianness = "big",
    uppercase  = false,
  },
  keys = {
    register = true,  -- register default keymap
    map = {
      toggle = "<Leader>x",
    },
  },
})
```

## Sidebar

When hex mode is active a floating window appears in the top-right corner showing:

```
Offset: 0x1A4
INT8:    -92
INT16 BE:-23552
INT16 LE: 256
INT32 BE:-1526726656
INT32 LE: 16973824
```

Values update on every cursor move. The sidebar closes automatically when hex mode is exited.

## Development

Hot-reload during development by re-sourcing the entry point inside Neovim:

```
:luafile lua/Ox.lua
```

`plenary.nvim` must be available in the Neovim instance. There is no build step or test suite.
