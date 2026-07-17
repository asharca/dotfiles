-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
-- The current plugin stack uses LSP/DAP and does not need Python remote plugins.
vim.g.loaded_python3_provider = 0
vim.g.autoformat = false
vim.opt.spelllang = { "en", "cjk" }
vim.g.maplocalleader = ","
vim.g["suda#noninteractive"] = 1
vim.opt.conceallevel = 0
