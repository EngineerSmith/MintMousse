function text_update_text(payload) {
  const id = payload.id;
  const text = getText(payload.text) ?? "";

  const p = document.getElementById(id);
  p.innerHTML = text;
}