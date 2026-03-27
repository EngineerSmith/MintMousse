componentRegistry.register({
  typeName: "Row",
  create: function(payload) {
    const instance = helper.prepareInstance(payload.id, this.typeName, payload.parentID);

    const root = document.createElement("div");
    root.className = "row g-2";

    instance.element = root;
    instance.parts.wrappers = new Map();

    return instance;
  },

  insert: function(instance, payload) {
    const childComponent = componentRegistry[payload.childType];
    if (!childComponent) return;

    const wrapper = document.createElement("div");
    this._applyColumnWidth(wrapper, payload.values.columnWidth);
    instance.parts.wrappers.set(payload.id, wrapper);

    const childInstance = childComponent.create(payload);
    wrapper.append(childInstance.element);

    const children = instance.children;
    const targetIndex = helper.getIntInRange(payload.childPosition, 1, children.length + 1, children.length + 1) - 1;
    children.splice(targetIndex, 0, childInstance);
    if (targetIndex >= children.length - 1) {
      instance.element.append(wrapper);
    } else {
      const neighborID = children[targetIndex + 1].id;
      const neighborWrapper = instance.parts.wrappers.get(neighborID);
      neighborWrapper.before(wrapper);
    }
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
    wrapper?.remove();
    instance.parts.wrappers.delete(childInstance.id);
  },

  _applyColumnWidth: function(element, widthValue) {
    const width = helper.getIntInRange(widthValue, 1, 12, null);

    element.className = element.className
      .replace(/\bcol-md-\S+/g, "")
      .replace(/\bcol-md\b/g, "")
      .trim();

    if (width) {
      element.classList.add(`col-md-${width}`);
    } else {
      element.classList.add("col-md");
    }
  },

  update_child_columnWidth: function(instance, payload) {
    const wrapper = instance.parts.wrappers.get(payload.id);
    if (wrapper) {
      this._applyColumnWidth(wrapper, payload.values.columnWidth);
    }
  },

});