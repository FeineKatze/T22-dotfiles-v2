-- ~/.config/nvim/plugin/00-keymaps.lua
local map = vim.keymap.set
local opts = {}

map("n", "<leader>cd", vim.cmd.Ex)

map("n", "<leader>w", "<cmd>write<cr>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit" })
map("n", "<esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- window navigation
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

-- diagnostics
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Prev diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Line diagnostics" })

-- Split the line at cursor, as if you typed i<CR><Esc>. Safe to remap
-- normal-mode <CR> globally: buffer-local <CR> maps in special buffers
-- (quickfix, oil, snacks pickers, help) always take priority over this.
map("n", "<CR>", "i<CR><Esc>", { desc = "Insert newline at cursor" })

-- Insert a blank line above the current line, staying in normal mode
-- (same as O<Esc>). <S-CR>/<C-CR> only work as distinct keys because
-- Kitty implements the enhanced keyboard protocol -- most terminals
-- can't tell these apart from plain <CR>.
map("n", "<S-CR>", "O<Esc>", { desc = "Insert blank line above" })
map("n", "<C-CR>", "O<Esc>", { desc = "Insert blank line above" })

-- Don't copy character on x-delete
map("n", "x", '"_x')
map("v", "x", '"_x')
map("n", "dd", '"_dd')
map("v", "d", '"_d')
map("x", "p", '"_dP')
map("n", "cw", '"_cw')

map("n", "X", "dd")
map("v", "X", "d")

-- Toggle line wrap
map("n", "<leader>lw", "<cmd>set wrap! linebreak!<CR>", opts)

-- clear highlights
map("n", "<Esc>", ":noh<CR>", opts)

vim.api.nvim_create_user_command("W", "w", {})
vim.api.nvim_create_user_command("Wq", "wq", {})
vim.api.nvim_create_user_command("Q", "q", {})
vim.cmd("cnoreabbrev Res restart")
vim.cmd("cnoreabbrev res restart")
