function card_getSizeClass(element) {
  if (!element)
    return null;

  for (const className of element.classList) {
    if (/^grid-item-[1-5]$/.test(className))
      return className;
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
  const borderColor = BSColor(payload.borderColor);
  const titleText = getText(payload.title);
  const text = getText(payload.text);

  const container = document.createElement("div");
  container.classList.add("grid-item", newSize);
  container.setAttribute("id", id + "-root");

  const card = document.createElement("div");
  card.classList.add("card");
  if (bgColor !== null)
    card.classList.add("text-bg-" + bgColor);
  if (isContentCenter)
    card.classList.add("text-center");
  if (borderColor !== null)
    card.classList.add("border-" + borderColor);
  card.setAttribute("id", id);

  const body = document.createElement("div");
  body.classList.add("card-body");
  body.setAttribute("id", id + "-body");

  const title = document.createElement("h4");
  title.classList.add("card-title")
  title.setAttribute("id", id + "-title");
  title.textContent = titleText;
  title.hidden = titleText === null;

  const p = document.createElement("p");
  p.classList.add("card-text");
  p.setAttribute("id", id + "-text");
  p.textContent = text;
  p.hidden = text === null;

  body.append(title, p);
  body.hidden = title.hidden && p.hidden;

  card.append(body);
  container.append(card);

  return container;
}

function card_insert(payload) {
  const id = payload.parentID;

  const card = document.getElementById(id);
  const element = insertPayload(card, payload);
  
  const currentBorderColor = getColorClass(card, "border-");
  if (currentBorderColor !== null && element !== null && (
    element.classList.contains("card-header") || element.classList.contains("card-footer")
  )) {
    const elementBorderColor = getColorClass(element, "border-");
    if (element !== null)
      element.classList.remove(elementBorderColor);
    element.classList.add(currentBorderColor);
  }

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

function card_update_borderColor(payload) {
  const id = payload.id;
  const borderColor = BSColor(payload.borderColor);

  const card = document.getElementById(id);
  const currentBorderColor = getColorClass(card, "border-");
  if (currentBorderColor !== null)
    card.classList.remove(currentBorderColor);
  if (borderColor !== null)
    card.classList.add("border-" + borderColor);

  for (const child of card.children) {
    if (child.classList.contains("card-header") || child.classList.contains("card-footer")) {
      const childBorderColor = getColorClass(child, "border-");
      if (childBorderColor !== null)
        child.classList.remove(childBorderColor);
      if (borderColor !== null)
        child.classList.add("border-" + borderColor);
    }
  }
}

function card_update_title(payload) {
  const id = payload.id;
  const titleText = getText(payload.title);

  const title = document.getElementById(id + "-title")
  title.textContent = titleText;
  title.hidden = titleText === null;

  const body = document.getElementById(id + "-body");
  const p = document.getElementById(id + "-text");
  body.hidden = title.hidden && p.hidden
}

function card_update_text(payload) {
  const id = payload.id;
  const text = getText(payload.text);

  const p = document.getElementById(id + "-text");
  p.textContent = text;
  p.hidden = text === null;

  const body = document.getElementById(id + "-body");
  const title = document.getElementById(id + "-title");
  body.hidden = title.hidden && p.hidden;
}