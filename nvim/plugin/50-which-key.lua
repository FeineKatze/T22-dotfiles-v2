-- ~/.config/nvim/plugin/50-which-key.lua
vim.pack.add({
	{ src = "https://github.com/folke/which-key.nvim" },
})

require("which-key").setup({})

-- Group labels for the leader-key popup (purely cosmetic, matches
-- keymaps already defined in 00-keymaps.lua and 20-lsp.lua)
require("which-key").add({
	{ "<leader>c", group = "code" },
	{ "<leader>r", group = "rename" },
	{ "<leader>s", group = "search" },
	{ "<leader>g", group = "git" },
	{ "<leader>t", group = "terminal/toggle" },
	{ "<leader>w", desc = "Save file" },
	{ "<leader>q", desc = "Quit" },
	{ "<leader>e", desc = "Line diagnostics" },
	{ "<leader>f", desc = "Format buffer" },
})
