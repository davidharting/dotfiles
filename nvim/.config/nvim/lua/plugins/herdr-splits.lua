return {
  "lmilojevicc/herdr-splits.nvim",
  cond = vim.env.HERDR_ENV == "1",
  event = "VeryLazy",
  build = ':lua require("herdr-splits").sync_herdr()',
  config = function()
    require("herdr-splits").setup({
      auto_sync_herdr = true,
      default_amount = 0.03,
      neovim_amount = 3,
      at_edge = "wrap",
      unzoom_on_nav = false,
    })
  end,
  keys = {
    {
      "<C-h>",
      function()
        require("herdr-splits").move_cursor_left()
      end,
      desc = "Navigate left",
    },
    {
      "<C-j>",
      function()
        require("herdr-splits").move_cursor_down()
      end,
      desc = "Navigate down",
    },
    {
      "<C-k>",
      function()
        require("herdr-splits").move_cursor_up()
      end,
      desc = "Navigate up",
    },
    {
      "<C-l>",
      function()
        require("herdr-splits").move_cursor_right()
      end,
      desc = "Navigate right",
    },
    {
      "<M-h>",
      function()
        require("herdr-splits").resize_left()
      end,
      desc = "Resize left",
    },
    {
      "<M-l>",
      function()
        require("herdr-splits").resize_right()
      end,
      desc = "Resize right",
    },
  },
}
