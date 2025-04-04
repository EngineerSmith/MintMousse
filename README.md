# MintMousse
MintMousse is a simple yet powerful web console for your [Love][love] project, offering live control, monitoring, and interaction. It allows you to create customisable web interfaces with real-time component updates, enhancing the development experience for both headless and traditional Love projects.

## Key Principles
**Simplicity and Ease of Use**:
Designed to be intuitive, making it quick and easy to create web interfaces for your applications. Focuses on a straightforward API, allowing you to easily define and integrate web-based control and monitoring for your Love games and applications.

**Live and Reactive Updates**:
Leverages WebSockets for instantaneous two-way communication, ensuring a truly live interaction between your Love application and the web console.

**Multi-threading Support**:
Allows you to build web console interfaces that react to events and data from any thread in your Love application, providing a comprehensive live view for control and monitoring.

**Extensibility and Community Contributions**:
Designed to be easily extended with custom components, empowering the community to contribute new features and tailor the library to diverse needs using a component-based design.

# Quickstart
```
cd loveProject
git clone https://github.com/EngineerSmith/MintMousse --recurse-submodules libs/.
```
### Hello world
```lua
require("libs.MintMousse")
love.mintmousse.start({
  whitelist = { "127.0.0.1", "192.168.0.0/16", "10.0.0.0/8", "172.16.0.0/12" },
})

local dashboard = love.mintmousse.newTab("Dashboard", "dashboard")
dashboard:newCard({ size = 5, title = "Hello World!" })
```

# Docs
Check out our [wiki][doclink]

# Credits
## Dependencies
Massive thank you to our dependencies! Without them the MintMousse wouldn't exist as it is.
- [Lustache][git.lustache]
- [Bootstrap][git.bootstrap]
- [Json.lua][git.json]

## Kudos
Special thanks to:
- **[Immow](https://github.com/Immow)** Suggesting the lua api for defining the components.

[doclink]: https://github.com/EngineerSmith/MintMousse/wiki
[git.lustache]: https://github.com/Olivine-Labs/lustache
[git.bootstrap]: https://github.com/twbs
[git.json]: https://github.com/rxi/json.lua
[love]: https://love2d.org