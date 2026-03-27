componentRegistry.register({
  typeName: "Text",
  create: function(payload) {
    const instance = helper.prepareInstance(payload.id, this.typeName, payload.parentID);

    instance.element = document.createElement("p");

    this.update_text(payload);
    this.update_isCentered(payload);

    return instance;
  },
  update_text: (instance, payload) => instance.element.innerHTML = helper.getText(payload.values.text, ""),
  update_isCentered:
    (instance, payload) => instance.element.classList.toggle("text-center", helper.getBoolean(payload.values.isCentered)),
});