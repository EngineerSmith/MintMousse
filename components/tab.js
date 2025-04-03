var activeTab = true;
function tab_new(payload) {
  const id = payload.id;
  const title = payload.title;

  const buttonID = id + "-button";
  const tabPaneID = id + "-panel";
  const gridID = id + "-grid";

  // add to Navbar
  const li = document.createElement("li");
  setAttributes(li, {
    "role": "presentation",
    "id": id + "-li",
  });

  const button = document.createElement("button");
  button.classList.add("nav-link");
  button.textContent = title ? title : "UNKNOWN";
  setAttributes(button, {
    "id": buttonID,
    "data-bs-toggle": "tab",
    "data-bs-target": "#" + tabPaneID,
    "type": "button",
    "role": "tab",
    "aria-controls": tabPaneID,
    "aria-selected": "false",
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
    "aria-labelledby": buttonID,
    "tabindex": "0",
  });

  const grid = document.createElement("div");
  grid.classList.add("grid");
  grid.setAttribute("id", gridID);

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
  const masonryInstance = new Masonry(`#${gridID}`, masonryOptions);
  tabMasonry.set(id, masonryInstance);

  eventInit();

  // Add tab to Bootstrap
  const tabTrigger = new bootstrap.Tab(button);
  button.addEventListener('click', event => {
    event.preventDefault();
    tabTrigger.show();
    resizeMasonry();
  });

  if (activeTab) {
    activeTab = false;
    button.click();
  }

  console.log("Added tab:", title);
}

function tab_insert(payload) {
  const id = payload.parentID;
  const grid = document.getElementById(id + "-grid");

  insertPayload(grid, payload);

  const masonry = tabMasonry.get(id)
  masonry.appended(grid.lastChild);
  masonry.layout();

  eventInit();
}

function tab_update_title(payload) {
  const id = payload.id;
  const title = payload.title;

  const button = document.getElementById(id + "-tab");
  button.textContent = title;

  console.log("Updated tab: Title updated to ", title);
}

function tab_remove(payload) {
  const id = payload.id;

  const button = document.getElementById(id + "-tab");
  const title = button.textContent;
  const isActive = button.classList.contains("active");

  const li = document.getElementById(id + "-li");
  removeElement(li);

  const tabPane = document.getElementById(id + "-tab-panel");
  removeElement(tabPane);

  if (isActive) {
    const firstTabButton = document.querySelector('.nav-link');
    if (firstTabButton) {
      bootstrap.Tab.getInstance(firstTabButton).show();
    } else {
      activeTab = true;
    }
  }

  console.log("Removed tab:", title);
}