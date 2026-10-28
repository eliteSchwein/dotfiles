require "nvchad.options"

vim.opt.colorcolumn = "100"
vim.cmd "set expandtab"
vim.cmd "set tabstop=2"
vim.cmd "set softtabstop=2"
vim.cmd "set shiftwidth=2"
vim.cmd "set rnu"

vim.filetype.add {
  pattern = {
    [".+ansible/.*.yml"] = "yaml.ansible",
  },
}

-- folding options
vim.opt.foldcolumn = "0"
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldtext = ""
vim.opt.foldnestmax = 3
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
-- local o = vim.o
-- o.cursorlineopt ='both' -- to enable cursorline!
