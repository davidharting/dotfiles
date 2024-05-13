-- This will run last in the setup process and is a good place to configure
-- things like custom filetypes. This just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

vim.api.nvim_exec(
  [[
  autocmd VimResized * wincmd =
  ]],
  false
)

require("which-key").register {
  ["<leader>j"] = { name = "David's scope", _ = "which_key_ignore" },
}

vim.keymap.set("n", "<leader>jt", "<cmd>Neotree filesystem reveal current<CR>", {
  desc = "Open Neotree in curent buffer",
})

vim.keymap.set("n", "<leader>jg", "<cmd>Alpha<CR> | <cmd>Ge:<CR>", {
  desc = "Open vim-fugitive in current buffer",
})

