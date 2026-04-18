local M = {}

local history = {}
local cursor = 0
local pasted = false
local ns = vim.api.nvim_create_namespace("clpb")

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
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  vim.api.nvim_buf_set_extmark(bufnr, ns, start_pos[2] - 1, start_pos[3] - 1, {
    end_row = end_pos[2] - 1,
    end_col = end_pos[3],
    hl_group = "IncSearch",
  })
  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = bufnr,
    once = true,
    callback = function()
      vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    end,
  })
end

function M.yank(event)
  event = event or vim.v.event
  local lines = event.regcontents
  if not lines or #lines == 0 then
    return
  end
  table.insert(history, { lines = lines, regtype = event.regtype })
  cursor = #history
  pasted = false
end

function M.paste()
  if cursor == 0 or #history == 0 then
    return
  end
  local bufnr = vim.api.nvim_get_current_buf()
  -- Use + register to support content copied from external applications
  local lines = vim.fn.getreg("+", 1, true)
  local regtype = vim.fn.getregtype("+")
  vim.api.nvim_put(lines, put_type(regtype), true, true)
  set_highlight(bufnr)
  pasted = true
end

function M.prev()
  if not pasted then
    return
  end
  if cursor <= 1 then
    return
  end
  vim.cmd("silent! undo")
  pasted = false
  cursor = cursor - 1
  local item = history[cursor]
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_put(item.lines, put_type(item.regtype), true, true)
  set_highlight(bufnr)
  pasted = true
end

function M.next()
  if not pasted then
    return
  end
  if cursor >= #history then
    return
  end
  vim.cmd("silent! undo")
  pasted = false
  cursor = cursor + 1
  local item = history[cursor]
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_put(item.lines, put_type(item.regtype), true, true)
  set_highlight(bufnr)
  pasted = true
end

function M.list()
  return vim.deepcopy(vim.iter(history):rev():totable())
end

return M
