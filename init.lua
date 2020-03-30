local awful   = require("awful")
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
    sequence_box.text = ''
  else
    sequence_box.text = sequence
  end
end

local function startmode(modename, stop_grabber)
  sequence_box.text = ''
  mode_box.text     = modename

  if stop_grabber then
    grabber:stop()
  end
end

local function init(args)
  args              = args or {}
  args.modkey       = args.modkey or "Super_L"
  args.modes        = args.modes or require("vimawesome.modes")
  args.default_mode = args.default_mode or "tag"

  modes = args.modes
  grabber = awful.keygrabber {
    keybindings = {
      {{}, args.modkey, function() startmode(args.default_mode) end },
    },
    export_keybindings = true,
    mask_modkeys = true,
    keypressed_callback  = grabkey
  }

  for _, mode in pairs(modes) do
    for _, command in pairs(mode) do
      command.startmode = startmode
    end
  end

  grabber:start()
  startmode(args.default_mode)
end

return {init = init, sequence = sequence_box, active_mode= mode_box, modes = modes}
