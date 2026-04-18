local helper = require("clpb.test.helper")
local clpb = helper.require("clpb")
local assert = require("assertlib").typed(assert)

describe("clpb.list()", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("returns empty list initially", function()
    assert.same({}, clpb.list())
  end)

  it("returns history after yank", function()
    clpb.yank({ regcontents = { "hello" }, regtype = "v" })

    local got = clpb.list()

    assert.equal(1, #got)
    assert.same({ "hello" }, got[1].lines)
    assert.equal("v", got[1].regtype)
  end)

  it("accumulates multiple yanks", function()
    clpb.yank({ regcontents = { "first" }, regtype = "v" })
    clpb.yank({ regcontents = { "second" }, regtype = "V" })

    local got = clpb.list()

    assert.equal(2, #got)
    assert.same({ "second" }, got[1].lines)
    assert.equal("V", got[1].regtype)
    assert.same({ "first" }, got[2].lines)
    assert.equal("v", got[2].regtype)
  end)

  it("returns a copy (not the internal state)", function()
    clpb.yank({ regcontents = { "hello" }, regtype = "v" })

    local got = clpb.list()
    got[1].lines[1] = "mutated"

    assert.same({ "hello" }, clpb.list()[1].lines)
  end)
end)

describe("clpb.paste()", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("does nothing when history is empty", function()
    clpb.paste()

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.same({ "" }, lines)
  end)

  it("inserts charwise yanked text into buffer", function()
    clpb.yank({ regcontents = { "hello" }, regtype = "v" })
    vim.fn.setreg("+", { "hello" }, "v")

    clpb.paste()

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.same({ "hello" }, lines)
  end)

  it("inserts linewise yanked text as a new line", function()
    clpb.yank({ regcontents = { "hello" }, regtype = "V" })
    vim.fn.setreg("+", { "hello" }, "V")

    clpb.paste()

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.same({ "", "hello" }, lines)
  end)

  it("pastes the latest yank when multiple yanks exist", function()
    clpb.yank({ regcontents = { "first" }, regtype = "v" })
    clpb.yank({ regcontents = { "second" }, regtype = "v" })
    vim.fn.setreg("+", { "second" }, "v")

    clpb.paste()

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.same({ "second" }, lines)
  end)
end)

describe("clpb.prev()", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("does nothing when history is empty", function()
    clpb.prev()

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.same({ "" }, lines)
  end)

  it("does nothing when already at the oldest item", function()
    clpb.yank({ regcontents = { "only" }, regtype = "v" })
    vim.fn.setreg("+", { "only" }, "v")
    clpb.paste()

    clpb.prev()

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.same({ "only" }, lines)
  end)

  it("replaces pasted text with previous history item", function()
    clpb.yank({ regcontents = { "first" }, regtype = "v" })
    clpb.yank({ regcontents = { "second" }, regtype = "v" })
    vim.fn.setreg("+", { "second" }, "v")
    clpb.paste()

    clpb.prev()

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.same({ "first" }, lines)
  end)

  it("does not undo when called without a preceding paste", function()
    clpb.yank({ regcontents = { "first" }, regtype = "v" })
    clpb.yank({ regcontents = { "second" }, regtype = "v" })

    clpb.prev()

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.same({ "" }, lines)
  end)
end)

describe("clpb.next()", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("does nothing when history is empty", function()
    clpb.next()

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.same({ "" }, lines)
  end)

  it("does nothing when already at the newest item", function()
    clpb.yank({ regcontents = { "only" }, regtype = "v" })
    vim.fn.setreg("+", { "only" }, "v")
    clpb.paste()

    clpb.next()

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.same({ "only" }, lines)
  end)

  it("replaces pasted text with next history item after prev", function()
    clpb.yank({ regcontents = { "first" }, regtype = "v" })
    clpb.yank({ regcontents = { "second" }, regtype = "v" })
    vim.fn.setreg("+", { "second" }, "v")
    clpb.paste()
    clpb.prev()

    clpb.next()

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.same({ "second" }, lines)
  end)
end)

describe("clpb.paste() register and highlight", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("pastes external content from + register without overwriting it", function()
    clpb.yank({ regcontents = { "from_neovim" }, regtype = "v" })
    vim.fn.setreg("+", { "external" }, "v")

    clpb.paste()

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.same({ "external" }, lines)
    assert.equal("external", vim.fn.getreg("+"))
  end)

  it("prev does not overwrite + register", function()
    clpb.yank({ regcontents = { "first" }, regtype = "v" })
    clpb.yank({ regcontents = { "second" }, regtype = "v" })
    vim.fn.setreg("+", { "second" }, "v")
    clpb.paste()
    vim.fn.setreg("+", { "external" }, "v")

    clpb.prev()

    assert.equal("external", vim.fn.getreg("+"))
  end)

  it("sets extmark highlight after paste", function()
    clpb.yank({ regcontents = { "hello" }, regtype = "v" })
    vim.fn.setreg("+", { "hello" }, "v")

    clpb.paste()

    local ns_id = vim.api.nvim_get_namespaces()["clpb"]
    local marks = vim.api.nvim_buf_get_extmarks(0, ns_id, 0, -1, {})
    assert.equal(1, #marks)
  end)

  it("clears highlight on CursorMoved", function()
    clpb.yank({ regcontents = { "hello" }, regtype = "v" })
    vim.fn.setreg("+", { "hello" }, "v")
    clpb.paste()

    vim.wait(0)
    vim.api.nvim_exec_autocmds("CursorMoved", { buffer = 0 })

    local ns_id = vim.api.nvim_get_namespaces()["clpb"]
    local marks = vim.api.nvim_buf_get_extmarks(0, ns_id, 0, -1, {})
    assert.same({}, marks)
  end)

  it("sets extmark highlight after prev", function()
    clpb.yank({ regcontents = { "first" }, regtype = "v" })
    clpb.yank({ regcontents = { "second" }, regtype = "v" })
    vim.fn.setreg("+", { "second" }, "v")
    clpb.paste()

    clpb.prev()

    local ns_id = vim.api.nvim_get_namespaces()["clpb"]
    local marks = vim.api.nvim_buf_get_extmarks(0, ns_id, 0, -1, {})
    assert.equal(1, #marks)
  end)

  it("sets extmark highlight after next", function()
    clpb.yank({ regcontents = { "first" }, regtype = "v" })
    clpb.yank({ regcontents = { "second" }, regtype = "v" })
    vim.fn.setreg("+", { "second" }, "v")
    clpb.paste()
    clpb.prev()

    clpb.next()

    local ns_id = vim.api.nvim_get_namespaces()["clpb"]
    local marks = vim.api.nvim_buf_get_extmarks(0, ns_id, 0, -1, {})
    assert.equal(1, #marks)
  end)
end)
