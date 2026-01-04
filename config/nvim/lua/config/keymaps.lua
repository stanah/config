local map = vim.keymap.set

map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search" })
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Prev diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Diagnostics" })
map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Diagnostics list" })
map("n", "<leader>o", "<cmd>Oil<CR>", { desc = "Open Oil" })
map("n", "<leader>g", function()
  require("config.floatterm").open("lazygit")
end, { desc = "Open lazygit (float)" })
map("n", "<leader>t", function()
  require("config.floatterm").open()
end, { desc = "Open terminal (float)" })
map("n", "<leader>r", function()
  require("config.floatterm").open_prompt()
end, { desc = "Run command (float)" })

local ok, telescope = pcall(require, "telescope.builtin")
if ok then
  map("n", "<leader>ff", telescope.find_files, { desc = "Find files" })
  map("n", "<leader>fg", telescope.live_grep, { desc = "Live grep" })
  map("n", "<leader>fb", telescope.buffers, { desc = "Buffers" })
  map("n", "<leader>fh", telescope.help_tags, { desc = "Help" })
end
