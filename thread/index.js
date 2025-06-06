var tabMasonry = new Map();
const masonryOptions = {
  "itemSelector": ".grid-item",
  "columnWidth": ".grid-sizer",
  "gutter": ".gutter-sizer",
  "percentPosition": true,
  "transitionDuration": "0.2s",
};

function resizeMasonry() {
  tabMasonry.forEach(function(value, _) {
    value.layout();
  });
}

// https://getbootstrap.com/docs/5.3/utilities/colors/
const validBootstrapColors = [
  "primary", "secondary",
  "success", "danger",
  "warning", "info",
  "light", "dark",
  "white", "black",
  "body",
]
function BSColor(color) {
  if (color === undefined || color === null)
    return null;

  const colorLower = String(color).toLowerCase();

  if (validBootstrapColors.includes(colorLower))
    return colorLower;

  return null;
}

const validBootstrapWidths = [
  "25", "50", "75", "100", "auto"
]
function BSWidth(width) {
  if (width === undefined || width === null)
    return null;

  const widthLower = String(width).toLowerCase();

  if (validBootstrapWidths.includes(widthLower))
    return widthLower;

  return null;
}

function getColorClass(element, prefix) {
  if (!element || !element.classList)
    return null;

  for (const className of element.classList) {
    if (className.startsWith(prefix)) {
      const colorPart = className.substring(prefix.length);
      if (validBootstrapColors.includes(colorPart)) {
        return className
      }
    }
  }
  return null;
}

function getClassWithPrefix(element, prefix) {
  if (!element || !element.classList)
    return null;

  for (const className of element.classList) {
    if (className.startsWith(prefix)) {
      return className;
    }
  }
  return null;
}

function getText(text) {
  if (text === null || text === undefined) {
    return null;
  }
  return String(text);
}

function truncateToTwoDecimalPlaces(str) {
  const decimalIndex = str.indexOf('.');
  if (decimalIndex === -1)
    return str;
  return str.slice(0, decimalIndex + 3);
}

var isLowEndMachine = false;
{
  const userAgent = navigator.userAgent;
  if (userAgent.match(/(Android|iPhone|iPad|iPod)/)) {
    // check RAM
    isLowEndMachine = navigator.deviceMemory < 1024;
  } else {
    // check CPU
    isLowEndMachine = navigator.cpuClass < "medium";
  }
}

const connectedStatus = document.getElementById("connected-status");
const disconnectedStatus = document.getElementById("disconnected-status");
const disconnectedStatusText = document.getElementById("disconnected-status-text");

function setConnectedStatus() {
  connectedStatus.style.display = "inline-block";
  disconnectedStatus.style.display = "none";
  disconnectedStatusText.style.display = "none";
}

function setDisconnectedStatus() {
  connectedStatus.style.display = "none";
  disconnectedStatus.style.display = "inline-block";
  disconnectedStatusText.style.display = "inline-block";
}

function hideSpinner() {
  const spinnerElement = document.getElementById("loadingSpinner");
  spinnerElement.style.display = "none";
}

function showNoContentText() {
  const noContentContainer = document.getElementById("noContentContainer");
  noContentContainer.style.setProperty("display", "flex", "important");
}

function hideNoContentText() {
  const noContentContainer = document.getElementById("noContentContainer");
  noContentContainer.style.setProperty("display", "none", "important");
}

function hasEvent(element, eventType) {
  const listeners = element.addEventListener ? element.addEventListener._listeners : element._listeners;
  return listeners && listeners[eventType] !== undefined;
}

function eventInit() {
  for (const element of document.getElementsByClassName("collapse")) {
    if (hasEvent(element, "show.bs.collapse"))
      continue;
    if (!isLowEndMachine)
      element.addEventListener("hide.bs.collapse", resizeMasonry);
    element.addEventListener("hidden.bs.collapse", resizeMasonry);
    if (!isLowEndMachine)
      element.addEventListener("show.bs.collapse", resizeMasonry);
    element.addEventListener("shown.bs.collapse", resizeMasonry);
  }
}

function setAttributes(element, attributes) {
  for(const key in attributes){
    element.setAttribute(key, attributes[key]);
  }
}

function getSizeClass(element) {
  if (!element)
    return null;

  for (const className of element.classList) {
    if (/^grid-item-[1-5]$/.test(className))
      return className;
  }
  return null;
}

function insertPayload(target, payload) {
  if (typeof payload.render === "string") {
    target.insertAdjacentHTML("beforeend", payload.render)
    return target.lastElementChild;
  } else if (typeof payload.newFunc === "string") {
    const func = window[payload.newFunc];
    if (typeof func === "function") {
      const element = func(payload);
      target.insertAdjacentElement("beforeend", element);
      return element;
    } else {
      console.error("MM: Could not find ", payload.newFunc, " function to create element for insertion!");
      return null;
    }
  }
  return null;
}

