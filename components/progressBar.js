function progressBar_update_percentage(element, value) {
  var progressBar = element.childNodes[1];
  progressBar.style['width'] = value+"%";
  if (progressBar.dataset.updateLabel === "true") {
    progressBar.textContent = value+"%";
  }
}

function progressBar_update_percentageLabel(element, value) {
  var progressBar = element.childNodes[1];
  progressBar.textContent = value;
  progressBar.dataset.updateLabel = "false";
}