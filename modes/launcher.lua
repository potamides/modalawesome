local awful = require("awful")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")

local launcher_commands = {
  {
    description = "show help",
    pattern = {'h'},
    handler = function() hotkeys_popup.show_help() end
  },
  {
    description = "reload awesome",
    pattern = {'r'},
    handler = function() awesome.restart() end
  },
  {
    description = "quit awesome",
    pattern = {'Q'},
    handler = function() awesome.quit() end
  },
  {
    description = "lua execute prompt",
    pattern = {'x'},
    handler = function()
      awful.prompt.run {
        prompt       = "Run Lua code: ",
        textbox      = awful.screen.focused().mypromptbox.widget.widget,
        exe_callback = awful.util.eval,
        history_path = awful.util.get_cache_dir() .. "/history_eval"
      }
    end,
  },
  {
    description = "run prompt",
    pattern = {'s'},
    handler = function()  awful.screen.focused().mypromptbox.widget:run() end
  },
  {
    description = "open a terminal",
    pattern = {'t'},
    handler = function() awful.spawn(menubar.utils.terminal) end
  },
  {
    description = "show the menubar",
    pattern = {'m'},
    handler = function() menubar.show() end
  },
  {
    description = "enter client mode",
    pattern = {'i'},
    handler = function(mode) mode.stop() end
  },
}

return launcher_commands
