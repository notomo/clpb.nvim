local setup_highlight_groups = function()
  local highlightlib = require("clpb.vendor.misclib.highlight")
  return {
    --used for pasted region highlight
    ClpbPasted = highlightlib.link("ClpbPasted", "IncSearch"),
  }
end

local group = vim.api.nvim_create_augroup("clpb.highlight_group", {})
vim.api.nvim_create_autocmd({ "ColorScheme" }, {
  group = group,
  pattern = { "*" },
  callback = function()
    setup_highlight_groups()
  end,
})

return setup_highlight_groups()
