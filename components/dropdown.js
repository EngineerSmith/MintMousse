componentRegistry.register({
  typeName: "Dropdown",
  create: function(payload) {
    const instance = helper.prepareInstance(payload.id, this.typeName, payload.parentID);

    const root = document.createElement("select");
    root.className = "form-select border border-secondary rounded";

    instance.element = root;

    root.addEventListener("change", (event) => {
      this.event_change(event, instance);
    });

    this.update_options(payload);
    this.update_value(payload);
    this.update_isDisabled(payload);

    return instance;
  },

  update_options: function(instance, payload) {
    const options = payload.values.options;
    if (!Array.isArray(options)) return;

    const root = instance.element;
    root.innerHTML = "";

    options.forEach(opt => {
      const text = helper.getText(opt, "");
      const optionEl = document.createElement("option");
      optionEl.value = text;
      optionEl.textContent = text;
      root.append(optionEl);
    });
  },

  update_value: function(instance, payload) {
    const value = helper.getText(payload.values.value, "");
    instance.element.value = value;
  },

  update_isDisabled: function(instance, payload) {
    const disabled = helper.getBoolean(payload.values.isDisabled, false);
    instance.element.disabled = disabled;
  },

  eventPayload_change: "value",
  event_change: function(event, instance) {
    const value = instance.element.value;

    const success = Network.send({
      id: instance.id,
      event: "change",
      value: value,
    })

    if (!success) {
      console.warn("MM: Dropdown change event triggered but failed to send.")
    }
  },

});