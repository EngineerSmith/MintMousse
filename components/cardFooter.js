function cardFooter_new(payload) {
  const id = payload.id;
  const text = getText(payload.text);
  const isTransparent = Boolean(payload.isTransparent ?? false);

  const footer = document.createElement("div")
  footer.classList.add("card-footer", "text-body-secondary");
  if (isTransparent)
    footer.classList.add("bg-transparent");

  footer.setAttribute("id", id);
  footer.innerHTML = text;
  footer.hidden = text === null;

  return footer
}

function cardFooter_update_text(payload) {
  const id = payload.id;
  const text = getText(payload.text);

  const footer = document.getElementById(id);
  footer.innerHTML = text;
  footer.hidden = text === null;
}

function cardFooter_update_isTransparent(payload) {
  const id = payload.id;
  const isTransparent = Boolean(payload.isTransparent ?? false);

  const footer = document.getElementById(id);
  if (isTransparent) {
    footer.classList.add("bg-transparent");
  } else {
    footer.classList.remove("bg-transparent");
  }
}