return {
  "linux-cultist/venv-selector.nvim",
  lazy = false,
  dependencies = {
    "neovim/nvim-lspconfig",
    "mfussenegger/nvim-dap",
    "mfussenegger/nvim-dap-python",
  },
  keys = {
    { "<leader>cv", "<cmd>VenvSelect<cr>", { desc = "Select VirtualEnv" } },
  },
  opts = {
    options = {},
    settings = {
      options = {},
      search = {
        uv = {
          command = "fd 'bin/python$' /Users/ashark/.local/share/uv/python/ --full-path",
        },
        MacAnaconda3 = {
          command = "fd /bin/python$ /opt/anaconda3/envs/ --full-path",
        },
      },
    },
  },
}
