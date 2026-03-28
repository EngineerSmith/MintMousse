---
title: Logging Colors
---
# Color
The `color` field within the logging module expects either a `string`, or a `table` with two fields `fg` (foreground, e.g. text) and `bg` (background, e.g. a 'highlight'). If just a `string` is passed, it is used like the `fg` argument, and `bg` will default to the console's background.

ANSI color support in Windows Console only became reliable with Windows 10 build 10586 (late 2015) and later; older versions (or very old Windows 7/8) usually show plain white/gray output.

## Constants
The following are string fields that are allowed. Their exact HEX color depends on the rendering console, but here are _approximate_ PuTTY colors:
<ul class="color-list">
  <li><span class="color-swatch" style="background:#000000;"></span><b>black</b></li>
  <li><span class="color-swatch" style="background:#bb0000;"></span><b>red</b></li>
  <li><span class="color-swatch" style="background:#00bb00;"></span><b>green</b></li>
  <li><span class="color-swatch" style="background:#bbbb00;"></span><b>yellow</b></li>
  <li><span class="color-swatch" style="background:#0000bb;"></span><b>blue</b></li>
  <li><span class="color-swatch" style="background:#bb00bb;"></span><b>magenta</b></li>
  <li><span class="color-swatch" style="background:#00bbbb;"></span><b>cyan</b></li>
  <li><span class="color-swatch" style="background:#bbbbbb;"></span><b>white</b></li>

  <li><span class="color-swatch" style="background:#555555;"></span><b>bright_black</b></li>
  <li><span class="color-swatch" style="background:#ff5555;"></span><b>bright_red</b></li>
  <li><span class="color-swatch" style="background:#55ff55;"></span><b>bright_green</b></li>
  <li><span class="color-swatch" style="background:#ffff55;"></span><b>bright_yellow</b></li>
  <li><span class="color-swatch" style="background:#5555ff;"></span><b>bright_blue</b></li>
  <li><span class="color-swatch" style="background:#ff55ff;"></span><b>bright_magenta</b></li>
  <li><span class="color-swatch" style="background:#55ffff;"></span><b>bright_cyan</b></li>
  <li><span class="color-swatch" style="background:#ffffff;"></span><b>bright_white</b></li>
<br/>
  <li><span class="color-swatch" style="background:#00000000;"></span><b>reset</b></li>
</ul>

!!! note "`reset`"

    `reset` is a special 'color', which reverts to what the default is of your console, for example usually `white` text for foreground, or `black` background.

!!! tip "Quick tip: `white` vs `bright_white`"

    In many terminals, `white` renders as silvery gray (`~#bbbbbb`), while `bright_white` is pure white (`#ffffff`).

    For regular log text, you should use `white` as it's more comfortable on the eyes - especially on OLED/AMOLED screens or when reading for long periods. Reserve `bright_white` for emphasis, errors, or when you need maximum contrast (e.g. white text on a red background).

## Examples
```lua
local logger = mintmousse.newLogger("foo", "cyan")

local loggerBar = logger:extend("bar", "green")

local loggerFatal = mintmousse.newLogger("FATAL", { fg = "bright_white", bg = "red" })

local loggerInvert = loggerFatal:extend("Inverted", {
  fg = "black",
  bg = "bright_white",
})
```
# See Also
- [Logging](index.md)
- [`mintmousse.newLogger`](newLogger.md)
- [`(Logger):extend`](logger/extend.md)