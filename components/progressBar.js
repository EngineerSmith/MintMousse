function progressBar_update_percentage(element, value) {
  var progressBar = element.getElementsByTagName("div")[0];
  progressBar.style['width'] = value+"%";
  if (progressBar.dataset.updateLabel) {
    progressBar.textContent = value+"%";
  }
}