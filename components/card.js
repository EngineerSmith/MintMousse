function card_new(payload) {
  const id = payload.id;
  const bgColor = BSColor(payload.color);
  const isContentCenter = Boolean(payload.isContentCenter ?? false);
  const borderColor = BSColor(payload.borderColor);
  const titleText = getText(payload.title);
  const text = getText(payload.text);

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
  title.innerHTML = titleText;
  title.hidden = titleText === null;

  const p = document.createElement("p");
  p.classList.add("card-text");
  p.setAttribute("id", id + "-text");
  p.innerHTML = text;
  p.hidden = text === null;

  body.append(title, p);
  body.hidden = title.hidden && p.hidden;

  card.append(body);

  return card;
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
  const isContentCenter = Boolean(payload.isContentCenter ?? false);

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
  title.innerHTML = titleText;
  title.hidden = titleText === null;

  const body = document.getElementById(id + "-body");
  const p = document.getElementById(id + "-text");
  body.hidden = title.hidden && p.hidden
}

function card_update_text(payload) {
  const id = payload.id;
  const text = getText(payload.text);

  const p = document.getElementById(id + "-text");
  p.innerHTML = text;
  p.hidden = text === null;

  const body = document.getElementById(id + "-body");
  const title = document.getElementById(id + "-title");
  body.hidden = title.hidden && p.hidden;
}