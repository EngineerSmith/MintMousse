function progressBar_new(payload) {
  const id = payload.id;
  const percentage = String(payload.percentage ?? "0");
  const showLabel = payload.showPercentageLabel === true;
  const ariaLabel = String(payload.ariaLabel ?? "Unknown");

  const container = document.createElement("div");
  container.classList.add("progress", "m-1")
  setAttributes(container, {
    "id": id + "-root",
    "role": "progressbar",
    "aria-valuemin": "0",
    "aria-valuemax": "100",
    "aria-valuenow": percentage,
    "aria-label": ariaLabel,
  });

  const progressBar = document.createElement("div");
  progressBar.classList.add("progress-bar")
  setAttributes(progressBar, {
    "id": id,
  })
  progressBar.style["width"] = percentage + "%";
  progressBar.dataset.showLabel = showLabel;

  if (progressBar.dataset.showLabel) {
    progressBar.textContent = percentage + "%";
  }

  container.append(progressBar);

  return container;
}

function progressBar_update_percentage(payload) {
  const id = payload.id;
  const percentage = String(payload.percentage ?? "0");

  const progressBar = document.getElementById(id);
  progressBar.style["width"] = percentage + "%";

  if (progressBar.dataset.showLabel) {
    progressBar.textContent = percentage + "%";
  }

  const container = document.getElementById(id + "-root");
  container.setAttribute("aria-valuenow", percentage);
}

function progressBar_update_showPercentageLabel(payload) {
  const id = payload.id;
  const showLabel = payload.showPercentageLabel === true;

  const progressBar = document.getElementById(id);
  progressBar.dataset.showLabel = showLabel;
}

function progressBar_update_ariaLabel(payload) {
  const id = payload.id;
  const ariaLabel = String(payload.ariaLabel ?? "Unknown");

  const container = document.getElementById(id + "-root");
  container.setAttribute("aria-label") = ariaLabel;
}