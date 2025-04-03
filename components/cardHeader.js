function cardHeader_new(payload) {
  const id = payload.id;
  const text = String(payload.text);
  const isTransparent = Boolean(payload.isTransparent);

  const header = document.createElement("h4");
  header.classList.add("card-header");
  if (isTransparent === true)
    header.classList.add("bg-transparent");

  header.setAttribute("id", id);
  header.textContent = text;

  return header;
}

function cardHeader_update_text(payload) {
  const id = payload.id;
  const text = String(payload.text);

  const header = document.getElementById(id);
  header.textContent = text;
}

function cardHeader_update_isTransparent(payload) {
  const id = payload.id;
  const isTransparent = Boolean(payload.isTransparent);

  const header = document.getElementById(id);
  if (isTransparent === true) {
    header.classList.add("bg-transparent");
  } else {
    header.classList.remove("bg-transparent");
  }
}
