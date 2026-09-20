-- ~/.config/nvim/plugin/70-completion.lua
vim.pack.add({
	{ src = "https://github.com/rafamadriz/friendly-snippets" }, -- snippet collection
	{ src = "https://github.com/saghen/blink.cmp", version = vim.version.range("^1") },
	-- pinning to the v1.x tag matters: only tagged releases ship a prebuilt
	-- Rust fuzzy-matcher binary, `main` would require a local cargo build
})

require("blink.cmp").setup({
	keymap = { preset = "super-tab" }, -- Tab accepts/selects next, Shift-Tab previous, also drives snippet jumps
	appearance = {
		nerd_font_variant = "mono",
	},
	completion = {
		documentation = { auto_show = true },
	},
	sources = {
		default = { "lsp", "path", "snippets", "buffer" },
	},
	signature = { enabled = true },
})

-- Merge blink's enhanced capabilities into every LSP server's config.
-- This must exist regardless of file load order relative to 20-lsp.lua:
-- vim.lsp.config('*', ...) just stores data, actual servers only start
-- (and read merged config) once a matching buffer is opened later.
vim.lsp.config("*", {
	capabilities = require("blink.cmp").get_lsp_capabilities(),
})
