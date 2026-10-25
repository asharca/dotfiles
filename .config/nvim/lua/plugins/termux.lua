-- Platform-specific compatibility overrides for the Termux branch.
-- The rest of the Neovim configuration comes from main.
local prefix = vim.env.PREFIX or ""
local is_termux = prefix:match("/com%.termux/files/usr$") ~= nil or vim.fn.has("android") == 1
if not is_termux then
  return {}
end

return {
  -- Use the stable v1 Lua matcher rather than requiring a Rust build on Android.
  {
    "saghen/blink.cmp",
    version = "1.*",
    build = false,
    opts = function(_, opts)
      opts.fuzzy = opts.fuzzy or {}
      opts.fuzzy.implementation = "lua"
    end,
  },
  -- Mason-managed binaries are typically glibc/musl, not Android/Bionic.
  -- Keep direct LSP configuration; install Android-native servers using pkg/npm.
  { "mason-org/mason.nvim", enabled = false },
  { "mason-org/mason-lspconfig.nvim", enabled = false },
  { "jay-babu/mason-nvim-dap.nvim", enabled = false },
  { "WhoIsSethDaniel/mason-tool-installer.nvim", enabled = false },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      for name, server in pairs(opts.servers or {}) do
        if name ~= "*" and type(server) == "table" then
          server.mason = false
        end
      end
    end,
  },
  -- Do not download native parsers or run a parser build automatically.
  {
    "nvim-treesitter/nvim-treesitter",
    build = false,
    opts = function(_, opts)
      opts.ensure_installed = {}
      opts.auto_install = false
    end,
  },
  { "lambdalisue/suda.vim", enabled = false },
  { "zbirenbaum/copilot.lua", enabled = false },
  { "CopilotC-Nvim/CopilotChat.nvim", enabled = false },
}

