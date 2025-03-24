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

document.addEventListener('DOMContentLoaded', () => {
  const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
  const host = window.location.hostname;
  const port = window.location.port ? `:${window.location.port}` : '';
  const websocketEndpoint = '/live-updates';
  const websocketUrl = `${protocol}//${host}${port}${websocketEndpoint}`;

  const websocket = new WebSocket(websocketUrl);

  websocket.onopen = () => {
    console.log("WebSocket connection opened");
    websocket.send("hello world");
  }
  websocket.onmessage = (event) => {
    console.log("Message from server:", event.data);
  };
  websocket.onclose = () => {
    console.log("WebSocket connection closed");
  }
  websocket.onerror = (error) => {
    console.log("WebSocket error:", error);
  }
});