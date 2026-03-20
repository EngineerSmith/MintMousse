componentRegistry.register({
  typeName: "Alert",
  create: function(payload) {
    const instance = helper.prepareInstance(payload.id, this.typeName, payload.parentID);

    instance.state.color = helper.getColor(payload.values.color, "warning");
    instance.state.isDismissible = helper.getBoolean(payload.values.isDismissible, true);

    const root = document.createElement("div");
    root.className = `alert fade show alert-${instance.state.color}`;
    root.setAttribute("role", "alert");

    const p = document.createElement("p");
    p.className = "mb-0";
    root.append(p);

    instance.element = root;
    instance.parts.text = p;

    // Init sync
    this.update_text(payload);
    this.update_isDismissible(payload);

    root.addEventListener("closed.bs.alert", () => helper.removeInstance(payload.id));

    return instance;
  },

  update_text: (instance, payload) => instance.parts.text.innerHTML = helper.getText(payload.values.text, "UNKNOWN"),

  update_color: function(instance, payload) {
    const newColor = helper.getColor(payload.values.color, "warning");
    const oldColor = instance.state.color;
    if (oldColor === newColor) return;

    instance.element.classList.replace(`alert-${oldColor}`, `alert-${newColor}`);
    instance.state.color = newColor;
  },

  update_isDismissible: function(instance, payload) {
    const shouldBeDismissible = helper.getBoolean(payload.values.isDismissible, true);
    
    if (instance.state.isDismissible === shouldBeDismissible && instance.parts.dismissBtn) return;

    if (shouldBeDismissible) {
      instance.element.classList.add("alert-dismissible");
      const btn = document.createElement("button");
      btn.className = "btn-close";
      helper.setAttributes(btn, {
        "type": "button",
        "data-bs-dismiss": "alert",
      });

      instance.element.append(btn);
      instance.parts.dismissBtn = btn;
    } else {
      instance.element.classList.remove("alert-dismissible");
      instance.parts.dismissBtn?.remove();

      instance.parts.dismissBtn = null;
    }

    instance.state.isDismissible = shouldBeDismissible;
  },

});