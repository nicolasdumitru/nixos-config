-- Neovim configuration
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.mouse = "a"
opt.breakindent = true
opt.undofile = true
opt.ignorecase = true
opt.smartcase = true
opt.signcolumn = "yes"
opt.updatetime = 250
opt.timeoutlen = 300
opt.splitright = true
opt.splitbelow = true
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.inccommand = "split"
opt.cursorline = true
opt.scrolloff = 10
opt.confirm = true
opt.termguicolors = true

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic list" })
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight text when it is yanked",
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Parsers are supplied declaratively by nvim-treesitter.withPlugins in default.nix.
vim.api.nvim_create_autocmd("FileType", {
  desc = "Enable treesitter highlighting",
  callback = function(args)
    pcall(vim.treesitter.start, args.buf)
  end,
})

require("gruvbox").setup({
  contrast = "hard",
})
vim.o.background = "dark"
vim.cmd.colorscheme("gruvbox")

require("lualine").setup({ options = { theme = "gruvbox" } })
require("gitsigns").setup()
require("which-key").setup()

local telescope = require("telescope.builtin")
vim.keymap.set("n", "<leader>sf", telescope.find_files, { desc = "Search files" })
vim.keymap.set("n", "<leader>sg", telescope.live_grep, { desc = "Search by grep" })
vim.keymap.set("n", "<leader>sb", telescope.buffers, { desc = "Search buffers" })
vim.keymap.set("n", "<leader>sh", telescope.help_tags, { desc = "Search help" })
vim.keymap.set("n", "<leader>sd", telescope.diagnostics, { desc = "Search diagnostics" })

local luasnip = require("luasnip")
require("luasnip.loaders.from_vscode").lazy_load()

local cmp = require("cmp")
cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-n>"] = cmp.mapping.select_next_item(),
    ["<C-p>"] = cmp.mapping.select_prev_item(),
    ["<C-y>"] = cmp.mapping.confirm({ select = true }),
    ["<C-Space>"] = cmp.mapping.complete(),
  }),
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "luasnip" },
  }, {
    { name = "buffer" },
  }),
})

local capabilities = require("cmp_nvim_lsp").default_capabilities()
local servers = {
  nixd = {},
  lua_ls = {
    settings = {
      Lua = {
        completion = { callSnippet = "Replace" },
        diagnostics = { globals = { "vim" } },
      },
    },
  },
}

-- Neovim 0.11+ uses vim.lsp.config; the fallback keeps the configuration
-- usable on this flake's stable nixpkgs host as well.
if vim.lsp.config then
  for name, config in pairs(servers) do
    config.capabilities = capabilities
    vim.lsp.config(name, config)
    vim.lsp.enable(name)
  end
else
  local lspconfig = require("lspconfig")
  for name, config in pairs(servers) do
    config.capabilities = capabilities
    lspconfig[name].setup(config)
  end
end

vim.api.nvim_create_autocmd("LspAttach", {
  desc = "LSP keymaps",
  callback = function(event)
    local map = function(keys, action, desc)
      vim.keymap.set("n", keys, action, { buffer = event.buf, desc = desc })
    end

    map("gd", telescope.lsp_definitions, "Go to definition")
    map("gr", telescope.lsp_references, "Go to references")
    map("gI", telescope.lsp_implementations, "Go to implementation")
    map("<leader>D", telescope.lsp_type_definitions, "Type definition")
    map("<leader>ds", telescope.lsp_document_symbols, "Document symbols")
    map("<leader>ws", telescope.lsp_dynamic_workspace_symbols, "Workspace symbols")
    map("<leader>rn", vim.lsp.buf.rename, "Rename")
    map("<leader>ca", vim.lsp.buf.code_action, "Code action")
    map("K", vim.lsp.buf.hover, "Hover documentation")
  end,
})
