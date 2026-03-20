# MintMousse
MintMousse is a web console for [LÖVE][love] that lets you monitor and interact with your project through a browser.

It runs a local web server alongside your game, providing a dedicated space to inspect values, tweak game states, and visualise data in real-time. It's built to replace the cluttered `print` statements and make-shift in-game UIs, while acting as a remote interface for headless servers.

### Key Features
- **Visual Debugging** - Move past `print` statements with a fully featured coloured logging system
- **Live Interaction** - Trigger events or toggle flags with buttons and sliders in the browser while the game is running
- **Thread Support** - Update your dashboard and log from any thread without worrying about conflicts
- **Headless Support** - Manage and monitor dedicated servers or windowless projects seamlessly across the network with full IPv6/dual-stack support
- **Extendable Components** - Add your own custom components, allowing you to make the dashboard work for you

## Quickstart
First, add the library to your project:
```bash
cd your/love/project/directory
git clone https://github.com/EngineerSmith/MintMousse libs/MintMousse
```
Next, add the preload script to `conf.lua`:
```lua
require("libs.MintMousse.preload")
```
Then, add the "Hello World" example to `main.lua`:
```lua
local mintmousse = require("libs.MintMousse")
mintmousse.start({ whitelist = "localhost" })

local dashboard = mintmousse.newTab("Dashboard")
dashboard:newCard({ text = "Hello World!" })
```
Finally, run your project and view the console in your browser at [http://localhost:8080](http://localhost:8080) (or the port shown in your console)
