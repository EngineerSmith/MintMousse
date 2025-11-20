function list_new(payload) {
  const id = payload.id;
  const parentID = payload.parentID;
  const isNumbered = Boolean(payload.isNumbered ?? false);

  const listGroup = document.createElement("ul");
  listGroup.classList.add("list-group");
  listGroup.setAttribute("id", id)

  if (isNumbered === true)
    listGroup.classList.add("list-group-numbered");

  const parent = document.getElementById(parentID);
  if (parent && parent.classList.contains("card"))
    listGroup.classList.add("list-group-flush")

  return listGroup;
}

function list_update_isNumbered(payload) {
  const id = payload.id;
  const isNumbered = Boolean(payload.isNumbered ?? false);

  const listGroup = document.getElementById(id);
  if (isNumbered === true) {
    listGroup.classList.add("list-group-numbered");
  } else {
    listGroup.classList.remove("list-group-numbered");
  }
}

function list_insert(payload) {
  const id = payload.parentID;
  const childID = id + "-" + payload.id;

  const listItem = document.createElement("li");
  listItem.classList.add("list-group-item", "d-flex");
  listItem.setAttribute("id", childID);

  insertPayload(listItem, payload);

  const listGroup = document.getElementById(id);
  listGroup.append(listItem);

  eventInit();
}

function list_remove_child(payload) {
  const id = payload.parentID;
  const childID = id + "-" + payload.id;

  const listItem = document.getElementById(childID);
  removeElement(listItem);
}