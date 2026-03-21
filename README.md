# MintMousse
MintMousse is a web console for [LÖVE][love] that lets you monitor and interact with your project through a browser.

It runs a local web server alongside your game, providing a dedicated space to inspect values, tweak game states, and visualise data in real-time. It's built to replace the cluttered `print` statements and make-shift in-game UIs, while acting as a remote interface for headless servers.

### Key Features
- **Visual Debugging** - Move past `print` statements with a fully featured colored logging system
- **Live Interaction** - Trigger events or toggle flags with buttons and sliders in the browser while the game is running
- **Thread Support** - Update your dashboard and log from any thread without worrying about conflicts
- **Headless Support** - Manage and monitor dedicated servers or windowless projects seamlessly across the network with full IPv6/dual-stack support
- **Extendable Components** - Add your own custom components, allowing you to make the dashboard work for you

## Docs
Check out our [wiki][doclink] to get going!

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

---
### Dependencies
MintMousse utilises the following libraries:
- [Bootstrap 5.3][git.bootstrap]
- [DOMPurify][git.dompurify]
- [LuaSocket][luasocket]
- [Lustache][git.lustache]
- [Json.lua][git.json]

### Kudos
Special thanks to:
- **[Immow](https://github.com/Immow)** Suggesting the lua API structure for defining the components.
- **[Josh](https://github.com/josh-perry)** For a fix to log buffering that reduced logging overhead to negligible levels.

[doclink]: https://mintmousse.engineersmith.net
[git.lustache]: https://github.com/Olivine-Labs/lustache
[git.bootstrap]: https://github.com/twbs/bootstrap
[git.dompurify]: https://github.com/cure53/DOMPurify
[git.json]: https://github.com/rxi/json.lua
[love]: https://love2d.org
[luasocket]: https://github.com/lunarmodules/luasocket
