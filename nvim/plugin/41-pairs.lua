-- ~/.config/nvim/plugin/41-pairs.lua
vim.pack.add({
	{ src = "https://github.com/windwp/nvim-autopairs" },
})

require("nvim-autopairs").setup({
	check_ts = true, -- treesitter-aware: don't pair inside strings/comments
})

-- blink.cmp (plugin/70-completion.lua) has its own separate feature for
-- inserting () when accepting a function/method completion
-- (completion.accept.auto_brackets), which is unrelated to nvim-autopairs
-- and doesn't need any glue code between them. If you ever see a doubled
-- closing paren after accepting a completion, disable that blink option
-- rather than touching this file. No nvim-cmp-style integration is needed
-- since we're not using nvim-cmp.
