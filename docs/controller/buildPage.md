# `mintmousse.buildPage`
Used to add a preconfigured tab to your console page. Useful to quickly setting up a repeating-tab, or to use someone else's preset.

## Synopsis
```lua
tab = mintmousse.buildPage( requirePath, config, index )
```

## Parameters
`requirePath` _string_
:   The require path to the page code you want to add to the console.

`config` _table_ (**{ }**)
:   The config table given to the page to set up the page. If it contains `tabName` field, it will use that for the name of the tab it will create, or one defined by the page itself if it's `nil`.

`index` _number_ (**nil**)
:   The position in the navbar you want the new tab to appear at. Default behaviour is to add it to the end of the navbar.

## Returns
`tab` [_Tab_](#TODO)
:   The newly create and populated tab.

## Examples
```lua
mintmousse.buildPage("libs.MintMousse.pages.sandbox")

local logTab = mintmousse.buildPage("libs.MintMousse.pages.console", { tabName = "Logs", maxLines = 32 })
logTab:newCard({ size = 5 })
  :addCardFooter({ text = "This is the console page, but I can still add components to it" })
```

## See Also
- [Controller](index.md)