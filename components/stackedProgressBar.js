function stackedProgressBar_new(payload) {
  const id = payload.id;

  const stackedProgressBar = document.createElement("div");
  stackedProgressBar.classList.add("progress-stacked");
  setAttributes(stackedProgressBar, {
    "id": id,
    "progressBarCounter": 0,
  })

  return stackedProgressBar;
}

function stackedProgressBar_insert(payload) {
  const id = payload.parentID;
  const childID = payload.id;

  let percentage = getText(payload.percentage) ?? "0";

  const stackedProgressBar = document.getElementById(id);
  const childContainer = insertPayload(stackedProgressBar, payload);
  if (!childContainer.classList.contains("progress"))
    return;

  let count = parseInt(stackedProgressBar.getAttribute("progressBarCounter"));
  count++;
  stackedProgressBar.setAttribute("progressBarCounter", count);

  childContainer.setAttribute("aria-valuenow", percentage);

  const progressBarContainers = stackedProgressBar.querySelectorAll(".progress");

  count *= 100;
  progressBarContainers.forEach(bar => {
    let percentage = parseInt(bar.getAttribute("aria-valuenow"));
    percentage = String((percentage / count) * 100);
    bar.style["width"] = percentage + "%";
  });

  const child = document.getElementById(childID);
  child.style["width"] = "";

  eventInit();
}

function stackedProgressBar_update_child_percentage(payload) {
  const id = payload.parentID;
  const childID = payload.id;
  const childContainerID = childID + "-root";

  const percentage = getText(payload.percentage) ?? "0";

  const childContainer = document.getElementById(childContainerID);
  if (!childContainer || !childContainer.classList.contains("progress"))
    return; // non-progressBar container

  const stackedProgressBar = document.getElementById(id);
  const count = parseInt(stackedProgressBar.getAttribute("progressBarCounter"));

  childContainer.style["width"] = String((parseInt(percentage) / (count * 100)) * 100) + "%";
  childContainer.setAttribute("aria-valuenow", percentage);

  const progressBar = document.getElementById(childID);
  progressBar.style["width"] = "";
  if (progressBar.dataset.showLabel === "true")
    progressBar.textContent = truncateToTwoDecimalPlaces(percentage) + "%";
}