# MintMousse
MintMousse is a live web console for your [LÖVE][love] project, giving you real-time control and insight into your project's internals. Instead of relying on countless `print()` statements or clunky in-game debug menus, MintMousse lets you build a real-time dashboard viewable in any browser. From there, you can monitor variables, tweak settings, and interact with code. This makes development a breeze for both headless and traditional [LÖVE][love] projects.

With this powerful control panel, you can trigger events, change player stats, or visualise performance metrics with graphs. This provides instance feedback, making it an ideal tool for debugging or managing a game server. This library is thread-safe, allowing you to update the console directly from any thread. Ultimately, it streamlines your workflow and gives you a much clearer picture of what's happening under the hood.

# Quickstart
First, add the library to your project:
```
cd your/love/project/directory
git clone https://github.com/EngineerSmith/MintMousse --recurse-submodules libs/.
```
Then, add the "Hello World" example to your `main.lua` file:
```lua
require("libs.MintMousse")
love.mintmousse.start({
  whitelist = { "127.0.0.1", "192.168.0.0/16", "10.0.0.0/8", "172.16.0.0/12" },
})

local dashboard = love.mintmousse.newTab("Dashboard")
dashboard:newCard({ size = 5, title = "Hello World!" })
```
Finally, run your project and view the console in your browser at [http://localhost](http://localhost)

# Docs
Check out our [wiki][doclink]!

# Credits
## Dependencies
MintMousse would not be possible without the following dependencies:
- [Lustache][git.lustache]
- [Bootstrap 5.3][git.bootstrap]
- [Json.lua][git.json]
- [LuaSocket][luasocket] (Included in [LÖVE][love])

## Kudos
Special thanks to:
- **[Immow](https://github.com/Immow)** Suggesting the lua API for defining the components.
- **[Josh](https://github.com/josh-perry)** For proposing a critical fix to log buffering, which drastically reduced performance overhead (from 1ms per print to negligible time per log call!).

[doclink]: https://github.com/EngineerSmith/MintMousse/wiki
[git.lustache]: https://github.com/Olivine-Labs/lustache
[git.bootstrap]: https://github.com/twbs/bootstrap
[git.json]: https://github.com/rxi/json.lua
[love]: https://love2d.org
[luasocket]: https://github.com/lunarmodules/luasocket
