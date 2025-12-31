return {
  {
    "williamboman/mason.nvim",
    config = true,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = {
      "williamboman/mason.nvim",
      "neovim/nvim-lspconfig",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      local mason_lspconfig = require("mason-lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      local function as_set(list)
        local set = {}
        for _, item in ipairs(list) do
          set[item] = true
        end
        return set
      end

      local available = as_set(mason_lspconfig.get_available_servers())

      local function pick_server(candidates)
        for _, name in ipairs(candidates) do
          if available[name] then
            return name
          end
        end
        return nil
      end

      local servers = {
        "rust_analyzer",
        "pyright",
      }

      local ts_name = pick_server({ "ts_ls", "tsserver" })
      if ts_name then
        table.insert(servers, ts_name)
      end

      local solidity_name = pick_server({ "solidity_ls_nomicfoundation", "solidity_ls", "solidity" })
      if solidity_name then
        table.insert(servers, solidity_name)
      end

      mason_lspconfig.setup({ ensure_installed = servers })

      local function setup_server(server_name)
        if vim.lsp and vim.lsp.config then
          if vim.lsp.config[server_name] ~= nil then
            vim.lsp.config(server_name, { capabilities = capabilities })
            vim.lsp.enable(server_name)
          end
          return
        end

        local lspconfig = require("lspconfig")
        if lspconfig[server_name] then
          lspconfig[server_name].setup({
            capabilities = capabilities,
          })
        end
      end

      for _, server_name in ipairs(servers) do
        setup_server(server_name)
      end
    end,
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
    },
  },
}
