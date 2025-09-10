// TODO judge if I want to keep the badge component
// Issue:
// To add badge to text, headers, buttons, etc. I would need to give them all insert functions
// Which were once those without are meant to be without to stop odd component chains.
// I would also add a new type of variable "position", which adds end user complexity
/*
function badge_new(payload) {
  const id = payload.id;
  const color = BSColor(payload.color) ?? "primary";
  const isRounded = Boolean(payload.isRounded ?? false);
  const text = getText(payload.text);

  const colorClass = "text-bg-" + color;

  const badge = document.createElement("span");
  badge.classList.add("badge", colorClass);

  if (isRounded === true)
    badge.classList.add("rounded-pill");

  badge.innerHTML = text;

  //badge.classList.add("position-absolute", "top-0", "start-100", "translate-middle")

  return badge;
}

function badge_update_color(payload) {
  const id = payload.id;
  const color = BSColor(payload.color) ?? "primary";

  const badge = document.getElementById(id);
  const currentColor = getColorClass(badge, "text-bg-");
  badge.classList.remove(currentColor);

  const colorClass = "text-bg-" + color;
  badge.classList.add(colorClass);
}

function badge_update_isRounded(payload) {
  const id = payload.id;
  const isRounded = Boolean(payload.isRounded ?? false);

  const badge = document.getElementById(id);
  if (isRounded === true) {
    badge.classList.add("rounded-pill");
  } else {
    badge.classList.remove("rounded-pill");
  }
}

function badge_update_text(payload) {
  const id = payload.id;
  const text = getText(payload.text);

  const badge = document.getElementById(id);
  badge.innerHTML = text;
}
*/