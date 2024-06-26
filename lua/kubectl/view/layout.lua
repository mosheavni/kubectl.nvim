local hl = require("kubectl.view.highlight")
local config = require("kubectl.config")
local M = {}
local api = vim.api

function M.set_buf_options(buf, win, filetype, syntax)
  api.nvim_set_option_value("filetype", filetype, { buf = buf })
  api.nvim_set_option_value("syntax", syntax, { buf = buf })
  api.nvim_set_option_value("bufhidden", "wipe", { scope = "local" })
  api.nvim_set_option_value("cursorline", true, { win = win })
  api.nvim_set_option_value("modified", false, { buf = buf })

  -- TODO: How do we handle long text?
  -- api.nvim_set_option_value("wrap", true, { scope = "local" })
  -- api.nvim_set_option_value("linebreak", true, { scope = "local" })

  -- TODO: Is this neaded?
  -- vim.wo[win].winhighlight = "Normal:Normal"
  -- TODO: Need to workout how to reuse single buffer with this setting, or not
  -- api.nvim_set_option_value("modifiable", false, { buf = buf })
end

function M.main_layout(buf, filetype, syntax)
  if not syntax then
    syntax = filetype
  end
  local win = api.nvim_get_current_win()
  M.set_buf_options(buf, win, filetype, syntax)
  hl.set_highlighting()
end

function M.filter_layout(buf, filetype, title)
  local width = 0.8 * vim.o.columns
  local height = 0.1 * vim.o.lines
  local row = 10
  local col = 10

  local win = api.nvim_open_win(buf, true, {
    relative = "editor",
    style = "minimal",
    width = math.floor(width),
    height = math.floor(height),
    row = row,
    border = "rounded",
    col = col,
    title = filetype .. " - " .. (title or ""),
  })
  return win
end

function M.float_layout(buf, filetype, title, syntax)
  if not syntax then
    syntax = filetype
  end
  local width = config.options.float_size.width * vim.o.columns
  local height = config.options.float_size.height * vim.o.lines
  local row = config.options.float_size.row
  local col = config.options.float_size.col

  local win = api.nvim_open_win(buf, true, {
    relative = "editor",
    style = "minimal",
    width = math.floor(width),
    height = math.floor(height),
    row = row,
    border = "rounded",
    col = col,
    title = filetype .. " - " .. (title or ""),
  })

  M.set_buf_options(buf, win, filetype, syntax)
  hl.set_highlighting()
end

return M
