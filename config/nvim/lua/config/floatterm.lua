local M = {}

local function open_float(buf, opts)
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  if row < 0 then
    row = 0
  end
  if col < 0 then
    col = 0
  end

  return vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = opts.border or "rounded",
  })
end

function M.open(cmd)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "terminal"

  open_float(buf, {})

  if cmd and cmd ~= "" then
    vim.fn.termopen(cmd)
  else
    vim.fn.termopen(vim.o.shell)
  end

  vim.cmd("startinsert")
end

function M.open_prompt()
  vim.ui.input({ prompt = "Command: " }, function(input)
    if input and input ~= "" then
      M.open(input)
    end
  end)
end

function M.setup()
  vim.api.nvim_create_user_command("FloatTerm", function(opts)
    if opts.args and opts.args ~= "" then
      M.open(opts.args)
    else
      M.open()
    end
  end, { nargs = "*", complete = "shellcmd" })
end

return M
