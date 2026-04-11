const instances = { };
const tabMasonry = new Map();

const isLowEndMachine = (function() {
  const ua = navigator.userAgent;
  const isMobile = /(Android|iPhone|iPad|iPod)/.test(ua)

  const lowMemory = (navigator.deviceMemory || 8) < 2;

  const lowCPU = (navigator.hardwareConcurrency || 8) <= 4;

  if (isMobile)
    return lowMemory || lowCPU;
  // Desktop
  return lowCPU;
})();

const UI = {
  setStatus: (connected) => {
    const c = document.getElementById("connected-status");
    const d = document.getElementById("disconnected-status");
    const dt = document.getElementById("disconnected-status-text");

    c.style.display = connected ? "inline-block" : "none";
    d.style.display = connected ? "none" : "inline-block";
    dt.style.display = connected ? "none" : "inline-block";

    if (!connected) {
      UI.disconnected.startTime = Date.now();

      dt.setAttribute("data-bs-toggle", "tooltip");

      if (UI.disconnected.tooltip)
        UI.disconnected.tooltip.dispose();
      UI.disconnected.tooltip = new bootstrap.Tooltip(dt, { placement: "bottom", html: true });

      UI.disconnected.updateTooltipContent();
      UI._startDisconnectTooltipUpdater();
    } else {
      if (UI.disconnected.tooltip) {
        UI.disconnected.tooltip.dispose();
        UI.disconnected.tooltip = null;
      }
      if (UI.disconnected.timerID) {
        clearTimeout(UI.disconnected.timerID);
        UI.disconnected.timerID = null;
      }
      UI.disconnected.startTime = null;
    }
  },

  disconnected: {
    startTime: null,
    tooltip: null,
    timerID: null,

    updateTooltipContent: function() {
      if (!this.tooltip || !this.startTime) return;
      const full = UI.Toast._getFullTimestamp(this.startTime);
      const rel = UI.relativeTime(this.startTime);
      const html = `${full}<br/><small>${rel}</small>`;
      this.tooltip.setContent({ ".tooltip-inner": html });
    }
  },

  _startDisconnectTooltipUpdater: function() {
    if (UI.disconnected.timerID) return;

    const tick = () => {
      UI.disconnected.updateTooltipContent();

      const sec = Math.floor((Date.now() - UI.disconnected.startTime) / 1000);
      let delay = 1000;
      if (sec >= 60 && sec < 3600) delay = (60 - (sec % 60)) * 1000 + 100;
      else if (sec >= 3600)        delay = (3600 - (sec % 3600)) * 1000 + 100;

      UI.disconnected.timerID = setTimeout(tick, delay);
    };
    UI.disconnected.timerID = setTimeout(tick, 800);
  },

  setLoading: (isLoading) => document.getElementById("loadingSpinner").style.display = isLoading ? "block" : "none",

  toggleNoContent: () => {
    const hasContent = !!document.querySelector(".nav-link");
    const container = document.getElementById("noContentContainer");
    container.style.setProperty("display", hasContent ? "none" : "flex", "important");
  },

  Toast: {
    defaults: { animation: true, autohide: true, delay: 12000 },

    show: function(payload) {
      const h = componentHelper;

      const title = h.getText(payload.title);
      const text = h.getText(payload.text);
      const sentTime = Date.now();

      const options = {
        ...this.defaults,
        animation: h.getBoolean(payload.animatedFade, this.defaults.animation),
        autohide: h.getBoolean(payload.autoHide, this.defaults.autohide),
        delay: h.getInt(payload.hideDelay, this.defaults.delay),
      };

      const toast = document.createElement("div");
      toast.className = "toast";
      h.setAttributes(toast, {
        "role": "alert",
        "aria-live": "assertive",
        "aria-atomic": "true",
      });

      const header = document.createElement("div");
      header.className = "toast-header";

      const headerTitle = Object.assign(document.createElement("strong"), { className: "me-auto", innerHTML: title });

      const timestamp = document.createElement("small");
      const preciseTime = this._getFullTimestamp(sentTime);
      h.setAttributes(timestamp, {
        "data-bs-toggle": "tooltip",
        "data-bs-title": preciseTime,
      });
      const timestampTooltip = new bootstrap.Tooltip(timestamp);

      const closeBtn = Object.assign(document.createElement("button"), { className: "btn-close" });
      h.setAttributes(closeBtn, {
        "type": "button",
        "data-bs-dismiss": "toast",
        "aria-label": "Close",
      });

      header.append(headerTitle, timestamp, closeBtn);

      const body = Object.assign(document.createElement("div"), { className: "toast-body", innerHTML: text });
      body.hidden = !text;

      toast.append(header, body);

      const timerState = { active: true };
      this._startSmartTimer(timestamp, sentTime, timerState);

      toast.addEventListener("hidden.bs.toast", () => {
        timerState.active = false;
        clearTimeout(timerState.timerId);

        timestampTooltip.dispose();

        const bsToast = bootstrap.Toast.getInstance(toast);
        if (bsToast) {
          bsToast.dispose();
        }

        toast.remove();
      });

      document.getElementById("toastContainer")?.append(toast);
      const bsToast = new bootstrap.Toast(toast, options);
      bsToast.show();
    },

    _getFullTimestamp: (function() {
      try {
        const locale = document.documentElement.lang || "en";
        const options = {
          year: "numeric", month: "short", day: "numeric",
          hour: "2-digit", minute: "2-digit", second: "2-digit",
          hour12: false,
        };
        const dtf = new Intl.DateTimeFormat(locale, options);
        return (time) => dtf.format(time);
      } catch (e) { // fallback
        return (time) => new Date(time).toISOString().replace("T", " ").split(".")[0];
      }
    })(),

    _startSmartTimer: function(element, start, state) {
      if (!state?.active || !element?.isConnected) return;

      const sec = this._updateTimestamp(element, start);

      let nextDelay;
      if (sec < 60) nextDelay = 1000;
      else if (sec < 3600) nextDelay = (60 - (sec % 60)) * 1000 + 100;
      else nextDelay = (3600 - (sec % 3600)) * 1000 + 100;

      state.timerId = setTimeout(() => this._startSmartTimer(element, start, state), nextDelay);
    },

    _updateTimestamp: (function() {
      const rtf = (typeof Intl !== "undefined" && Intl.RelativeTimeFormat)
        ? new Intl.RelativeTimeFormat(document.documentElement.lang || "en", { numeric: "auto" })
        : null;

      const units = [
        { max:       60, name: "second", div:     1 },
        { max:     3600, name: "minute", div:    60 },
        { max:    86400, name: "hour",   div:  3600 },
        { max: Infinity, name: "day",    div: 86400 },
      ];

      return function(element, start) {
        const sec = Math.floor((Date.now() - start) / 1000);
        const unit = units.find(u => sec < u.max) || units[units.length - 1];
        const value = Math.floor(sec / unit.div);

        if (element)
          element.textContent = rtf
            ? rtf.format(-value, unit.name)
            : `${value} ${unit.name}${value === 1 ? '' : 's'} ago`; // This solution is locked to English, but it's a fallback

        return sec;
      };
    })(),

  },

  relativeTime: (function() {
      const rtf = (typeof Intl !== "undefined" && Intl.RelativeTimeFormat)
        ? new Intl.RelativeTimeFormat(document.documentElement.lang || "en", { numeric: "auto" })
        : null;

      const units = [
        { max:       60, name: "second", div:     1 },
        { max:     3600, name: "minute", div:    60 },
        { max:    86400, name: "hour",   div:  3600 },
        { max: Infinity, name: "day",    div: 86400 },
      ];

      return function(start) {
        const sec = Math.floor((Date.now() - start) / 1000);
        const unit = units.find(u => sec < u.max) || units[units.length - 1];
        const value = Math.floor(sec / unit.div);

        return rtf
          ? rtf.format(-value, unit.name)
          : `${value} ${unit.name}${value === 1 ? '' : 's'} ago`; // This solution is locked to English, but it's a fallback
      };
    })(),

};

