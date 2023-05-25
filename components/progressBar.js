function progressBar_update_percentage(element, value) {
  var progressBar = element.childNodes[1];
  progressBar.style['width'] = value+"%";
  if (progressBar.dataset.updateLabel) {
    progressBar.textContent = value+"%";
  }
}