vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local opt = vim.opt

-- Editing
opt.shiftwidth = 4
opt.softtabstop = 4
opt.tabstop = 4
opt.smartindent = true
opt.expandtab = true
opt.undofile = true
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.scrolloff = 4
opt.splitright = true
opt.splitbelow = true
opt.foldenable = false
opt.updatetime = 250
opt.timeoutlen = 300
opt.confirm = true
opt.inccommand = "split"
opt.breakindent = true
opt.mouse = "a"

-- UI
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.list = true
opt.listchars = {
  tab = "▎  ",
  leadmultispace = "    ",
  trail = "·",
  nbsp = "+",
}
opt.conceallevel = 2
opt.title = true
opt.termguicolors = true
opt.guicursor = "n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20"

local indentation = {
  haskell = { width = 2, expandtab = true },
  make = { width = 4, expandtab = false },
  markdown = { width = 2, expandtab = true },
  nasm = { width = 4, expandtab = true },
  nix = { width = 2, expandtab = true },
  text = { width = 2, expandtab = true },
}

vim.api.nvim_create_autocmd("FileType", {
  desc = "Set filetype-specific indentation",
  pattern = vim.tbl_keys(indentation),
  callback = function(event)
    local settings = indentation[vim.bo[event.buf].filetype]
    vim.bo[event.buf].shiftwidth = settings.width
    vim.bo[event.buf].softtabstop = settings.width
    vim.bo[event.buf].tabstop = settings.width
    vim.bo[event.buf].expandtab = settings.expandtab
  end,
})

local number_toggle = vim.api.nvim_create_augroup("number-toggle", { clear = true })

vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave", "CmdlineLeave", "WinEnter" }, {
  desc = "Show relative line numbers in normal mode",
  group = number_toggle,
  callback = function()
    if vim.wo.number and vim.api.nvim_get_mode().mode ~= "i" then
      vim.wo.relativenumber = true
    end
  end,
})

