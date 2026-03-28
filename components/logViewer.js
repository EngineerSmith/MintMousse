const colorMap = { // Putty color scheme
  "black"  : "#212121",
  "red"    : "#bb0000",
  "green"  : "#00bb00",
  "yellow" : "#bbbb00",
  "blue"   : "#0000bb",
  "magenta": "#bb00bb",
  "cyan"   : "#00bbbb",
  "white"  : "#bbbbbb",

  "bright_black"  : "#555555",
  "bright_red"    : "#ff5555",
  "bright_green"  : "#55ff55",
  "bright_yellow" : "#ffff55",
  "bright_blue"   : "#5555ff",
  "bright_magenta": "#ff55ff",
  "bright_cyan"   : "#55ffff",
  "bright_white"  : "#ffffff",
};

const getColor = function(def) {
  const fgName = typeof def === "string" ? def : (def?.fg || "white");
  const bgName = (def && typeof def === "object") ? (def.bg || null) : null;

  return {
    fg: colorMap[fgName] || colorMap["white"],
    bg: colorMap[bgName] || null,
  };
};

const logLevel = { };
{
  const rawLevels = {
    info   : { name: "INFO ", color: "green"  },
    debug  : { name: "DEBUG", color: "cyan"   },
    warning: { name: "WARN ", color: "yellow" },
    error  : { name: "ERROR", color: "red"    },
    fatal  : { name: "FATAL", color: { fg: "bright_white", bg: "red" } },
  };

  for (const [key, value] of Object.entries(rawLevels)) {
    logLevel[key] = {
      name: value.name,
      color: getColor(value.color),
    };
  }
}

const newSpan = (text, fg, bg) => {
  const span = document.createElement("span");
  span.textContent = text;
  if (fg) span.style.color = fg;
  if (bg) span.style.backgroundColor = bg;
  return span;
}

componentRegistry.register({
  typeName: "LogViewer",
  create: function(payload) {
    const instance = helper.prepareInstance(payload.id, this.typeName, payload.parentID);

    let initialLogs = [];
    if (Array.isArray(payload.pushes.log)) {
      initialLogs = payload.pushes.log;
    }

    const root = document.createElement("div");
    root.className = "log-viewer bg-dark text-light p-2 border border-secondary rounded font-monospace overflow-auto";

    instance.element = root;

    instance.state.atBottom = true;
    instance.state.wasVisible = false;

    const updateScrollState = () => {
      const isAtBottomNow = (root.scrollHeight - root.scrollTop - root.clientHeight) <= 7;
      instance.state.atBottom = isAtBottomNow;
    }
    root.addEventListener("scroll", updateScrollState, { passive: true });

    instance.state.resizeObserver = new ResizeObserver(() => {
      const isVisibleNow = root.offsetHeight > 0 && root.offsetWidth > 0;
      if (isVisibleNow && !instance.state.wasVisible && instance.state.atBottom)
        root.scrollTop = root.scrollHeight;
      instance.state.wasVisible = isVisibleNow;
    })
    instance.state.resizeObserver.observe(root);

    if (initialLogs.length > 0)
      initialLogs.forEach(log => this._addLog(instance, log));

    this.update_maxLines(payload);

    return instance;
  },

  _renderLog: function(log) {
    const line = document.createElement("div");
    line.className = "log-line";

    // [LEVEL]
    const levelDef = logLevel[log.level] || logLevel["info"];
    line.append(
      newSpan("[", colorMap["bright_black"]),
      newSpan(levelDef.name, levelDef.color.fg, levelDef.color.bg),
      newSpan("] ", colorMap["bright_black"]),
    );

    // [TIME]
    const time = helper.getText(log.time);
    if (time) {
      line.append(
        newSpan("[", colorMap["bright_black"]),
        newSpan(time, colorMap["bright_blue"]),
        newSpan("] ", colorMap["bright_black"]),
      );
    }

    // [LOGGER]
    if (Array.isArray(log.loggerAncestry) && log.loggerAncestry.length) {
      line.append(newSpan("[", colorMap["bright_black"]));

      log.loggerAncestry.forEach((part, i) => {
        if (i > 0) {
          line.append(newSpan(":", colorMap["bright_black"]));
        }
        const partColor = getColor(part.colorDef);
        const name = helper.getText(part.name, "");
        line.append(newSpan(name, partColor.fg, partColor.bg));
      });

      line.append(newSpan("] ", colorMap["bright_black"]));
    }

    // [DEBUG INFO]
    if (log.debugInfo) {
      const debugInfo = helper.getText(log.debugInfo);
      if (debugInfo)
        line.append(
          newSpan("[", colorMap["bright_black"]),
          newSpan(debugInfo, colorMap["cyan"]),
          newSpan("] ", colorMap["bright_black"]),
        );
    }

    // MESSAGE
    const message = helper.getText(log.message, "");
    if (message)
      line.append(newSpan(message, colorMap["white"]));

    return line;
  },

  _addLog: function(instance, logData) {
    if (!logData) return;

    const root = instance.element;
    const lineEl = this._renderLog(logData);

    const isVisibleNow = root.offsetHeight > 0 && root.offsetWidth > 0;
    let shouldAutoScroll = false;
    if (isVisibleNow) {
      instance.state.atBottom = (root.scrollHeight - root.scrollTop - root.clientHeight) <= 7;
      if (instance.state.atBottom)
        shouldAutoScroll = true;
    }

    root.append(lineEl);
    if (shouldAutoScroll) {
      root.scrollTop = root.scrollHeight;
    }
  },

  push_log: function(instance, payload) {
    const log = payload.pushes.log;
    if (log) {
      this._addLog(instance, log);
    }
  },

  update_maxLines: function(instance, payload) {
    const newMax = helper.getInt(payload.values.maxLines, 25);
    instance.state.maxLines = newMax;

    const root = instance.element;
    root.style.setProperty("--max-lines", newMax);
  },

});