componentRegistry.register({
  typeName: "Button",
  create: function(payload) {
    const instance = helper.prepareInstance(payload.id, this.typeName, payload.parentID);

    instance.state = {
      color: helper.getColor(payload.values.color, "primary"),
      colorOutline: helper.getBoolean(payload.values.colorOutline, false),
      width: helper.getWidth(payload.values.width, "100"),
      isCentered: helper.getBoolean(payload.values.isCentered, true),
    };

    const root = document.createElement("button");
    root.type = "button";
    instance.element = root;

    root.addEventListener('click', (event) => {
      this.event_click(event, instance);
    });

    this.update_text(payload);
    this._updateVisuals(instance);
    this.update_isDisabled(payload);

    return instance;
  },

  _updateVisuals: function(instance) {
    const { element, state } = instance;

    const colorPrefix = state.colorOutline ? "btn-outline" : "btn";
    const colorClass = `${colorPrefix}-${state.color}`;

    element.className = `btn ${colorClass} w-${state.width} d-block ${state.isCentered ? "mx-auto" : ""}`;
  },

  update_color: function(instance, payload) {
    instance.state.color = helper.getColor(payload.values.color, "primary");
    this._updateVisuals(instance);
  },

  update_colorOutline: function(instance, payload) {
    instance.state.colorOutline = helper.getBoolean(payload.values.colorOutline, false);
    this._updateVisuals(instance);
  },

  update_text: function(instance, payload) {
    let text = helper.getText(payload.values.text, "");
    instance.element.innerHTML = text;
  },

  update_isDisabled: (instance, payload) => instance.element.disabled = helper.getBoolean(payload.values.isDisabled, false),

  update_width: function(instance, payload) {
    instance.state.width = helper.getWidth(payload.values.width, "100");
    this._updateVisuals(instance);
  },

  update_isCentered: function(instance, payload) {
    instance.state.isCentered = helper.getBoolean(payload.values.isCentered, true);
    this._updateVisuals(instance);
  },

  event_click: function(event, instance) {
    const success = Network.send({ id: instance.id, event: "click", });

    if (!success) {
      console.warn("MM: Button event triggered; but failed to send.")
    }
  },

});