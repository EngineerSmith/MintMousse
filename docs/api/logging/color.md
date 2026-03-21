# Color
The `color` field within the logging module expects either a `string`, or a `table` with two fields `fg` (foreground, e.g. text) and `bg` (background, e.g. a 'highlight').

For Windows PCs, terminal doesn't support until Windows 10. So, expect white output if you're running an older version.

## Constants
The following are string fields that are allowed. Their exact HEX color depends on the rendering console, but here are _approximate_ PuTTY colors:
- <span class="color-swatch" style="background:#000000;"></span> **black**
- <span class="color-swatch" style="background:#bb0000;"></span> **red**
- <span class="color-swatch" style="background:#00bb00;"></span> **green**
- <span class="color-swatch" style="background:#bbbb00;"></span> **yellow**
- <span class="color-swatch" style="background:#0000bb;"></span> **blue**
- <span class="color-swatch" style="background:#bb00bb;"></span> **magenta**
- <span class="color-swatch" style="background:#00bbbb;"></span> **cyan**
- <span class="color-swatch" style="background:#bbbbbb;"></span> **white** (light gray)
- <span class="color-swatch" style="background:#555555;"></span> **bright_black** (dark gray)
- <span class="color-swatch" style="background:#ff5555;"></span> **bright_red**
- <span class="color-swatch" style="background:#55ff55;"></span> **bright_green**
- <span class="color-swatch" style="background:#ffff55;"></span> **bright_yellow**
- <span class="color-swatch" style="background:#5555ff;"></span> **bright_blue**
- <span class="color-swatch" style="background:#ff55ff;"></span> **bright_magenta**
- <span class="color-swatch" style="background:#55ffff;"></span> **bright_cyan**
- <span class="color-swatch has-border" style="background:#ffffff;"></span> **bright_white**