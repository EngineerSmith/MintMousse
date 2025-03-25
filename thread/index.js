var tabMasonry = new Map();
const masonryOptions = {
  "itemSelector": ".grid-item",
  "columnWidth": ".grid-sizer",
  "gutter": ".gutter-sizer",
  "percentPosition": true,
};

function resizeMasonry() {
  tabMasonry.forEach(function(value, _) {
    value.layout();
  });
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

function setConnectedStatus() {
  const connectedStatus = document.getElementById("connected-status");
  connectedStatus.style.display = "inline-block";
  const disconnectedStatus = document.getElementById("disconnected-status");
  disconnectedStatus.style.display = "none";
}

function setDisconnectedStatus() {
  const disconnectedStatus = document.getElementById("disconnected-status");
  disconnectedStatus.style.display = "inline-block";
  const connectedStatus = document.getElementById("connected-status");
  connectedStatus.style.display = "none";
}

function hideSpinner() {
  const spinnerElement = document.getElementById("loadingSpinner");
  spinnerElement.style.display = "none";
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

// https://stackoverflow.com/a/57888548
const fetchTimeout = (url, ms, { signal, ...options } = {}) => {
  const controller = new AbortController();
  const promise = fetch(url, { signal: controller.signal, ...options });
  if (signal) signal.addEventListener("abort", () => controller.abort());
  const timeout = setTimeout(() => controller.abort(), ms);
  return promise.finally(() => clearTimeout(timeout));
};

function startConnectionMonitor(pingIntervalSeconds) {
  const interval = Math.max(1, pingIntervalSeconds) * 1000;

  setInterval(() => {
    fetchTimeout('/api/ping', interval - 500)
      .then(response => {
        if (response.status === 204) {
          console.log("Server is alive, reloading page.");
          window.location.reload()
        } else {
          console.log(`Ping failed with status: ${response.status}`);
        }
      })
      .catch(error => {
        if (error.name === "AbortError") {
          console.log("Ping request timed out.")
        } else {
          console.error("Error pinging server:", error)
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
    console.log("WebSocket connection opened");
    setConnectedStatus();
  }
  websocket.onmessage = (event) => {
    console.log("Message from server:", event.data);
  };
  websocket.onclose = () => {
    console.log("WebSocket connection closed");
    setDisconnectedStatus();
    startConnectionMonitor(5);
  }
  websocket.onerror = (error) => {
    console.log("WebSocket error:", error);
    setDisconnectedStatus();
    startConnectionMonitor(5);
  }
}

document.addEventListener("DOMContentLoaded", () => {
  createWebSocketConnection();
});