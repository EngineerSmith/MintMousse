function tab_new(id, name) {
  const tabPaneID = id + "-tab-panel";

  // add to Navbar
  const li = document.createElement("li");
  setAttributes(li, {
    "role": "presentation",
    "id": id + "-li",
  });

  const button = document.createElement("button");
  button.classList.add("nav-link");
  button.textContent = name ? name : "UNKNOWN";
  setAttributes(button, {
    "id": id + "-tab",
    "data-bs-toggle": "tab",
    "data-bs-target": "#" + tabPaneID,
    "type": "button",
    "role": "tab",
    "aria-controls": tabPaneID,
    "aria-selected": false,
  });
  const tabTrigger = new bootstrap.Tab(button);
  button.addEventListener('click', event => {
    event.preventDefault();
    tabTrigger.show();
    resizeMasonry();
  });

  li.append(button);
  const navbar = document.getElementById("tabNavbar");
  navbar.append(li); //todo set index

  // add tab pane
  const tabPane = document.createElement("div");
  tabPane.classList.add("tab-pane", "fade", "container", "mt-2");
  setAttributes(tabPane, {
    "id": tabPaneID,
    "role": "tabpanel",
    "aria-labelledby": id + "-tab",
    "tabindex": 0,
  });

  const grid = document.createElement("div");
  grid.classList.add("grid");
  grid.setAttribute("id", id + "-tab-grid");

  const gridSizer = document.createElement("div");
  gridSizer.classList.add("grid-sizer");

  const gutterSizer = document.createElement("div");
  gutterSizer.classList.add("gutter-sizer");

  grid.append(gridSizer);
  grid.append(gutterSizer);

  // append components to grid

  tabPane.append(grid);

  const tabContent = document.getElementById("tabContent");
  tabContent.append(tabPane);

  // Initialise Masonry
  const masonryInstance = new Masonry(grid, masonryOptions);
  tabMasonry.set(id, masonryInstance);

  eventInit();
}