function getSizeClass(element) {
  if (!element) return null;

  for (const className of element.classList) {
    if (/^grid-item-[1-5]$/.test(className)) {
      return className;
    }
  }

  return null;
}

function card_update_size(payload) {
  const id = payload.id;
  const size = payload.size;
  const newSize = "grid-item-" + size;

  const element = document.getElementById(id + "-root");
  const currentSize = getSizeClass(element);

  if (newSize !== currentSize ) {
    element.classList.remove(currentSize)
    element.classList.add(newSize);

    // todo resize masonry
  }
}