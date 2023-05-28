function buttonGroup_update_event(element, value) {
  for (const button of element.getElementsByTagName("button")) {
    button.setAttribute("event", value);
  }
}

function buttonGroup_update_child_text(element, value) {
  element.textContent = value;
}

function buttonGroup_update_child_event(element, value) {
  element.setAttribute("event", value);
}

function buttonGroup_update_child_variable(element, value) {
  element.setAttribute("variable", value);
}

function buttonGroup_update_child_disabled(element, value) {
  if (value) {
    element.disabled = true;
  } else {
    element.disabled = false;
  }
}