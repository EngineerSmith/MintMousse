componentRegistry.register({
  typeName: "TextInput",
  create: function(payload) {
    const instance = helper.prepareInstance(payload.id, this.typeName, payload.parentID);

    instance.state = {
      placeholder: helper.getText(payload.values.placeholder, ""),
      isDisabled: helper.getBoolean(payload.values.isDisabled, false),
    };

    const root = document.createElement("input");
    root.type = "text";
    root.className = "form-control font-monospace";
    instance.element = root;

    root.addEventListener("keydown", (event) => {
      if (event.key === "Enter") {
        this.event_submit(event, instance);
      }
    });

    this.update_value(payload);
    this.update_placeholder(payload);
    this.update_isDisabled(payload);

    return instance;
  },

  update_value: function(instance, payload) {
    const newValue = helper.getText(payload.values.value, "");
    instance.element.value = newValue;
  },

  update_placeholder: function(instance, payload) {
    const newPlaceholder = helper.getText(payload.values.placeholder, "");
    instance.state.placeholder = newPlaceholder;
    instance.element.placeholder = newPlaceholder;
  },

  update_isDisabled: function(instance, payload) {
    instance.state.isDisabled = helper.getBoolean(payload.values.isDisabled, false);
    instance.element.disabled = instance.state.isDisabled;
  },

  eventPayload_submit: "value",
  event_submit: function(event, instance) {
    const value = instance.element.value;

    const success = Network.send({
      id: instance.id,
      event: "submit",
      value: value,
    });

    if (!success) {
      console.warn("MM: TextInput submit event triggered but failed to send.");
    } else {
      instance.element.value = "";
    }
  },

})