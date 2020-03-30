local hotkeys_popup = require("awful.hotkeys_popup")

local launcher_commands = {
  {
    description = "show help",
    pattern = {{"h"}},
    handler =
      function()
        hotkeys_popup.show_help()
      end
  }
}

return launcher_commands
