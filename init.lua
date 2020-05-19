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
  grabber:start()
end

local function stopmode(modename)
  return function()
    mode_box:set_text(modename)
    sequence_box:set_text('')
    grabber:stop()
  end
end

local function create_default_mode_keybindings(modkey, default_mode)
  -- need to find keynames for modifiers, e.g. Super_L and Super_R for Mod4
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

local function create_mode_hotkeys(modes_table)
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

local function process_modes(modes_table, stop_name)
  create_mode_hotkeys(modes_table)

  for _, mode in pairs(modes_table) do
    for _, command in pairs(mode) do
      command.start   = startmode
      command.stop    = stopmode(stop_name)
      command.grabber = grabber
    end
  end

  return modes_table
end

local function add_root_keybindings(keybindings)
  -- Delayed call is required to make sure that the root.keys table doesn't get overwritten.
  -- This solution to set root.keys is not optimal, however using the keygrabber option to set
  -- root.keys would mean that the keygrabber gets restarted which is not what we want.
  gears.timer.delayed_call(function()
    local keys = {}
    for _, keybinding in ipairs(keybindings) do
      table.insert(keys, awful.key(unpack(keybinding)))
    end
    root.keys(gears.table.join(root.keys() or {}, unpack(keys)))
  end)
end

local function init(args)
  args              = args or {}
  args.modkey       = args.modkey or "Mod4"
  args.modes        = args.modes or require("modalawesome.modes")
  args.default_mode = args.default_mode or "tag"
  args.stop_name    = args.stop_name or "client"
  args.keybindings  = args.keybindings or {}

  gears.table.merge(args.keybindings, create_default_mode_keybindings(args.modkey, args.default_mode))
  add_root_keybindings(args.keybindings)
  modes = process_modes(args.modes, args.stop_name)

  grabber = awful.keygrabber {
    keybindings         = args.keybindings,
    mask_modkeys        = true,
    autostart           = true,
    keypressed_callback = grabkey
  }

  startmode(args.default_mode)
end

return {init = init, sequence = sequence_box, active_mode = mode_box}
