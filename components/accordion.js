function accordion_update_child_title(element, value) {
  const titleElement = document.getElementById(element.dataset.title);
  titleElement.textContent = value;
}

function accordion_update_child_text(element, value) {
  const textElement = element.querySelector('.accordion-body');
  textElement.textContent = value;
}