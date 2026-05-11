return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.filetype.add({ filename = { Tiltfile = "starlark" } })
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "starlark" })
    end,
  },
}
