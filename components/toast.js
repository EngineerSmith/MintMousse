const toastOptions = {
  "animation": true,
  "autohide": true,
  "delay": 12000, // ms
};

function toast_updateTimestamp(timestampElement, startTime) {
  const now = Date.now();
  const seconds = Math.floor((now - startTime) / 1000);
  let displayText;

  if (seconds < 60) {
    displayText = `${seconds} second${seconds === 1 ? '' : 's'} ago`;
  } else if (seconds < 3600) {
    const minutes = Math.floor(seconds/60);
    displayText = `${minutes} minute${minutes === 1 ? '' : 's'} ago`;
  } else if (seconds < 86400) {
    const hours = Math.floor(seconds / 3600);
    displayText = `${hours} hour${hours === 1 ? '' : 's'} ago`;
  } else {
    const days = Math.floor(seconds / 86400);
    displayText = `${days} day${days === 1 ? '' : 's'} ago`;
  }

  timestampElement.textContent = displayText;
}

function toast_notify(payload) {
  const title = getText(payload.title);
  const text = getText(payload.text);
  const animatedFade = Boolean(payload.animatedFade ?? toastOptions.animation);
  const autoHide = Boolean(payload.autoHide ?? toastOptions.autohide);
  const delay = Number(payload.hideDelay);
  const sentTime = Date.now();

  const currentOptions = { ...toastOptions };
  currentOptions.animation = animatedFade;
  currentOptions.autohide = autoHide;
  if (typeof delay === "number" && !isNaN(delay)) {
    currentOptions.delay = delay;
  }

  const toast = document.createElement("div");
  toast.classList.add("toast");
  setAttributes(toast, {
    "role": "alert",
    "aria-live": "assertive",
    "aria-atomic": "true",
  });

  const header = document.createElement("div");
  header.classList.add("toast-header");

  const headerTitle = document.createElement("strong");
  headerTitle.classList.add("me-auto")
  headerTitle.innerHTML = title; // if null; we still use me-auto to right align it's siblings

  const timestamp = document.createElement("small");
  timestamp.textContent = "0 seconds ago"

  const dismissButton = document.createElement("button");
  dismissButton.classList.add("btn-close")
  setAttributes(dismissButton, {
    "type": "button",
    "data-bs-dismiss": "toast",
    "aria-label": "Close",
  })

  header.append(headerTitle, timestamp, dismissButton);

  const body = document.createElement("div");
  body.classList.add("toast-body");
  body.innerHTML = text;
  body.hidden = text === null;

  toast.append(header, body);

  const intervalID = setInterval(toast_updateTimestamp, 1000, timestamp, sentTime);

  toast.addEventListener("hidden.bs.toast", () => {
    clearInterval(intervalID);
    removeElement(toast);
  });

  const container = document.getElementById("toastContainer");
  container.append(toast);
  const t = new bootstrap.Toast(toast, currentOptions);

  toast_updateTimestamp(timestamp, sentTime);
  t.show()
}