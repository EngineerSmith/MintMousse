let activeTabFlag = true;

const masonryOptions = {
  "itemSelector": ".grid-item",
  "columnWidth": ".grid-sizer",
  "gutter": ".gutter-sizer",
  "percentPosition": true,
  "transitionDuration": "0.2s",
};

componentRegistry.register({
  typeName: "Tab",
  create: function(payload) {
    const instance = helper.prepareInstance(payload.id, this.typeName, null);

    const paneID = `${payload.id}-pane`;
    const buttonID = `${payload.id}-button`;

    const li = document.createElement("li");
    li.className = "nav-item";
    li.setAttribute("role", "presentation");

    const button = document.createElement("button");
    button.id = buttonID;
    button.className = "nav-link";
    button.innerHTML = helper.getText(payload.values.title, "UNKNOWN");
    helper.setAttributes(button, {
      "data-bs-toggle": "tab",
      "data-bs-target": `#${paneID}`,
      "type": "button",
      "role": "tab",
      "aria-controls": paneID,
      "aria-selected": false,
    });

    li.append(button);

    const navbar = document.getElementById("tabNavbar");
    if (navbar) {
      const targetIndex = helper.getIntInRange(payload.index, 1, navbar.children.length + 1, navbar.children.length + 1) - 1;

      if (targetIndex >= navbar.children.length - 1){
        navbar.append(li);
      } else {
        navbar.children[targetIndex].before(li);
      }
    }

    document.getElementById("tabNavbar")?.append(li);

    const pane = document.createElement("div");
    pane.id = paneID;
    pane.className = "tab-pane fade container mt-2";
    helper.setAttributes(pane, {
      "role": "tabpanel",
      "aria-labelledby": buttonID,
      "tabindex": "0",
    });

    const grid = document.createElement("div");
    grid.className = "grid";

    grid.append(
      Object.assign(document.createElement("div"), { className: "grid-sizer" }),
      Object.assign(document.createElement("div"), { className: "gutter-sizer" }),
    );

    pane.append(grid);
    document.getElementById("tabContent")?.append(pane);

    instance.element = pane;
    instance.parts.grid = grid;
    instance.parts.button = button;
    instance.parts.li = li;
    instance.parts.wrappers = new Map();

    // Initialise Masonry
    const masonryInstance = new Masonry(grid, masonryOptions);
    tabMasonry.set(payload.id, masonryInstance);

    // Add tab to Bootstrap
    const tabTrigger = new bootstrap.Tab(button);
    button.addEventListener('click', (e) => {
      e.preventDefault();
      tabTrigger.show();
      masonryInstance.layout();
    });

    // Auto-activate first tab
    if (activeTabFlag) {
      activeTabFlag = false;
      button.click();
    }

    return instance;
  },

  insert: function(instance, payload) {
    const childComponent = componentRegistry[payload.childType];
    if (!childComponent) return;

    const sizeNum = helper.getIntInRange(payload.values.size, 1, 5, 1);
    const wrapper = document.createElement("div");
    wrapper.className = `grid-item grid-item-${sizeNum}`;
    instance.parts.wrappers.set(payload.id, wrapper);

    const childInstance = childComponent.create(payload);
    wrapper.append(childInstance.element);

    const children = instance.children;
    const targetIndex = helper.getIntInRange(payload.childPosition, 1, children.length + 1, children.length + 1) - 1;
    children.splice(targetIndex, 0, childInstance);

    const grid = instance.parts.grid;
    if (targetIndex >= children.length - 1) {
      grid.append(wrapper);
    } else {
      const neighborID = children[targetIndex + 1].id;
      const neighborWrapper = instance.parts.wrappers.get(neighborID);
      neighborWrapper.before(wrapper);
    }

    const masonryInstance = tabMasonry.get(instance.id);
    if (masonryInstance) {
      masonryInstance.appended(wrapper);

      if (targetIndex < children.length - 1) {
        masonryInstance.reloadItems();
      }

      masonryInstance.layout();
    }
  },

  reorderChildren: function(instance, payload) {
    const oldChildren = instance.children;
    const newIndices = payload.newOrder;

    if (!Array.isArray(newIndices)) return;

    const newChildren = newIndices.map(pos => {
      const oldIndex = helper.getIntInRange(pos, 1, oldChildren.length) - 1;
      return oldChildren[oldIndex];
    });
    instance.children = newChildren;

    const wrappersToAppend = newChildren
      .map(child => instance.parts.wrappers.get(child.id))
      .filter(Boolean);

    // We use this over replaceChildren to keep [grid-sizer, gutter-sizer] at the front
    wrappersToAppend.forEach(wrapper => instance.parts.grid.append(wrapper));

    const masonryInstance = tabMasonry.get(instance.id);
    if (masonryInstance) {
      masonryInstance.reloadItems();
      masonryInstance.layout();
    }
  },

  moveChild: function(instance, payload) {
    const children = instance.children;
    const oldIndex = helper.getIntInRange(payload.oldIndex, 1, children.length) - 1;
    const newIndex = helper.getIntInRange(payload.newIndex, 1, children.length) - 1;
    
    if (oldIndex === newIndex) return;

    const [movingChild] = children.splice(oldIndex, 1);
    children.splice(newIndex, 0, movingChild);

    const movingWrapper = instance.parts.wrappers.get(movingChild.id);

    if (newIndex >= children.length - 1) {
      instance.parts.grid.append(movingWrapper);
    } else {
      const neighborID = children[newIndex + 1].id;
      const neighborWrapper = instance.parts.wrappers.get(neighborID);
      neighborWrapper.before(movingWrapper);
    }

    const masonryInstance = tabMasonry.get(instance.id);
    if (masonryInstance) {
      masonryInstance.reloadItems();
      masonryInstance.layout();
    }
  },

  remove_child: function(instance, childInstance) {
    const wrapper = instance.parts.wrappers.get(childInstance.id);
    const masonryInstance = tabMasonry.get(instance.id);

    if (wrapper && masonryInstance) {
      masonryInstance.remove(wrapper);
      masonryInstance.layout();
    }

    instance.parts.wrappers.delete(childInstance.id);
  },

  remove: function(instance) {
    const id = instance.id;
    const isActive = instance.parts.button.classList.contains("active");

    instance.parts.li?.remove();
    instance.element?.remove();

    tabMasonry.get(id)?.destroy();
    tabMasonry.delete(id);

    if (isActive) {
      const firstTabButton = document.querySelector('.nav-link');
      if (firstTabButton) {
        bootstrap.Tab.getInstance(firstTabButton)?.show();
      } else {
        activeTabFlag = true;
      }
    }
  },

  update_title: (instance, payload) => instance.parts.button.innerHTML = helper.getText(payload.values.title, "UNKNOWN"),

  update_child_size: function(instance, payload) {
    const wrapper = instance.parts.wrappers.get(payload.id);
    if (!wrapper) return;

    const sizeNum = helper.getIntInRange(payload.values.size, 1, 5, 1);
    const newSizeClass = `grid-item-${sizeNum}`;

    wrapper.className = wrapper.className.replace(/\bgrid-item-[1-5]\b/g, "").trim();
    wrapper.classList.add(newSizeClass);

    tabMasonry.get(instance.id)?.layout();
  },

});