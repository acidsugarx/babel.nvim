# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `:BabelLang` command and `<leader>tl` keymap for interactive language selection
- `:BabelSwap` command and `<leader>ts` keymap to swap source ↔ target
- `L` keymap inside translation float to change languages
- `languages` config option to override built-in language list
- `float.enter` option to open float without focusing it (default `true`)
- `float.auto_close` option to close float on `CursorMoved` in the source buffer (default `false`)
- `network.connect_timeout` and `network.request_timeout` options for configurable provider request time limits
- Shared curl transport layer for providers with unified `stdout/stderr/on_exit` handling
- Provider/translate reliability tests (curl transport, Google, DeepL, and error normalization paths)
- Command tests for `:Babel` and `:BabelWord`
- `:[range]Babel` support for translating explicit line ranges
- Optional in-memory translation history with configurable entry limit
- `:BabelRepeat` command to repeat the last translation input
- Float toggles for auto-close timer, pin/unpin, and original-text copy
- Configurable per-provider fallback chain (default `deepl -> google`)
- Optional in-memory translation cache with configurable entry limit
- Provider capability table API via `require("babel").get_provider_capabilities()`

### Changed
- Google/DeepL providers now use shared timeout configuration from `setup()`
- Added timeout-focused provider tests for configurable request deadlines
- Provider errors are normalized in `translate.lua` for consistent user-facing `vim.notify` messages
- CI now runs `make test` in GitHub Actions
- Updated README with history, range command, repeat command, and float toggle examples
- Updated README with fallback chain, cache, and provider capability usage examples

### Fixed
- Transport failures now handle curl exit codes consistently, including friendly timeout errors
- Google and DeepL now guard against empty responses, invalid JSON, and unexpected API payload shapes

## [0.1.2] - 2026-03-01

### Added
- `float.mode` option with presets: `"center"` (default) and `"cursor"`
- `float.nvim_open_win` option to pass custom `nvim_open_win()` parameters
- Tests for float mode defaults, cursor preset, override precedence, and invalid mode fallback

### Changed
- `make test` now exits headless Neovim explicitly with `qa`

## [0.1.1] - 2025-12-07

### Added
- DeepL provider with API key support (config or `DEEPL_API_KEY` env) — **🧪 experimental, may not work as expected**
- Auto-detect DeepL Free/Pro endpoint by key suffix (`:fx`)
- DeepL formality option (`default`, `more`, `less`, `prefer_more`, `prefer_less`)
- Automatic fallback to Google Translate when DeepL API key is missing

## [0.1.0] - 2025-12-07

### Added
- Google Translate provider (unofficial API)
- Visual selection translation
- Word under cursor translation
- Async translation via `vim.fn.jobstart`
- Float display mode with keymaps (q/Esc/Enter to close, y to copy)
- Multi-picker support: telescope, fzf-lua, snacks, mini.pick
- Auto-detection of available pickers
- Language selection with picker integration
- Newline preservation in translations

[Unreleased]: https://github.com/acidsugarx/babel.nvim/compare/v0.1.2...HEAD
[0.1.2]: https://github.com/acidsugarx/babel.nvim/releases/tag/v0.1.2
[0.1.1]: https://github.com/acidsugarx/babel.nvim/releases/tag/v0.1.1
[0.1.0]: https://github.com/acidsugarx/babel.nvim/releases/tag/v0.1.0
