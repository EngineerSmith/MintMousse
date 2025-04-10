function cardHeader_new(payload) {
  const id = payload.id;
  const text = getText(payload.text);
  const isTransparent = Boolean(payload.isTransparent ?? false);

  const header = document.createElement("h4");
  header.classList.add("card-header");
  if (isTransparent === true)
    header.classList.add("bg-transparent");

  header.setAttribute("id", id);
  header.innerHTML = text;
  header.hidden = text === null;

  return header;
}

function cardHeader_update_text(payload) {
  const id = payload.id;
  const text = getText(payload.text);

  const header = document.getElementById(id);
  header.innerHTML = text;
  header.hidden = text === null;
}

function cardHeader_update_isTransparent(payload) {
  const id = payload.id;
  const isTransparent = Boolean(payload.isTransparent ?? false);

  const header = document.getElementById(id);
  if (isTransparent === true) {
    header.classList.add("bg-transparent");
  } else {
    header.classList.remove("bg-transparent");
  }
}