const componentRegistry = {
  register: function(component) {
    const { typeName } = component;
    this[typeName] = component;

    for (let key in component) {
      if (typeof component[key] !== "function") continue;

      const originalFn = component[key];

      if (key.startsWith("update_")) {
        component[key] = (payload) => {
          const instance = componentHelper.getInstance(payload.id);
          if (componentHelper.isValidInstance(instance, typeName)) {
            originalFn.call(component, instance, payload);
          }
        };
      } else if (key.startsWith("push_")) {
        component[key] = (payload) => {
          const instance = componentHelper.getInstance(payload.id);
          if (componentHelper.isValidInstance(instance, typeName)) {
            originalFn.call(component, instance, payload);
          }
        }
      } else if (key === "insert") {
        component[key] = (parentInstance, payload) => {
          originalFn.call(component, parentInstance, payload);
          componentHelper.eventInit();
        };
      } else if (key === "remove") {
        component[key] = (instance) => {
          originalFn.call(component, instance);
        };
      }
    }
  },
}

let debouncedLayoutFn = null;

const componentHelper = Object.freeze({
  getInstance: (id) => (instances[id] ??={
    id, type: null, parentID: null, element: null,
    children: [ ], state: { }, parts: { },
  }),

  getParentOfInstance: (instance) => {
    return instances[instance.parentID];
  },

  prepareInstance: function(id, typeName, parentID) {
    if (instances[id]?.element) this.removeInstance(id);
    const instance = this.getInstance(id);
    instance.type = typeName;
    instance.parentID = parentID;
    return instance;
  },

  isValidInstance: (instance, type) => !!(instance?.element && (!type || instance.type === type)),

  removeInstance: function(id) {
    const instance = instances[id];
    if (!instance) return;

    if (instance.parentID) {
      const parent = instances[instance.parentID];
      if (this.isValidInstance(parent)) {
        componentRegistry[parent.type]?.remove_child?.(parent, instance);
        const index = parent.children.indexOf(instance);
        if (index !== -1) parent.children.splice(index, 1);
      }
    }
    while (instance.children?.length > 0) {
      this.removeInstance(instance.children[0].id);
    }

    componentRegistry[instance.type]?.remove?.(instance);

    instance.element?.remove();
    instance.element = null;
    instance.children = null;
    instance.state = null;
    instance.parts = null;

    delete instances[id];
  },

  insertNewChild: function(parentInstance, payload) {
    const component = componentRegistry[payload.childType];
    if (!component) return;

    const childInstance = component.create(payload);
    const children = parentInstance.children;
    const targetIndex =  this.getIntInRange(payload.childPosition, 1, children.length + 1, children.length + 1) - 1;

    children.splice(targetIndex, 0, childInstance);

    if (targetIndex >= children.length - 1) {
      parentInstance.element.append(childInstance.element);
    } else {
      children[targetIndex + 1].element.before(childInstance.element);
    }
    return childInstance;
  },

  moveChild: function(parentInstance, payload) {
    const children = parentInstance.children;
    const oldIndex = this.getIntInRange(payload.oldIndex, 1, children.length) - 1;
    const newIndex = this.getIntInRange(payload.newIndex, 1, children.length) - 1;
    if (oldIndex === newIndex) return;

    const [ movingChild ] = children.splice(oldIndex, 1);
    children.splice(newIndex, 0, movingChild);

    if (newIndex >= children.length - 1) {
      parentInstance.element.append(movingChild.element);
    } else {
      children[newIndex + 1].element.before(movingChild.element);
    }
  },

  moveTab: function(instance, payload) {
    const navbar = document.getElementById("tabNavBar");
    if (!navbar || !instance.parts?.li) return;

    const li = instance.parts.li;
    const numTabs = navbar.children.length;

    const oldIndex = this.getIntInRange(payload.oldIndex, 1, numTabs) - 1;
    const newIndex = this.getIntInRange(payload.newIndex, 1, numTabs) - 1;
    if (oldIndex == newIndex) return;

    li.remove()

    const adjusted = (oldIndex < newIndex) ? newIndex - 1 : newIndex;
    if (adjusted >= navbar.children.length) {
      navbar.append(li);
    } else {
      navbar.children[adjusted].before(li);
    }
  },

  reorderChildren: function(parentInstance, payload) {
    if (!Array.isArray(payload.newOrder)) return;
    const oldChildren = parentInstance.children;

    parentInstance.children = payload.newOrder.map(pos => {
      return oldChildren[this.getIntInRange(pos, 1, oldChildren.length) - 1];
    });

    const elements = parentInstance.children.map(c => c.element).filter(Boolean);
    parentInstance.element.replaceChildren(...elements);
  },

  reorderTabs: function(payload) {
    if (!Array.isArray(payload.newOrder)) return;

    const navbar = document.getElementById("tabNavbar");
    if (!navbar) return;

    const oldList = Array.from(navbar.children);
    const numTabs = oldList.length;

    const newList = payload.newOrder.map(pos => {
      const index = this.getIntInRange(pos, 1, numTabs) - 1;
      return oldList[index];
    }).filter(Boolean);

    navbar.replaceChildren(...newList);
  },

  debounce: function(func, wait) {
    let timeout;
    return function(...args) {
      const context = this;
      clearTimeout(timeout);
      timeout = setTimeout(() => func.apply(context, args), wait);
    };
  },

  eventInit: function() {
    if (!debouncedLayoutFn) {
      const delay = isLowEndMachine ? 200 : 100;
      debouncedLayoutFn = this.debounce(() => {
        tabMasonry.forEach(masonryInstance => masonryInstance.layout());
      }, delay);
    }

    const collapses = document.getElementsByClassName("collapse");
    for (const element of collapses) {
      if (element.dataset.mmObserved) continue;
      element.dataset.mmObserved = "true";

      const events = isLowEndMachine
        ? [ "hidden.bs.collapse", "shown.bs.collapse" ]
        : [ "hide.bs.collapse", "hidden.bs.collapse", "show.bs.collapse", "shown.bs.collapse"];
      
      events.forEach(event => element.addEventListener(event, debouncedLayoutFn));
    }
  },

  // Getters
  getInt: (val, fb = 0) => {
    if (val == null || val === "") return fb;
    const num = Number(val);
    return isNaN(num) ? fb : num;
  },
  getIntInRange: function(val, min, max, fb) {
    const n = this.getInt(val, fb);
    if (n == null) return fb;
    return Math.max(min, Math.min(n, max));
  },
  getFloat: (val, fb = 0.0) => {
    if (val == null || val === "") return fb;
    const num = parseFloat(val);
    return isNaN(num) ? fb : num;
  },
  getFloatInRange: function(val, min, max, fb) {
    const f = this.getFloatInRange(val, fb);
    if (f == null) return fb;
    return Math.max(min, Math.min(f, max));
  },
  getText: (function() {
    const options = {
      ALLOWED_TAGS: ['b', 'i', 'strong', 'em', 'code', 'span', 'br', 'div'],
      ALLOWED_ATTR: ['class', 'style'],
      KEEP_CONTENT: true,
    };
    return function(text, fb = null) {
      if (!text) return fb;
      return DOMPurify.sanitize(text.replace(/\n/g, "<br/>"), options);
    };
  })(),
  setAttributes: (el, attrs) => Object.entries(attrs).forEach(([k, v]) => v != null && el.setAttribute(k, v)),
  getBoolean: (function() {
    const truthy = new Set(['true', '1', 'yes']);
    const falsy = new Set(['false', '0', 'no']);
    return function(bool, fb = null) {
      if (typeof bool === 'boolean') return bool;
      if (bool == null) return fb;

      const lower = String(bool).toLowerCase().trim();
      if (truthy.has(lower)) return true;
      if (falsy.has(lower)) return false;
      return fb;
    };
  })(),
  getColor: (function() {
    // https://getbootstrap.com/docs/5.3/utilities/colors/
    const validBootstrapColors = new Set([
      "primary", "secondary",
      "success", "danger",
      "warning", "info",
      "light", "dark",
      "white", "black",
      "body",
    ]);
    return function(color, fb = null) {
      if (color == null) return fb;
      if (validBootstrapColors.has(color)) return color;
      const lower = String(color).toLowerCase().trim();
      return validBootstrapColors.has(lower) ? lower : fb;
    };
  })(),
  getWidth: (function() {
    const validBootstrapWidths = new Set([
      "25", "50", "75", "100", "auto"
    ]);
    return function(width, fb = "100") {
      if (width == null) return fb;
      if (validBootstrapWidths.has(width)) return width;
      const lower = String(width).toLowerCase().trim();
      return validBootstrapWidths.has(lower) ? lower : fb;
    };
  })(),
});

