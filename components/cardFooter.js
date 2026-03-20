componentRegistry.register({
  typeName: "CardFooter",
  create: function(payload) {
    const instance = helper.prepareInstance(payload.id, this.typeName, payload.parentID);

    const root = document.createElement("div");
    root.className = "card-footer text-body-secondary";

    instance.element = root;

    this.update_text(payload);
    this.update_isTransparent(payload);

    return instance;
  },

  update_text: function(instance, payload){
    const text = helper.getText(payload.values.text);

    instance.element.innerHTML = text;
    instance.element.hidden = !text;
  },

  update_isTransparent: function(instance, payload) {
    const isTransparent = helper.getBoolean(payload.values.isTransparent, false);
    instance.element.classList.toggle("bg-transparent", isTransparent);
  },

});