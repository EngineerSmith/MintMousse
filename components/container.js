componentRegistry.register({
  typeName: "Container",
  create: function(payload) {
    const instance = helper.prepareInstance(payload.id, this.typeName, payload.parentID);

    const root = document.createElement("div");

    instance.element = root;

    return instance;
  },

  insert: (parentInstance, payload) => helper.insertNewChild(parentInstance.element, payload),
});