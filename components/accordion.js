function accordion_new(payload) {
  const id = payload.id;

  const accordion = document.createElement("div");
  accordion.classList.add("accordion");
  accordion.setAttribute("id", id);

  return accordion;
}

function accordion_insert(payload) {
  const id = payload.parentID;
  const childID = id + "-" + payload.id;
  const childTitleID = childID + "-title";
  const childContainerID = childID + "-container";
  const childTitle = getText(payload.title) ?? "UNKNOWN TITLE"; // todo if update_child_(%S*); add to insert payload

  const accordionItem = document.createElement("div");
  accordionItem.classList.add("accordion-item");
  accordionItem.setAttribute("id", childID);

  const title = document.createElement("h2");
  title.classList.add("accordion-header");

  const button = document.createElement("button");
  button.classList.add("accordion-button", "collapsed");
  setAttributes(button, {
    "id": childTitleID,
    "type": "button",
    "data-bs-toggle": "collapse",
    "data-bs-target": "#" + childContainerID,
    "aria-controls": childContainerID,
  });
  button.innerHTML = childTitle;

  title.append(button)

  const childContainer = document.createElement("div");
  childContainer.classList.add("accordion-collapse", "collapse");
  setAttributes(childContainer, {
    "id": childContainerID,
    "data-bs-parent": "#" + id,
  });

  const childBody = document.createElement("div");
  childBody.classList.add("accordion-body")

  childContainer.append(childBody);

  accordionItem.append(title, childContainer);

  insertPayload(childBody, payload);

  const accordion = document.getElementById(id);
  accordion.append(accordionItem);

  eventInit();
}

function accordion_update_child_title(payload) {
  const id = payload.parentID;
  const childID = id + "-" + payload.id;
  const childTitleID = childID + "-title";
  const childTitle = getText(payload.title) ?? "UNKNOWN TITLE";

  const button = document.getElementById(childTitleID);
  button.innerHTML = childTitle;
}

function accordion_remove_child(payload) {
  const id = payload.parentID;
  const childID = id + "-" + payload.id;

  const accordionItem = document.getElementById(childID);
  removeElement(accordionItem);
}