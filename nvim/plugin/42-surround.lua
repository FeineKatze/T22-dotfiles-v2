-- ~/.config/nvim/plugin/42-surround.lua
vim.pack.add({
	{ src = "https://github.com/kylechui/nvim-surround", version = vim.version.range("4.x") },
	-- pinned to the 4.x tag for stability; omit the version field for
	-- bleeding-edge main-branch features instead
})

require("nvim-surround").setup({})
-- ys{motion}{char} add, ds{char} delete, cs{old}{new} change, S in visual
-- mode. dsf deletes a surrounding function call (treesitter-aware).
