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
  const bgColor = BSColor(payload.color);
  const isContentCenter = Boolean(payload.isContentCenter) === true;

  const container = document.createElement("div");
  container.classList.add("grid-item", newSize);
  container.setAttribute("id", id + "-root");

  const card = document.createElement("div");
  card.classList.add("card");
  if (bgColor)
    card.classList.add("text-bg-" + bgColor);
  if (isContentCenter)
    card.classList.add("text-center");

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

function card_update_color(payload) {
  const id = payload.id;
  const bgColor = BSColor(payload.color);

  const card = document.getElementById(id);
  const currentBGColor = getColorClass(card, "text-bg-");
  if (currentBGColor)
    card.classList.remove(currentBGColor);
  if (bgColor)
    card.classList.add("text-bg-" + bgColor);
}

function card_update_isContentCenter(payload) {
  const id = payload.id;
  const isContentCenter = Boolean(payload.isContentCenter) === true;

  const card = document.getElementById(id);
  if (isContentCenter) {
    card.classList.remove("text-center");
  } else {
    card.classList.add("text-center");
  }
}