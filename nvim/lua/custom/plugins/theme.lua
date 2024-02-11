local nightOwl = {
    'oxfist/night-owl.nvim',
    priority = 1000,
    lazy = false,
    config = function()
      vim.cmd.colorscheme("night-owl")
    end,
 }

local rosePine = { 
  "rose-pine/neovim",
  priority = 1000,
  lazy = false,
  config = function()
    vim.cmd.colorscheme("rose-pine")
  end,
}

local iterm2Profile = os.getenv("ITERM_PROFILE")


if iterm2Profile == "Night Owl" then
  return nightOwl
elseif iterm2Profile == "Rose Pine" then
  return rosePine
else
  return nightOwl
end
