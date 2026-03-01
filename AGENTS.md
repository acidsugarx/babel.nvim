# AI Agent Guide for babel.nvim

This file helps coding agents understand the project quickly and make safe changes.

## Project goal

- Translate selected text or word under cursor without leaving Neovim.
- Keep API simple: `require("babel").setup({...})` + keymaps/commands.

## Architecture map

- `lua/babel/init.lua` - public API and keymap setup.
- `lua/babel/config.lua` - defaults + option merge.
- `lua/babel/translate.lua` - provider selection + fallback logic.
- `lua/babel/ui.lua` - render translation (float/picker).
- `lua/babel/providers/google.lua` - Google provider.
- `lua/babel/providers/deepl.lua` - DeepL provider.
- `plugin/babel.lua` - user commands `:Babel`, `:BabelWord`.

## Expected behavior

- Empty text should never trigger provider request.
- Unknown provider should error with clear `vim.notify` message.
- DeepL without key should fall back to Google with warning.
- Float mode supports:
  - `float.mode = "center"`
  - `float.mode = "cursor"`
  - `float.nvim_open_win` overrides defaults/preset

## Quality gates

- `make style`
- `make lint`
- `make test`

All should pass before release tags.

## Testing notes

- mini.test discovers files matching `tests/**/test_*.lua`.
- Prefer deterministic tests with function stubs over network calls.
- Validate both success and failure branches.

## Change checklist for agents

- Update LuaCATS annotations when adding new options.
- Update README options table/examples for user-facing config changes.
- Add/adjust tests for every behavior change.
- Update CHANGELOG entry for release-impacting changes.

## Near-term priorities

- Harden provider error handling (`on_exit`, `stderr`, exit codes).
- Add translate/provider command-level tests.
- Enable test job in CI.