function removeElement(element) { // todo what if a child has a _remove pattern that needs to be called? e.g. cleaning up a callback
  if (typeof element.remove === "function")
    element.remove()
  else
    element.parentNode.removeChild(element)
}

function removeComponent(payload) {
  const id = payload.id;

  const elementRoot = document.getElementById(id+"-root");
  if (elementRoot) {
    removeElement(elementRoot);
    return;
  }

  const element = document.getElementById(id);
  removeElement(element);
}

function notify(payload) {
  const type = payload.type;
  const funcName = type + "_notify";

  const func = window[funcName];
  if (typeof func === "function") {
    func(payload);
  } else {
    console.error("MM: Couldn't find notify function for type:", type);
  }
}

// https://stackoverflow.com/a/57888548
const fetchTimeout = (url, ms, { signal, ...options } = {}) => {
  const controller = new AbortController();
  const promise = fetch(url, { signal: controller.signal, ...options });
  if (signal) signal.addEventListener("abort", () => controller.abort());
  const timeout = setTimeout(() => controller.abort(), ms);
  return promise.finally(() => clearTimeout(timeout));
};

function startConnectionMonitor(pingIntervalSeconds = 1) {
  const interval = Math.max(0.5, pingIntervalSeconds) * 1000;

  setInterval(() => {
    fetchTimeout('/api/ping', interval - 100)
      .then(response => {
        if (response.status === 204) {
          console.log("MM: Server is alive, reloading page.");
          window.location.reload()
        } else {
          console.error(`MM: Ping failed with returned status: ${response.status}`);
        }
      });
  }, interval);
}

function createWebSocketConnection() {
  const protocol = window.location.protocol === "https:" ? "wss:" : "ws:";
  const host = window.location.hostname;
  const port = window.location.port ? `:${window.location.port}` : "";
  const websocketEndpoint = "/live-updates";
  const websocketUrl = `${protocol}//${host}${port}${websocketEndpoint}`;

  const websocket = new WebSocket(websocketUrl);

  websocket.onopen = () => {
    console.log("WebSocket: Connection opened");
    setConnectedStatus();
  };

  websocket.onmessage = (event) => {
    if (typeof event.data === "string") {
      const receivedString = event.data;
      if (receivedString.trim().length !== 0) {
        try {
          const payload = JSON.parse(receivedString);
          //console.log("WebSocket: Received JSON data:", payload); // For debugging
          for (let i = 0; i < payload.length; i++) {
            try {
              const func = window[payload[i].func];
              if (typeof func === "function") {
                func(payload[i]);
              } else {
                console.error("MM: Error while processing payload. Couldn't find function:", payload[i].func);
              }
            } catch (error) {
              console.error("MM: Error in processing payload loop:", error);
            }
          }
        } catch (error) {
          console.log("WebSocket: Received text data:", receivedString);
          console.error("MM: Error parsing JSON:", error);
        }
      }
    } else if (event.data instanceof Blob) {
      console.log("WebSocket: Received binary data (Blob):", event.data);
    } else if (event.data instanceof ArrayBuffer) {
      console.log("WebSocket: Received binary data (ArrayBuffer):", event.data);
    } else {
      console.log("WebSocket: Received unknown data type:", event.data);
    }
    hideSpinner();
    if (document.querySelector('.nav-link')) {
      hideNoContentText();
    } else {
      showNoContentText();
    }
  };

  websocket.onclose = () => {
    console.log("WebSocket: Connection closed");
    setDisconnectedStatus();
    startConnectionMonitor(2);
  };

  websocket.onerror = (error) => {
    console.log("WebSocket Error:", error);
    setDisconnectedStatus();
    startConnectionMonitor(2);
  };

  return websocket;
}

let appWebSocket;
document.addEventListener("DOMContentLoaded", () => {
  new bootstrap.Tooltip(document.getElementById("connected-status"));

  appWebSocket = createWebSocketConnection();
});

function websocketSend(data) {
  if (!appWebSocket) {
    console.error("MM: Tried to send data while websocket isn't initialized.")
    return false;
  }
  if (appWebSocket.readyState !== WebSocket.OPEN) {
    console.error("MM: Tried to send data while websocket wasn't open.")
    return false;
  }

  try {
    appWebSocket.send(JSON.stringify(data));
    return true;
  } catch (error) {
    console.error("WebSocket: Error sending data:", error, data)
    return false;
  }
}