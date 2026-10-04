const views = {
  settings: ["settings-general.webp", "Settings · measured 1024 × 699 frame; sample data"],
  desktop: ["desktop-frame.webp", "Composition · measured Figma layout with sample data"],
  calendar: ["calendar-frame.webp", "Calendar · enlarged frame; sample weather and readings"],
  rail: ["rail-frame.webp", "Rail · cylindrical workspace wheel, fixed indicator and grouped controls"],
  wheel: ["workspace-wheel-motion.webp", "Workspace wheel · actual isolated QML motion; sample desktops"],
  sidebar: ["sidebar-frame.webp", "Sidebar · three-layer cards and notification history; sample data"],
  notification: ["notification-popup.webp", "Notification popup · actual QML; explicitly labeled sample data"],
  power: ["power-frame.webp", "Power · a second click confirms disruptive actions"],
  launcher: ["launcher.png", "Launcher / native application catalogue and persistent pins."],
  search: ["launcher-search.png", "Search / ranked name, category description and keyword matches."],
  empty: ["launcher-empty.png", "Search / clear feedback when there are no matching applications."],
  cpu: ["calendar-performance.png", "CPU / utilization from aggregate counter deltas."],
  gpu: ["calendar-gpu.png", "GPU / NVIDIA utilization sampled while selected."],
  clock: ["calendar-clock.png", "Clock / average processor MHz; scale from the hardware maximum."],
  audio: ["audio-panel.png", "Audio / PipeWire volume and output controls."],
  icons: ["icons.png", "Icons / the same shapes rendered in white and black."]
};
const settingsPages = ["sound", "battery", "widgets", "brightness", "wallpaper", "notifications", "network", "bluetooth", "airplane", "accessibility", "storage", "applications", "about"];
const settingsFlows = [
  ["name-editor", "PC name", "PC-name editor · fixture only; no computer renamed"],
  ["portrait-fixture", "Profile picture", "Profile-picture selection · sample wallpaper crop; originals preserved"],
  ["search-sound", "Navigation search", "Navigation search · grouped Sound result"]
];
const settingsNav = document.querySelector("#settings-nav");
for (const page of settingsPages) {
  const label = page === "widgets" ? "Sidebar widgets" : page[0].toUpperCase() + page.slice(1);
  views["settings-" + page] = ["settings-" + page + ".webp", "Settings / " + label + " · sample data; system actions disabled"];
  const button = document.createElement("button");
  button.type = "button";
  button.dataset.view = "settings-" + page;
  button.setAttribute("aria-pressed", "false");
  button.textContent = label;
  settingsNav.append(button);
}
for (const [page, label, description] of settingsFlows) {
  views["settings-" + page] = ["settings-" + page + ".webp", "Settings / " + description];
  const button = document.createElement("button");
  button.type = "button";
  button.dataset.view = "settings-" + page;
  button.setAttribute("aria-pressed", "false");
  button.textContent = label;
  settingsNav.append(button);
}
const surface = document.querySelector("#surface");
let selection = "calendar";
document.querySelectorAll("[data-view]").forEach(button => {
  button.addEventListener("click", () => {
    selection = button.dataset.view;
    const chosen = selection;
    let [file, description] = views[chosen];
    if (chosen === "wheel" && matchMedia("(prefers-reduced-motion: reduce)").matches) file = "workspace-wheel-still.webp";
    const next = new Image();
    next.onload = () => {
      if (selection !== chosen) return;
      surface.src = next.src;
      surface.alt = "ghOSt component preview: " + description;
      document.querySelector("#caption").textContent = description;
      document.querySelector("#fullsize").href = next.src;
      document.querySelector("figure").dataset.view = selection;
    };
    next.src = "assets/" + file;
    document.querySelectorAll("[data-view]").forEach(b => b.setAttribute("aria-pressed", String(b === button)));
  });
});
