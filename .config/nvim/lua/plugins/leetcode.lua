local leet_arg = "leetcode.nvim"

return {
  "kawre/leetcode.nvim",
  cmd = "Leet",
  build = ":TSUpdate html", -- if you have `nvim-treesitter` installed
  lazy = leet_arg ~= vim.fn.argv(0, -1),
  dependencies = {
    "nvim-telescope/telescope.nvim",
    -- "ibhagwan/fzf-lua",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
  },
  keys = {
    { "<localleader>t", "<Cmd>Leet tabs<CR>" },
    { "<localleader>o", "<Cmd>Leet open<CR>" },
    { "<localleader>d", "<Cmd>Leet desc<CR>" },
    { "<localleader>D", "<Cmd>Leet daily<CR>" },
    { "<localleader><localleader>", "<Cmd>Leet run<CR>" },
    { "<localleader>r", "<Cmd>Leet random<CR>" },
    { "<localleader>e", "<Cmd>Leet random difficulty=Easy<CR>" },
    { "<localleader>m", "<Cmd>Leet random difficulty=Medium<CR>" },
    { "<localleader>h", "<Cmd>Leet random difficulty=Hard<CR>" },
    { "<localleader>R", "<Cmd>Leet random status=todo<CR>" },
    { "<localleader>E", "<Cmd>Leet random difficulty=Easy status=todo<CR>" },
    { "<localleader>M", "<Cmd>Leet random difficulty=Medium status=todo<CR>" },
    { "<localleader>H", "<Cmd>Leet random difficulty=Hard status=todo<CR>" },
    { "<localleader><cr>", "<Cmd>Leet submit<CR>" },
    { "<localleader>i", "<Cmd>Leet info<CR>" },
    { "<localleader>c", "<Cmd>Leet console<CR>" },
    { "<localleader>p", "<Cmd>Leet list<CR>" },
    { "<localleader>l", "<Cmd>Leet lang<CR>" },
    { "<localleader><space>", "<Cmd>Leet<CR>" },
  },
  opts = {
    -- configuration goes here
    -- cn = { -- leetcode.cn
    -- 	enabled = true, ---@type boolean
    -- 	translator = true, ---@type boolean
    -- 	translate_problems = true, ---@type boolean
    -- },

    ---@type string
    arg = "leetcode.nvim",
    lang = "python3",

    ---@type boolean
    image_support = false,
    ---@type lc.storage

    storage = {
      home = "/Users/ashark/Github/MyLeetcode",
      cache = vim.fn.stdpath("cache") .. "/leetcode",
    },

    injector = { ---@type table<lc.lang, lc.inject>
      ["python3"] = {
        before = false,
      },
      ["cpp"] = {
        before = { "#include <bits/stdc++.h>", "using namespace std;" },
        after = "int main() {}",
      },
      ["java"] = {
        before = "import java.util.*;",
      },
    },

    keys = {
      toggle = { "q", "<esc>" },
      confirm = { "<cr>" },
      reset_testcases = "r",
      use_testcase = "U",
      focus_testcases = "H",
      focus_result = "L",
    },
  },
}
