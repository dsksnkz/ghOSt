// Searchable local tutorials. No commands, service calls or settings writes here.
var topics = [
    {id: "start", title: "Start here", icon: "ghost", recommended: true,
     summary: "Find apps and open your desktop controls.",
     body: "Press Super + Space to find apps or run a command. Use the menu button at the top left for the sidebar. Click the centered clock for the calendar, weather and system meters.",
     action: "sidebar", button: "Open sidebar", keywords: "launcher search terminal calendar top rail"},
    {id: "shortcuts", title: "Keyboard shortcuts", icon: "keyboard", recommended: true,
     summary: "The keys that run the desktop.",
     body: "",
     action: "", button: "", keywords: "keybinds keybindings keys hotkeys tutorial",
     shortcuts: [
         {group: "Apps", items: [
             ["Launcher", "Super + Space"],
             ["Terminal", "Super + W"],
             ["Firefox", "Super + S"],
             ["Files", "Super + E"],
             ["Code editor", "Super + A"],
             ["Clipboard history", "Super + V"]]},
         {group: "Windows", items: [
             ["Close window", "Super + Q"],
             ["Float window", "Super + T"],
             ["Move focus", "Super + Arrows"],
             ["Move window", "Super + Ctrl + Arrows"],
             ["Resize window", "Super + Shift + Arrows"],
             ["Drag window", "Super + Left click"],
             ["Resize with mouse", "Super + Right click"]]},
         {group: "Desktops", items: [
             ["Desktop switcher", "Super + Tab"],
             ["Go to desktop", "Super + 1 to 0"],
             ["Send window to desktop", "Super + Shift + 1 to 0"],
             ["Change desktop", "Super + Scroll"],
             ["AI workspace", "Super + F"],
             ["Music workspace", "Super + G"],
             ["Send window to AI", "Super + Shift + F"],
             ["Send window to Music", "Super + Shift + G"]]},
         {group: "System", items: [
             ["Settings", "Super + I"],
             ["Wallpaper", "Super + B"],
             ["Network", "Super + N"],
             ["About", "Super + R"],
             ["Reload shell", "Super + M"],
             ["Lock", "Super + L"],
             ["Screenshot region", "Super + Shift + S"],
             ["Screenshot screen", "Super + Print"],
             ["Exit Hyprland", "Super + Shift + M"]]}
     ]},
    {id: "appearance", title: "Make it yours", icon: "wallpaper", recommended: true,
     summary: "Choose a wallpaper with an image preview.",
     body: "Open Wallpaper in Settings. Browse folders, select an image and inspect the preview before applying it. Your current wallpaper is kept until you confirm.",
     action: "wallpaper", button: "Open Wallpaper", keywords: "background picture image theme"},
    {id: "sound", title: "Sound and edge volume", icon: "volume", recommended: true,
     summary: "Use either screen edge to reveal the volume slider.",
     body: "Hold the pointer anywhere along the left or right screen edge for 0.2 seconds. The OSD appears at that height and stays fixed. Once open, you can move a little inward or onto the OSD without closing it. Scroll in the expanded edge area or over the OSD for animated 2% volume steps; drag its slider for direct adjustment. Move away from both to close. Fullscreen apps keep their edges. Settings → Sound controls output, input and interface click sounds.",
     action: "sound", button: "Open Sound", keywords: "audio speaker microphone mute brightness osd"},
    {id: "workspaces", title: "Move between desktops", icon: "display", recommended: false,
     summary: "Switch workspaces without losing your windows.",
     body: "Scroll over the desktop numbers in the top bar, or press Super + number to open that desktop. Super + Tab shows every desktop at once.",
     action: "", button: "", keywords: "workspace switcher wheel shortcut keyboard"},
    {id: "calendar", title: "Calendar and weather", icon: "calendar", recommended: false,
     summary: "Browse days and read real system usage.",
     body: "Click the clock to open the calendar. Scroll the weather list to select a day; the headline changes with your selection. The meters show system measurements. Click outside to close the panel.",
     action: "calendar", button: "Open calendar", keywords: "date forecast london cpu gpu ram meter"},
    {id: "connections", title: "Connections", icon: "wifi", recommended: false,
     summary: "Manage Wi-Fi and Bluetooth from the sidebar or Settings.",
     body: "The top-rail internet button always uses the Wi-Fi symbol, including on Ethernet. Connection details in Settings still identify the actual connection. The sidebar shows available networks and paired Bluetooth devices.",
     action: "network", button: "Open Network", keywords: "ethernet internet router wireless bluetooth"},
    {id: "accessibility", title: "Comfort and motion", icon: "accessibility", recommended: false,
     summary: "Reduce motion.",
     body: "Settings → Accessibility includes reduced motion. These options are available here; nothing is enabled or changed without your choice.",
     action: "accessibility", button: "Open Accessibility", keywords: "animation reduced volume quiet disable"}
];

function shortcutText(topic) {
    return (topic.shortcuts || []).map(group => group.items.map(item => item.join(" ")).join(" ")).join(" ");
}

function search(query) {
    var words = query.trim().toLowerCase().split(/\s+/).filter(Boolean);
    return topics.filter(topic => words.every(word =>
        (topic.title + " " + topic.summary + " " + topic.body + " " + topic.keywords + " " + shortcutText(topic))
            .toLowerCase().includes(word)));
}
