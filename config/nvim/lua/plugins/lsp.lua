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
      local lspconfig = require("lspconfig")
      local mason_lspconfig = require("mason-lspconfig")
      local mapping = require("mason-lspconfig.mappings.server").lspconfig_to_package
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      local function pick_server(candidates)
        for _, name in ipairs(candidates) do
          if mapping[name] then
            return name
          end
        end
        for _, name in ipairs(candidates) do
          if lspconfig[name] then
            return name
          end
        end
        return nil
      end

      local servers = {
        "rust_analyzer",
        "pyright",
      }

      local ts_name = pick_server({ "tsserver", "ts_ls" })
      if ts_name then
        table.insert(servers, ts_name)
      end

      local solidity_name = pick_server({ "solidity_ls_nomicfoundation", "solidity_ls", "solidity" })
      if solidity_name then
        table.insert(servers, solidity_name)
      end

      mason_lspconfig.setup({ ensure_installed = servers })
      mason_lspconfig.setup_handlers({
        function(server_name)
          if lspconfig[server_name] then
            lspconfig[server_name].setup({
              capabilities = capabilities,
            })
          end
        end,
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
    },
  },
}