const ActionProcessor = {
  process: function(messages) {
    if (!Array.isArray(messages)) return;

    messages.forEach(payload => {
      try {
        if (payload.action === "toast") {
          UI.Toast.show(payload);
          return;
        }

        const handler = this.actions[payload.action];
        if (handler) {
          handler(payload);
        } else {
          console.error(`MM: Unknown action '${payload.action}'`, payload);
        }
      } catch (e) {
        console.error("MM: Dispatcher error:", e, payload);
      }
    });

    UI.toggleNoContent();
    UI.setLoading(false);
  },

  actions: {
    "limits": (payload) => {
      if (Network._receivedLimits)
        return
      Network.limits = {
        maxFrameSize: payload.maxFrameSize,
        maxMessageSize: payload.maxMessageSize,
      };
      Network._receivedLimits = true;
    },

    "new": (payload) => componentRegistry["Tab"]?.create(payload),

    "insert": (payload) => {
      const parent = componentHelper.getInstance(payload.parentID);
      const comp = componentRegistry[parent.type];
      if (comp?.insert) {
        comp.insert(parent, payload)
        componentHelper.eventInit();
      }
    },

    "update": (payload) => {
      const instance = componentHelper.getInstance(payload.id);
      const parent = componentHelper.getInstance(instance.parentID);
      const parentComp = componentRegistry[parent.type];

      const parentFunc = `update_child_${payload.field}`;
      if (parentComp && typeof parentComp[parentFunc] === "function") {
        parentComp[parentFunc](payload);
        return;
      }

      const comp = componentRegistry[instance.type];
      const func = `update_${payload.field}`;
      if (comp && typeof comp[func] === "function") {
        comp[func](payload);
      }
    },

    "push": (payload) => {
      const instance = componentHelper.getInstance(payload.id);
      const comp = componentRegistry[instance.type];
      const func = `push_${payload.field}`;
      if (comp && typeof comp[func] === "function") {
        comp[func](payload);
      }
    },

    "move": (payload) => {
      const instance = componentHelper.getInstance(payload.id);

      if (instance.parentID == null && instance.type == "Tab") {
        componentHelper.moveTab(instance, payload);
        return;
      }

      const parent = componentHelper.getInstance(instance.parentID);
      const comp = componentRegistry[parent.type];
      (comp?.moveChild || componentHelper.moveChild)(parent, payload);
    },

    "reorder": (payload) => {
      if (payload.id == null) {
        componentHelper.reorderTabs(payload);
        return;
      }
      
      const parent = componentHelper.getInstance(payload.id);
      const comp = componentRegistry[parent.type];
      (comp?.reorderChildren || componentHelper.reorderChildren)(parent, payload);
    },

    "remove": (payload) => componentHelper.removeInstance(payload.id),

    "setTitle": (payload) => {
      const title = componentHelper.getText(payload.title);
      document.title = title;

      const element = document.querySelector("nav .navbar-brand.h1");
      if (element) {
        element.textContent = title;
      }
    },
  },
};

