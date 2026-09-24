-- vim-tmux-navigator: seamless navigation between tmux panes and vim splits
-- Use Ctrl+h/j/k/l to navigate between both tmux panes and vim splits
return {
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    keys = {
      { "<C-h>", "<cmd><C-U>TmuxNavigateLeft<cr>",      desc = "Navigate left (tmux-aware)" },
      { "<C-j>", "<cmd><C-U>TmuxNavigateDown<cr>",      desc = "Navigate down (tmux-aware)" },
      { "<C-k>", "<cmd><C-U>TmuxNavigateUp<cr>",        desc = "Navigate up (tmux-aware)" },
      { "<C-l>", "<cmd><C-U>TmuxNavigateRight<cr>",     desc = "Navigate right (tmux-aware)" },
      { "<C-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>", desc = "Navigate to previous pane (tmux-aware)" },
    },
  },
}
