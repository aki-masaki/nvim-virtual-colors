local M = {
  opts = {},
  ns_id = nil,
}

function M.hide()
  if M.ns_id ~= nil then
    vim.api.nvim_buf_clear_namespace(0, M.ns_id, 0, -1)
  end
end

function M.show()
  if M.ns_id ~= nil then
    vim.api.nvim_buf_clear_namespace(0, M.ns_id, 0, -1)
  end

  M.detect_colors()
end

function M.init_autocmd()
  local files_pattern = { '*.css' }

  vim.api.nvim_create_autocmd('InsertEnter', {
    pattern = files_pattern,
    callback = function(ev)
      M.hide()
    end
  })

  vim.api.nvim_create_autocmd('InsertLeave', {
    pattern = files_pattern,
    callback = function(ev)
      M.detect_colors()
    end
  })

  vim.api.nvim_create_autocmd('BufEnter', {
    pattern = files_pattern,
    callback = function(ev)
      M.show()
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

        local red   = tonumber(color:sub(1, 2), 16)
        local green = tonumber(color:sub(3, 4), 16)
        local blue  = tonumber(color:sub(5, 6), 16)

        local opts

        if M.opts.display == 'bg' or M.opts.display == 'bg-fn' then
          local fg

          if red + green + blue < 200 then
            fg = "#ffffff"
          else
            fg = "#000000"
          end

          vim.api.nvim_set_hl(0, color, { bg = '#' .. color , fg = fg})

          if M.opts.display == 'bg' then
            opts = {
              virt_text = {{'#' .. color, color}},
              virt_text_pos = 'overlay',
            }
          else
            opts = {
              virt_text = {{'#', color}},
              virt_text_pos = 'overlay',
            }
          end
        else
          vim.api.nvim_set_hl(0, color, { fg = '#' .. color})

          opts = {
            virt_text = {{'█', color}},
            virt_text_pos = 'inline',
          }
        end

        if M.opts.display_on_sign_column == true then
          opts.sign_text = '  '
          opts.sign_hl_group = color
        end

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

        if red == nil or red < 0 or red > 255 or green == nil or green < 0 or green > 255 or blue == nil or blue < 0 or blue > 255 then
          break
        end

        local color = string.format("%02x%02x%02x", red, green, blue)

        if M.opts.display == 'bg' or M.opts.display == 'bg-fn' then
          local fg

          if red + green + blue < 200 then
            fg = "#ffffff"
          else
            fg = "#000000"
          end

          vim.api.nvim_set_hl(0, color, { bg = '#' .. color , fg = fg})

          if M.opts.display == 'bg' then
            opts = {
              virt_text = {{string.format("rgb(%d, %d, %d)", red, green, blue), color}},
              virt_text_pos = 'overlay',
            }
          else
            opts = {
              virt_text = {{'rgb', color}},
              virt_text_pos = 'overlay',
            }
          end
        else
          vim.api.nvim_set_hl(0, color, { fg = '#' .. color})

          opts = {
            virt_text = {{'█', color}},
            virt_text_pos = 'inline',
          }
        end

        if M.opts.display_on_sign_column == true then
          opts.sign_text = '  '
          opts.sign_hl_group = color
        end

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
  opts = opts or {}

  M.opts = {
    display = opts.display or 'bg',
    display_on_sign_column = opts.display_on_sign_column or true
  }

  M.ns_id = vim.api.nvim_create_namespace("virtual-colors")

  M.init_autocmd()

  vim.api.nvim_create_user_command("HideVirtualColors", M.hide, {})
  vim.api.nvim_create_user_command("ShowVirtualColors", M.show, {})
end

return M
