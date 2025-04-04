function cardSubtitle_new(payload) {
  const id = payload.id;
  const text = getText(payload.text);

  const subtitle = document.createElement("h5");
  subtitle.classList.add("card-subtitle", "text-body-secondary");
  subtitle.setAttribute("id", id);
  subtitle.innerHTML = text;
  subtitle.hidden = text === null;

  return subtitle;
}

function cardSubtitle_update_text(payload) {
  const id = payload.id;
  const text = getText(payload.text);

  const subtitle = document.getElementById(id);
  subtitle.innerHTML = text;
}