return {
  {
    "stevearc/conform.nvim",
    keys = {
      {
        "<leader>cx",
        function()
          local fixers_by_ft = {
            javascript = { "eslint_d" },
            javascriptreact = { "eslint_d" },
            typescript = { "eslint_d" },
            typescriptreact = { "eslint_d" },
            css = { "stylelint" },
            scss = { "stylelint" },
          }
          local fixers = fixers_by_ft[vim.bo.filetype]
          if not fixers then
            vim.notify("Нет фиксера для " .. vim.bo.filetype, vim.log.levels.WARN)
            return
          end
          require("conform").format({ formatters = fixers })
        end,
        mode = "n",
        desc = "Fix Lint Errors (ESLint/Stylelint)",
      },
    },
    opts = {
      formatters_by_ft = {
        javascript = { "eslint_d", "prettier" },
        javascriptreact = { "eslint_d", "prettier" },
        typescript = { "eslint_d", "prettier" },
        typescriptreact = { "eslint_d", "prettier" },
        css = { "stylelint", "prettier" },
        scss = { "stylelint", "prettier" },
        json = { "prettier" },
      },
      formatters = {
        eslint_d = {
          command = "eslint_d",
          args = {
            "--fix-to-stdout",
            "--stdin",
            "--stdin-filename",
            "$FILENAME",
          },
          stdin = true,
          exit_codes = { 0, 1 },
          cwd = require("conform.util").root_file({
            "eslint.config.js",
            "eslint.config.mjs",
            ".eslintrc",
            ".eslintrc.json",
            "package.json",
            ".git",
          }),
        },
        stylelint = {
          command = "stylelint",
          args = {
            "--fix",
            "--stdin-filename",
            "$FILENAME",
          },
          stdin = true,
          cwd = require("conform.util").root_file({ "package.json", ".git" }),
        },
      },
    },
  },
}
