-- ~/.config/nvim/init.lua
-- Minimal Neovim 0.12 config using native vim.pack

vim.loader.enable() -- faster require() caching

vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt

opt.number = true
opt.cursorline = true
opt.relativenumber = true
opt.signcolumn = "yes"

opt.termguicolors = true
opt.showmatch = true
-- opt.showmode = false
opt.mouse = "a"
opt.clipboard = "unnamedplus"

opt.undofile = true
local undodir = "~/.local/share/nvim/undodir"
opt.undodir = vim.fn.expand(undodir)
local undodir_path = vim.fn.expand(undodir)
if vim.fn.isdirectory(undodir_path) == 0 then
	vim.fn.mkdir(undodir_path, "p")
end

opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true

opt.splitright = true
opt.splitbelow = true

opt.scrolloff = 10
opt.sidescrolloff = 8
opt.wrap = false

opt.cmdheight = 1
opt.updatetime = 250

opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
opt.smartindent = true
opt.autoindent = true
opt.breakindent = true

opt.grepprg = "rg --vimgrep"
opt.grepformat = "%f:%l:%c:%m"

opt.selection = "inclusive"

opt.guicursor = {
	"n-v-c:block",
	"i-ci-ve:ver25",
	"r-cr:hor20",
	"o:hor50",
}

-- plugin/*.lua files are auto-sourced by Neovim at startup, alphabetically
-- Nothing else needs to happen here

-- Restore last cursor position when reopening a file
local last_cursor_group = vim.api.nvim_create_augroup("LastCursorGroup", {})
vim.api.nvim_create_autocmd("BufReadPost", {
	group = last_cursor_group,
	callback = function()
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		local lcount = vim.api.nvim_buf_line_count(0)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- Highlight the yanked text for 200ms
local highlight_yank_group = vim.api.nvim_create_augroup("HighlightYank", {})
vim.api.nvim_create_autocmd("TextYankPost", {
	group = highlight_yank_group,
	pattern = "*",
	callback = function()
		vim.hl.on_yank({
			higroup = "IncSearch",
			timeout = 200,
		})
	end,
})

-- Treesitter-based code folding, built into Neovim core, no plugin needed.
-- za toggle fold, zM close all, zR open all, zo/zc open/close, zj/zk jump
-- between folds.
-- Combines LSP-provided folding ranges (when a server offers them) with
-- an automatic fallback to treesitter -- more reliable than plain
-- vim.treesitter.foldexpr() alone, which has a long-standing unresolved
-- core bug (E490: No fold found on fresh buffers, see neovim/neovim#25948,
-- #28692, #32675). Neovim already advertises foldingRange capability by
-- default, nothing extra needed on the LSP config side.
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.lsp.foldexpr()"
opt.foldlevel = 99 -- start with everything unfolded
