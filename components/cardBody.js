function cardBody_new(payload) {
  const id = payload.id;

  const body = document.createElement("div");
  body.classList.add("card-body");
  body.setAttribute("id", id);

  return body
}

function cardBody_insert(payload) {
  const id = payload.parentID;

  const body = document.getElementById(id);
  insertPayload(body, payload);

  eventInit();
}