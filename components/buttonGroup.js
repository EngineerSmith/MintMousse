function buttonGroup_new(payload) {
  const id = payload.id;

  const buttonGroup = document.createElement("div");
  buttonGroup.classList.add("btn-group");
  setAttributes(buttonGroup, {
    "id": id,
    "role": "group",
  });

  return buttonGroup;
}

function buttonGroup_insert(payload) {
  const id = payload.parentID;

  const buttonGroup = document.getElementById(id);
  insertPayload(buttonGroup, payload);

  eventInit();
}