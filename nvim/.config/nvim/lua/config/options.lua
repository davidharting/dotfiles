-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.relativenumber = false

vim.g.lazyvim_python_lsp = "ty"

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.conceallevel = 0
  end,
})

local render_dir = vim.fs.normalize(vim.fn.expand("~/repos/render")) .. "/"

vim.api.nvim_create_autocmd("BufEnter", {
  callback = function(event)
    local filename = vim.fs.normalize(vim.api.nvim_buf_get_name(event.buf))
    if not vim.startswith(filename, render_dir) then
      return
    end

    local project = filename:sub(#render_dir + 1):match("^[^/]+")
    if project ~= "dashboard" and project ~= "website" then
      vim.b[event.buf].autoformat = false
    end
  end,
})
