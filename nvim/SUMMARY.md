# Neovim 0.12 config — session summary

Minimal Neovim config built from scratch using the native `vim.pack` package
manager (Neovim 0.12+), no lazy.nvim/packer, no Mason. Modular structure:
`plugin/*.lua` files auto-source alphabetically at startup, numbered prefixes
control load order. Language servers installed as system packages via
pacman/AUR, never Mason.

## Files (in `~/.config/nvim/`)

| File | Purpose |
|---|---|
| `init.lua` | Core options, `vim.loader.enable()` |
| `plugin/00-keymaps.lua` | Basic keymaps, window nav, diagnostics nav |
| `plugin/01-colorscheme.lua` | tokyonight, transparent background |
| `plugin/10-treesitter.lua` | nvim-treesitter (`main` branch — new API, no `configs` module), highlighting only, no indentexpr |
| `plugin/20-lsp.lua` | All LSP servers via `vim.lsp.enable()`, `nvim-lspconfig` used only for its bundled config definitions |
| `plugin/30-statusline.lua` | lualine, tokyonight theme, `globalstatus = true` |
| `plugin/40-format.lua` | conform.nvim, fills gaps LSP formatting doesn't cover, falls back to LSP formatter otherwise |
| `plugin/41-pairs.lua` | nvim-autopairs (`check_ts = true`) |
| `plugin/50-which-key.lua` | which-key, group labels for leader prefixes |
| `plugin/51-render-markdown.lua` | render-markdown.nvim, live in-buffer markdown rendering |
| `plugin/60-oil.lua` | oil.nvim, replaces netrw entirely (`default_file_explorer = true`) |
| `plugin/62-snacks.lua` | snacks.nvim: picker (telescope replacement), indent, bigfile, notifier, scope, statuscolumn, gitbrowse, terminal |
| `plugin/70-completion.lua` | blink.cmp (pinned to `^1` for prebuilt binary), `super-tab` keymap preset, friendly-snippets |

Explicitly **not** using: telescope.nvim (replaced by `snacks.picker` per
user preference), mini.nvim/mini.pairs (chose nvim-autopairs instead, for
future blink.cmp completion-confirm integration), Mason (all LSP servers
installed via pacman/AUR instead), nvim-cmp (chose blink.cmp).

## Language servers configured (`plugin/20-lsp.lua`)

From this Arch wiki install list:
```
bash-language-server clang neocmakelsp vscode-css-languageserver
dockerfile-language-server nodejs-compose-language-service fish-lsp
vscode-html-languageserver deno vscode-json-languageserver jdtls
lua-language-server autotools-language-server marksman rumdl basedpyright
ruff qt6-declarative rust-analyzer systemd-lsp texlab vim-language-server
lemminx yaml-language-server sqls typescript-language-server
```

Notable non-default wiring:
- **ts_ls vs denols**: mutually exclusive via `root_markers`
  (`package.json` vs `deno.json(c)`), not a global choice
- **Python**: `basedpyright` for type checking/intelligence,
  `ruff` for lint/format/import-sort; `basedpyright.disableOrganizeImports
  = true`, ruff's hover disabled to avoid overlap
- **Markdown**: `marksman` for navigation/completion, `rumdl` for
  diagnostics + formatting (`cmd = { "rumdl", "server" }`). Neither reads
  the LSP `settings` table — both are configured via their own
  `.marksman.toml` / `.rumdl.toml` project files instead
- **qmlls**, **systemd_ls**: not in nvim-lspconfig, defined manually
  (`cmd`, `filetypes`, `root_markers`)
- systemd unit file extensions (`.service`, `.socket`, etc.) mapped to a
  `systemd` filetype via `vim.filetype.add`
- LSP semantic tokens **disabled globally** (`client.server_capabilities.
  semanticTokensProvider = nil` in `LspAttach`) — works around a Neovim
  core race-condition crash in `semantic_tokens.lua` (nil-comparison,
  corrupts highlight cache over time). Treesitter handles highlighting
  instead, unaffected.

## Known issues hit + fixes applied

1. **`nvim-treesitter.configs` not found** — `main` branch was fully
   rewritten, module removed. Fixed: `require("nvim-treesitter").setup()`
   + `.install(parsers)`, manual `vim.treesitter.start()` per filetype via
   autocmd.
2. **`tree-sitter build` ENOENT** — `main` branch shells out to the real
   `tree-sitter` CLI now. Fixed: `pacman -S tree-sitter-cli`.
3. **Auto-indent broken (cursor jumps to column 1 on `<CR>`)** — caused by
   setting treesitter's `indentexpr`, which its own docs call
   "experimental"; silently returns bad values for languages without a
   proper `indents.scm` query. Fixed: removed the indentexpr override
   entirely, reverted to Neovim's built-in per-filetype indent scripts.
4. **`semantic_tokens.lua:425` crash / colors degrading over time** —
   Neovim core bug, race condition, worse with multiple LSP clients per
   buffer (which this config has several of). Fixed: disabled semantic
   tokens capability on attach (see above).
5. **Stuck in terminal insert mode, Ctrl+n does nothing** — real escape
   is `<C-\><C-n>` (two chords, not held together). Fixed: added
   `<Esc><Esc>` as a simpler escape in terminal mode, and made
   `<leader>tt` (terminal toggle) work from terminal mode too, not just
   normal mode.

## Full keybind reference

See the table given earlier in conversation — general nav, LSP
(`gd`/`gD`/`gr`/`K`/`<leader>rn`/`<leader>ca`/`<leader>td`), format
(`<leader>f`), completion (Tab/S-Tab/Enter, `super-tab` preset), oil (`-`),
snacks picker (`<leader><space>`, `/`, `,`, `sh`, `sd`, `sr`, `gb`, `tt`),
built-in comment toggle (`gcc`/`gc{motion}`).

## Not yet configured / discussed as optional

- Per-formatter indent style config (`.editorconfig`, `stylua.toml`,
  `.prettierrc`, `rustfmt.toml`, `.clang-format`) — discussed conceptually,
  no files generated yet
- Additional snacks modules mentioned but not enabled: `words`
- Additional folke plugins mentioned but not added: `flash.nvim`,
  `trouble.nvim`, `todo-comments.nvim`, `ts-comments.nvim`,
  `persistence.nvim`, `edgy.nvim`, `lazydev.nvim`, `neoconf.nvim`
- oil.nvim cannot compact single-child directory chains (e.g. `a/b/c` on
  one line) — open upstream feature request, not implemented in the
  plugin, no workaround beyond fast navigation or jumping via `:e path` /
  the picker

## User context relevant to future nvim work

- Arch Linux, Hyprland/Wayland, Fish shell in Kitty terminal
- Strong preference: pacman/AUR over any other install method wherever
  possible; git-source `vim.pack` accepted as the exception for Neovim
  plugins specifically since there's no better alternative
- Prefers concise, bullet-point-heavy answers
- Dotfiles: bare git repo, GitHub `FeineKatze/T22-dotFiles`
