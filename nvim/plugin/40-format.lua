-- ~/.config/nvim/plugin/40-format.lua
vim.pack.add({
	{ src = "https://github.com/stevearc/conform.nvim" },
})

require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		javascript = { "prettier" },
		typescript = { "prettier" },
		typescriptreact = { "prettier" },
		css = { "prettier" },
		html = { "prettier" },
		json = { "prettier" },
		yaml = { "prettier" },
		sh = { "shfmt" },
		bash = { "shfmt" },
		fish = { "fish_indent" },
		-- python, rust, c/cpp, markdown intentionally omitted:
		-- ruff/rust_analyzer/clangd/rumdl already format via LSP below
	},
	format_on_save = {
		timeout_ms = 1000,
		lsp_format = "fallback", -- use the attached LSP formatter if no entry above
	},
})

vim.keymap.set({ "n", "v" }, "<leader>f", function()
	require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "Format buffer" })
