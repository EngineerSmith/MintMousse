function progressBar_new(payload) {
  const id = payload.id;
  const percentage = getText(payload.percentage) ?? "0";
  const showLabel = Boolean(payload.showLabel ?? false);
  const ariaLabel = getText(payload.ariaLabel) ?? "Unknown";
  const isStriped = Boolean(payload.isStriped ?? false);
  const bgColor = BSColor(payload.color);

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
  progressBar.classList.add("progress-bar");
  if (bgColor !== null)
    progressBar.classList.add("text-bg-" + bgColor)

  setAttributes(progressBar, {
    "id": id,
  });
  progressBar.style["width"] = percentage + "%";
  progressBar.dataset.showLabel = String(showLabel);

  if (progressBar.dataset.showLabel === "true")
    progressBar.textContent = truncateToTwoDecimalPlaces(percentage) + "%";

  if (isStriped)
    progressBar.classList.add("progress-bar-striped", "progress-bar-animated");

  container.append(progressBar);

  return container;
}

function progressBar_update_percentage(payload) {
  const id = payload.id;
  const percentage = getText(payload.percentage) ?? "0";

  const progressBar = document.getElementById(id);
  progressBar.style["width"] = percentage + "%";

  if (progressBar.dataset.showLabel === "true")
    progressBar.textContent = truncateToTwoDecimalPlaces(percentage) + "%";

  const container = document.getElementById(id + "-root");
  container.setAttribute("aria-valuenow", percentage);
}

function progressBar_update_showLabel(payload) {
  const id = payload.id;
  const showLabel = Boolean(payload.showLabel ?? false);

  const progressBar = document.getElementById(id);
  progressBar.dataset.showLabel = String(showLabel);

  payload.percentage = progressBar.style["width"].slice(0, -1);
  progressBar_update_percentage(payload);
}

function progressBar_update_ariaLabel(payload) {
  const id = payload.id;
  const ariaLabel = getText(payload.ariaLabel) ?? "Unknown";

  const container = document.getElementById(id + "-root");
  container.setAttribute("aria-label") = ariaLabel;
}

function progressBar_update_isStriped(payload) {
  const id = payload.id;
  const isStriped = Boolean(payload.isStriped ?? false);

  const progressBar = document.getElementById(id);
  if (isStriped) {
    progressBar.classList.add("progress-bar-striped", "progress-bar-animated");
  } else {
    progressBar.classList.remove("progress-bar-striped", "progress-bar-animated");
  }
}

function progressBar_update_color(payload) {
  const id = payload.id;
  const bgColor = BSColor(payload.color);

  const progressBar = document.getElementById(id);
  const currentBGColor = getColorClass(progressBar, "text-bg-");
  if (currentBGColor)
    progressBar.classList.remove(currentBGColor);
  if (bgColor)
    progressBar.classList.add("text-bg-" + bgColor);
}