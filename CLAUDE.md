# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```sh
# Run all tests
make test

# Run a single spec file
vusted --shuffle spec/lua/clpb/init_spec.lua

# Generate docs
make doc

# Type check with lua-language-server
make check
```

`make test` clones deps into `spec/.shared/packages/` on first run.

## Architecture

`clpb.nvim` is a Neovim plugin (Lua) for managing yank history and cycling through it after pasting.

- `lua/clpb/init.lua` — public API (`yank`, `paste`, `prev`, `next`, `list`); thin wrappers that lazy-require `clpb.command`
- `lua/clpb/command.lua` — all state and logic

Tests use [vusted](https://github.com/notomo/vusted) (busted runner for Neovim) and [assertlib.nvim](https://github.com/notomo/assertlib.nvim). The helper (`lua/clpb/test/helper.lua`) installs a fake in-memory clipboard provider via `vim.g.clipboard` to avoid slow external clipboard calls, and resets module state via `helper.cleanup_loaded_modules` between tests.
