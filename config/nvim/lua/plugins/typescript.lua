return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ts_ls = false,
      },
    },
  },
  {
    "pmizio/typescript-tools.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "neovim/nvim-lspconfig",
    },
    opts = {
      settings = {
        separate_diagnostic_server = true,
        publish_diagnostic_on = "insert_leave",
      },
    },
  },
  {
    "windwp/nvim-ts-autotag",
    opts = {},
  },
}
