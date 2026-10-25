// Searchable local tutorials. No commands, service calls or settings writes here.
var topics = [
    {id: "start", title: "Start here", icon: "ghost", recommended: true,
     summary: "Find apps and open your desktop controls.",
     body: "Press Super + Space to find apps or run a command. Use the menu button at the top left for the sidebar. Click the centered clock for the calendar, weather and system meters.",
     action: "sidebar", button: "Open sidebar", keywords: "launcher search terminal calendar top rail"},
    {id: "appearance", title: "Make it yours", icon: "wallpaper", recommended: true,
     summary: "Choose a wallpaper with an image preview.",
     body: "Open Wallpaper in Settings. Browse folders, select an image and inspect the preview before applying it. Your current wallpaper is kept until you confirm.",
     action: "wallpaper", button: "Open Wallpaper", keywords: "background picture image theme"},
    {id: "sound", title: "Sound and edge volume", icon: "volume", recommended: true,
     summary: "Use either screen edge to reveal the volume slider.",
     body: "Hold the pointer anywhere along the left or right screen edge for 0.2 seconds. The OSD appears at that height and stays fixed. Once open, you can move a little inward or onto the OSD without closing it. Scroll in the expanded edge area or over the OSD for animated 2% volume steps; drag its slider for direct adjustment. Move away from both to close. Fullscreen apps keep their edges. Settings → Sound controls output, input and interface click sounds.",
     action: "sound", button: "Open Sound", keywords: "audio speaker microphone sfx click mute brightness osd"},
    {id: "workspaces", title: "Move between desktops", icon: "display", recommended: false,
     summary: "Switch workspaces without losing your windows.",
     body: "Scroll over the desktop numbers in the top rail. Super + number opens that desktop. The filled white dot stays below the active number while the wheel turns. Scrolling includes desktops 1–5 and occupied higher desktops.",
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
     summary: "Reduce motion or tune interface sounds.",
     body: "Settings → Accessibility includes reduced motion. Sound includes interface sound volume and a fixed sound choice for each control group. These options are available here; nothing is enabled or changed without your choice.",
     action: "accessibility", button: "Open Accessibility", keywords: "animation reduced volume quiet disable"}
];

function search(query) {
    var words = query.trim().toLowerCase().split(/\s+/).filter(Boolean);
    return topics.filter(topic => words.every(word =>
        (topic.title + " " + topic.summary + " " + topic.body + " " + topic.keywords)
            .toLowerCase().includes(word)));
}
