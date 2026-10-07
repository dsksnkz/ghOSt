// Capture coordinates stay fixed; the display scales them as a single unit.
export const assetVersion = "20261007-rail";
export const views = {
  rail: {
    title: "Top rail",
    description: "Workspaces and device controls. Scroll switches desktops; clicks open panels.",
    file: "rail-native.png", size: [1920, 60], crop: [0, 0, 1920, 60],
    maxWidth: 1200, kind: "Desktop capture",
  },
  calendar: {
    title: "Calendar",
    description: "Weather, dates and device usage. System readings drive the meters.",
    file: "calendar-native.png", size: [820, 347], crop: [0, 0, 820, 347],
    maxWidth: 900, kind: "Desktop capture",
  },
  sidebar: {
    title: "Sidebar",
    description: "Connections, volume, brightness and notifications. Opens from the rail.",
    file: "sidebar-frame.webp", size: [1920, 1080], crop: [0, 144, 356, 794],
    maxWidth: 356, kind: "Sample data",
  },
  settings: {
    title: "Settings",
    description: "Device and desktop preferences. Uses standard Linux services.",
    file: "settings-general.webp", size: [1100, 760], crop: [36, 36, 1024, 699],
    maxWidth: 1024, kind: "Sample data",
  },
  launcher: {
    title: "App launcher",
    description: "Find and open apps. Searches installed entries and keeps pinned favourites.",
    file: "launcher.png", size: [1600, 820], crop: [605, 54, 392, 550],
    maxWidth: 480, kind: "Desktop catalogue capture",
  },
  "sidebar-motion": {
    title: "Sidebar motion",
    description: "Slides in from the left. Complete widget groups follow in random order.",
    file: "sidebar-frame.webp", size: [1920, 1080], crop: [0, 144, 356, 794],
    maxWidth: 356, kind: "Browser motion · sample data", motion: "sidebar",
  },
  "calendar-motion": {
    title: "Calendar motion",
    description: "Frame drops into place, then sections reveal in random order over 1.5 seconds.",
    file: "calendar-native.png", size: [820, 347], crop: [0, 0, 820, 347],
    maxWidth: 900, kind: "Browser motion · desktop capture", motion: "calendar",
  },
};

export const settingsPages = [
  ["general", "General"],
  ["network", "Wireless network"],
  ["bluetooth", "Bluetooth"],
  ["airplane", "Airplane mode"],
  ["accessibility", "Accessibility"],
  ["sound", "Sound"],
  ["battery", "Battery"],
  ["brightness", "Brightness"],
  ["widgets", "Sidebar widgets"],
  ["wallpaper", "Wallpaper"],
  ["notifications", "Notifications"],
  ["storage", "Storage"],
  ["applications", "Applications"],
  ["about", "Info"],
];

export const motionGroups = {
  sidebar: [
    [0, 12, 356, 104],
    [28, 122, 144, 224],
    [188, 122, 146, 224],
    [28, 362, 306, 36],
    [28, 416, 306, 36],
    [28, 472, 306, 284],
  ],
  calendar: [
    [36, 25, 195, 250],
    [258, 28, 142, 142, "diamond"],
    [415, 28, 142, 142, "diamond"],
    [336, 104, 142, 142, "diamond"],
    [550, 45, 269, 235],
    [310, 265, 190, 70],
  ],
};

export function settingsView(index) {
  const [page, label] = settingsPages[index];
  return {...views.settings, title: "Settings / " + label, file: "settings-" + page + ".webp"};
}

export function assetUrl(file) {
  return "assets/" + file + "?v=" + assetVersion;
}
