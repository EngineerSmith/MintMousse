function setCardBodyText(textElement, value, cardElement) {
  if (textElement) {
    textElement.textContent = value;
    if (value) {
      textElement.classList.remove('invisible');
    } else {
      textElement.classList.add('invisible');
    }
  }
}

function cardBody_update_title(element, value) {
  var titleElement = element.querySelector('.card-title');
  if (value) {
    if (!titleElement) {
      titleElement = document.createElement("h5");
      titleElement.classList.add("card-title");
      titleElement.textContent = value;
      element.prepend(titleElement);
    }
    titleElement.textContent = value;
  } else if (titleElement)
    titleElement.remove();
}

function cardBody_update_text(element, value) {
  var textElement = element.querySelector('.card-text');
  if (value) {
    if (!textElement) {
      textElement = document.createElement("p");
      textElement.classList.add("card-text");
      const titleElement = element.querySelector('.card-title');
      if (titleElement)
        element.insertAfter(textElement, titleElement);
      else
        element.prepend(textElement);
    }
    textElement.textContent = value;
  } else if (textElement)
    textElement.remove();
}

function cardBody_update_subtext(element, value) {
  var subtextElement = element.querySelector('.text-body-secondary');
  if (value) {
    if (!subtextElement) {
      const textElement = document.createElement("p");
      textElement.classList.add("card-text");
      subtextElement = document.createElement("small");
      subtextElement.classList.add("text-body-secondary");
      textElement.append(subtextElement);
      element.append(textElement);
    }
    subtextElement.textContent = value;
  } else if (subtextElement)
    subtextElement.parentNode.remove();
}