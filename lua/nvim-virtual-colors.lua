local M = {
  ns_id = 0,
}

function M.init_autocmd()
  vim.api.nvim_create_autocmd('InsertEnter', {
    pattern = {'*.css'},
    callback = function(ev)
      vim.api.nvim_buf_clear_namespace(0, M.ns_id, 0, -1)
    end
  })

  vim.api.nvim_create_autocmd('InsertLeave', {
    pattern = {'*.css'},
    callback = function(ev)
      M.detect_colors()
    end
  })

  vim.api.nvim_create_autocmd('BufEnter', {
    pattern = {'*.css'},
    callback = function(ev)
      M.detect_colors()
    end
  })
end

function M.detect_colors()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local color_index
  local semic_index
  local color
  local len
  local offset = 0

  for i, line in ipairs(lines) do
    while true do
      color_index = line:find('#', offset)
      semic_index = line:find(';', offset)

      if color_index ~= nil and semic_index ~= nil then
        len = semic_index - color_index - 1

        if not (len == 3 or len == 6) then
          return
        end

        len = semic_index - color_index - 1

        color = line:sub(color_index + 1, semic_index - 1)

        if len == 3 then
          color = color:rep(2)
        end

        vim.api.nvim_set_hl(0, color, { fg = '#' .. color })

        local opts = {
          virt_text = {{'█', color}},
          virt_text_pos = 'inline',
        }

        local mark_id = vim.api.nvim_buf_set_extmark(0, M.ns_id, i - 1, color_index - 1, opts)

        offset = offset + semic_index + 1
      else
        offset = 0

        break
      end
    end
  end
end

function M.setup(opts)
  M.ns_id = vim.api.nvim_create_namespace("virtual-colors")

  M.init_autocmd()
end

return M
