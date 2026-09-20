-- ~/.config/nvim/plugin/01-colorscheme.lua
vim.pack.add({
    { src = "https://github.com/folke/tokyonight.nvim" },
})

vim.cmd.colorscheme("tokyonight")

vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
