local M = {}

local default_opts = {
  max_blank_lines = 2,
  hl_ws_group = { link = "Error" },
  hl_ws_name = "ExtraWhitespace",
  hl_ws_prio = 10,
  hl_clear_name = "Whitespace",
  hl_clear_prio = 20,
}

-- Reapply or remove highlights depending on buffer + window state
local function refresh_highlight(opts)
  local win_hl_applied = not not vim.w.hl_ids
  local buf_hl_enabled = not not vim.b.hl_enabled

  -- If window state matches buffer intention, nothing to do
  if win_hl_applied == buf_hl_enabled then
    return
  end

  if buf_hl_enabled then
    -- Regex for extra blank lines beyond max_blank_lines
    -- Match N allowed blank lines, then highlight the rest
    local reg = "\\(^\\s*\\n\\)\\{" .. opts.max_blank_lines .. "}\\zs\\(^\\s*\\n\\)\\+"

    vim.w.hl_ids = {
      -- highlight trailing whitespace
      vim.fn.matchadd(opts.hl_ws_name, "\\s\\+$", opts.hl_ws_prio),
      -- do NOT highlight trailing WS before the cursor
      vim.fn.matchadd(opts.hl_clear_name, "\\s\\+\\%#", opts.hl_clear_prio),
      -- highlight extra blank lines beyond max_blank_lines
      vim.fn.matchadd(opts.hl_ws_name, reg, opts.hl_ws_prio),
    }
  else
    for _, id in ipairs(vim.w.hl_ids) do
      vim.fn.matchdelete(id)
    end
    vim.w.hl_ids = nil
  end
end

M.setup = function(user_opts)
  local opts = vim.tbl_extend("force", {}, default_opts, user_opts or {})

  local augrp = vim.api.nvim_create_augroup("WhiteSpace", { clear = true })

  -- Set buffer intention on FileType
  vim.api.nvim_create_autocmd("FileType", {
    group = augrp,
    callback = function()
      vim.b.hl_enabled = vim.bo.buftype == ""
      refresh_highlight(opts)
    end,
  })

  -- Reapply highlights when entering buffer/window
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "WinEnter" }, {
    group = augrp,
    callback = function()
      refresh_highlight(opts)
    end,
  })

  -- Define highlight group
  vim.api.nvim_set_hl(0, opts.hl_ws_name, opts.hl_ws_group)
end

return M
