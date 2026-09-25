return {
  "folke/flash.nvim",
  -- <c-space> 与 macOS 输入法切换冲突，增量选中改用 <c-n>（<BS> 缩小不变）
  keys = {
    { "<c-space>", false },
    {
      "<c-n>",
      mode = { "n", "o", "x" },
      function()
        require("flash").treesitter({
          actions = {
            ["<c-n>"] = "next",
            ["<BS>"] = "prev",
          },
        })
      end,
      desc = "Treesitter Incremental Selection",
    },
  },
}
