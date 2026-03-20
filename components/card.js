componentRegistry.register({
  typeName: "Card",
  create: function(payload) {
    const instance = helper.prepareInstance(payload.id, this.typeName, payload.parentID);

    instance.state.colorBG = helper.getColor(payload.values.color);
    instance.state.isContentCenter = helper.getBoolean(payload.values.isContentCenter, false);
    instance.state.colorBorder = helper.getColor(payload.values.borderColor);

    const root = document.createElement("div");

    const body = document.createElement("div");
    body.className = "card-body";

    const title = document.createElement("h4");
    title.className = "card-title";

    const text = document.createElement("p");
    text.className = "card-text";

    body.append(title, text);
    root.append(body);

    instance.element = root;
    instance.parts.body = body;
    instance.parts.title = title;
    instance.parts.text = text;

    this.update_title(payload);
    this.update_text(payload);
    this._updateVisuals(instance);

    return instance;
  },

  insert: function(instance, payload) {
    const childInstance = helper.insertNewChild(instance, payload);

    if (childInstance) {
      const element = childInstance.element;
      if (element.classList.contains("card-header") || element.classList.contains("card-footer")) {
        element.className = element.className.replace(/\bborder-\S+/g, "").trim();
        if (instance.state.colorBorder) {
          element.classList.add(`border-${instance.state.colorBorder}`);
        }
      }
    }
  },

  _updateVisuals: function(instance) {
    const { element, state } = instance;

    let classes = ["card"];
    if (state.colorBG) classes.push(`text-bg-${state.colorBG}`);
    if (state.isContentCenter) classes.push("text-center");
    if (state.colorBorder) classes.push(`border-${state.colorBorder}`);

    element.className = classes.join(" ");

    Array.from(element.children).forEach(child => {
      if (child.classList.contains("card-header") || child.classList.contains("card-footer")) {
        child.className = child.className.replace(/\bborder-\S+/g, "").trim();
        if (state.colorBorder) {
          child.classList.add(`border-${state.colorBorder}`);
        }
      }
    });
  },

  update_color: function(instance, payload) {
    instance.state.colorBG = helper.getColor(payload.values.color);
    this._updateVisuals(instance);
  },

  update_isContentCenter: function(instance, payload) {
    instance.state.isContentCenter = helper.getBoolean(payload.values.isContentCenter, false);
    this._updateVisuals(instance);
  },

  update_borderColor: function(instance, payload) {
    instance.state.colorBorder = helper.getColor(payload.values.borderColor);
    this._updateVisuals(instance);
  },

  update_title: function(instance, payload) {
    const titleText = helper.getText(payload.values.title);
    const { body, title, text } = instance.parts;

    title.innerHTML = titleText;
    title.hidden = !titleText;

    body.hidden = title.hidden && text.hidden;
  },

  update_text: function(instance, payload) {
    const textContent = helper.getText(payload.values.text);
    const { body, title, text } = instance.parts;

    text.innerHTML = textContent;
    text.hidden = !textContent;

    body.hidden = title.hidden && text.hidden;
  },

});