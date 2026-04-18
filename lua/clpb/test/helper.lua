local helper = require("vusted.helper")
local plugin_name = helper.get_module_root(...)

helper.root = helper.find_plugin_root(plugin_name)
vim.opt.packpath:prepend(vim.fs.joinpath(helper.root, "spec/.shared/packages"))
require("assertlib").register(require("vusted.assert").register)

function helper.before_each()
  vim.g.clipboard = helper.clipboard()
end

function helper.after_each()
  vim.g.clipboard = nil
  helper.cleanup()
  helper.cleanup_loaded_modules(plugin_name)
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
