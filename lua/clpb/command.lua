local M = {}

local history = {}
local cursor = 0
local pasted = false

local function put_type(regtype)
  if regtype == "V" then
    return "l"
  elseif regtype:sub(1, 1) == "\22" then
    return "b"
  end
  return "c"
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
  local item = history[cursor]
  vim.api.nvim_put(item.lines, put_type(item.regtype), true, true)
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
  M.paste()
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
  M.paste()
end

function M.list()
  return vim.deepcopy(history)
end

return M
