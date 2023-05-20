function updateProgressBar(id, json) {
  var progressBar = document.getElementById(id).firstChild
  progressBar.style.width = json.percentage
  if (progressBar.dataset.updateLabel) {
    progressBar.textContent = json.percentage
  }
}