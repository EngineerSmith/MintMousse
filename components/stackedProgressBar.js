componentRegistry.register({
  typeName: "StackedProgressBar",
  create: function(payload) {
    const instance = helper.prepareInstance(payload.id, this.typeName, payload.parentID);

    const root = document.createElement("div");
    root.className = "progress-stacked";
    
    instance.element = root;

    return instance;
  },

  insert: function(instance, payload) {
    helper.insertNewChild(instance, payload);
    this._refreshLayout(instance);
  },

  reorderChildren: function(instance, payload) {
    helper.reorderChildren(instance, payload);
    this._refreshLayout(instance);
  },

  moveChild: function(instance, payload) {
    helper.moveChild(instance, payload);
    this._refreshLayout(instance);
  },

  _refreshLayout: function(instance) {
    const children = instance.children;
    const progressBars = children.filter(c => c.type === "ProgressBar");

    const totalPossibleValue = progressBars.length * 100;

    progressBars.forEach(child => {
      const childRoot = child.element;
      const childBar = child.parts.bar;

      const percentage = parseFloat(child.state.percentage) || 0;
      const scaledWidth = (percentage / totalPossibleValue) * 100;

      childRoot.style.width = `${scaledWidth}%`;
      if (childBar) {
        childBar.style.width = "100%";
      }
    })
  },

  update_child_percentage: function(childInstance, payload) {
    childInstance.state.percentage = helper.getFloat(payload.values.percentage);

    componentRegistry["ProgressBar"]._updateVisuals(childInstance);
    this._refreshLayout(helper.getParentOfInstance(childInstance));
  },

});