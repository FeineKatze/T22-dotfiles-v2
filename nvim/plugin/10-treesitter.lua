-- ~/.config/nvim/plugin/10-treesitter.lua
-- Hook MUST be created before the vim.pack.add() call that installs the plugin
vim.api.nvim_create_autocmd("PackChanged", {
	callback = function(ev)
		local name, kind = ev.data.spec.name, ev.data.kind
		if name == "nvim-treesitter" and kind == "update" then
			if not ev.data.active then
				vim.cmd.packadd("nvim-treesitter")
			end
			vim.cmd("TSUpdate")
		end
	end,
})

vim.pack.add({
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
})

-- Matches the LSP server set: bashls, clangd, neocmakelsp, cssls, dockerls,
-- fish_lsp, html, denols/ts_ls, jsonls, jdtls, lua_ls, autotools_ls,
-- marksman, rumdl, basedpyright, ruff, qmlls, rust_analyzer, texlab,
-- vimls, lemminx, yamlls, sqls.
-- Note: docker_compose_language_service handles docker-compose.yml files,
-- which are plain YAML -- that's the "yaml" parser below, not "dockerfile".
-- "dockerfile" here is only for the Dockerfile itself.
local parsers = {
	"bash",
	"c",
	"cpp",
	"cmake",
	"css",
	"dockerfile",
	"fish",
	"html",
	"javascript",
	"typescript",
	"tsx",
	"json",
	"java",
	"lua",
	"make",
	"markdown",
	"markdown_inline",
	"python",
	"qmljs",
	"rust",
	"latex",
	"vim",
	"vimdoc",
	"xml",
	"yaml",
	"sql",
}

require("nvim-treesitter").setup()
require("nvim-treesitter").install(parsers)

-- main branch no longer auto-starts highlighting; do it per filetype.
-- Note: filetype names don't always match parser names (tsx -> typescriptreact,
-- qmljs -> qml, bash -> sh/bash, latex -> tex, vimdoc -> help).
-- Deliberately NOT setting indentexpr here: nvim-treesitter's own docs
-- call that feature "experimental". Languages without an indents.scm
-- query (or a buggy one) make it silently return a bad value, which
-- Neovim reads as indent 0 -- cursor slams to column 1 on <CR>.
-- Neovim's built-in per-filetype indent scripts in $VIMRUNTIME are more
-- reliable and already handle this for python/lua/c/etc.
local filetypes = {
	"sh",
	"bash",
	"c",
	"cpp",
	"cmake",
	"css",
	"dockerfile",
	"fish",
	"html",
	"javascript",
	"typescript",
	"typescriptreact",
	"json",
	"java",
	"lua",
	"make",
	"markdown",
	"python",
	"qml",
	"rust",
	"tex",
	"vim",
	"help",
	"xml",
	"yaml",
	"sql",
}

vim.api.nvim_create_autocmd("FileType", {
	pattern = filetypes,
	callback = function(ev)
		vim.treesitter.start(ev.buf)
	end,
})
