function cardSubtitle_new(payload) {
  const id = payload.id;
  const text = String(payload.text);

  const header = document.createElement("h5");
  header.classList.add("card-subtitle", "text-body-secondary");
  header.setAttribute("id", id);
  header.textContent = text;

  return header;
}

function cardSubtitle_update_text(payload) {
  const id = payload.id;
  const text = String(payload.text);

  const header = document.getElementById(id);
  header.textContent = text;
}