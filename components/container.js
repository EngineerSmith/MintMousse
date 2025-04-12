function container_new(payload) {
  const id = payload.id;

  const container = document.createElement("div");
  container.setAttribute("id", id);

  return container;
}

function container_insert(payload) {
  const id = payload.parentID;
  
  const container = document.getElementById(id);
  insertPayload(container, payload);

  eventInit();
}