<div align="center">

# 🌍 babel.nvim

**Translate text without leaving Neovim**

[![Neovim](https://img.shields.io/badge/Neovim-0.9+-57A143?style=for-the-badge&logo=neovim&logoColor=white&color=a6e3a1)](https://neovim.io)
[![Lua](https://img.shields.io/badge/Lua-5.1+-2C2D72?style=for-the-badge&logo=lua&logoColor=white&color=89b4fa)](https://lua.org)
[![License](https://img.shields.io/badge/License-MIT-pink?style=for-the-badge&color=f5c2e7)](./LICENSE)

</div>

---

<!-- TODO: Add GIF demo -->
<!-- ![Demo](assets/demo.gif) -->

## ✨ Features

- 🔤 Translate selected text or word under cursor
- 🪟 Multiple display modes (float, picker)
- 🔍 Auto-detect installed picker
- 📋 Copy translation to clipboard with `y`
- ⚡ Async translation (non-blocking)

### Supported Pickers

| Picker | Status |
|--------|:------:|
| Native float | ✅ |
| [snacks.nvim](https://github.com/folke/snacks.nvim) | ✅ |
| [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) | ✅ |
| [fzf-lua](https://github.com/ibhagwan/fzf-lua) | ✅ |
| [mini.pick](https://github.com/echasnovski/mini.pick) | ✅ |

## ⚡ Requirements

- Neovim >= 0.9.0
- `curl`

**Optional** (for picker display):

- snacks.nvim, telescope.nvim, fzf-lua, or mini.pick

## 📦 Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "acidsugarx/babel.nvim",
  version = "*", -- recomended for the latest tag, not main
  opts = {
    target = "ru",  -- target language
  },
  keys = {
    { "<leader>tr", mode = "v", desc = "Translate selection" },
    { "<leader>tw", desc = "Translate word" },
  },
}
```

## ⚙️ Configuration

### Minimal Setup

```lua
require("babel").setup({
  target = "ru",
})
```

### Full Options

<details>
<summary>Default Configuration</summary>

```lua
require("babel").setup({
  source = "auto",        -- source language (auto-detect)
  target = "ru",          -- target language
  provider = "google",    -- translation provider: "google", "deepl"
  network = {
    connect_timeout = 5,   -- curl connect timeout in seconds
    request_timeout = 15,  -- max request time in seconds
  },
  history = {
    enabled = false,       -- keep in-memory translation history
    limit = 20,            -- max saved entries
  },
  display = "float",      -- "float" or "picker"
  picker = "auto",        -- "auto", "telescope", "fzf", "snacks", "mini"
  float = {
    border = "rounded",
    mode = "center", -- "center" or "cursor"
    max_width = 80,
    max_height = 20,
    auto_close_ms = 0, -- auto-close delay, 0 = disabled
    pin = true, -- allow pin toggle with `p` when auto-close is enabled
    copy_original = false, -- allow copying original text with `Y`
    nvim_open_win = {}, -- extra nvim_open_win() options (overrides defaults)
  },
  keymaps = {
    translate = "<leader>tr",
    translate_word = "<leader>tw",
  },
  -- DeepL provider settings (optional)
  deepl = {
    api_key = nil,        -- or use DEEPL_API_KEY env variable
    pro = nil,            -- nil = auto-detect, true = Pro, false = Free
    formality = "default", -- "default", "more", "less", "prefer_more", "prefer_less"
  },
})
```

</details>

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `source` | string | `"auto"` | Source language (auto-detect) |
| `target` | string | `"ru"` | Target language code |
| `provider` | string | `"google"` | Translation provider: `"google"`, `"deepl"` |
| `network.connect_timeout` | number | `5` | Network connect timeout (seconds) |
| `network.request_timeout` | number | `15` | Network request timeout (seconds) |
| `history.enabled` | boolean | `false` | Enable in-memory translation history |
| `history.limit` | number | `20` | Maximum stored history entries |
| `display` | string | `"float"` | Display mode: `"float"` or `"picker"` |
| `picker` | string | `"auto"` | Picker: `"auto"`, `"telescope"`, `"fzf"`, `"snacks"`, `"mini"` |
| `float.mode` | string | `"center"` | Float preset: `"center"` or `"cursor"` |
| `float.auto_close_ms` | number | `0` | Auto-close timeout in milliseconds (`0` disables) |
| `float.pin` | boolean | `true` | Enable pin toggle key (`p`) when auto-close is enabled |
| `float.copy_original` | boolean | `false` | Enable copying original text with `Y` |
| `float.nvim_open_win` | table | `{}` | Extra `nvim_open_win()` options for float window |
| `deepl.api_key` | string | `nil` | DeepL API key (or use `DEEPL_API_KEY` env) |
| `deepl.pro` | boolean | `nil` | Force Pro/Free endpoint (`nil` = auto-detect by key) |
| `deepl.formality` | string | `"default"` | Formality: `"default"`, `"more"`, `"less"`, `"prefer_more"`, `"prefer_less"` |

### Cursor-follow float preset

For a smaller popup that follows your cursor, use:

```lua
require("babel").setup({
  float = {
    mode = "cursor",
    max_width = 60,
    max_height = 10,
  },
})
```

### Network timeout customization

You can tune provider request timeouts for slow/unstable networks:

```lua
require("babel").setup({
  network = {
    connect_timeout = 3,
    request_timeout = 25,
  },
})
```

### Translation history

You can keep the latest successful translations in memory:

```lua
require("babel").setup({
  history = {
    enabled = true,
    limit = 50,
  },
})
```

### Float window customization

You can override Babel's default float settings by passing options directly to `nvim_open_win()`:

```lua
require("babel").setup({
  float = {
    max_width = 60,
    max_height = 10,
    nvim_open_win = {
      relative = "cursor",
      row = 1,
      col = 0,
      anchor = "NW",
      border = "single",
      title = " Babel ",
    },
  },
})
```

### Language Codes

<details>
<summary>Common language codes</summary>

| Code | Language |
|------|----------|
| `en` | English |
| `ru` | Russian |
| `de` | German |
| `fr` | French |
| `es` | Spanish |
| `it` | Italian |
| `pt` | Portuguese |
| `zh` | Chinese |
| `ja` | Japanese |
| `ko` | Korean |
| `ar` | Arabic |
| `hi` | Hindi |
| `tr` | Turkish |
| `pl` | Polish |
| `uk` | Ukrainian |

</details>

## 🚀 Usage

### Keymaps

| Keymap | Mode | Description |
|--------|------|-------------|
| `<leader>tr` | Visual | Translate selection |
| `<leader>tw` | Normal | Translate word under cursor |

### Commands

| Command | Description |
|---------|-------------|
| `:Babel [text]` | Translate provided text |
| `:[range]Babel` | Translate selected line range (e.g. `:10,20Babel`) |
| `:BabelWord` | Translate word under cursor |
| `:BabelRepeat` | Repeat last translation input |

### In Translation Window

| Key | Action |
|-----|--------|
| `q` / `<Esc>` / `<CR>` | Close window |
| `y` | Copy translation to clipboard |
| `Y` | Copy original text (if `float.copy_original = true`) |
| `p` | Pin/unpin auto-close timer (if enabled) |
| `j` / `k` | Scroll |

## 🌐 Providers

| Provider | Status | API Key | Notes |
|----------|:------:|:-------:|-------|
| Google Translate | ✅ | No | Default, unofficial API |
| [DeepL](https://deepl.com) | 🧪 | Yes (free tier) | Best quality, 500k chars/month free |
| [LibreTranslate](https://libretranslate.com) | 🔜 | No | Open source, self-hostable |
| [Yandex](https://translate.yandex.ru) | 🔜 | Yes | Great for Russian |
| [Lingva](https://lingva.ml) | 🔜 | No | Google proxy, no rate limits |

> **🧪 Testing:** DeepL provider is implemented but needs testing. If you have a DeepL API key and want to help test, please [open an issue](https://github.com/acidsugarx/babel.nvim/issues) with your feedback!

<details>
<summary>DeepL Setup</summary>

1. Get a free API key at [deepl.com/pro#developer](https://www.deepl.com/pro#developer) (500k chars/month free)

2. Set up the API key (choose one):

   **Option A:** Environment variable
   ```bash
   export DEEPL_API_KEY="your-api-key-here"
   ```

   **Option B:** In config
   ```lua
   require("babel").setup({
     provider = "deepl",
     deepl = {
       api_key = "your-api-key-here",
     },
   })
   ```

3. The endpoint (Free/Pro) is auto-detected from the key suffix (`:fx` = Free). You can override with `deepl.pro = true/false`.

4. If no API key is found, babel.nvim will automatically fall back to Google Translate with a warning.

</details>

## 🤝 Contributing

Contributions are welcome! Feel free to:

- 🐛 Report bugs
- 💡 Suggest features
- 🔧 Submit pull requests

If you use AI coding assistants, check `AGENTS.md` for project architecture, quality gates, and safe-change checklist.

## 🙏 Acknowledgments

Thanks to the amazing Neovim plugin ecosystem:

- [folke](https://github.com/folke) for [snacks.nvim](https://github.com/folke/snacks.nvim) and [lazy.nvim](https://github.com/folke/lazy.nvim)
- [nvim-telescope](https://github.com/nvim-telescope) for [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [ibhagwan](https://github.com/ibhagwan) for [fzf-lua](https://github.com/ibhagwan/fzf-lua)
- [echasnovski](https://github.com/echasnovski) for [mini.nvim](https://github.com/echasnovski/mini.nvim)

## 📝 License

[MIT](./LICENSE) © Ilya Gilev
