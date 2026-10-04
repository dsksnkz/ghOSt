import {assetUrl, motionGroups, settingsPages, settingsView, views} from "./catalogue.mjs";
import {entranceFrames, groupFrames, groupTiming, revealOrder} from "./motion.mjs";

const stage = document.querySelector("#stage");
const pagePicker = document.querySelector("#settings-page");
const motionPreference = matchMedia("(prefers-reduced-motion: reduce)");
let currentView = "calendar";
let settingsIndex = 0;
let renderRevision = 0;
let animations = [];
let lastOrder = [];

function cancelMotion() {
  for (const animation of animations) animation.cancel();
  animations = [];
}

function loadImage(url) {
  return new Promise((resolve, reject) => {
    const image = new Image();
    image.onload = () => resolve(image);
    image.onerror = reject;
    image.src = url;
  });
}

function cropImage(view, region = view.crop) {
  const [left, top, width, height] = region;
  const crop = document.createElement("div");
  crop.className = "crop";
  crop.style.setProperty("--aspect", width + " / " + height);
  crop.style.setProperty("--max-width", view.maxWidth + "px");
  const image = document.createElement("img");
  image.src = assetUrl(view.file);
  image.alt = view.title + " — " + view.kind;
  image.style.width = (view.size[0] / width * 100) + "%";
  image.style.left = (-left / width * 100) + "%";
  image.style.top = (-top / height * 100) + "%";
  crop.append(image);
  return crop;
}

function motionFragment(view, group) {
  const [left, top, width, height, shape = ""] = group;
  const fragment = document.createElement("div");
  fragment.className = "motion-fragment " + shape;
  fragment.setAttribute("aria-hidden", "true");
  fragment.style.left = (left / view.crop[2] * 100) + "%";
  fragment.style.top = (top / view.crop[3] * 100) + "%";
  fragment.style.width = (width / view.crop[2] * 100) + "%";
  fragment.style.height = (height / view.crop[3] * 100) + "%";
  const region = [view.crop[0] + left, view.crop[1] + top, width, height];
  fragment.append(cropImage(view, region));
  return fragment;
}

function motionFrame(view) {
  const frame = document.createElement("div");
  frame.className = "motion-frame " + view.motion;
  frame.style.setProperty("--max-width", view.maxWidth + "px");
  frame.style.setProperty("--aspect", view.crop[2] + " / " + view.crop[3]);
  frame.setAttribute("role", "img");
  frame.setAttribute("aria-label", view.title + ". " + view.description);
  for (const group of motionGroups[view.motion]) frame.append(motionFragment(view, group));
  return frame;
}

function playMotion(frame, view) {
  if (motionPreference.matches || document.hidden) return;
  const fragments = [...frame.children];
  lastOrder = revealOrder(fragments.length, lastOrder);
  animations.push(frame.animate(entranceFrames(view.motion), {
    duration: 260, easing: "ease-out", fill: "both",
  }));
  for (const [rank, index] of lastOrder.entries()) {
    animations.push(fragments[index].animate(groupFrames(view.motion), groupTiming(view.motion, rank)));
  }
}

function updateControls(view) {
  document.querySelector("#display-title").textContent = view.title;
  document.querySelector("#description").textContent = view.description;
  document.querySelector("#capture-kind").textContent = view.kind;
  document.querySelector("#full-image").href = assetUrl(view.file);
  document.querySelector("#settings-controls").hidden = currentView !== "settings";
  document.querySelector("#replay").hidden = !view.motion;
  pagePicker.value = String(settingsIndex);
  document.querySelector("#page-number").textContent =
    String(settingsIndex + 1).padStart(2, "0") + " / " + settingsPages.length;
  for (const button of document.querySelectorAll("[data-view]")) {
    button.setAttribute("aria-pressed", String(button.dataset.view === currentView));
  }
}

async function render() {
  const revision = ++renderRevision;
  const view = currentView === "settings" ? settingsView(settingsIndex) : views[currentView];
  cancelMotion();
  updateControls(view);
  stage.setAttribute("aria-busy", "true");
  document.querySelector("#load-error").hidden = true;
  try {
    await loadImage(assetUrl(view.file));
    if (revision !== renderRevision) return;
    const content = view.motion ? motionFrame(view) : cropImage(view);
    stage.replaceChildren(content);
    if (view.motion) playMotion(content, view);
  } catch {
    if (revision !== renderRevision) return;
    stage.replaceChildren();
    document.querySelector("#load-error").hidden = false;
  } finally {
    if (revision === renderRevision) stage.setAttribute("aria-busy", "false");
  }
}

function selectPage(index) {
  settingsIndex = (index + settingsPages.length) % settingsPages.length;
  currentView = "settings";
  render();
}

function populatePages() {
  for (const [index, [, label]] of settingsPages.entries()) {
    const option = document.createElement("option");
    option.value = String(index);
    option.textContent = label;
    pagePicker.append(option);
  }
}

function connectControls() {
  document.querySelector("#surfaces").addEventListener("click", event => {
    const button = event.target.closest("[data-view]");
    if (!button) return;
    currentView = button.dataset.view;
    render();
  });
  pagePicker.addEventListener("change", () => selectPage(Number(pagePicker.value)));
  document.querySelector("#previous-page").addEventListener("click", () => selectPage(settingsIndex - 1));
  document.querySelector("#next-page").addEventListener("click", () => selectPage(settingsIndex + 1));
  document.querySelector("#replay").addEventListener("click", render);
  motionPreference.addEventListener("change", cancelMotion);
  document.addEventListener("visibilitychange", () => {
    if (document.hidden) cancelMotion();
  });
}

populatePages();
connectControls();
render();
