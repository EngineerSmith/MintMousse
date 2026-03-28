# `mintmousse.setIconRaw`
Skip the validation of [`mintmousse.setIcon`](setIcon.md), and allows you to manually define the icon data and it's Content Type.

If you're feeling lost with this function, I do recommend sticking with [`mintmousse.setIcon`](setIcon.md) to keep it simple.

## Synopsis
```lua
mintmousse.setIconRaw( icon, iconType )
```

## Parameters
`icon` _string_
:   The raw binary data of the image file.

`iconType` _string_
:   The MIMIE Type (Content Type) of the data. This is the "label" that tells the browser how to render the raw data you've given.

### Common Icon Content Types
If you aren't sure what to put here, find your extensions below:

|File Extension|Content Type (`iconType`)|
|---|---|
|`.png`|`"image/png"`|
|`.jpg`/`.jpeg`|`"image/jpeg"`|
|`.ico`|`"image/x-icon"`|
|`.svg`|`"image/svg+xml"`|
|`.gif`|`"image/gif"`|

!!! tip "Why do I need this?"
    On the web, file extensions (like `.png`) don't actually matter; they're just flair to the file name. Without the Content Type label, the browser might treat your icon as plain text, and not display anything instead of the icon.

## Returns
Nothing.

## Examples
```lua
local file = love.filesystem.newFile("assets/console/icon.png", "r")
mintmousse.setIconRaw(file:read(), "image/png")
file:close()

mintmousse.setIconRaw(love.filesystem.read("assets/console.icon.svg"), "image/svg+xml")
```

## See Also
- [Controller](index.md)
- [`mintmousse.setIcon`](setIcon.md)