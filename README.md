# clpb.nvim

Manage yank history and cycle through it after pasting.

## Example

```lua
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("config.clpb", {}),
  callback = function()
    require("clpb").yank(vim.v.event)
  end,
})

vim.keymap.set("n", "p", function()
  require("clpb").paste()
end)
vim.keymap.set("n", "<C-p>", function()
  require("clpb").prev()
end)
vim.keymap.set("n", "<C-n>", function()
  require("clpb").next()
end)
```