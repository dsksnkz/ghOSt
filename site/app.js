const views = {
  calendar: ["calendar-frame.webp", "Calendar · sample storm and performance readings"],
  rail: ["rail-frame.webp", "Rail · three-position workspace wheel and grouped controls"],
  sidebar: ["sidebar-frame.webp", "Sidebar · sample network and Bluetooth names; staged"],
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
const surface = document.querySelector("#surface");
let selection = "calendar";
document.querySelectorAll("[data-view]").forEach(button => {
  button.addEventListener("click", () => {
    selection = button.dataset.view;
    const chosen = selection, [file, description] = views[chosen];
    const next = new Image();
    next.onload = () => {
      if (selection !== chosen) return;
      surface.src = next.src;
      surface.alt = "Staged ghOSt preview: " + description;
      document.querySelector("#caption").textContent = description;
      document.querySelector("#fullsize").href = next.src;
      document.querySelector("figure").dataset.view = selection;
    };
    next.src = "assets/" + file;
    document.querySelectorAll("[data-view]").forEach(b => b.setAttribute("aria-pressed", String(b === button)));
  });
});
