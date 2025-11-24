return {
  {
    "iamcco/markdown-preview.nvim",
    build = function()
      require("lazy").load({ plugins = { "markdown-preview.nvim" } })
      vim.fn["mkdp#util#install"]()
    end,
  },
  {
    "3rd/image.nvim",
    -- Disable on Windows system
    cond = function()
      return vim.fn.has("win32") ~= 1
    end,
    opts = {
      backend = "kitty", -- 你用 kitty，所以用 kitty backend
      max_width = 80,
      max_height = 40,
      integrations = {
        markdown = {
          enabled = true,
          download_remote_images = true, -- 支持网络图像
        },
      },
    },
  },
}
