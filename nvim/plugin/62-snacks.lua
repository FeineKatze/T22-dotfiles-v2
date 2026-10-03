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
		sources = {
			keymaps = {
				-- Drop the leading icon; bold+color the mode letter instead so
				-- entries are still easy to tell apart at a glance. The actual
				-- keymap data (lhs/desc/rhs) is nested under item.item, not the
				-- top-level item -- mode happens to also be set top-level,
				-- which is why that one column worked before this fix.
				format = function(item)
					local km = item.item or {}
					local ret = {}
					-- mapleader is a literal space, so leader-based lhs strings
					-- contain real space characters -- render them visibly
					local lhs_display = (km.lhs or ""):gsub(" ", "␣")
					ret[#ret + 1] = { ("%-4s"):format(item.mode or km.mode or ""), "Type" }
					ret[#ret + 1] = { (" %-22s"):format(lhs_display), "SnacksPickerKeymapLhs" }
					local label = km.desc
					if not label or label == "" then
						label = type(km.rhs) == "string" and km.rhs or "callback"
					end
					ret[#ret + 1] = { label, "Comment" }
					return ret
				end,
			},
		},
		win = {
			list = {
				wo = { wrap = true }, -- wrap long lines (diagnostics, grep) instead of cutting them off
				keys = { ["dd"] = "bufdelete" }, -- delete buffer under cursor in the buffers picker; pinned explicitly since this has flip-flopped between snacks.nvim versions as a true default
			},
		},
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
map("n", "<leader>sk", function()
	Snacks.picker.keymaps()
end, { desc = "Keymaps (browse all)" })
