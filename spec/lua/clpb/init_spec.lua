local helper = require("clpb.test.helper")
local clpb = helper.require("clpb")
local assert = require("assertlib").typed(assert)

describe("clpb.yank()", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("limits history to 20 items", function()
    for i = 1, 21 do
      clpb.yank({ lines = { tostring(i) }, regtype = "v" })
    end

    local got = clpb.list()

    assert.equal(20, #got)
    assert.same({ "21" }, got[1].lines)
    assert.same({ "2" }, got[20].lines)
  end)
end)

describe("clpb.list()", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("returns empty list initially", function()
    assert.same({}, clpb.list())
  end)

  it("accumulates multiple yanks", function()
    clpb.yank({ lines = { "first" }, regtype = "v" })
    clpb.yank({ lines = { "second" }, regtype = "V" })

    local got = clpb.list()

    assert.equal(2, #got)
    assert.same({ "second" }, got[1].lines)
    assert.equal("V", got[1].regtype)
    assert.same({ "first" }, got[2].lines)
    assert.equal("v", got[2].regtype)
  end)
end)

describe("clpb.on_pasted()", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("sets extmark highlight after paste", function()
    clpb.yank({ lines = { "hello" }, regtype = "v" })
    vim.api.nvim_put({ "hello" }, "c", true, false)

    clpb.on_pasted()

    local ns_id = vim.api.nvim_get_namespaces()["clpb"]
    local marks = vim.api.nvim_buf_get_extmarks(0, ns_id, 0, -1, {})
    assert.equal(1, #marks)
  end)

  it("resets cursor so subsequent prev starts from latest", function()
    clpb.yank({ lines = { "first" }, regtype = "v" })
    clpb.yank({ lines = { "second" }, regtype = "v" })
    vim.api.nvim_put({ "second" }, "c", true, false)
    clpb.on_pasted()
    clpb.prev()
    vim.api.nvim_put({ "external" }, "c", true, false)
    clpb.on_pasted()

    -- without reset: cursor stays at 1, prev wraps to 2 = "second"
    -- with reset: cursor=2, prev goes to 1 = "first"
    clpb.prev()

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.same({ "first" }, lines)
  end)

  it("clears highlight on CursorMoved", function()
    clpb.yank({ lines = { "hello" }, regtype = "v" })
    vim.api.nvim_put({ "hello" }, "c", true, false)
    clpb.on_pasted()

    vim.wait(0)
    vim.api.nvim_exec_autocmds("CursorMoved", { buffer = 0 })

    local ns_id = vim.api.nvim_get_namespaces()["clpb"]
    local marks = vim.api.nvim_buf_get_extmarks(0, ns_id, 0, -1, {})
    assert.same({}, marks)
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

  it("wraps to newest when prev at oldest item", function()
    clpb.yank({ lines = { "first" }, regtype = "v" })
    clpb.yank({ lines = { "second" }, regtype = "v" })
    vim.api.nvim_put({ "second" }, "c", true, false)
    clpb.on_pasted()
    clpb.prev()

    clpb.prev()

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.same({ "second" }, lines)
  end)

  it("replaces pasted text with previous history item", function()
    clpb.yank({ lines = { "first" }, regtype = "v" })
    clpb.yank({ lines = { "second" }, regtype = "v" })
    vim.api.nvim_put({ "second" }, "c", true, false)
    clpb.on_pasted()

    clpb.prev()

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.same({ "first" }, lines)
  end)

  it("does not undo when called without a preceding paste", function()
    clpb.yank({ lines = { "first" }, regtype = "v" })
    clpb.yank({ lines = { "second" }, regtype = "v" })

    clpb.prev()

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.same({ "" }, lines)
  end)

  it("does not overwrite + register", function()
    clpb.yank({ lines = { "first" }, regtype = "v" })
    clpb.yank({ lines = { "second" }, regtype = "v" })
    vim.api.nvim_put({ "second" }, "c", true, false)
    clpb.on_pasted()
    vim.fn.setreg("+", { "external" }, "v")

    clpb.prev()

    assert.equal("external", vim.fn.getreg("+"))
  end)

  it("sets extmark highlight after prev", function()
    clpb.yank({ lines = { "first" }, regtype = "v" })
    clpb.yank({ lines = { "second" }, regtype = "v" })
    vim.api.nvim_put({ "second" }, "c", true, false)
    clpb.on_pasted()

    clpb.prev()

    local ns_id = vim.api.nvim_get_namespaces()["clpb"]
    local marks = vim.api.nvim_buf_get_extmarks(0, ns_id, 0, -1, {})
    assert.equal(1, #marks)
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

  it("wraps to oldest when next at newest item", function()
    clpb.yank({ lines = { "first" }, regtype = "v" })
    clpb.yank({ lines = { "second" }, regtype = "v" })
    vim.api.nvim_put({ "second" }, "c", true, false)
    clpb.on_pasted()

    clpb.next()

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.same({ "first" }, lines)
  end)

  it("replaces pasted text with next history item after prev", function()
    clpb.yank({ lines = { "first" }, regtype = "v" })
    clpb.yank({ lines = { "second" }, regtype = "v" })
    vim.api.nvim_put({ "second" }, "c", true, false)
    clpb.on_pasted()
    clpb.prev()

    clpb.next()

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.same({ "second" }, lines)
  end)

  it("sets extmark highlight after next", function()
    clpb.yank({ lines = { "first" }, regtype = "v" })
    clpb.yank({ lines = { "second" }, regtype = "v" })
    vim.api.nvim_put({ "second" }, "c", true, false)
    clpb.on_pasted()
    clpb.prev()

    clpb.next()

    local ns_id = vim.api.nvim_get_namespaces()["clpb"]
    local marks = vim.api.nvim_buf_get_extmarks(0, ns_id, 0, -1, {})
    assert.equal(1, #marks)
  end)
end)
