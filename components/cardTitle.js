componentRegistry.register({
  typeName: "CardTitle",
  create: function(payload) {
    const instance = helper.prepareInstance(payload.id, this.typeName, payload.parentID);

    const root = document.createElement("h4");
    root.className = "card-title";

    instance.element = root;

    this.update_text(payload);

    return instance;
  },

  update_text: function(instance, payload){
    const text = helper.getText(payload.values.text);

    instance.element.innerHTML = text;
    instance.element.hidden = !text;
  },

});