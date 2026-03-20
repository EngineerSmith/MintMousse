componentRegistry.register({
  typeName: "Accordion",
  create: function(payload) {
    const instance = helper.prepareInstance(payload.id, this.typeName, payload.parentID);

    const root = document.createElement("div");
    root.id = payload.id;
    root.className = "accordion";

    instance.parts.wrappers = new Map();
    instance.parts.titles = new Map();

    instance.element = root;

    return instance;
  },

  insert: function(instance, payload) {
    const childComponent = componentRegistry[payload.childType];
    if (!childComponent) return;

    const wrapper = this._createAccordionWrapper(instance, payload);
    const body = wrapper.querySelector(".accordion-body");

    const childInstance = childComponent.create(payload);
    body.append(childInstance.element);

    const children = instance.children;
    const targetIndex = helper.getIntInRange(payload.childPosition, 1, children.length + 1, children.length + 1) - 1;
    children.splice(targetIndex, 0, childInstance);

    instance.parts.wrappers.set(payload.id, wrapper);

    if (targetIndex >= children.length - 1) {
      instance.element.append(wrapper);
    } else {
      const neighborID = children[targetIndex + 1].id;
      const neighborWrapper = instance.parts.wrappers.get(neighborID);
      neighborWrapper.before(wrapper);
    }
  },

  _createAccordionWrapper: function(instance, payload) {
    const childID = `${instance.id}-${payload.id}`
    const containerID = `${childID}-container`;

    const item = document.createElement("div");
    item.className = "accordion-item";

    const header = document.createElement("h2");
    header.className = "accordion-header";

    const button = document.createElement("button");
    button.className = "accordion-button collapsed";
    helper.setAttributes(button, {
      "type": "button",
      "data-bs-toggle": "collapse",
      "data-bs-target": `#${containerID}`,
      "aria-expanded": "false",
      "aria-controls": containerID,
    });
    button.innerHTML = helper.getText(payload.values.title, "Untitled");

    instance.parts.titles.set(payload.id, button);

    const collapse = document.createElement("div");
    collapse.id = containerID;
    collapse.className = "accordion-collapse collapse";
    collapse.setAttribute("data-bs-parent", `#${instance.id}`);

    const body = document.createElement("div");
    body.className = "accordion-body";

    collapse.append(body);
    header.append(button);
    item.append(header, collapse);

    return item;
  },

  reorderChildren: function(instance, payload) {
    const oldChildren = instance.children;
    const newIndices = payload.newOrder;

    if (!Array.isArray(newIndices)) return;

    const newChildren = newIndices.map(pos => {
      const oldIndex = helper.getIntInRange(pos, 1, oldChildren.length) - 1;
      return oldChildren[oldIndex];
    });
    instance.children = newChildren;

    const wrappersToAppend = newChildren
      .map(child => instance.parts.wrappers.get(child.id))
      .filter(Boolean);

    instance.element.replaceChildren(...wrappersToAppend);
  },

  moveChild: function(instance, payload) {
    const children = instance.children;
    const oldIndex = helper.getIntInRange(payload.oldIndex, 1, children.length) - 1;
    const newIndex = helper.getIntInRange(payload.newIndex, 1, children.length) - 1;

    if (oldIndex === newIndex) return;

    const [movingChild] = children.splice(oldIndex, 1);
    children.splice(newIndex, 0, movingChild);

    const movingWrapper = instance.parts.wrappers.get(movingChild.id);

    if (newIndex >= children.length - 1) {
      instance.element.append(movingWrapper);
    } else {
      const neighborID = children[newIndex + 1].id;
      const neighborWrapper = instance.parts.wrappers.get(neighborID);
      neighborWrapper.before(movingWrapper);
    }
  },

  remove_child: function(instance, childInstance) {
    const wrapper = instance.parts.wrappers.get(childInstance.id);
    wrapper?.remove()

    instance.parts.wrappers.delete(childInstance.id);
    instance.parts.titles.delete(childInstance.id);
  },

  update_child_title: function(instance, payload) {
    const button = instance.parts.titles.get(payload.id);
    if (button) {
      button.innerHTML = helper.getText(payload.values.title, "Untitled");
    }
  },

});