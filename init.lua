local awful   = require("awful")
local textbox = require("wibox.widget.textbox")
local parser  = require("vimawesome.parser")

local grabber
local sequence_box = textbox()
local mode_box     = textbox()
local modes = {
  launcher = require("vimawesome.launcher"),
  tag      = require("vimawesome.tag")
}

local function grabkey(_, _, key)
  local sequence = sequence_box.text .. key
  if parser.parse(sequence, modes[mode_box.text]) then
    sequence_box.text = ''
  else
    sequence_box.text = sequence
  end
end

local function startmode(modename, stop_grabber)
  sequence_box.text = ''
  mode_box.text = modename

  if stop_grabber then
    grabber:stop()
  end
end

local function init(modkey, default_mode)
  default_mode = default_mode or "tag"

  grabber = awful.keygrabber {
    keybindings = {
      {{}, modkey, function() startmode(default_mode) end
    }},
    export_keybindings = true,
    keypressed_callback  = grabkey
  }

  for _, mode in pairs(modes) do
    for _, command in pairs(mode) do
      command.startmode = startmode
    end
  end

  grabber:start()
  startmode(default_mode)
end


init('Alt_R')

return {init = init, sequence = sequence_box, active_mode= mode_box, modes = modes}
