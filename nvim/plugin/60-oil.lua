-- ~/.config/nvim/plugin/60-oil.lua
vim.pack.add({
	{ src = "https://github.com/stevearc/oil.nvim" },
})

require("oil").setup({
	default_file_explorer = true, -- fully replaces netrw, no :Ex fallback
	view_options = { show_hidden = true },
})

vim.keymap.set("n", "-", "<cmd>Oil<cr>", { desc = "Open parent directory" })

-- Show the current dir relative to cwd (":.") or home ("~") instead of
-- the full absolute oil:// path -- picks whichever is shorter/applicable.
_G.oil_winbar = function()
	local ok, oil = pcall(require, "oil")
	if not ok then
		return ""
	end
	local dir = oil.get_current_dir()
	if not dir then
		return ""
	end
	-- fnamemodify(":.") strips the cwd prefix entirely when dir == cwd,
	-- leaving "" instead of ".", so fall back to plain "~"-relative form
	local rel = vim.fn.fnamemodify(dir, ":~:.")
	if rel == "" then
		rel = vim.fn.fnamemodify(dir, ":~")
	end
	return rel
end

vim.api.nvim_create_autocmd("FileType", {
	pattern = "oil",
	callback = function()
		vim.wo.winbar = "%{v:lua.oil_winbar()}"
	end,
})
