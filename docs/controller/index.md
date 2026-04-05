# Controller
Using these functions you can start, and stop the library.

## Functions
|Function|Description|
|---|---|
|[`mintmousse.start`](start.md)|Start the web server|
|[`mintmousse.stop`](stop.md)|Stop the MM thread|
|[`mintmousse.wait`](wait.md)|Wait for the MM thread to stop|
|[`mintmousse.setIcon`](setIcon.md)|Set the web console's icon|
|[`mintmousse.setIconRaw`](setIconRaw.md)|Set the web console's icon directly|
|[`mintmousse.setIconRFG`](setIconRFG.md)|Set the web console's icon to an [RFG](https://realfavicongenerator.net/) zip file|
|[`mintmousse.setTitle`](setTitle.md)|Set the web console's title|
|[`mintmousse.notify`](notify.md)|Send a toast notification to connected clients|
|[`mintmousse.addToWhitelist`](addToWhitelist.md)|Add a rule to the whitelist|
|[`mintmousse.removeFromWhitelist`](removeFromWhitelist)|Remove a rule from the whitelist|
|[`mintmousse.clearWhitelist`](clearWhitelist.md)|Clear all rules from the whitelist|
|[`mintmousse.batchStart`](batchStart.md)|Start batching changes|
|[`mintmousse.batchEnd`](batchEnd.md)|End batching changes, and send to thread|
|[`mintmousse.buildPage`](buildPage.md)|Add a preconfigured tab|
|[`mintmousse.getThreadID`](getThreadID.md)|Get the current thread's ID|

## Variables
|Variable|Description|
|---|---|
|`love.isThread`|Boolean if code is running in a thread|