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

// function card_update_size(element, value) { // removed due to being buggy with the grid system, kept for reference
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

function setCardText(textElement, value) {
  if (textElement) {
    textElement.textContent = value;
    setElementVisiblity(element, value);
  }
}

function card_update_imgTop(element, value) {
  const imgTop = element.querySelector('.card-img-top');
  if (value) {
    if (!imgTop) {
      imgTop = document.createElement("img");
      imgTop.classList.add("card-img-top");
      imgTop.src = value;
      const header = element.querySelector('.card-header');
      if (header)
        element.insertAfter(imgTop, header);
      else
        element.append(imgTop);
    }
    imgTop.src = value;
  } else if (imgTop)
    imgTop.remove();
}

function card_update_imgBottom(element, value) {
  const imgBottom = element.querySelector('.card-img-bottom');
  if (value) {
    if (!imgBottom) {
      imgBottom = document.createElement("img");
      imgBottom.classList.add("card-img-bottom");
      const footer = element.querySelector('.card-footer');
      if (footer)
        element.insertBefore(imgBottom, footer);
      else
        element.append(imgBottom);
    }
    imgBottom.src = value;
  } else if (imgBottom)
    imgBottom.remove();
}

function card_update_header(element, value) {
  const header = element.querySelector('.card-header');
  const isTitle = element.dataset.headerTitle == "true" ? "h4" : "div";

  if (value) {
    if (header)
      header.textContent = value;
    else {
      const header = document.createElement(isTitle);
      header.classList.add("card-header");
      header.textContent = value;
      element.prepend(header);
    }
  } else if (header)
    header.remove();
}

function card_update_footer(element, value) {
  const footer = element.querySelector('.card-footer');
  const isSmall = element.dataset.smallFooter == "true"

  if (value) {
    if (footer) {
      if (isSmall)
        footer.querySelector('.text-body-secondary').textContent = value;
      else
        footer.textContent = value;
    } else {
      const footer = document.createElement("div");
      footer.classList.add("card-footer");
      if (isSmall) {
        const small = document.createElement("small");
        small.classList.add("text-body-secondary");
        small.textContent = value;
        footer.append(small);
      } else
        footer.textContent = value;
      element.append(footer);
    }
  } else if (footer)
    footer.remove();
}
