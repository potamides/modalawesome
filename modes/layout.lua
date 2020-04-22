local awful     = require("awful")

local layout_commands = {
  {
    description = "change client height factor",
    pattern = {'[jk]'},
    handler = function(_, movement)
      if movement == 'j' then
        awful.client.incwfact(-0.05)
      else
        awful.client.incwfact(0.05)
      end
    end
  },
  {
    description = "change master width factor",
    pattern = {'[hl]'},
    handler = function(_, movement)
      if movement == 'h' then
        awful.tag.incmwfact(-0.05)
      else
        awful.tag.incmwfact(0.05)
      end
    end
  },
  {
    description = "change number of master clients",
    pattern = {'%d*', '[sd]'},
    handler = function(_, count, movement)
      count = count == '' and 1 or tonumber(count)

      if movement == 's' then
        awful.tag.incnmaster(count, nil, true)
      else
        awful.tag.incnmaster(-count, nil, true)

      end

    end
  },
  {
    description = "change number of columns",
    pattern = {'%d*', '[mn]'},
    handler = function(_, count, movement)
      count = count == '' and 1 or tonumber(count)

      if  movement == 'm' then
        awful.tag.incncol(count, nil, true)
      else
        awful.tag.incncol(-count, nil, true)
      end
    end
  },
  {
    description = "change layout",
    pattern = {'%d*', '[fb]'},
    handler = function(_, count, movement)
      count = count == '' and 1 or tonumber(count)

      if  movement == 'f' then
        awful.layout.inc(count)
      else
        awful.layout.inc(-count)
      end
    end
  },
  {
    description = "change useless gap",
    pattern = {'%d*', '[+-]'},
    handler = function(_, count, movement)
      count = count == '' and 1 or tonumber(count)

      if  movement == '+' then
        awful.tag.incgap(count)
      else
        awful.tag.incgap(-count)
      end
    end
  },
  {
    description = "enter client mode",
    pattern = {'i'},
    handler = function(self) self.startinsert() end
  },
}

return layout_commands
