# Logging Colors
The `color` field within the logging module expects either a `string`, or a `table` with two fields `fg` (foreground, e.g. text) and `bg` (background, e.g. a 'highlight').

For Windows PCs, terminal doesn't support until Windows 10. So, expect white output if you're running an older version.

## Constants
The following are string fields that are allowed. Their exact HEX color depends on the rendering console, but here are _approximate_ PuTTY colors:
<ul>
  <li><span class="color-swatch" style="background:#000000;"></span><b>black</b></li>
  <li><span class="color-swatch" style="background:#bb0000;"></span><b>red</b></li>
  <li><span class="color-swatch" style="background:#00bb00;"></span><b>green</b></li>
  <li><span class="color-swatch" style="background:#bbbb00;"></span><b>yellow</b></li>
  <li><span class="color-swatch" style="background:#0000bb;"></span><b>blue</b></li>
  <li><span class="color-swatch" style="background:#bb00bb;"></span><b>magenta</b></li>
  <li><span class="color-swatch" style="background:#00bbbb;"></span><b>cyan</b></li>
  <li><span class="color-swatch" style="background:#bbbbbb;"></span><b>white</b> (light gray)</li>
  <li><span class="color-swatch" style="background:#555555;"></span><b>bright_black</b> (dark gray)</li>
  <li><span class="color-swatch" style="background:#ff5555;"></span><b>bright_red<b/></li>
  <li><span class="color-swatch" style="background:#55ff55;"></span><b>bright_green<b/></li>
  <li><span class="color-swatch" style="background:#ffff55;"></span><b>bright_yellow<b/></li>
  <li><span class="color-swatch" style="background:#5555ff;"></span><b>bright_blue<b/></li>
  <li><span class="color-swatch" style="background:#ff55ff;"></span><b>bright_magenta<b/></li>
  <li><span class="color-swatch" style="background:#55ffff;"></span><b>bright_cyan<b/></li>
  <li><span class="color-swatch has-border" style="background:#ffffff;"></span> **bright_white**</li>
</ul>