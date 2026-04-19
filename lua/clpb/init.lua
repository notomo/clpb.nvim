local M = {}

--- @class ClpbItem
--- @field lines string[] yanked text lines
--- @field regtype string register type |getregtype()|

--- Save yanked text to history.
--- @param event {regcontents:string[],regtype:string}
function M.yank(event)
  require("clpb.command").yank(event)
end

--- Call after pasting to enable prev/next cycling.
function M.on_pasted()
  require("clpb.command").on_pasted()
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
--- @return ClpbItem[] |ClpbItem|
function M.list()
  return require("clpb.command").list()
end

return M