vim.api.nvim_create_autocmd({ "BufLeave", "CmdlineEnter", "WinLeave" }, {
  desc = "Show absolute line numbers outside normal mode",
  group = number_toggle,
  callback = function()
    if vim.wo.number then
      vim.wo.relativenumber = false
    end
  end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight yanked text",
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Parsers are supplied declaratively by nvim-treesitter.withPlugins in default.nix.
vim.api.nvim_create_autocmd("FileType", {
  desc = "Enable Tree-sitter highlighting",
  callback = function(event)
    pcall(vim.treesitter.start, event.buf)
  end,
})

local function current_file_directory()
  local file = vim.api.nvim_buf_get_name(0)
  return file ~= "" and vim.fs.dirname(file) or vim.uv.cwd()
end

local function cd(directory)
  if directory then
    vim.api.nvim_set_current_dir(directory)
    vim.notify(vim.fn.getcwd())
  end
end

local function cd_repository_root()
  local root = vim.fs.root(0, ".git")
  if root then
    cd(root)
  else
    vim.notify("Not inside a Git repository", vim.log.levels.WARN)
  end
end

local function open_terminal_here()
  local terminal = vim.env.TERMINAL or "ghostty"
  if vim.fn.executable(terminal) == 0 then
    vim.notify(("Terminal executable not found: %s"):format(terminal), vim.log.levels.ERROR)
    return
  end

  vim.system({ terminal }, { cwd = current_file_directory(), detach = true })
end

local home = vim.env.HOME or vim.uv.os_homedir()
local config_home = vim.env.XDG_CONFIG_HOME or (home .. "/.config")
local code_home = vim.env.CODE_HOME or (home .. "/code")

vim.keymap.set("n", "<leader>cd<Return>", function()
  cd(home)
end, { desc = "Change directory to $HOME" })
vim.keymap.set("n", "<leader>cdf", function()
  cd(current_file_directory())
end, { desc = "Change directory to the current file's directory" })
vim.keymap.set("n", "<leader>cd.", function()
  cd(vim.fs.dirname(vim.fn.getcwd()))
end, { desc = "Change directory to the parent directory" })
vim.keymap.set(
  "n",
  "<leader>cdrr",
  cd_repository_root,
  { desc = "Change directory to the Git root" }
)
vim.keymap.set("n", "<leader>cdcf", function()
  cd(config_home)
end, { desc = "Change directory to $XDG_CONFIG_HOME" })
vim.keymap.set("n", "<leader>cdco", function()
  cd(code_home)
end, { desc = "Change directory to $CODE_HOME or ~/code" })
vim.keymap.set(
  "n",
  "<leader>tt",
  open_terminal_here,
  { desc = "Open a terminal beside the current file" }
)

vim.keymap.set({ "n", "x" }, "<leader>y", '"+y', { desc = "Yank to the system clipboard" })
vim.keymap.set("n", "<leader>Y", '"+y$', { desc = "Yank to end of line to the system clipboard" })
vim.keymap.set({ "n", "x" }, "<leader>d", '"+d', { desc = "Delete to the system clipboard" })
vim.keymap.set("n", "<leader>D", '"+D', { desc = "Delete to end of line to the system clipboard" })
vim.keymap.set({ "n", "x" }, "<leader>c", '"_d', { desc = "Delete without copying" })
vim.keymap.set("n", "<leader>C", '"_D', { desc = "Delete to end of line without copying" })
vim.keymap.set("x", "<leader>p", '"_dP', { desc = "Paste without replacing the yank register" })

vim.keymap.set("x", "<C-j>", ":move '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("x", "<C-k>", ":move '<-2<CR>gv=gv", { desc = "Move selection up" })

local window_maps = {
  ["<A-h>"] = "h",
  ["<A-j>"] = "j",
  ["<A-k>"] = "k",
  ["<A-l>"] = "l",
  ["<A-H>"] = "H",
  ["<A-J>"] = "J",
  ["<A-K>"] = "K",
  ["<A-L>"] = "L",
  ["<A-=>"] = "=",
  ["<A-m>"] = "|",
}

for keys, command in pairs(window_maps) do
  vim.keymap.set({ "n", "i", "t" }, keys, "<Cmd>wincmd " .. command .. "<CR>", { silent = true })
end

vim.keymap.set({ "n", "i", "t" }, "<A-Left>", "<Cmd>vertical resize -2<CR>", { silent = true })
vim.keymap.set({ "n", "i", "t" }, "<A-Down>", "<Cmd>resize -1<CR>", { silent = true })
vim.keymap.set({ "n", "i", "t" }, "<A-Up>", "<Cmd>resize +1<CR>", { silent = true })
vim.keymap.set({ "n", "i", "t" }, "<A-Right>", "<Cmd>vertical resize +2<CR>", { silent = true })

vim.keymap.set("i", "<C-BS>", "<C-G>u<C-W>", { desc = "Delete a word with a separate undo point" })
vim.keymap.set("i", "<C-U>", "<C-G>u<C-U>", { desc = "Delete a line with a separate undo point" })
vim.keymap.set("i", "<C-W>", "<C-G>u<C-W>", { desc = "Delete a word with a separate undo point" })
vim.keymap.set("n", "<C-d>", "M<C-d>zz")
vim.keymap.set("n", "<C-u>", "M<C-u>zz")
vim.keymap.set("n", "<C-f>", "<C-f>zz")
vim.keymap.set("n", "<C-b>", "<C-b>zz")
vim.keymap.set("n", "n", "nzz")
vim.keymap.set("n", "N", "Nzz")
vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<Esc>", "<Cmd>nohlsearch<CR>")
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

require("flash").setup({
  highlight = { backdrop = true },
  label = { rainbow = { enabled = true, shade = 5 } },
  modes = { char = { highlight = { backdrop = true } } },
})

vim.keymap.set({ "n", "x", "o" }, "s", function()
  vim.cmd.nohlsearch()
  vim.cmd.diffupdate()
  require("flash").jump()
end, { desc = "Flash" })
vim.keymap.set({ "n", "x", "o" }, "S", function()
  require("flash").treesitter()
end, { desc = "Flash Tree-sitter" })
vim.keymap.set("o", "r", function()
  require("flash").remote()
end, { desc = "Remote Flash" })
vim.keymap.set({ "o", "x" }, "R", function()
  require("flash").treesitter_search()
end, { desc = "Flash Tree-sitter search" })
vim.keymap.set("c", "<C-s>", function()
  require("flash").toggle()
end, { desc = "Toggle Flash search" })

local telescope = require("telescope")
telescope.setup({
  defaults = {
    sorting_strategy = "ascending",
    layout_strategy = "horizontal",
    layout_config = { prompt_position = "top" },
    border = true,
  },
  pickers = {
    commands = { theme = "ivy" },
    current_buffer_fuzzy_find = { theme = "dropdown" },
  },
  extensions = {
    file_browser = {
      hijack_netrw = true,
      sorting_strategy = "ascending",
      layout_config = { prompt_position = "top" },
    },
  },
})
telescope.load_extension("file_browser")

local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>st", builtin.builtin, { desc = "Search Telescope pickers" })
vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "Search files" })
vim.keymap.set("n", "<leader>sr", builtin.git_files, { desc = "Search Git files" })
vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "Search by grep" })
vim.keymap.set(
  "n",
  "<leader>/",
  builtin.current_buffer_fuzzy_find,
  { desc = "Search current buffer" }
)
vim.keymap.set("n", "<leader>sb", builtin.buffers, { desc = "Search buffers" })
vim.keymap.set("n", "<leader>so", builtin.oldfiles, { desc = "Search recent files" })
vim.keymap.set("n", "<leader>sj", builtin.jumplist, { desc = "Search jump list" })
vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "Search help" })
vim.keymap.set("n", "<leader>:", builtin.commands, { desc = "Search commands" })
vim.keymap.set({ "n", "i" }, "<M-x>", builtin.commands, { desc = "Search commands" })
vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "Search keymaps" })
vim.keymap.set("n", "<leader>fm", telescope.extensions.file_browser.file_browser, {
  desc = "Open Telescope file browser",
})
