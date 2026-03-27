componentRegistry.register({
  typeName: "HorizontalRule",
  create: function(payload) {
    const instance = helper.prepareInstance(payload.id, this.typeName, payload.parentID);

    instance.element = document.createElement("hr");

    this.update_color(payload);
    this.update_margin(payload);

    return instance;
  },

  _updateVisuals: function(instance) {
    const { element, state } = instance;

    let classes = [];
    if (state.color) classes.push("border", "border-2", `border-${state.color}`);
    if (state.margin) classes.push(`my-${state.margin}`);

    element.className = classes.join(" ");
  },

  update_color: function(instance, payload) {
    instance.state.color = helper.getColor(payload.values.color);
    this._updateVisuals(instance);
  },

  update_margin: function(instance, payload) {
    instance.state.margin = helper.getIntInRange(payload.values.margin, 0, 5, null);
    this._updateVisuals(instance);
  },

});