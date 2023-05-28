function getSizeClass(element) {
  const classList = element.classList;
  if (classList.contains('grid-item-1'))
    return 'grid-item-1';
  if (classList.contains('grid-item-2'))
    return 'grid-item-2';
  if (classList.contains('grid-item-3'))
    return 'grid-item-3';
  if (classList.contains('grid-item-4'))
    return 'grid-item-4';
  if (classList.contains('grid-item-5'))
    return 'grid-item-5';
  return null;
}

// function card_update_size(element, value) { // removed due to being buggy with the grid system, kept for the future
//   element = element.parentNode;
//   const sizeClass = getSizeClass(element);
//   const size = sizeClass ? parseInt(sizeClass.slice(9)) : null;
//   if (size == value) 
//     return;

//   element.classList.remove(sizeClass);
//   if (value)
//     element.classList.add('grid-item-' + value);
// }

function setElementVisiblity(element, bool) {
  if (bool) {
    element.classList.remove('invisible');
  } else {
    element.classList.add('invisible');
  }
}

function setElementImageSrc(element, imageSrc) {
  if (element) {
    element.src = imageSrc;
    setElementVisiblity(element, imageSrc);
  }
}

function card_update_imgTop(element, value) {
  element = element.querySelector('.card-img-top');
  setElementImageSrc(element, value);
}

function card_update_imgBottom(element, value) {
  element = element.querySelector('.card-img-bottom');
  setElementImageSrc(element, value);
}

function setCardText(textElement, value) {
  if (textElement) {
    textElement.textContent = value;
    setElementVisiblity(element, value);
  }
}

function card_update_header(element, value) {
  setCardText(element.querySelector('.card-header'), value);
}

function card_update_footer(element, value) {
  setCardText(element.querySelector('.card-footer'), value);
}
