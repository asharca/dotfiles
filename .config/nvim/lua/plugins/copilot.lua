return {
  "zbirenbaum/copilot.lua",
  enabled = vim.uv.os_uname().sysname == "Darwin",
  event = "InsertEnter",
  opts = function(_, opts)
    opts.suggestion = vim.tbl_deep_extend("force", opts.suggestion or {}, {
      enabled = not vim.g.ai_cmp,
      auto_trigger = true,
      hide_during_completion = vim.g.ai_cmp,
      debounce = 75,
      keymap = {
        accept = false,
        accept_word = false,
        accept_line = false,
        next = "<M-]>",
        prev = "<M-[>",
        dismiss = "<C-]>",
      },
    })

    opts.filetypes = vim.tbl_deep_extend("force", opts.filetypes or {}, {
      yaml = true,
      markdown = true,
      help = false,
      gitcommit = true,
      gitrebase = true,
      hgcommit = false,
      svn = false,
      cvs = false,
      ["."] = false,
      python = true,
      javascript = true,
      typescript = true,
      lua = true,
    })

    opts.copilot_node_command = "node"

    opts.server_opts_overrides = vim.tbl_deep_extend("force", opts.server_opts_overrides or {}, {
      settings = {
        advanced = {
          listCount = 10,
          inlineSuggestCount = 5,
        },
      },
    })
  end,
}
