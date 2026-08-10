# AI Agent Guide for babel.nvim

This file helps coding agents understand the project quickly and make safe changes.

## Project goal

- Translate selected text or word under cursor without leaving Neovim.
- Keep API simple: `require("babel").setup({...})` + keymaps/commands.

## Architecture map

- `lua/babel/init.lua` - public API and keymap setup.
- `lua/babel/config.lua` - defaults + option merge, all LuaCATS type classes.
- `lua/babel/translate.lua` - provider registry + fallback chain + cache/history.
- `lua/babel/ui.lua` - render translation (float + telescope/fzf/snacks/mini pickers).
- `lua/babel/utils.lua` - visual selection / word / line-range text extraction.
- `lua/babel/languages.lua` - built-in ISO 639-1 list for the language picker.
- `lua/babel/providers/google.lua` - Google provider (unofficial endpoint).
- `lua/babel/providers/deepl.lua` - DeepL provider (Pro/Free auto-detect by `:fx` suffix).
- `lua/babel/providers/curl.lua` - jobstart wrapper, timeout/stderr/exit-code handling.
- `lua/babel/providers/capabilities.lua` - static provider capability table.
- `plugin/babel.lua` - user commands `:Babel`, `:BabelWord`, `:BabelRepeat`, `:BabelLang`, `:BabelSwap`, `:BabelHistory`, `:BabelHistoryClear`.

## Toolchain config

- `.luarc.json` - LuaJIT runtime, inlay hints ON, `missing-fields` disabled.
- `.stylua.toml` - 2 spaces, 120 cols, double quotes, always parens, never collapse simple statements.
- `selene.toml` - `std = "vim"`, `mixed_table = "allow"`. CI passes on 0 errors (warnings allowed).
- `scripts/minimal_init.lua` - test bootstrap; adds plugin + deps to rtp.

## Dev environment

- Requires Neovim >= 0.9.0 and `curl` on PATH.
- `deps/` is gitignored. `make test` auto-clones `deps/mini.test` on first run (see Makefile target).

## Build & test (exact commands from Makefile)

- `make chores` - style + lint. Run before every commit.
- `make style` - `stylua --check .`
- `make lint` - `selene lua/` + `typos lua/`
- `make test` - headless `nvim` with `MiniTest.run()` via `scripts/minimal_init.lua`.

All should pass before release tags.

## Conventions (observed in the code)

- Every public function has `---@param` / `---@return` LuaCATS annotations. Inline docs are mandatory — no exceptions, including providers and helpers.
- New options must be added as a `---@field` on the matching class in `config.lua` AND to the `defaults` table.
- Provider errors are structured tables `{ code, provider, message }`, never bare strings.
- `vim.notify` messages use the `Babel: ` prefix.
- Commit messages: `<type>: <summary>` (e.g. `docs:`, `feat:`, `fix:`).

## Testing notes

- mini.test discovers files matching `tests/test_*.lua` (currently 9 files, 58 cases).
- Tests use function stubs for `curl.run` / `vim.notify` / `vim.api` — never real network calls.
- Validate both success and failure branches.

## Expected behavior

- Empty text should never trigger provider request.
- Unknown provider should error with clear `vim.notify` message.
- DeepL without key should fall back to Google with warning.
- Float mode supports:
  - `float.mode = "center"`
  - `float.mode = "cursor"`
  - `float.nvim_open_win` overrides defaults/preset

## Pitfalls

- `vim.tbl_deep_extend("force", defaults, opts)` ignores `nil` values in opts — a `nil` field will NOT override a non-nil default.
- `deps/` must not be committed; it is auto-cloned by the Makefile.

## Change checklist for agents

- Update LuaCATS annotations when adding new options.
- Update README options table/examples for user-facing config changes.
- Add/adjust tests for every behavior change.
- Run `make chores` and `make test` before claiming done.

## Near-term priorities

- Harden provider error handling (`on_exit`, `stderr`, exit codes).
- Issue #4: interactive provider selection (`:BabelSelect`).
- Issue #1: Yandex provider.
