function cardTitle_new(payload) {
  const id = payload.id;
  const text = getText(payload.text);

  const title = document.createElement("h4");
  title.classList.add("card-title");
  title.setAttribute("id", id);
  title.innerHTML = text;
  title.hidden = text === null;

  return title;
}

function cardTitle_update_text(payload) {
  const id = payload.id;
  const text = getText(payload.text);

  const title = document.getElementById(id);
  title.innerHTML = text;
  title.hidden = text === null;
}