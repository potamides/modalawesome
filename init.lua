local awful   = require("awful")
local gears   = require("gears")
local textbox = require("wibox.widget.textbox")
local parser  = require("vimawesome.parser")
--local naughty = require("naughty")

local grabber
local modes
local sequence_box = textbox()
local mode_box     = textbox()

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
  args.modkeys       = args.modkeys or {"Super_L"}
  args.modes        = args.modes or require("vimawesome.modes")
  args.default_mode = args.default_mode or "tag"
  args.keybindings  = args.keybindings or {}

  local modbindings = {}

  for _, modkey in pairs(args.modkeys) do
    table.insert( modbindings,
      {{}, modkey, function() startmode(args.default_mode) end })
  end

  modes   = args.modes
  grabber = awful.keygrabber {
    keybindings = gears.table.join(
      modbindings,
      args.keybindings
    ),
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

  startmode(args.default_mode)
end

return {init = init, sequence = sequence_box, active_mode = mode_box, modes = modes}
