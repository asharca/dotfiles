local uv_python_dir = vim.fn.shellescape(vim.fn.expand("~/.local/share/uv/python"))

return {
  "linux-cultist/venv-selector.nvim",
  opts = {
    search = {
      uv = {
        command = "fd 'bin/python$' " .. uv_python_dir .. " --full-path",
      },
      MacAnaconda3 = {
        command = "fd /bin/python$ /opt/anaconda3/envs/ --full-path",
        type = "anaconda",
      },
    },
  },
}
