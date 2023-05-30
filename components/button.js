function buttonPressed(button) { 
  var request = new XMLHttpRequest();
  request.open("POST", "api/event", true);
  var body = "event=" + encodeURIComponent(button.getAttribute("event"));
  var variable = button.getAttribute("variable");
  if (variable != null) {
    body += "&variable=" + encodeURIComponent(variable);
  }
  request.send(body);
}

function button_update_disabled(element, value) {
  if (value) { // ensure bool
    element.disabled = true;
  } else {
    element.disabled = false;
  }
}

function button_update_text(element, value) {
  element.textContent = value;
}

function button_update_event(element, value) {
  element.setAttribute("event", value);
}

function button_update_variable(element, value) {
  element.setAttribute("variable", value);
}