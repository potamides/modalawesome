local awful         = require("awful")
local gears         = require("gears")
local textbox       = require("wibox.widget.textbox")
local parser        = require("modalawesome.parser")
local hotkeys_popup = require("awful.hotkeys_popup.widget")
local unpack        = unpack or table.unpack -- compatibility with Lua 5.1

local grabber
local modes
local sequence_box = textbox()
local mode_box     = textbox()

local function create_hotkeys(keybindings, modes_table)
  for _, keybinding in ipairs(keybindings) do
    awful.key(unpack(keybinding))
  end

  local hotkeys = {}
  for modename, commands in pairs(modes_table) do
    hotkeys[modename]              = hotkeys[modename] or {{}}
    hotkeys[modename][1].keys      = hotkeys[modename].keys or {}
    hotkeys[modename][1].modifiers = hotkeys[modename].modifiers or {}

    local keys = hotkeys[modename][1].keys
    for _, command in ipairs(commands) do
      -- when multiple commands with same keybindings exist, only respect first occurence
      if not keys[table.concat(command.pattern)] then
        keys[table.concat(command.pattern)] = command.description
      end
    end
  end

  hotkeys_popup.add_hotkeys(hotkeys)
end

local function grabkey(_, _, key)
  local sequence = sequence_box.text .. key
  if parser.parse(sequence, modes[mode_box.text]) then
    sequence_box:set_text('')
  else
    sequence_box:set_text(sequence)
  end
end

local function startmode(modename)
  mode_box:set_text(modename)
  sequence_box:set_text('')
end

local function stopmode(modename)
  return function()
    startmode(modename)
    grabber:stop()
  end
end

local function create_default_mode_keybindings(modkey, default_mode)
  local keysyms     = awesome._modifiers[modkey] or {{keysym = modkey}}
  local keybindings = {}

  for _, keysym in pairs(keysyms) do
    table.insert(keybindings,
      {
        {}, keysym.keysym, function() startmode(default_mode) end,
        {description = "start " .. default_mode .. " mode", group = "global"}
      })
  end

  return keybindings
end

local function init(args)
  args              = args or {}
  args.modkey       = args.modkey or "Mod4"
  args.modes        = args.modes or require("modalawesome.modes")
  args.default_mode = args.default_mode or "tag"
  args.stop_name    = args.stop_name or "client"
  args.keybindings  = args.keybindings or {}

  gears.table.merge(args.keybindings, create_default_mode_keybindings(args.modkey, args.default_mode))
  modes   = args.modes
  grabber = awful.keygrabber {
    keybindings         = args.keybindings,
    export_keybindings  = true,
    mask_modkeys        = true,
    autostart           = true,
    keypressed_callback = grabkey
  }

  for _, mode in pairs(modes) do
    for _, command in pairs(mode) do
      command.start   = startmode
      command.stop    = stopmode(args.stop_name)
      command.grabber = grabber
    end
  end

  create_hotkeys(args.keybindings, modes)
  startmode(args.default_mode)
end

return {init = init, sequence = sequence_box, active_mode = mode_box}