const Network = {
  socket: null,
  _monitoring: false,
  limits: { maxFrameSize: 0, maxMessageSize: 0 },
  _receivedLimits: false,

  connect: function() {
    const protocol = location.protocol === "https:" ? "wss:" : "ws:";
    const url = `${protocol}//${location.host}/live-updates`;

    this.socket = new WebSocket(url);

    this.socket.onopen = () => UI.setStatus(true);
    this.socket.onclose = () => { UI.setStatus(false); this.monitor(); };
    this.socket.onerror = () => UI.setStatus(false); // Should we try to reopen the socket?

    this.socket.onmessage = (e) => {
      if (typeof e.data !== "string") return;
      try {
        const json = JSON.parse(e.data);

        ActionProcessor.process(json);
      } catch (e) {
        console.error("MM: Socket Parse Error", e);
      }
    };
  },

  send: function(data) {
    if (this.socket?.readyState !== WebSocket.OPEN) {
      return false;
    }

    const payload = JSON.stringify(data);
    const size = payload.length;

    if (this._receivedLimits && size > this.limits.maxMessageSize) {
      console.warn(`MM: Message too big (${size} > ${this.limits.maxMessageSize}). Chunk it or reduce payload.`);
      return false;
    }

    this.socket.send(payload);
    return true;
  },

  _fetchTimeout: function(url, ms, options = { }) {
    const controller = new AbortController();
    const promise = fetch(url, { signal: controller.signal, ...options });

    if (options.signal) {
      options.signal.addEventListener("abort", () => controller.abort());
    }

    const timeoutId = setTimeout(() => controller.abort(), ms);
    return promise.finally(() => clearTimeout(timeoutId));
  },

  monitor: function() {
    if (this._monitoring) return;
    this._monitoring = true;

    const check = () => {
      this._fetchTimeout("/api/ping", 1900)
        .then(r => {
          if (r.status === 204) {
            location.reload();
          } else {
            setTimeout(check, 2000);
          }
        })
        .catch(() => setTimeout(check, 2000));
    };
    check();
  },
};

// INIT
document.addEventListener("DOMContentLoaded", () => {
  new bootstrap.Tooltip(document.getElementById("connected-status"));
  Network.connect();
});

// Component Loading (Mustache)
// Ignore any IDE errors
{{#components}}
(function(helper, registry) {
{{&.}}
})(componentHelper, componentRegistry);
{{/components}}
