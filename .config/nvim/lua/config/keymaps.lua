-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- 在普通模式下绑定 <Tab> 和 <S-Tab> 为缓冲区切换
-- vim.keymap.set("n", "<Tab>", ":bnext<CR>", { noremap = true, silent = true, desc = "Next Buffer" })
-- vim.keymap.set("n", "<S-Tab>", ":bprevious<CR>", { noremap = true, silent = true, desc = "Previous Buffer" })
-- Use H and L if the buffer you want to go to is visually close to where you are
