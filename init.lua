local awful = require("awful")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local beautiful = require("beautiful")
local textbox = require("wibox.widget.textbox")
local execute = require("modalawesome.matcher").execute
local hotkeys_popup = require("awful.hotkeys_popup.widget")
local unpack = unpack or table.unpack -- luacheck: globals unpack (compatibility with Lua 5.1)

local grabber, modes = {}
local modalawesome = {sequence = textbox(), active_mode = textbox()}

local function grabkey(_, modifiers, key)
  local sequence = modalawesome.sequence.text .. key
  if execute(sequence, modifiers, modes[modalawesome.active_mode.text]) then
    modalawesome.sequence:set_text('')
  else
    modalawesome.sequence:set_text(sequence)
  end
end

local function startmode(modename)
  modalawesome.active_mode:set_text(modename)
  grabber:start()
end

local function stopmode(modename)
  modalawesome.active_mode:set_text(modename)
  grabber:stop()
end

local function create_default_mode_keybindings(modkey, default_mode)
  -- need to find keynames for modifiers, e.g. Super_L and Super_R for Mod4
  local keysyms = awesome._modifiers[modkey] or {{keysym = modkey}}
  local keybindings = {}

  for _, keysym in pairs(keysyms) do
    table.insert(keybindings, {{}, keysym.keysym, function()
      startmode(default_mode)
      modalawesome.sequence:set_text('')
    end})
  end

  return keybindings
end

local function markup(item)
  if type(item) == "string" then
    return item
  end

  local color = beautiful.hotkeys_modifiers_fg or beautiful.bg_minimize or "#555555"
  local key = item[#item]
  local mod_string = table.concat(item, "-"):sub(1, -(#key + 1))
  return string.format('<span foreground=%q>%s</span>%s', color, mod_string, key)
end

local function create_hotkeys(modes_table, stop_name, default_mode, modkey, format)
  local hotkeys = {[stop_name] = {{modifiers = {}, keys = {}}}}
  for modename, commands in pairs(modes_table) do
    hotkeys[modename] = {{modifiers = {}, keys = {}}}

    local keys = hotkeys[modename][1].keys
    for _, command in ipairs(commands) do
      local hotkeys_string = table.concat(gtable.map(markup, command.pattern))
      -- when multiple commands with same keybindings exist, only respect first occurence
      if not keys[hotkeys_string] then
        keys[hotkeys_string] = command.description
      end
    end
  end

  for modename, _ in pairs(hotkeys) do
    if modename ~= default_mode and not (modes_table[modename] and modes_table[modename].merge) then
      hotkeys[modename][1].keys[modkey] = string.format(format, default_mode)
    end
  end

  hotkeys_popup.add_hotkeys(hotkeys)
end

local function process_modes(modes_table, stop_name)
  local normalmodes = gtable.find_keys(modes_table, function(_, mode) return not mode.merge end) or {}
  for _, mode in pairs(modes_table) do
    if mode.merge then
      for _, modename in pairs(type(mode.merge) == "table" and mode.merge or normalmodes) do
        gtable.merge(modes_table[modename], mode)
      end
    end
  end

  for _, mode in pairs(modes_table) do
    for _, command in ipairs(gtable.reverse(mode)) do
      command.start   = startmode
      command.stop    = function() stopmode(stop_name) end
      command.grabber = grabber

      -- Commands which use explicit modifiers should come before normal commands,
      -- since normal commands don't do any modifier matching.
      if #gtable.keys_filter(command.pattern, "table") > 0 then
        table.insert(mode, 1, table.remove(mode, gtable.find_first_key(mode,
          function(_, cmd) return cmd == command end, true)))
      end
    end
  end

  return modes_table
end

local function add_root_keybindings(keybindings)
  -- Delayed call is required to make sure that the root.keys table doesn't get overwritten.
  -- This solution to set root.keys is not optimal, however using the keygrabber option to set
  -- root.keys would mean that the keygrabber gets restarted which is not what we want.
  gtimer.delayed_call(function()
    local keys = {}
    for _, keybinding in ipairs(keybindings) do
      table.insert(keys, awful.key(unpack(keybinding)))
    end
    root.keys(gtable.join(root.keys() or {}, unpack(keys)))
  end)
end

-- Awesome stops keygrabbers when runtime errors occur, this function makes sure to restart
-- our keygrabber to still be able to control awesome under error conditions.
local function create_error_handler()
  local in_error = false
  awesome.connect_signal("debug::error", function(_, ignore)
    -- Make sure we don't go into an endless error loop
    if not in_error and not ignore and grabber == awful.keygrabber.current_instance then
      in_error = true
      grabber:stop()
      gtimer.delayed_call(function()
        grabber:start()
        in_error = false
      end)
    end
  end)
end

function modalawesome.init(args)
  args              = args or {}
  args.modkey       = args.modkey or "Mod4"
  args.format       = args.format or "enter %s mode"
  args.modes        = args.modes or require("modalawesome.modes")
  args.default_mode = args.default_mode or "tag"
  args.stop_name    = args.stop_name or "client"
  args.keybindings  = args.keybindings or {}

  gtable.merge(args.keybindings, create_default_mode_keybindings(args.modkey, args.default_mode))
  add_root_keybindings(args.keybindings)

  grabber = awful.keygrabber {
    keybindings         = args.keybindings,
    mask_modkeys        = true,
    keypressed_callback = grabkey
  }

  create_error_handler()
  create_hotkeys(args.modes, args.stop_name, args.default_mode, args.modkey, args.format)
  modes = process_modes(args.modes, args.stop_name)
  startmode(args.default_mode)
end

return modalawesome
