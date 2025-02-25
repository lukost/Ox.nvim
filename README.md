# Ox.nvim

Ox.nvim is an enhanced hex edit mode for Neovim supporting interactive highlights, maintaining cursor position, and more.

## Overview

Ox.nvim provides an improved experience for editing binary files in Neovim by offering features such as interactive highlights and cursor position maintenance. It is designed to make hex editing more intuitive and efficient.

## Installation

To install Ox.nvim, use your preferred plugin manager. Below are examples for [packer.nvim](https://github.com/wbthomason/packer.nvim) and [Lazy.nvim](https://github.com/folke/lazy.nvim):

### Using packer.nvim

```lua
use 'lukost/Ox.nvim'
```

### Using Lazy.nvim

```lua
{
  'lukost/Ox.nvim',
  config = function()
    require('ox').setup({
      -- Configuration options
    })
  end
}
```

## Usage

To start using Ox.nvim, you need to set it up in your Neovim configuration file. Below is an example of how to configure and use the plugin:

```lua
-- Example usage
require('ox').setup({
  view = {
    keep_position = true, -- keep cursor position when switching from and to xxd
    highlight_cursor = true, -- use preview highlight when in hex mode
  },
  xxd = { -- xxd configuration
    command = 'xxd',
    cols = 16,
    group = 2,
    addrlen = 8,
  },
  keys = { -- keymappings
    register = true, -- register basic keymaps
    map = {
      toggle = "<Leader>x",
    },
  }
})
```

### Commands

- `:OxToggle` - Toggle hex edit mode.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request on GitHub if you have suggestions or improvements.

## License

MIT License. See [LICENSE](./LICENSE) for more information.
