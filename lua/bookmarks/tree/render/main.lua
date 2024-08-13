local render_context = require("bookmarks.tree.render.context")
local tree_operate = require("bookmarks.tree.operate")
local config = require("bookmarks.config")

local M = {}

---@class Bookmarks.PopupWindowCtx
---@field buf integer
---@field win integer
---@field previous_window integer

---@param opts {width: integer}
---@return integer
local function create_vsplit_with_width(opts)
  vim.cmd("vsplit")

  local new_win = vim.api.nvim_get_current_win()

  vim.api.nvim_win_set_width(new_win, opts.width)

  return new_win
end

local function register_local_shortcuts(buf)
  local keymap = config.default_config.treeview.keymap
  if vim.g.bookmarks_config.treeview and vim.g.bookmarks_config.treeview.keymap then
    keymap = vim.g.bookmarks_config.treeview.keymap
  end

  local options = {
    noremap = true,
    silent = true,
    nowait = true,
    buffer = buf,
  }

  for action, keys in pairs(keymap) do
    if type(keys) == "string" then
      pcall(vim.keymap.set, { "v", "n" }, keys, tree_operate[action], options)
    elseif type(keys) == "table" then
      for _, k in ipairs(keys) do
        pcall(vim.keymap.set, { "v", "n" }, k, tree_operate[action], options)
      end
    end
  end
end

---@param bookmark_lists Bookmarks.BookmarkList[]
---@param opts {win: integer?, buf: integer?}
function M.render(bookmark_lists, opts)
  opts = opts or {}
  local cur_window = vim.api.nvim_get_current_win()
  local context, lines = render_context.from_bookmark_lists(bookmark_lists)

  local buf = opts.buf or vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  local width = vim.g.bookmarks_config.treeview.width
  local win = opts.win or create_vsplit_with_width({ width = width })
  vim.api.nvim_win_set_buf(win, buf)

  vim.b[buf]._bm_context = context

  register_local_shortcuts(buf)

  vim.g.bookmark_list_win_ctx = {
    buf = buf,
    win = win,
    previous_window = cur_window,
  }
end

return M
