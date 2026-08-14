return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles", "DiffviewFileHistory" },
  keys = {
    { "<leader>gv", "<cmd>DiffviewOpen<cr>",          desc = "Diff View (working tree)" },
    { "<leader>gV", "<cmd>DiffviewClose<cr>",         desc = "Close Diff View" },
    { "<leader>gh", "<cmd>DiffviewFileHistory<cr>",   desc = "Git History (repo)" },
    { "<leader>gH", "<cmd>DiffviewFileHistory %<cr>", desc = "Git History (current file)" },
  },
  opts = function()
    local actions = require("diffview.actions")

    vim.opt.diffopt:append("context:1000000")

    return {
      enhanced_diff_hl = true,
      view = {
        merge_tool = {
          layout = "diff3_horizontal",
        },
      },
      file_panel = {
        listing_style = "tree",
        win_config = {
          width = 35,
        },
      },
      keymaps = {
        view = {
          { "n", "<tab>",     actions.select_next_entry, { desc = "Open the diff for the next file" } },
          { "n", "<s-tab>",   actions.select_prev_entry, { desc = "Open the diff for the previous file" } },
          { "n", "<leader>e", actions.focus_files,       { desc = "Focus the file panel" } },
          { "n", "<leader>b", actions.toggle_files,      { desc = "Toggle the file panel" } },
          { "n", "q",         "<cmd>DiffviewClose<cr>",  { desc = "Close Diffview" } }, },
        file_panel = {
          { "n", "j",       actions.next_entry,         { desc = "Next entry" } },
          { "n", "k",       actions.prev_entry,         { desc = "Previous entry" } },
          { "n", "<cr>",    actions.select_entry,       { desc = "Open diff for selected entry" } },
          { "n", "o",       actions.select_entry,       { desc = "Open diff for selected entry" } },
          { "n", "-",       actions.toggle_stage_entry, { desc = "Stage / unstage" } },
          { "n", "S",       actions.stage_all,          { desc = "Stage all" } },
          { "n", "U",       actions.unstage_all,        { desc = "Unstage all" } },
          { "n", "X",       actions.restore_entry,      { desc = "Restore entry (discard changes)" } },
          { "n", "R",       actions.refresh_files,      { desc = "Refresh file list" } },
          { "n", "<tab>",   actions.select_next_entry,  { desc = "Next file" } },
          { "n", "<s-tab>", actions.select_prev_entry,  { desc = "Previous file" } },
          { "n", "q",       "<cmd>DiffviewClose<cr>",   { desc = "Close Diffview" } },
        },
      },
    }
  end,
}
