local awful         = require("awful")
local textbox       = require("wibox.widget.textbox")
local parser        = require("vimawesome.parser")
local hotkeys_popup = require("awful.hotkeys_popup.widget")
--local naughty = require("naughty")

local grabber
local modes
local sequence_box = textbox()
local mode_box     = textbox()

local function create_hotkeys(keybindings, modes_table)
  -- TODO: on awesome master branch, keys can be created directly in keybindings table, update code on next release
  for _, keybinding in ipairs(keybindings) do
    awful.key(table.unpack(keybinding))
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
  --naughty.notify({ preset = naughty.config.presets.critical,
  --         text = key })
  local sequence = sequence_box.text .. key
  if parser.parse(sequence, modes[mode_box.text]) then
    sequence_box:set_text('')
  else
    sequence_box:set_text(sequence)
  end
end

local function startmode(modename, stop_grabber)
  sequence_box:set_text('')
  mode_box:set_text(modename)

  if stop_grabber then
    grabber:stop()
  end
end

local function init(args)
  args              = args or {}
  args.modkeys      = args.modkeys or {"Super_L"}
  args.modes        = args.modes or require("vimawesome.modes")
  args.default_mode = args.default_mode or "tag"
  args.keybindings  = args.keybindings or {}

  for _, modkey in pairs(args.modkeys) do
    table.insert(args.keybindings,
      {
        {}, modkey, function() startmode(args.default_mode) end,
        {description = "start " .. args.default_mode .. " mode", group = "global"}
      })
  end

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
      command.startmode = startmode
      command.grabber   = grabber
    end
  end

  create_hotkeys(args.keybindings, modes)
  startmode(args.default_mode)
end

return {init = init, sequence = sequence_box, active_mode = mode_box, modes = modes}
