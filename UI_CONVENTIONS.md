# Neovim Floating Window UI Conventions

Extracted from the source of **snacks.nvim** (`snacks.win`), **lazy.nvim** (`lazy.view.float`), **dressing.nvim** (`select/builtin` + `util`), **noice.nvim** (`view/nui` + `config/views`), and **fzf-lua** (`utils`).

These are actionable conventions babel.nvim's `ui.lua` should adopt.

---

## 1. Window creation (`nvim_open_win`)

### zindex ladder (consistent across the ecosystem)
| Layer | zindex | Who |
|---|---|---|
| Backdrop / dim overlay | **49** (main zindex − 1) | lazy, snacks |
| Main floating window | **50** | lazy, snacks (default) |
| Hover / transient popup | **45** | noice `hover` |
| `vim.ui.select` / input | **150** | dressing (UI.select must sit above plugin floats) |
| Title sub-window (pre-0.9 hack) | **151** | dressing |
| Popupmenu / cmdline | **60–65** | noice |
| Confirm dialogs / cmdline popup | **200–210** | noice (must be above everything) |

**Rule for babel:** the translation display float → `zindex = 50`. A picker overlay should be `zindex = 150` (it's a `ui.select`-like transient). Backdrop, if used, is `zindex = 49`.

### `nvim_open_win` config — the canonical set
Every plugin passes these. babel should too:

```lua
vim.api.nvim_open_win(buf, enter, {
  relative = "editor",      -- or "cursor" for hover/picker-at-cursor
  anchor   = "NW",          -- dressing/noice default for popups
  width    = <int>,         -- ALWAYS pre-computed to int; never pass floats like 0.9
  height   = <int>,
  row      = <int>,         -- math.floor((max_lines - height) / 2) for center
  col      = <int>,
  style    = "minimal",     -- universal: strips number/relativenumber/etc.
  border   = "rounded",     -- see §5
  zindex   = 50,            -- see ladder
  title    = " title ",     -- nvim >= 0.9 only
  title_pos = "center",
})
```

- **Always compute size to an integer first.** dressing (`util.lua`) and lazy both have a helper: `value > 1 and math.min(value, max) or math.floor(max * value)`. Snacks accepts `0.9` but resolves it in `:dim()`. babel should resolve early (the dressing way) to keep the `open_win` call clean.
- **`noautocmd`** — lazy passes `noautocmd = self.opts.noautocmd`; fzf-lua wraps *every* window mutation in an `eventignore` helper. Opening the float with `noautocmd = true` prevents `BufEnter`/`FileType` storms. **Recommendation:** open with `noautocmd = true`, then set filetype manually (snacks does this to prevent treesitter attaching prematurely).
- **`relative = "editor"`** for centered translation window; **`relative = "cursor"`** for a picker that should appear at cursor (noice hover, dressing cursor mode). When `relative = "cursor"`, set `row = 1, col = 0` (below cursor) like noice hover.
- **`enter`**: `false` for non-interactive display (translation result), `true` for picker where user must move cursor. fzf-lua always enters; noice hover explicitly sets `enter = false`.

---

## 2. Buffer setup

### The universal buffer recipe
All five create a **scratch buffer** (`nvim_create_buf(false, true)` — listed=false, scratch=true) and then set:

```lua
local buf = vim.api.nvim_create_buf(false, true)
vim.bo[buf].swapfile  = false
vim.bo[buf].bufhidden = "wipe"      -- lazy: "wipe" unless persistent, then "hide"
vim.bo[buf].buftype   = "nofile"
vim.bo[buf].filetype  = "babel"     -- or "DressingSelect" / "snacks_win" / "noice"
```

| Option | Value | Source |
|---|---|---|
| `bufhidden` | `"wipe"` (default), `"hide"` if you want to reuse the buffer | lazy (persistent flag), dressing (`"wipe"`), snacks (`scratch_buf`) |
| `buftype` | `"nofile"` | all |
| `swapfile` | `false` | all |
| `modifiable` | `false` after writing lines (dressing sets false right after `nvim_buf_set_lines`; noice toggles `true` → render → `false` around each `show()`) | dressing, noice |
| `filetype` | unique plugin filetype (`"babel"`), set **after** `open_win` with `noautocmd` | snacks |

**Rule for babel:** set content with `modifiable = true`, then immediately `vim.bo[buf].modifiable = false`. This prevents accidental edits and matches dressing/noice. Use `bufhidden = "wipe"` for the translation result (single-use); `"hide"` only if reusing a persistent buffer.

### Text / lines
- dressing computes `lines` as a Lua table, then **one** `nvim_buf_set_lines(buf, 0, -1, true, lines)` call.
- snacks supports `opts.text` (string or string[]) set at buffer creation.
- noice renders via a message-object `:render(buf, ns, linenr)` using extmarks.

**For babel:** build a Lua table of translation lines, single `set_lines` call, then lock `modifiable = false`.

---

## 3. Keymaps

### Buffer-local + `nowait` — universal
**Every plugin uses buffer-local keymaps with `nowait = true`.** This is the single most consistent convention.

- **lazy.nvim** (`on_key`):
  ```lua
  vim.keymap.set("n", key, function() fn(self) end, {
    nowait = true,
    buffer = self.buf,
    desc = desc,
  })
  ```
- **snacks.win** (`:map`): iterates `self.keys`, sets `opts.buffer = self.buf`, `opts.nowait = true`. Keys are **sorted in reverse** so `nowait` precedence works (`table.sort(self.keys, function(a,b) return a[1] > b[1] end)`).
- **dressing** (`map_util`): `create_plug_maps` → `vim.keymap.set("", plug, rhs, { buffer=bufnr, desc=..., nowait=true })`. Then `create_maps_to_plug` maps user keys to `<Plug>` targets with `{ buffer=bufnr, remap=true, nowait=true }`.
- **noice** (`view/nui` mount): `self._nui:map("n", keys, function() self:hide() end, { remap=false, nowait=true })`.

### The `<Plug>` two-layer pattern (dressing)
dressing defines `<Plug>DressingSelect:Close` and `<Plug>DressingSelect:Confirm` as the *real* actions, then maps visible keys (`q`, `<Esc>`, `<CR>`) onto those plugs. This decouples the action from the key and makes remapping trivial for users.

### Default close keys
| Plugin | Close keys |
|---|---|
| lazy | configurable; default `q` |
| snacks | `q` → `"close"` action (in defaults) |
| dressing | user-configurable `mappings` table; close = `<Plug>DressingSelect:Close` |
| noice | `close.keys = { "q" }` per-view |

**Rule for babel:**
- All keymaps: `buffer = buf`, `nowait = true`, `desc = "..."`.
- Translation window: `q` and `<Esc>` → close.
- Picker: `q`/`<Esc>` → cancel, `<CR>` → confirm, plus `j`/`k` for navigation.
- Consider the `<Plug>Babel<...>` two-layer pattern if you want user-remappable keys (overkill for a simple plugin — direct buffer maps are fine).
- Sort defined keys reverse-alphabetically before mapping (snacks trick) so `nowait` works deterministically.

---

## 4. Auto-close behavior

### Close triggers used in the wild
| Event | Who | Purpose |
|---|---|---|
| **`WinClosed`** (with `pattern = winid`) | lazy, snacks | primary lifecycle — cleanup when window closed by any means |
| **`BufLeave`** | dressing, noice `popup`, snacks (`toggle_help`) | close when focus leaves the buffer |
| **`BufDelete` / `BufHidden`** | lazy | close when buffer goes away |
| **`CursorMoved`** | *(not used by these 5 for auto-close — common in hover/LSP popups via timers)* | — |
| **timer (`uv.timer` / `vim.defer_fn`)** | noice (`timeout` per-view, e.g. mini = 2000ms) | auto-dismiss notifications |
| **`VimResized`** | lazy, snacks | re-layout, not close |

**Key patterns:**
1. **`WinClosed` is the cleanup anchor.** lazy: `self:on("WinClosed", function() self:close() end, { win = true })` — the `{ win = true }` translates to `pattern = "<winid>"`. snacks does the same. This catches `:q`, `<C-w>c`, mouse-close — everything.
2. **`BufLeave` for transient popups.** dressing: `vim.api.nvim_create_autocmd("BufLeave", { buffer=bufnr, nested=true, once=true, callback=M.cancel })`. noice popup: `close.events = { "BufLeave" }`.
3. **noice wraps close in retry logic** for `E565` (text lock) and `E11` (command window open) — it reschedules via `vim.schedule` / `vim.defer_fn` with a retry cap.

**Rule for babel:**
- Translation window: `WinClosed` on the window (catches all close paths) + `BufLeave` (closes when user tabs away). Use `once = true` for `BufLeave`.
- Picker: `BufLeave` → cancel callback with `nil` (like dressing's `M.cancel`).
- Do **not** use `CursorMoved` to auto-close unless you add a debounced timer (the hover-popup pattern) — none of these 5 do bare `CursorMoved` close.
- Wrap close in `pcall` and handle E565/E11 by rescheduling (snacks `try_close` does exactly this with `vim.defer_fn`).

---

## 5. Borders & titles

### Border styles
- **Default:** `"rounded"` (noice popup, dressing default). lazy defaults to `"none"` but users override via `Config.options.ui.border`.
- **snacks** supports extra pseudo-borders via 8-char char-tables: `left`, `right`, `top`, `bottom`, `top_bottom`, `hpad`, `vpad` — useful for "help" style windows with only a top border.
- **noice hover** uses `border = { style = "none", padding = { 0, 2 } }` — no visible border but internal padding.

### Title conventions (nvim ≥ 0.9)
- **Format:** `" " .. title .. " "` — dressing trims and pads: `opts.prompt:gsub("^%s*(.-)%s*$", " %1 ")`. snacks adds an extra trailing space if last char is non-word (icons).
- **Position:** `"center"` is the universal default (lazy, snacks, dressing).
- **Title only when border exists:** snacks explicitly nils out title/footer when `border = "none"` — `if border then opts.title_pos = ... else opts.title, opts.footer = nil, nil end`.
- **Pre-0.9 fallback:** dressing creates a *separate* floating window at `row = -1` relative to the main window to simulate a title (`add_title_to_win`). Only needed if supporting nvim < 0.9.

### Footer (snacks innovation, nvim ≥ 0.10)
snacks supports `footer_keys` — auto-generates a footer showing `[q] close  [j] next` style hints from the buffer's keymap descriptions, highlighted with `SnacksFooterKey` / `SnacksFooterDesc`.

**Rule for babel:**
- Border: `"rounded"` for both translation window and picker.
- Title: `" Babel "` (or the target language), padded with spaces, `title_pos = "center"`.
- Only set title/footer if border is present (guard like snacks).
- Footer key hints are a nice touch if you want to surface `q=close` etc., but optional.

---

## 6. Highlight groups

### Theme-linked, never hardcoded — with one exception
**Every plugin links its highlight groups to Neovim's built-in float/message groups.** None hardcode hex colors *except* the backdrop dim.

| Plugin | Pattern |
|---|---|
| **lazy** | `vim.api.nvim_set_hl(0, "LazyNormal", { default = true })` links to `NormalFloat` via setup; backdrop is hardcoded `{ bg = "#000000" }` |
| **snacks** | `SnacksNormal = "NormalFloat"`, `SnacksTitle = "FloatTitle"`, `SnacksFooter = "FloatFooter"`, `SnacksWinSeparator = "WinSeparator"` — all linked, all `{ default = true }` |
| **noice** | per-view `winhighlight = { Normal = "NoicePopup", FloatBorder = "NoicePopupBorder", FloatTitle = "NoiceCmdlinePopupTitle" }`, and each `NoicePopup` → links to built-ins |
| **dressing** | uses built-in `FloatTitle`, `FloatBorder` directly via `winhighlight` |

### `winhighlight` is the mechanism
Every float sets `winhighlight` to remap `Normal` → plugin group, `FloatBorder` → plugin border group, `CursorLine` → selection group (for pickers):

```lua
vim.wo[win].winhighlight = "Normal:BabelNormal,FloatBorder:BabelBorder,FloatTitle:BabelTitle,CursorLine:BabelCursorLine"
```

Then define groups with `{ default = true }` so user themes override:
```lua
vim.api.nvim_set_hl(0, "BabelNormal", { default = true, link = "NormalFloat" })
vim.api.nvim_set_hl(0, "BabelBorder", { default = true, link = "FloatBorder" })
vim.api.nvim_set_hl(0, "BabelTitle",  { default = true, link = "FloatTitle" })
vim.api.nvim_set_hl(0, "BabelCursorLine", { default = true, link = "CursorLine" })
```

### `winblend` / transparency
- lazy: `winblend = self.opts.backdrop` (60) on the **backdrop** window only; main window has no winblend.
- snacks: sets `winblend = 0` if the user has a transparent background (`Snacks.util.is_transparent()`).
- dressing: inherits `winblend` from parent window for title sub-window.

**Rule for babel:**
- Define `Babel*` highlight groups, all `{ default = true, link = <builtin> }`.
- Set `winhighlight` on the float window mapping `Normal`/`FloatBorder`/`FloatTitle`/`CursorLine`.
- Do **not** hardcode colors anywhere except an optional backdrop.
- Only apply `winblend` if implementing a backdrop dim.
- Re-apply highlights on `ColorScheme` event (lazy does this via `lazy.view.colors.setup()`).

---

## 7. Window lifecycle (open / close / cleanup)

This is where the plugins converge most strongly. The pattern:

### Lifecycle phases (synthesized from lazy + snacks)

```
new(opts) → init(opts) → mount()/show()
  ├─ create augroup (clear=true)       ← "babel_win_<id>"
  ├─ create/open buffer
  │    └─ set bo: swapfile, bufhidden, buftype
  ├─ [create backdrop window]           ← optional, zindex = main-1
  ├─ nvim_open_win(buf, enter, config)
  ├─ set wo: winhighlight, wrap, foldenable, etc.
  ├─ set filetype (triggers syntax/TS)
  ├─ set buffer-local keymaps (nowait=true)
  ├─ register autocmds:
  │    ├─ WinClosed (pattern=winid)  → close()
  │    ├─ BufLeave  (buffer=buf)     → close()/cancel()
  │    └─ VimResized                  → re-layout (nvim_win_set_config)
  └─ on_win callback (if any)

close(opts)
  ├─ on_close callback (while win still valid)
  ├─ clear augroup (deletes all autocmds at once)  ← KEY: single cleanup point
  ├─ nil out self.win, self.buf
  └─ vim.schedule(function()
       ├─ nvim_win_close(win, true)   ← pcall'd
       ├─ nvim_buf_delete(buf, {force=true})  ← pcall'd
       └─ close backdrop window/buf
     end)
```

### Critical lifecycle conventions
1. **Per-window augroup.** lazy: `"trouble.window." .. self.id`; snacks: `"snacks_win_" .. self.id`. This lets `close()` do `nvim_del_augroup_by_id(augroup)` to wipe *all* autocmds in one call.
2. **Weak-self in autocmd callbacks.** lazy wraps `self` in a weak reference (`Util.weak(self)`) so autocmds don't leak the window object; if the object is GC'd, the autocmd returns `true` (deletes itself).
3. **Close is scheduled + pcall'd.** lazy: the actual `nvim_win_close`/`nvim_buf_delete` happens inside `vim.schedule`, wrapped in pcalls, with E565/E11 retry (snacks `try_close` retries up to 20× with 50ms backoff for E565).
4. **`WinClosed` is not recursive** — snacks detects if it's inside a `WinClosed` event (`vim.tbl_contains(event_stack, "WinClosed")`) and schedules the close instead of calling directly.
5. **Validity helpers:** `win_valid()` = `self.win and nvim_win_is_valid(self.win)`; `buf_valid()` analogous. lazy/snacks/dressing all have these.
6. **`hide()` vs `close()`:** `hide()` keeps the buffer (`wipe=false`); `close()` wipes it. `toggle()` switches between them. lazy implements all three.

### Reusable state object for babel
```lua
---@class BabelWin
---@field id integer
---@field buf? integer
---@field win? integer
---@field augroup? integer
---@field opts table
```

**Rule for babel:**
- Create an augroup per window instance, named `"babel_" .. id`.
- Register all autocmds in that group; `close()` deletes the group (single cleanup point).
- `close()` must be: scheduled, pcall'd, retry on E565/E11.
- Provide `win_valid()` / `buf_valid()` helpers.
- Separate `close()` (wipe buf) from `hide()` (keep buf) if you ever want to cache the translation.
- For the picker: cancel-path must invoke `on_choice(nil, nil)` (dressing contract) — never leave the callback hanging.

---

## Quick-reference: babel.nvim recommended values

| Concern | Value |
|---|---|
| Translation window zindex | `50` |
| Picker zindex | `150` |
| Backdrop zindex | `49` |
| `relative` | `"editor"` (centered) or `"cursor"` (picker-at-cursor) |
| `style` | `"minimal"` |
| `border` | `"rounded"` |
| `title_pos` | `"center"` |
| `bufhidden` | `"wipe"` |
| `buftype` | `"nofile"` |
| `swapfile` | `false` |
| Keymaps | `buffer = buf`, `nowait = true`, always |
| Close keys | `q`, `<Esc>` |
| Close autocmds | `WinClosed` (pattern=winid) + `BufLeave` (once, buffer-scoped) |
| Cleanup | per-window augroup, deleted on close |
| Highlights | `Babel*` groups, `{ default = true, link = <builtin> }` |
| `winhighlight` | `"Normal:BabelNormal,FloatBorder:BabelBorder,FloatTitle:BabelTitle"` |
| Resize | `VimResized` → `nvim_win_set_config` with recomputed width/height/row/col |
| Close safety | `pcall` + `vim.schedule`, retry on E565/E11 |
