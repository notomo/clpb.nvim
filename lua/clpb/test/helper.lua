local helper = require("ntf.helper")
local plugin_name = helper.get_module_root(...)

helper.root = helper.find_plugin_root(plugin_name)
vim.opt.packpath:prepend(vim.fs.joinpath(helper.root, "spec/.shared/packages"))
require("assertlib").register(require("ntf.assert").register)

function helper.before_each()
  vim.g.clipboard = helper.clipboard()
end

function helper.after_each()
  vim.g.clipboard = nil
end

-- Emulate a paste. `nvim_put()` neither inserts into a pristine empty buffer nor
-- sets the `'[`/`']` change marks that on_pasted() reads, so paste via `p`, which
-- does both.
function helper.put(lines)
  vim.fn.setreg('"', lines, "c")
  vim.cmd("normal! p")
end

function helper.clipboard()
  local register = {}
  return {
    name = "test",
    copy = {
      ["+"] = function(lines, regtype)
        register = { lines, regtype }
      end,
    },
    paste = {
      ["+"] = function()
        return register
      end,
    },
  }
end

return helper
