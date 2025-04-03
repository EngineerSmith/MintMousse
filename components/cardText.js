function cardText_new(payload) {
  const id = payload.id;
  const text = String(payload.text);

  const p = document.createElement("p");
  p.classList.add("card-text");
  p.setAttribute("id", id);
  p.textContent = text

  return p;
}

function cardText_update_text(payload) {
  const id = payload.id;
  const text = payload.text;

  const p = document.getElementById(id);
  p.textContent = text;
}