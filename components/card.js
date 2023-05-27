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

// function card_update_size(element, value) {
//   element = element.parentNode;
//   const sizeClass = getSizeClass(element);
//   const size = sizeClass ? parseInt(sizeClass.slice(9)) : null;
//   if (size == value) 
//     return;

//   element.classList.remove(sizeClass);
//   if (value)
//     element.classList.add('grid-item-' + value);
// }

function card_update_title(element, value) {
  element = element.querySelector('.card-title');
  if (element)
    element.textContent = value;
}

function card_update_text(element, value) {
  element = element.querySelector('.card-text');
  if (element)
    element.textContent = value;
}

function card_update_subtext(element, value) {
  element = element.querySelector('.text-body-secondary');
  if (element)
    element.textContent = value;
}

function card_update_imgTop(element, value) {
  element = element.querySelector('.card-img-top');
  if (element)
    element.src = "data:image/" + value;
}

function card_update_imgBottom(element, value) {
  element = element.querySelector('.card-img-bottom');
  if (element)
    element.src = "data:image/" + value;
}