function button_new(payload) {
  const id = payload.id;
  const color = BSColor(payload.color) ?? "primary";
  const colorOutline = Boolean(payload.colorOutline ?? false);
  const text = getText(payload.text) ?? "";
  const isDisabled = Boolean(payload.disable ?? false);
  const widthClass = "w-" + (BSWidth(payload.width) ?? "100");
  const center = Boolean(payload.center ?? true);

  const colorClass = colorOutline ? "btn-outline-" + color : "btn-" + color

  const button = document.createElement("button");
  button.classList.add("btn", colorClass, widthClass, "d-block"); // est: d-block won't work work buttongroups 
  if (center === true) {
    button.classList.add("mx-auto");
  }
  setAttributes(button, {
    "id": id,
    "type": "button",
  });
  button.dataset.mmColor = color;
  button.dataset.mmColorOutline = colorOutline ? "true" : "false";
  button.innerHTML = text;
  button.disabled = isDisabled;

  button.addEventListener('click', button_event_click);

  return button;
}

function button_update_color(payload) {
  const id = payload.id;
  const color = BSColor(payload.color) ?? "primary";

  const button = document.getElementById(id);
  const colorOutline = button.dataset.mmColorOutline === "true";

  let currentColor;
  if (colorOutline === true) {
    currentColor = getColorClass(button, "btn-outline-");
  } else {
    currentColor = getColorClass(button, "btn-");
  }
  if (currentColor !== null)
    button.classList.remove(currentColor);

  const colorClass = colorOutline ? "btn-outline-" + color : "btn-" + color
  button.classList.add(colorClass);
  button.dataset.mmColor = color;
}

function button_update_colorOutline(payload) {
  const id = payload.id;
  const colorOutline = Boolean(payload.colorOutline ?? false);

  const button = document.getElementById(id);

  let currentColor;
  if (button.dataset.mmColorOutline === "true") {
    currentColor = getColorClass(button, "btn-outline-");
  } else {
    currentColor = getColorClass(button, "btn-");
  }
  if (currentColor !== null)
    button.classList.remove(currentColor);

  const color = button.dataset.mmColor;
  const colorClass = colorOutline ? "btn-outline-" + color : "btn-" + color;
  button.classList.add(colorClass);
  button.dataset.mmColorOutline = colorOutline;
}

function button_update_text(payload) {
  const id = payload.id;
  const text = getText(payload.text) ?? "";

  const button = document.getElementById(id);
  button.innerHTML = text;
}

function button_update_disable(payload) {
  const id = payload.id;
  const isDisabled = Boolean(payload.disable ?? false);

  const button = document.getElementById(id);
  button.disable = isDisabled;
}

function button_update_width(payload) {
  const id = payload.id;
  const widthClass = "w-" + (BSWidth(payload.width) ?? "100");

  const button = document.getElementById(id);
  const currentWidthClass = getClassWithPrefix(button, "w-");

  if (widthClass === currentWidthClass) {
    return;
  }

  if (currentWidthClass)
    button.classList.remove(currentWidthClass);
  button.classList.add(widthClass);
}

function button_update_center(payload) {
  const id = payload.id;
  const center = Boolean(payload.center ?? true);

  const button = document.getElementById(id);
  if (center === true) {
    button.classList.add("mx-auto");
  } else {
    button.classList.remove("mx-auto");
  }
}

function button_event_click(event) {
  const id = event.currentTarget.id;
  const success = websocketSend({
    id: id,
    event: "click",
  });
  if (!success) {
    console.warn("MM: Button event triggered; but failed to send.")
  }
}