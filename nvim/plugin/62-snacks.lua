-- ~/.config/nvim/plugin/62-snacks.lua
-- picker/indent/bigfile/notifier/scope/statuscolumn/gitbrowse/terminal.
-- explorer/dashboard deliberately left off: oil.nvim owns files.
vim.pack.add({
	{ src = "https://github.com/folke/snacks.nvim" },
})

require("snacks").setup({
	bigfile = { enabled = true }, -- disables treesitter/LSP on huge files
	indent = { enabled = true }, -- indent guides
	notifier = { enabled = true }, -- nicer vim.notify popups
	picker = {
		enabled = true, -- fuzzy finder, telescope replacement
		win = { list = { wo = { wrap = true } } }, -- wrap long lines (diagnostics, grep) instead of cutting them off
	},
	scope = { enabled = true }, -- highlights current indent scope
	statuscolumn = { enabled = true }, -- merges diagnostics/git/fold signs
	terminal = { enabled = true }, -- floating toggle terminal, keeps process alive
})

local map = vim.keymap.set
map({ "n", "t" }, "<leader>tt", function()
	Snacks.terminal.toggle()
end, { desc = "Toggle terminal" })
-- real sequence is Ctrl+\ then Ctrl+n as two separate chords, easy to fumble;
-- double-tap Esc as a simpler escape hatch out of terminal mode
map("t", "<esc><esc>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })
map("n", "<leader><space>", function()
	Snacks.picker.files()
end, { desc = "Find files" })
map("n", "<leader>/", function()
	Snacks.picker.grep()
end, { desc = "Grep" })
map("n", "<leader>,", function()
	Snacks.picker.buffers()
end, { desc = "Buffers" })
map("n", "<leader>sh", function()
	Snacks.picker.help()
end, { desc = "Help tags" })
map("n", "<leader>sd", function()
	Snacks.picker.diagnostics()
end, { desc = "Diagnostics" })
map("n", "<leader>sr", function()
	Snacks.picker.lsp_references()
end, { desc = "References (picker)" })
map("n", "<leader>ss", function()
	Snacks.picker.lsp_symbols()
end, { desc = "Document symbols" })
map("n", "<leader>sS", function()
	Snacks.picker.lsp_workspace_symbols()
end, { desc = "Workspace symbols" })
map("n", "<leader>gb", function()
	Snacks.gitbrowse()
end, { desc = "Open in browser" })
