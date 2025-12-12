local M = {
  ns_id = nil,
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
      if M.ns_id ~= nil then
        vim.api.nvim_buf_clear_namespace(0, M.ns_id, 0, -1)
      end

      M.detect_colors()
    end
  })
end

function M.detect_colors()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local offset = 0

  for i, line in ipairs(lines) do
    while true do
      local rgb_index = line:find('rgb', offset)
      local color_index = line:find('#', offset)
      local semic_index = line:find(';', offset)

      if color_index ~= nil and semic_index ~= nil then
        local len = semic_index - color_index - 1

        if not (len == 3 or len == 6) then
          return
        end

        local color = line:sub(color_index + 1, semic_index - 1)

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
      elseif rgb_index ~= nil and semic_index ~= nil then
        local lpar = line:find('%(', offset)
        local rpar = line:find('%)', offset)

        if lpar == nil or rpar == nil then
          break
        end

        local comma1 = line:find(',', lpar)
        
        if comma1 == nil then
          break
        end

        local comma2 = line:find(',', comma1 + 1)

        if comma2 == nil then
          break
        end

        local red = tonumber(line:sub(lpar + 1, comma1 - 1))
        local green = tonumber(line:sub(comma1 + 1, comma2 - 1))
        local blue = tonumber(line:sub(comma2 + 1, rpar - 1))

        if red == nil or green == nil or blue == nil then
          break
        end

        local color = string.format("%02x%02x%02x", red, green, blue)

        local opts = {
          virt_text = {{'█', color}},
          virt_text_pos = 'inline',
        }

        vim.api.nvim_set_hl(0, color, { fg = '#' .. color })

        local mark_id = vim.api.nvim_buf_set_extmark(0, M.ns_id, i - 1, rgb_index - 1, opts)

        offset = offset + rpar + 1
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
