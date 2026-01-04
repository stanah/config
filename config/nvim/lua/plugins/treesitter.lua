return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    local ok, ts = pcall(require, "nvim-treesitter")
    if not ok then
      vim.schedule(function()
        vim.notify("nvim-treesitter is not installed yet. Run :Lazy sync.", vim.log.levels.WARN)
      end)
      return
    end

    local function start_highlight(buf)
      local ft = vim.bo[buf].filetype
      if ft ~= "markdown" and ft ~= "json" and ft ~= "html" and ft ~= "sh" and ft ~= "python" then
        return
      end
      if ft == "sh" then
        pcall(vim.treesitter.start, buf, "bash")
      else
        pcall(vim.treesitter.start, buf)
      end
    end

    ts.setup({})

    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "markdown", "json", "html", "sh", "python" },
      callback = function(args)
        start_highlight(args.buf)
      end,
    })

    vim.api.nvim_create_autocmd("User", {
      pattern = "TSUpdate",
      callback = function()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(buf) then
            start_highlight(buf)
          end
        end

      end,
    })
  end,
}
