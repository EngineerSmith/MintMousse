const newSpan = (text) => {
  const span = document.createElement("span");
  span.textContent = text;
  return span;
}

componentRegistry.register({
  typeName: "TextViewer",
  create: function(payload) {
    const instance = helper.prepareInstance(payload.id, this.typeName, payload.parentID);

    let initialText = [];
    if (Array.isArray(payload.pushes.text)) {
      initialText = payload.pushes.text;
    }

    const root = document.createElement("div");
    root.className = "text-viewer bg-dark text-light p-2 border border-secondary rounded font-monospace overflow-auto";

    instance.element = root;

    instance.state.atBottom = true;
    instance.state.wasVisible = false;

    const updateScrollState = () => {
      const isAtBottomNow = (root.scrollHeight - root.scrollTop - root.clientHeight) <= 7;
      instance.state.atBottom = isAtBottomNow;
    }
    root.addEventListener("scroll", updateScrollState, { passive: true });

    instance.state.resizeObserver = new ResizeObserver(() => {
      const isVisibleNow = root.offsetHeight > 0 && root.offsetWidth > 0;
      if (isVisibleNow && !instance.state.wasVisible && instance.state.atBottom)
        root.scrollTop = root.scrollHeight;
      instance.state.wasVisible = isVisibleNow;
    })
    instance.state.resizeObserver.observe(root);

    if (initialText.length > 0)
      initialText.forEach(text => this._addText(instance, text));

    this.update_maxLines(payload);

    return instance;
  },

  _addText: function(instance, textData) {
    if (!textData) return;
    const text = helper.getText(textData);
    if (!text) return;

    const root = instance.element;

    const isVisibleNow = root.offsetHeight > 0 && root.offsetWidth > 0;
    let shouldAutoScroll = false;
    if (isVisibleNow) {
      instance.state.atBottom = (root.scrollHeight - root.scrollTop - root.clientHeight) <= 7;
      if (instance.state.atBottom)
        shouldAutoScroll = true;
    }

    root.append(newSpan(text), document.createElement("br"));
    if (shouldAutoScroll)
      root.scrollTop = root.scrollHeight;
  },

  push_text: function(instance, payload) {
    const text = payload.pushes.text;
    if (text) {
      this._addText(instance, text);
    }
  },

  update_maxLines: function(instance, payload) {
    const newMax = helper.getInt(payload.values.maxLines, 25);
    instance.state.maxLines = newMax;

    const root = instance.element;
    root.style.setProperty("--max-lines", newMax);
  },

})