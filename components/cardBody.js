componentRegistry.register({
  typeName: "CardBody",
  create: function(payload) {
    const instance = helper.prepareInstance(payload.id, this.typeName, payload.parentID);

    const root = document.createElement("div");
    root.className = "card-body";

    instance.element = root;

    return instance;
  },

  insert: (parentInstance, payload) => helper.insertNewChild(parentInstance.element, payload),

});