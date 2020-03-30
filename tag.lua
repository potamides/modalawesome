local awful = require("awful")

local tag_commands = {
  {
    description = "focus a client",
    pattern = {{'[hjkl]'}},
    handler =
      function(_, movement)
        local directions = {h = 'left', j = 'down', k = 'up', l = 'right'}
        awful.client.focus.bydirection(directions[movement])
      end
  },
  {
    description = "focus a tag",
    pattern = {
          {'f', '%d*', '[hl]'},
          {'f?', '%d*', 'g', 'g'}
        },
    handler =
      function(_, _, count, ...)
        local screen, movement, index = awful.screen.focused(), table.concat({...})
        count = count == '' and 1 or tonumber(count)

        if movement == 'gg' then
          index = count
        elseif movement == 'h' then
          index = ((screen.selected_tag.index - 1 - count) % #screen.tags) + 1
        elseif movement == 'l' then
          index = ((screen.selected_tag.index - 1 + count) % #screen.tags) + 1
        end

        if screen.tags[index] then
          screen.tags[index]:view_only()
        end
      end
  },
  {
    description = "move focused client to tag",
    pattern = {
          {'m', '%d*', '[hl]'},
          {'m', '%d*', 'g', 'g'},
          },
    handler =
      function(_, _, count, ...)
        local screen, movement, index = awful.screen.focused(), table.concat({...})
        count = count == '' and 1 or tonumber(count)

        if movement == 'gg' then
          index = count
        elseif movement == 'h' then
          index = ((screen.selected_tag.index - 1 - count) % #screen.tags) + 1
        elseif movement == 'l' then
          index = ((screen.selected_tag.index - 1 + count) % #screen.tags) + 1
        end

        if screen.tags[index] then
          awful.client.focus:move_to_tag(screen.tags[index])
        end
      end
  },
  {
    description = "toggle tag",
    pattern = {
          {'t', '%d*', '[hl]'},
          {'t', '%d*', 'g', 'g'},
          },
    handler =
      function(_, _, count, movement)
        local screen, index = awful.screen.focused()
        count = count == '' and 1 or tonumber(count)

        if movement == 'gg' then
          index = count
        elseif movement == 'h' then
          index = ((screen.selected_tag.index - 1 - count) % #screen.tags) + 1
        elseif movement == 'l' then
          index = ((screen.selected_tag.index - 1 + count) % #screen.tags) + 1
        end

        if screen.tags[index] then
          awful.tag.viewtoggle(screen.tags[index])
        end
      end
  },
  {
    description = "enter client mode",
    pattern = {{'i'}},
    handler = function(self) self.startmode("client", true) end
  },
  {
    description = "enter launcher mode",
    pattern = {{'s'}},
    handler = function(self) self.startmode("launcher") end
  }
}

return tag_commands
