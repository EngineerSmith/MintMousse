componentRegistry.register({
  typeName: "ButtonGroup",
  create: function(payload) {
    const instance = helper.prepareInstance(payload.id, this.typeName, payload.parentID);

    const root = document.createElement("div");
    root.className = "btn-group";
    root.setAttribute("type", "group");

    instance.element = root;

    return instance;
  },

  insert: (parentInstance, payload) => helper.insertNewChild(parentInstance, payload),

});