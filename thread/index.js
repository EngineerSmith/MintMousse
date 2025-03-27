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

function removeElement(element) {
  if (typeof element.remove === "function")
    element.remove()
  else
    element.parentNode.removeChild(element)
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
  };

  websocket.onmessage = (event) => {
    if (typeof event.data === "string") {
      const receivedString = event.data;
      if (receivedString.trim().length !== 0) {
        try {
          const payload = JSON.parse(receivedString);
          console.log("Received JSON data:", payload);
          try {
            for (let i = 0; i < payload.length; i++) {
              const func = window[payload[i].func];
              if (typeof func === "function") {
                func(payload[i]);
              } else {
                console.error("Error couldn't find function:", payload[i].func)
              }
            }
          } catch (error) {
            console.error("Error processing json:", error)
          }
        } catch (error) {
          console.error("Error parsing JSON:", error);
          console.log("Received text data:", receivedString);
        }
      }
    } else if (event.data instanceof Blob) {
      console.log("Received binary data (Blob):", event.data);
    } else if (event.data instanceof ArrayBuffer) {
      console.log("Received binary data (ArrayBuffer):", event.data);
    } else {
      console.log("Received unknown data type:", event.data);
    }
    hideSpinner();
    if (!document.querySelector('.nav-link')) {
      showNoContentText();
    } else {
      hideNoContentText();
    }
  };

  websocket.onclose = () => {
    console.log("WebSocket connection closed");
    setDisconnectedStatus();
    startConnectionMonitor(3);
  };

  websocket.onerror = (error) => {
    console.log("WebSocket error:", error);
    setDisconnectedStatus();
    startConnectionMonitor(3);
  };
}

document.addEventListener("DOMContentLoaded", () => {
  new bootstrap.Tooltip(document.getElementById("connected-status"));

  createWebSocketConnection();
});