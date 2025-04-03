function card_getSizeClass(element) {
  if (!element) return null;

  for (const className of element.classList) {
    if (/^grid-item-[1-5]$/.test(className)) {
      return className;
    }
  }

  return null;
}

function card_new(payload) {
  const id = payload.id;
  const sizeAsNumber = Number(payload.size);
  const size = Math.min(5, Math.max(1, isNaN(sizeAsNumber) ? 1 : sizeAsNumber));
  const newSize = "grid-item-" + size;

  const container = document.createElement("div");
  container.classList.add("grid-item", newSize);
  container.setAttribute("id", id + "-root");

  const card = document.createElement("div");
  card.classList.add("card");
  card.setAttribute("id", id);

  container.append(card);

  return container;
}

function card_insert(payload) {
  const id = payload.parentID;
  const card = document.getElementById(id);

  insertPayload(card, payload);

  eventInit();
}

function card_update_size(payload) {
  const id = payload.id;
  const sizeAsNumber = Number(payload.size);
  const size = Math.min(5, Math.max(1, isNaN(sizeAsNumber) ? 1 : sizeAsNumber));
  const newSize = "grid-item-" + size;

  const container = document.getElementById(id + "-root");
  const currentSize = card_getSizeClass(container);

  if (newSize !== currentSize ) {
    container.classList.remove(currentSize)
    container.classList.add(newSize);

     // todo could this be a targeted resize? It would requiring to know which tab this component is under
    resizeMasonry();
  }
}