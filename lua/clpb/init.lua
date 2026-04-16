local M = {}

--- @class ClpbItem
--- @field lines string[] yanked text lines
--- @field regtype string register type ('v'=charwise, 'V'=linewise, block=blockwise)

--- Save yanked text to history. Call inside |TextYankPost| autocmd.
--- @param event {regcontents: string[], regtype: string}?
function M.yank(event)
  require("clpb.command").yank(event)
end

--- Paste the current history item after cursor.
function M.paste()
  require("clpb.command").paste()
end

--- Replace last paste with the previous history item.
function M.prev()
  require("clpb.command").prev()
end

--- Replace last paste with the next history item.
function M.next()
  require("clpb.command").next()
end

--- Return the yank history.
--- @return ClpbItem[]
function M.list()
  return require("clpb.command").list()
end

return M
