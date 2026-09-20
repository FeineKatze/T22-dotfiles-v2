-- ~/.config/nvim/plugin/51-render-markdown.lua
-- Needs the markdown/markdown_inline treesitter parsers, already
-- installed via plugin/10-treesitter.lua.
vim.pack.add({
	{ src = "https://github.com/MeanderingProgrammer/render-markdown.nvim" },
})

require("render-markdown").setup({
	-- defaults are sane: headings, code blocks, bullets, checkboxes,
	-- tables all render live while editing. Rendering pauses in the
	-- window/mode where the cursor's line is being edited, so raw
	-- markdown is never hidden from you while typing it.
})
