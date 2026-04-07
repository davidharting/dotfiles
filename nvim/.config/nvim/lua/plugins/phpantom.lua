vim.lsp.config['phpantom'] = {
  cmd = { vim.fn.expand('~/.local/bin/phpantom_lsp') },
  filetypes = { 'php' },
  root_markers = { 'composer.json', '.git' },
}
vim.lsp.enable('phpantom')

return {}
