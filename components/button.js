function buttonPressed(button) {
  var request = new XMLHttpRequest();
  request.open("POST", "/event", true);
  var body = "event=" + encodeURIComponent(button.getAttribute("event"));
  var variable = button.getAttribute("variable");
  if (variable != null) {
    body += "&variable=" + encodeURIComponent(variable);
  }
  request.send(body);
}