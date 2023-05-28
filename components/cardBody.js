function setVisible(element) {
  element.classList.remove('invisible');
}

function updateBody(cardElement) {
  // elements within body
  const titleElement = cardElement.querySelector('.card-title');
  if (!titleElement.classList.contains('invisible'))
    return setVisible(cardElement);
  const textElement = cardElement.querySelector('.card-text');
  if (!textElement.classList.contains('invisible'))
    return setVisible(cardElement);
  const subtextElement = cardElement.querySelector('.text-body-secondary');
  if (!subtextElement.classList.contains('invisible'))
    return setVisible(cardElement);
  //todo check children for visiblity
  cardElement.classList.add('invisible');
}

function setCardBodyText(textElement, value, cardElement) {
  if (textElement) {
    textElement.textContent = value;
    if (value) {
      textElement.classList.remove('invisible');
    } else {
      textElement.classList.add('invisible');
    }
    updateBody(cardElement);
  }
}

function cardBody_update_title(element, value) {
  setCardBodyText(element.querySelector('.card-title'), value, element);
}

function cardBody_update_text(element, value) {
  setCardBodyText(element.querySelector('.card-text'), value, element);
}

function cardBody_update_subtext(element, value) {
  const subtextElement = element.querySelector('.text-body-secondary');
  if (subtextElement) {
    subtextElement.textContent = value;
    if (value) {
      subtextElement.parentNode.classList.remove('invisible');
    } else {
      subtextElement.parentNode.classList.add('invisible');
    }
    updateBody(element);
  }
}