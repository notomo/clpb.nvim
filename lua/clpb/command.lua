local M = {}

local history = {}
local cursor = 0
local ns = vim.api.nvim_create_namespace("clpb")
local max_history = 20

local function put_type(regtype)
  if regtype == "V" then
    return "l"
  elseif regtype:sub(1, 1) == "\22" then
    return "b"
  end
  return "c"
end

local function set_highlight(bufnr)
  local start_pos = vim.fn.getpos("'[")
  local end_pos = vim.fn.getpos("']")
  local group = vim.api.nvim_create_augroup("clpb", {})
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  vim.api.nvim_buf_set_extmark(bufnr, ns, start_pos[2] - 1, start_pos[3] - 1, {
    end_row = end_pos[2] - 1,
    end_col = end_pos[3],
    hl_group = "ClpbPasted",
  })
  vim.schedule(function()
    vim.api.nvim_create_autocmd("CursorMoved", {
      group = group,
      buffer = bufnr,
      once = true,
      callback = function()
        vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
      end,
    })
  end)
end

function M.yank(event)
  local lines = event.regcontents
  if #lines == 0 then
    return
  end

  table.insert(history, { lines = lines, regtype = event.regtype })
  if #history > max_history then
    table.remove(history, 1)
  end
  cursor = #history
end

function M.paste()
  cursor = #history
  local bufnr = vim.api.nvim_get_current_buf()
  -- Use + register to support content copied from external applications
  local lines = vim.fn.getreg("+", 1, true)
  local regtype = vim.fn.getregtype("+")
  vim.api.nvim_put(lines, put_type(regtype), true, false)
  set_highlight(bufnr)
end

local function cycle(offset)
  local bufnr = vim.api.nvim_get_current_buf()
  if #vim.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, { limit = 1 }) == 0 then
    return
  end

  local next_cursor = cursor + offset
  if next_cursor < 1 then
    next_cursor = #history
  elseif next_cursor > #history then
    next_cursor = 1
  end

  vim.cmd.undo({ mods = { silent = true } })
  cursor = next_cursor
  local item = history[cursor]
  vim.api.nvim_put(item.lines, put_type(item.regtype), true, false)
  set_highlight(bufnr)
end

function M.prev()
  cycle(-1)
end

function M.next()
  cycle(1)
end

function M.list()
  return vim.deepcopy(vim.iter(history):rev():totable())
end

return M
