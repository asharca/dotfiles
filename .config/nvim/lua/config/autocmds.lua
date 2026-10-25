-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here
-- 进入终端缓冲区时自动进入 insert（terminal）模式
vim.api.nvim_create_autocmd({ "TermOpen", "BufEnter", "WinEnter" }, {
  callback = function(ev)
    if vim.bo[ev.buf].buftype == "terminal" then
      vim.cmd.startinsert()
    end
  end,
})
