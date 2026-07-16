return {
  "mbbill/undotree",
  cmd = "UndotreeToggle",
  keys = {
    { "<leader>U", "<cmd>UndotreeToggle<cr>", desc = "Undotree (undo history)" },
  },
  config = function()
    -- 打开面板时把焦点切过去，方便直接 j/k 浏览历史
    vim.g.undotree_SetFocusWhenToggle = 1
  end,
}
