componentRegistry.register({
  typeName: "List",
  create: function(payload) {
    const instance = helper.prepareInstance(payload.id, this.typeName, payload.parentID);

    instance.state.isNumbered = helper.getBoolean(payload.values.isNumbered, false);

    const root = document.createElement("ul");
    root.className = "list-group";

    instance.element = root;
    instance.parts.wrappers = new Map();

    this._updateVisuals(instance);

    return instance;
  },

  insert: function(instance, payload) {
    const childComponent = componentRegistry[payload.childType];
    if (!childComponent) return;

    const listItem = document.createElement("li");
    listItem.className = "list-group-item d-flex";
    instance.parts.wrappers.set(payload.id, listItem);

    const childInstance = childComponent.create(payload);
    listItem.append(childInstance.element);

    const children = instance.children;
    const targetIndex = helper.getIntInRange(payload.childPosition, 1, children.length + 1, children.length + 1) - 1;
    children.splice(targetIndex, 0, childInstance);

    if (targetIndex >= children.length - 1) {
      instance.element.append(listItem);
    } else {
      const neighborID = children[targetIndex + 1].id;
      const neighborWrapper = instance.parts.wrappers.get(neighborID);
      neighborWrapper.before(listItem);
    }
  },

  _updateVisuals: function(instance) {
    const { element, state, parentID } = instance;

    element.classList.toggle("list-group-numbered", state.isNumbered);

    const parentInstance = helper.getInstance(parentID);
    element.classList.toggle("list-group-flush", parentInstance?.type === "Card");
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

  update_isNumbered: function(instance, payload) {
    instance.state.isNumbered = helper.getBoolean(payload.values.isNumbered, false);
    this._updateVisuals(instance);
  },
});