componentRegistry.register({
  typeName: "ProgressBar",
  create: function(payload) {
    const instance = helper.prepareInstance(payload.id, this.typeName, payload.parentID);

    instance.state.percentage = helper.getFloat(payload.values.percentage);
    instance.state.showLabel = helper.getBoolean(payload.values.showLabel, false);
    instance.state.ariaLabel = helper.getText(payload.values.ariaLabel);
    instance.state.isStriped = helper.getBoolean(payload.values.isStriped, false);
    instance.state.colorBG = helper.getColor(payload.values.color);

    const root = document.createElement("div");
    root.className = "progress";

    helper.setAttributes(root, {
      "role": "progressbar",
      "aria-valuemin": "0",
      "aria-valuemax": "100",
    });

    const bar = document.createElement("div");
    bar.className = "progress-bar";

    root.append(bar);

    instance.element = root;
    instance.parts.bar = bar;

    this._updateVisuals(instance);

    return instance;
  },

  _updateVisuals: function(instance) {
    const { element, parts, state } = instance;
    const bar = parts.bar;

    const percentageTrunc = String(Math.round(state.percentage * 100) / 100);

    helper.setAttributes(element, {
      "aria-label": state.ariaLabel || null,
      "aria-valuenow": percentageTrunc,
    });

    bar.style.width = `${state.percentage}%`;
    bar.textContent = state.showLabel ? `${percentageTrunc}%` : "";

    bar.className = bar.className.replace(/\btext-bg-\S+/g, "").trim();
    if (state.colorBG) {
      bar.classList.add(`text-bg-${state.colorBG}`);
    }

    bar.classList.toggle("progress-bar-striped", state.isStriped);
    bar.classList.toggle("progress-bar-animated", state.isStriped);
  },

  update_percentage: function(instance, payload) {
    instance.state.percentage = helper.getFloatInRange(payload.values.percentage, 0.0, 1.0, 0.0);
    this._updateVisuals(instance);
  },

  update_showLabel: function(instance, payload) {
    instance.state.showLabel = helper.getBoolean(payload.values.showLabel, false);
    this._updateVisuals(instance);
  },

  update_ariaLabel: function(instance, payload) {
    instance.state.ariaLabel = helper.getText(payload.values.ariaLabel);
    this._updateVisuals(instance);
  },

  update_isStriped: function(instance, payload) {
    instance.state.isStriped = helper.getBoolean(payload.values.isStriped, false);
    this._updateVisuals(instance);
  },

  update_color: function(instance, payload) {
    instance.state.colorBG = helper.getColor(payload.values.color);
    this._updateVisuals(instance);
  },

});