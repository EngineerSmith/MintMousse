componentRegistry.register({
  typeName: "Switch",
  create: function(payload) {
    const instance = helper.prepareInstance(payload.id, this.typeName, payload.parentID);
    
    const root = document.createElement("div");
    root.className = "form-check form-switch";

    const input = document.createElement("input");
    input.type = "checkbox";
    input.className = "form-check-input";
    input.role = "switch";

    const label = document.createElement("label");
    label.className = "form-check-label";

    root.append(input, label);

    instance.element = root;
    instance.parts.input = input;
    instance.parts.label = label;

    input.addEventListener("change", (event) => {
      this.event_toggle(event, instance);
    });

    this.update_text(payload);
    this.update_isChecked(payload);
    this.update_isDisabled(payload);

    return instance;
  },

  update_text: function(instance, payload) {
    const text = helper.getText(payload.values.text, "");
    instance.parts.label.textContent = text;
  },

  update_isChecked: function(instance, payload) {
    const checked = helper.getBoolean(payload.values.isChecked, false);
    instance.parts.input.checked = checked;
  },

  update_isDisabled: function(instance, payload) {
    const disabled = helper.getBoolean(payload.values.isDisabled, false);
    instance.parts.input.disabled = disabled;
  },

  eventPayload_toggle: "isChecked",
  event_toggle: function(event, instance) {
    const checked = instance.parts.input.checked;

    const success = Network.send({
      id: instance.id,
      event: "toggle",
      isChecked: checked,
    });

    if (!success) {
      console.warn("MM: Switch toggle event triggered but failed to send.")
    }
  },

})