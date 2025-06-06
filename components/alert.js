function alert_new(payload) {
  const id = payload.id;
  const pID = id + "-p";
  const buttonID = id + "-button";
  const text = getText(payload.text) ?? "UNKNOWN";
  const alertColor = BSColor(payload.color) ?? "warning";
  const dismissible = Boolean(payload.dismissible ?? true);

  const alert = document.createElement("div");
  alert.classList.add("alert", "fade", "show", "alert-" + alertColor);
  if (dismissible === true) {
    alert.classList.add("alert-dismissible");
  }
  setAttributes(alert, {
    "id": id,
    "role": "alert",
  });

  const p = document.createElement("p");
  p.classList.add("mb-0")
  p.setAttribute("id", pID);
  p.innerHTML = text;

  alert.append(p);

  if (dismissible === true) {
    const dismissButton = document.createElement("button");
    dismissButton.classList.add("btn-close");
    setAttributes(dismissButton, {
      "id": buttonID,
      "type": "button",
      "data-bs-dismiss": "alert",
      "aria-label": "Close",
    });

    alert.append(dismissButton);
  }

  if (typeof payload.parentID === "string") {
    const hyphenIndex = payload.parentID.indexOf("-");
    if (hyphenIndex !== -1) {
      const type = payload.parentID.substring(0, hyphenIndex);
      const type_remove_child = window[type + "_remove_child"];
      if (typeof type_remove_child === "function") {
        alert.addEventListener("closed.bs.alert", () => {
          type_remove_child(payload); // payload is reused than creating an object with parentID & id
        });
      }
    }
  }

  return alert;
}

function alert_update_text(payload) {
  const id = payload.id;
  const pID = id + "-p";
  const text = getText(payload.text) ?? "UNKNOWN";

  const alert = document.getElementById(id);
  if (alert === null) {
    console.log("MM: Tried to update alert that has been dismissed:", id, "TEXT to:", text)
    return; // todo Element has been dismissed by user - should it recreate the alert on update?
  }

  const p = document.getElementById(pID);
  p.innerHTML = text;
}

function alert_update_color(payload) {
  const id = payload.id;
  const color = BSColor(payload.color) ?? "warning";

  const alert = document.getElementById(id);
  if (alert === null) {
    console.log("MM: Tried to update alert that has been dismissed:", id, "COLOR to:", color);
    return; // todo Element has been dismissed by user - should it recreate the alert on update?
  }

  const currentColor = getColorClass(alert, "alert-");
  if (currentColor)
    alert.classList.remove(currentColor);
  alert.classList.add("alert-" + color);
}

function alert_update_dismissible(payload) {
  const id = payload.id;
  const buttonID = id + "-button";
  const dismissible = Boolean(payload.dismissible ?? true);

  const alert = document.getElementById(id);
  if (alert === null) {
    console.log("MM: Tried to update alert that has been dismissed:", id, "DISMISSIBLE to:", dismissible);
    return; // todo Element has been dismissed by user - should it recreate the alert on update?
  }

  let dismissButton = document.getElementById(buttonID);
  if ((dismissible === true && dismissButton !== null) || (dismissible === false && dismissButton === null)) {
    return;
  }

  if (dismissible === true) {
    dismissButton = document.createElement("button");
    dismissButton.classList.add("btn-close");
    setAttributes(dismissButton, {
      "id": buttonID,
      "type": "button",
      "data-bs-dismiss": "alert",
      "aria-label": "Close",
    });

    alert.append(dismissButton);

  } else if (dismissible === false) {
    removeElement(dismissButton);
  }
}

function alert_remove(payload) {
  const id = payload.id;

  const alert = document.getElementById(id);
  if (alert !== null) { // Alert could of been dismissed by user
    removeElement(alert);
  }
}