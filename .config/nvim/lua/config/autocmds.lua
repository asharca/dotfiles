-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { ".*" },
  callback = function(ev)
    -- 获取文件名（不含路径）
    local name = vim.fn.fnamemodify(ev.file, ":t")

    -- 如果以 "." 开头，例如 .env, .env.local, .gitignore 等
    if name:sub(1, 1) == "." then
      vim.b[ev.buf].autoformat = false
    end
  end,
})
vim.g.autoformat = false

-- 进入终端缓冲区时自动进入 insert（terminal）模式
vim.api.nvim_create_autocmd({ "TermOpen", "BufEnter", "WinEnter" }, {
  callback = function(ev)
    if vim.bo[ev.buf].buftype == "terminal" then
      vim.cmd.startinsert()
    end
  end,
})
