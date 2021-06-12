# modalawesome

Modalawesome makes it possible to create vi-like keybindings for the
[awesome window manager](https://awesomewm.org/). It introduces a modal
alternative to the standard
[awful.key](https://awesomewm.org/doc/api/libraries/awful.key.html) keybindings
and supports complex commands with motions and counts by making use of Lua
[patterns](https://www.lua.org/manual/5.3/manual.html#6.4.1). Check out the
[demo](https://v.redd.it/e4pzh8l53df51/DASH_1080.mp4) to get an overall
impression of what this is capable of.

## Installation

Clone the repository and put it in the Lua search path for awesome 
(e.g. `~/.config/awesome`).

```sh
git clone https://github.com/potamides/modalawesome
```

After that include the module at the top of the `rc.lua` file.

```lua
local modalawesome = require("modalawesome")
```

This project requires **awesome 4.3+** and **Lua 5.1+**. Older versions *may*
also work but are untested.

## Usage

The goal of modalawesome is to enable complete control over awesome with modal
commands. To make that possible modalawesome covers the same scope
as the keybindings set through the
[client:keys](https://awesomewm.org/doc/api/classes/client.html#client:keys)
(normally applied with
[awful.rules](https://awesomewm.org/doc/api/libraries/awful.rules.html)) and
[root.keys](https://awesomewm.org/doc/api/libraries/root.html#keys) tables
usually found in an `rc.lua` file. Thus after setting up modalawesome the
standard keybindings are redundant and can be safely removed, if desired.

### Quickstart

Add `modalawesome.init()` to your `rc.lua` and restart awesome. Press `r` to
enter **launcher** mode and `h` to launch a help window with all keybindings.
However it is advisable to read this file beforehand.

### Commands

Commands are realized as tables with three entries.

* **description**: a description to show in the [popup widget with hotkeys
  help](https://awesomewm.org/doc/api/libraries/awful.hotkeys_popup.widget.html#show_help)
* **pattern**: a table with Lua patterns, which the entered keys are matched
  against
* **handler**: a function which is called when a entered sequence fully matches
  the patterns

This concept can be best explained with an example. A command to focus another
tag could look like this:

```lua
local command = {
  description = "focus tag by direction",
  pattern = {'%d*', '[fb]'},
  handler = function(mode, index, direction)
    index = index == '' and 1 or tonumber(index)

    if direction == 'f' then
      awful.tag.viewidx(index)
    else
      awful.tag.viewidx(-index)
    end
  end
}
```

Each item in the **pattern** table has its own argument in the **handler**
function. Here `%d*` matches the relative index of the new tag and `[fb]`
determines if a tag before or after the current tag should be focused. This
means that e.g. the sequence `1b` would focus the previous tag and `3000f`
would move the focus three thousand tags forward. The first argument of the
**handler** function (`mode`), which was not used in this example, can be used
to switch modes.

### Modes

Like vi, modalawesome supports multiple modes. A mode is realized as a table of
commands. Each mode is associated with a name. Modes can be changed with the
`mode` argument of the **handler** function. It provides two functions for
that.

* **mode.start(name)**: start the mode named **name** and activate its commands
* **mode.stop()**: stop the current mode and interact with the focused client,
  no commands are active

A basic configuration with multiple modes could look like this:

```lua
local modes = {
  mode1 = {
    {
      description = "start mode2",
      pattern = {'v'},
      handler = function(mode)
        mode.start("mode2")
      end
    }
  },
  mode2 = {
    {
      description = "start mode1",
      pattern = {'v'},
      handler = function(mode)
        mode.start("mode1")
      end
    },
    {
      description = "start insert mode",
      pattern = {'i'},
      handler = function(mode)
        mode.stop()
      end
    }
  }
}
```

### Default Configuration

Modalawesome provides default modes and commands that are loosely based on the
default keybindings of awesome. The modalawesome default controls serve
as a good starting point for a customized configuration.

```lua
local modes = require("modalawesome.modes")
```

The default configuration provides three modes to control awesome. The **tag**
mode is used to change tags and to interact with different clients on a tag.
From it the **launcher** mode and the **layout** mode can be started. The
purpose of the **launcher** mode is to launch various applications, processes
and utility functions and the **layout** mode can be used to change various
layout options of the current tag.

### Indicators

Modalawesome provides two textboxes with information about the current mode
(`modalawesome.active_mode`) and the current entered key sequence
(`modalawesome.sequence`). These textboxes could be placed in the
[wibar](https://awesomewm.org/doc/api/classes/awful.wibar.html#).

```Lua
s.mywibox:setup {
  layout = wibox.layout.align.horizontal,
  { -- Left widgets
    layout = wibox.layout.fixed.horizontal,
    -- ...
    modalawesome.active_mode
  },
  -- ...
  { -- Right widgets
    layout = wibox.layout.fixed.horizontal,
    modalawesome.sequence,
    -- ...
  },
}
```

### Initialization

For configuration purposes modalawesome provides the `init` function. This
function expects a table with settings. The following settings are available:

* **modkey**: the key which can be used to go back to the default mode
  (comparable to `Esc` in vi)
* **default_mode**: name of the base mode of modalawesome (comparable to
  `Normal` mode in vi)
* **modes**: a table with modes, the index of a mode should be its name
* **stop_name**: the text to show in the `modalaweosme.active_mode` textbox,
  when no mode is active
* **keybindings**: a table of `awful.key` style keybindings which are active in
  all modes

The default settings are defined as follows:

```lua
modalawesome.init{
  modkey       = "Mod4",
  default_mode = "tag",
  modes        = require("modalawesome.modes"),
  stop_name    = "client",
  keybindings  = {}
}
```

The **keybindings** table makes it possible to easily integrate media keys into
modalawesome.

```Lua
local keybindings = {
  {{}, "XF86MonBrightnessDown", function () awful.spawn("xbacklight -dec 10") end},
  {{}, "XF86MonBrightnessUp", function () awful.spawn("xbacklight -inc 10") end},
}
```
## Advanced

### Access Internal Keygrabber

The `mode` argument of the **handler** function also exposes the internal
[keygrabber](https://awesomewm.org/doc/api/classes/awful.keygrabber.html) used
by modelawesome. This can be used to temporarily stop keygrabbing if another
keygrabber needs to be run.

```lua
handler = function(mode, ...)
  mode.grabber:stop()
  -- ...
  mode.grabber:start()
end
```

### Explicit Modifier Keys

In many cases it's not necessary to explicitly specify the modifiers to use in
a pattern, instead it's sufficient to specify the corresponding symbol
directly.

```lua
local pattern = {"S"} -- matches "Shift-s"
```

However this doesn't work with special keys like `Tab` or modifiers like
`Control`. For these cases you can use a slightly extended pattern syntax. Each
item in the pattern table for which explicit modifier matching is desired
should be replaced with a table with the modifiers as first elements and the
corresponding item as the last. Supported modifiers are `Shift`, `Control`,
`Mod1` and `Mod4`.

```lua
local pattern = {{"Control", "w"}, "[hjkl]"} -- matches "Control-w [hjkl]"
```

```lua
local pattern = {{"Control", "Shift", "Tab"}} -- matches "Control-Shift-Tab"
```

### Common Keybindings

In some scenarios it might be desirable to add a lot of common keybindings to
multiple modes (e.g. to make some commands accessible everywhere through a
leader key). It might be tedious to add these bindings to all modes manually
and it would also potentially clutter the hotkeys widget. For this use case
modalawesome honors the `merge` key in mode tables:

```lua
local modes = {
  tag      = { --[[ ... ]] },
  launcher = { --[[ ... ]] },
  layout   = { --[[ ... ]] },
  common   = { merge=true, --[[ ... ]] }
}
```

In this example all keybindings in **common** would be merged with the **tag**,
**launcher** and **layout** modes, however the hotkeys widget would still show
these bindings grouped under the **common** mode. For more fine-grained control
over merging the value of the `merge` key could also be a table with mode
names.
