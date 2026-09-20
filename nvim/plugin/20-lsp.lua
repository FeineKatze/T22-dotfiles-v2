-- ~/.config/nvim/plugin/20-lsp.lua
-- nvim-lspconfig here only provides lsp/*.lua config definitions on
-- runtimepath. It does NOT install servers or call .setup() for you.
-- Install the actual language servers via pacman/AUR (see README).

vim.pack.add({
	{ src = "https://github.com/neovim/nvim-lspconfig" },
})

------------------------------------------------------------------------
-- Servers with no overrides needed (defaults from nvim-lspconfig are fine)
--   bashls, clangd, neocmake, cssls, dockerls,
--   docker_compose_language_service, fish_lsp, html, jsonls, jdtls,
--   autotools_ls, texlab, vimls, lemminx, yamlls, sqls
------------------------------------------------------------------------

vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			diagnostics = { globals = { "vim" } },
			workspace = { checkThirdParty = false },
			telemetry = { enable = false },
		},
	},
})

vim.lsp.config("rust_analyzer", {
	settings = {
		["rust-analyzer"] = {
			cargo = { allFeatures = true },
			checkOnSave = { command = "clippy" },
		},
	},
})

vim.lsp.config("clangd", {
	cmd = { "clangd", "--background-index", "--clang-tidy" },
})

------------------------------------------------------------------------
-- ts_ls vs denols: mutually exclusive by root marker, not global choice.
-- package.json  -> ts_ls
-- deno.json(c)  -> denols
------------------------------------------------------------------------

vim.lsp.config("ts_ls", {
	root_markers = { "package.json" },
	single_file_support = false,
})

vim.lsp.config("denols", {
	root_markers = { "deno.json", "deno.jsonc" },
})

------------------------------------------------------------------------
-- Python: basedpyright for type checking/intelligence,
-- ruff for linting/formatting/import sorting. Disable the overlap.
------------------------------------------------------------------------

vim.lsp.config("basedpyright", {
	settings = {
		basedpyright = {
			-- let ruff own import sorting
			disableOrganizeImports = true,
		},
	},
})

vim.lsp.config("ruff", {
	init_options = {
		settings = {
			lint = { enable = true },
			organizeImports = true,
		},
	},
	on_attach = function(client)
		-- defer hover to basedpyright, ruff has none worth keeping anyway
		client.server_capabilities.hoverProvider = false
	end,
})

------------------------------------------------------------------------
-- Markdown: marksman for navigation/completion, rumdl for
-- diagnostics + formatting. rumdl isn't in nvim-lspconfig yet, so
-- it's defined manually.
------------------------------------------------------------------------

vim.lsp.config("rumdl", {
	cmd = { "rumdl", "server" },
	filetypes = { "markdown" },
	root_markers = { ".rumdl.toml", ".git" },
})

------------------------------------------------------------------------
-- QML: not in nvim-lspconfig, comes from qt6-declarative.
------------------------------------------------------------------------

vim.lsp.config("qmlls", {
	cmd = { "qmlls6" },
	filetypes = { "qml" },
	root_markers = { "*.qmlproject", ".git" },
})

------------------------------------------------------------------------
-- systemd unit files: not in nvim-lspconfig, comes from the
-- systemd-lsp AUR package (JFryy/systemd-lsp, binary: systemd-lsp).
------------------------------------------------------------------------

vim.filetype.add({
	extension = {
		service = "systemd",
		socket = "systemd",
		timer = "systemd",
		mount = "systemd",
		automount = "systemd",
		swap = "systemd",
		target = "systemd",
		path = "systemd",
		slice = "systemd",
		scope = "systemd",
		device = "systemd",
	},
})

vim.lsp.config("systemd_ls", {
	cmd = { "systemd-lsp" },
	filetypes = { "systemd" },
	root_markers = { ".git" },
})

------------------------------------------------------------------------
-- TOML: tombi (formatter + linter + LSP in one Rust binary). Not in
-- nvim-lspconfig yet, defined manually. Available straight from the
-- official `extra` repo: `pacman -S tombi`. Project-level config goes
-- in tombi.toml, same idea as rumdl's .rumdl.toml above.
------------------------------------------------------------------------

vim.lsp.config("tombi", {
	cmd = { "tombi", "lsp" },
	filetypes = { "toml" },
	root_markers = { "tombi.toml", ".git" },
})

vim.lsp.enable({
	"bashls",
	"clangd",
	"neocmake",
	"cssls",
	"dockerls",
	"docker_compose_language_service",
	"fish_lsp",
	"html",
	"jsonls",
	"jdtls",
	"autotools_ls",
	"texlab",
	"vimls",
	"lemminx",
	"yamlls",
	"sqls",
	"lua_ls",
	"rust_analyzer",
	"ts_ls",
	"denols",
	"basedpyright",
	"ruff",
	"marksman",
	"rumdl",
	"qmlls",
	"systemd_ls",
	"tombi",
})

-- Diagnostics look/feel
vim.diagnostic.config({
	virtual_text = { prefix = "●" },
	severity_sort = true,
	float = { border = "rounded" },
})

-- Toggle inline diagnostics (virtual text + underlines + signs) globally.
-- Diagnostics from :LspInfo-attached clients still run, this just hides
-- the visual clutter; use <leader>e to still check a line on demand.
vim.keymap.set("n", "<leader>td", function()
	local enabled = vim.diagnostic.is_enabled()
	vim.diagnostic.enable(not enabled)
end, { desc = "Toggle diagnostics" })

-- :LspRestart/:LspInfo/:LspLog were replaced in Neovim 0.12 by a single
-- :lsp command with subcommands (:lsp restart, :lsp enable, :lsp disable).
vim.keymap.set("n", "<leader>lr", "<cmd>lsp restart<cr>", { desc = "Restart LSP" })

-- Buffer-local keymaps once an LSP client attaches
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(ev)
		-- Disable LSP semantic tokens: a race condition in Neovim core's
		-- semantic_tokens.lua corrupts the highlight cache over time
		-- (index math ends up comparing against nil -> crash + broken colors),
		-- especially with multiple clients on one buffer like we have here
		-- (basedpyright+ruff, ts_ls+denols, marksman+rumdl). Treesitter
		-- already handles highlighting reliably, so just drop this capability.
		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		if client then
			client.server_capabilities.semanticTokensProvider = nil
		end

		local map = function(mode, lhs, rhs, desc)
			vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, desc = desc })
		end
		map("n", "gd", vim.lsp.buf.definition, "Goto definition")
		map("n", "gD", vim.lsp.buf.declaration, "Goto declaration")
		map("n", "gr", vim.lsp.buf.references, "References")
		map("n", "gy", vim.lsp.buf.type_definition, "Type definition")
		map("n", "gI", vim.lsp.buf.implementation, "Goto implementation")
		map("n", "K", vim.lsp.buf.hover, "Hover")
		map("i", "<C-k>", vim.lsp.buf.signature_help, "Signature help") -- manual trigger; blink.cmp also shows this automatically while typing args
		map("n", "<leader>rn", vim.lsp.buf.rename, "Rename")
		map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
		-- <leader>f is owned by conform.nvim (plugin/40-format.lua), which
		-- falls back to this client's formatter when nothing else applies
	end,
})
