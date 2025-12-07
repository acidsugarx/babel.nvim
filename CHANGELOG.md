# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/acidsugarx/babel.nvim/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/acidsugarx/babel.nvim/releases/tag/v0.1.0
