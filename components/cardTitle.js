function cardTitle_new(payload) {
  const id = payload.id;
  const text = String(payload.text);

  const header = document.createElement("h4");
  header.classList.add("card-title");
  header.setAttribute("id", id);
  header.textContent = text;

  return header;
}

function cardTitle_update_text(payload) {
  const id = payload.id;
  const text = String(payload.text);

  const header = document.getElementById(id);
  header.textContent = text;
}