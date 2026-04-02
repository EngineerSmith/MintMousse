# `mintmousse.setIcon`
Set the icon of the console (the little image shown in the window/tab) to make your project recognisable.

Don't have a ready-made image/logo? No problem - pass a simple table and the built in SVG generator will create a clean, emoji-based icon for you on the fly.

!!! note "Browser behaviour"

    A known issue with the SVG Schema option is that SVG's on Chrome render a lot blurrier than that on Firefox.
    
    I've noticed in [Chromium](https://www.chromium.org/Home/) it renders fine, not sure why Chrome wants to play up.

## Synopsis
```lua
mintmousse.setIcon( icon )
```

## Parameters
`icon` _string_ or _table_ or [_Data_](https://love2d.org/wiki/Data)
:   The icon source. The function handles four common use-cases in:

    1. SVG Schema: _table_
      * A table describing a custom SVG icon. See definition below. This is designed to be the quick and easy, so it's options are limited.

    2. File Path: _string_
        * Path to an image file. Supported extensions: `.png`, `.jpeg`, `.jpg`, `.svg`, `.ico`

    3. Raw Image Data: _string_ or [_Data_](https://love2d.org/wiki/Data)
        * Binary image data for a PNG or JPEG file. Automatically detected by their standard magic-number headers. If you pass a [_Data_](https://love2d.org/wiki/Data), it is converted into a _string_ first.

### SVG Schema Table
`shape` _string_ (**nil**)
:   Background shape: **"circle"**, **"rectangle"**, **"square"**, or omitted (uses a squircle - rounded square). Note **"rectangle"** and **"square"** are treated the same.

`insideColor` or `color` _string_ (**"#95D7AB"**)
:   Fill Colour of the icon. Accepts any standard web colour name (**"red"**, **"blue"**, etc.) or a hex code (**"#RRGGBB"** or **"#RGB"**).

`outsideColor` _string_ (**"#4A7C59"**)
:   Stroke (outline) colour. Same format as `insideColor`. Use **"none"** to disable the stroke entirely.

`strokeWidth` _number_ (**3**)
:   Thickness of the stroke. Ignored if `outsideColor` is **"none"**.

`emoji` _string_ (**"🍮"**)
:   Single emoji (or any single character) displayed in the centre. Note, multi-character emojis are supported, but no guarantee it will render correctly by browsers.

## Returns
Nothing.

## Examples
```lua
mintmousse.setIcon("assets/console/icon.svg")
mintmousse.setIcon("assets/console/icon.ico")

mintmousse.setIcon(love.filesystem.read("assets/console/icon.png"))
mintmousse.setIcon(love.filesystem.read("assets/console/icon.jpeg"))
```

### SVG Schema
```lua
mintmousse.setIcon({ }) -- MintMousse's default, same as:
mintmousse.setIcon({
  shape        = nil, -- squircle
  insideColor  = "#95D7AB",
  outsideColor = "#4A7C59",
  strokeWidth  = 3,
  emoji        = "🍮",
})

mintmousse.setIcon({
  shape        = "circle",
  insideColor  = "#abf",
  outsideColor = "#f00",
  strokeWidth  = 2,
  emoji        = "🚀",
})

mintmousse.setIcon({
  color = "#cca486",
  emoji = "🍖",
  outsideColor = "none",
})
```

## See Also
- [Controller](index.md)
- [`mintmousse.setIconRaw`](setIconRaw.md)