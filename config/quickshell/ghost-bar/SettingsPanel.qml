import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Dialogs
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import "SettingsNavigation.js" as Navigation

Item {
    id: settings
    // Settings-only tokens. Keep the supplied sidebar and native frame geometry.
    readonly property color primaryInk: "#f1f1f1"
    readonly property color secondaryInk: "#b8b8b8"
    readonly property color controlSurface: "#1f1f1f"
    readonly property color controlBorder: "#2e2e2e"
    readonly property int controlHeight: 56
    readonly property string creatorAttribution: "ghOSt - ChatGPT and dsksnkz"
    readonly property real navigationRowHeight: 44
    readonly property real navigationRowGap: 8
    readonly property real navigationStride: navigationRowHeight + navigationRowGap
    readonly property real navigationInset: 0
    readonly property real navigationGroupGap: 16
    readonly property var navigationMetrics: ({
        rowHeight: navigationRowHeight,
        rowGap: navigationRowGap,
        inset: navigationInset,
        groupGap: navigationGroupGap
    })
    // The new screenshot supersedes the old 40% glyph sizing.
    readonly property real iconRatio: 0.6
    function navigationGroupHeight(count) {
        return Navigation.groupHeight(count, navigationMetrics);
    }
    property bool previewMode: false
    property string page: "general"
    property string query: ""
    property real fixtureVolume: 62
    property real fixtureInput: 74
    property var airplaneSnapshot: null
    property string fixtureHost: "Unit-01"
    property url fixturePortrait: ""
    property string portraitOrigin: ""
    property bool portraitChooserRequested: false
    property string portraitError: ""
    property string nameDraft: ""
    property bool nameSubmitted: false
    readonly property string displayHost: previewMode ? fixtureHost : details.host || "Computer"
    readonly property url portraitSource: previewMode ? (fixturePortrait.toString() || Qt.resolvedUrl("artwork/profile.jpg")) : (details.preferences?.profilePicture || Qt.resolvedUrl("artwork/profile.jpg"))
    // Controls keep their size and the layout uses the window's room, as in
    // GNOME apps. The zoom only shrinks if the window is narrower than the design.
    property real zoom: 1
    readonly property real minimumWidth: 1024
    readonly property real minimumHeight: 490
    readonly property real fit: Math.min(zoom, width / minimumWidth, height / minimumHeight)
    // Layers are drawn at the zoomed pixel size, so scaled text stays sharp.
    readonly property real pixelRatio: Screen.devicePixelRatio || 1
    readonly property var details: previewMode ? ({
            host: "unit-001",
            kernel: "Linux",
            battery: {
                percent: 82,
                status: "Discharging"
            },
            brightness: {
                percent: 69,
                device: "Laptop display"
            },
            equalizer: true,
            notifications: {
                count: 0,
                dnd: false
            },
            storage: {
                used: 120e9,
                total: 512e9,
                free: 392e9
            },
            usage: {
                seconds: 0,
                samples: []
            },
            preferences: {
                usageTracking: false,
                reducedMotion: false,
                widgets: {}
            }
        }) : Settings.state
    readonly property var outputs: Pipewire.nodes.values.filter(n => !n.isStream && n.isSink && n.audio)
    readonly property var inputs: Pipewire.nodes.values.filter(n => !n.isStream && !n.isSink && n.audio)
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var categories: Navigation.categories()
    readonly property var filteredCategories: categories.filter(c => !query || c.name.toLowerCase().includes(query.toLowerCase()))
    readonly property var categoryGroups: Navigation.groups()
    readonly property var filteredGroups: categoryGroups.map(group => group.map(id => filteredCategories.find(c => c.id === id)).filter(c => !!c)).filter(group => group.length)
    readonly property var navLayout: navigationLayout()
    function navigationLayout() {
        return Navigation.layout(filteredGroups, navigationMetrics);
    }
    signal closeRequested
    function choose(id) {
        if (!categories.some(c => c.id === id))
            return;
        page = id;
        pageFlick.contentY = 0;
        entrance.restart();
        let y = 0;
        for (const group of filteredGroups) {
            const index = group.findIndex(c => c.id === id);
            if (index >= 0) {
                y += index * navigationStride;
                if (categoryGroups[0].includes(id))
                    navFlick.contentY = 0;
                else if (y < navFlick.contentY)
                    navFlick.contentY = y;
                else if (y + navigationRowHeight + 2 * navigationInset > navFlick.contentY + navFlick.height)
                    navFlick.contentY = y + navigationRowHeight + 2 * navigationInset - navFlick.height;
                break;
            }
            y += navigationGroupHeight(group.length) + navigationGroupGap;
        }
    }
    onQueryChanged: navFlick.contentY = 0
    function requestPortrait(origin) {
        portraitOrigin = origin;
        portraitChooserRequested = true;
        portraitError = "";
        if (!previewMode)
            portraitDialog.open();
    }
    function selectPortrait(value) {
        portraitChooserRequested = false;
        if (previewMode)
            fixturePortrait = value;
        else
            portraitProbe.source = value;
    }
    function editName() {
        nameDraft = details.host || "";
        nameSubmitted = false;
        nameDialog.open();
    }
    function validName(value) {
        return /^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$/.test(value);
    }
    function saveName() {
        if (!validName(nameDraft) || Settings.busy)
            return;
        nameSubmitted = true;
        if (previewMode) {
            fixtureHost = nameDraft;
            nameDialog.close();
        } else
            apply("hostname", nameDraft);
    }
    function cancelName() {
        nameDialog.close();
    }
    function cancelPortrait() {
        portraitDialog.close();
        portraitChooserRequested = false;
    }
    function apply(name, value) {
        if (!previewMode)
            Settings.apply(name, value);
    }
    function preference(name, value) {
        if (!previewMode)
            Settings.preference(name, value);
    }
    // Disk usage browser for the Storage page. One scan, then browsing is instant.
    property var storageResult: null
    property var storageTrail: []
    property bool storageScanning: false
    property bool storageFailed: false
    property int storageItems: 0
    property real storageBytes: 0
    readonly property var storageNode: storageTrail.length ? storageTrail[storageTrail.length - 1] : storageResult?.tree ?? null
    readonly property string storageFolder: {
        const names = storageTrail.map(node => node.n);
        return [storageResult?.path ?? Quickshell.env("HOME")].concat(names).join("/");
    }
    // Mirrors PROTECTED in storage_scan.py, which also refuses them.
    readonly property bool storageCanEmpty: {
        const relative = storageTrail.map(node => node.n).join("/");
        return relative !== "" && ![".config", ".local", ".local/share", ".local/state", ".ssh", ".gnupg", ".pki"].includes(relative);
    }
    property bool storageConfirmEmpty: false
    property bool storageEmptying: false
    property string storageEmptyMessage: ""
    onStorageFolderChanged: {
        storageConfirmEmpty = false;
        storageEmptyMessage = "";
    }
    function emptyStorageFolder() {
        if (previewMode || storageEmptying || !storageCanEmpty)
            return;
        storageConfirmEmpty = false;
        storageEmptying = true;
        storageEmpty.command = ["python3", Quickshell.shellPath("storage_scan.py"), "--empty", storageFolder];
        storageEmpty.running = true;
    }
    function bytesLabel(value) {
        if (value >= 1e9)
            return (value / 1e9).toFixed(1) + " GB";
        if (value >= 1e6)
            return (value / 1e6).toFixed(0) + " MB";
        return Math.max(1, Math.round(value / 1e3)) + " KB";
    }
    function storageAge() {
        const minutes = Math.floor((Date.now() / 1000 - (storageResult?.scanned ?? 0)) / 60);
        if (minutes < 1)
            return "Just now";
        if (minutes < 60)
            return minutes + " min ago";
        if (minutes < 1440)
            return Math.floor(minutes / 60) + " h ago";
        return Math.floor(minutes / 1440) + " d ago";
    }
    function startStorageScan() {
        if (previewMode || storageScanning)
            return;
        storageFailed = false;
        storageItems = 0;
        storageBytes = 0;
        storageScanning = true;
        storageScan.running = true;
    }
    function readStorageLine(line) {
        let data;
        try {
            data = JSON.parse(line);
        } catch (error) {
            return;
        }
        if (data.tree) {
            // Stay in the same folder after a new scan, as far as it still exists.
            const names = storageTrail.map(node => node.n);
            const trail = [];
            let node = data.tree;
            for (const name of names) {
                node = (node.c ?? []).find(child => child.n === name && child.d === 1);
                if (!node)
                    break;
                trail.push(node);
            }
            storageResult = data;
            storageTrail = trail;
        } else if (data.items !== undefined) {
            storageItems = data.items;
            storageBytes = data.size;
        }
    }
    Process {
        id: storageScan
        command: ["python3", Quickshell.shellPath("storage_scan.py")]
        stdout: SplitParser {
            onRead: line => settings.readStorageLine(line)
        }
        onExited: code => {
            settings.storageScanning = false;
            settings.storageFailed = code !== 0 && storageScan.wasCancelled !== true;
            storageScan.wasCancelled = false;
        }
        property bool wasCancelled: false
    }
    Process {
        id: storageEmpty
        stdout: SplitParser {
            onRead: line => {
                const data = JSON.parse(line);
                if (data.error)
                    settings.storageEmptyMessage = "Not deleted: " + data.error;
                else if (data.failed)
                    settings.storageEmptyMessage = data.failed + " items could not be deleted";
            }
        }
        onExited: {
            settings.storageEmptying = false;
            settings.startStorageScan();
        }
    }
    Process {
        id: storageCached
        command: ["python3", Quickshell.shellPath("storage_scan.py"), "--cached"]
        stdout: SplitParser {
            onRead: line => settings.readStorageLine(line)
        }
    }
    function gigabytes(value) {
        return typeof value === "number" ? (value / 1e9).toFixed(1) + " GB" : "Unavailable";
    }
    function toggleAirplane() {
        if (previewMode)
            return;
        if (Networking.wifiEnabled || Desk.adapter?.enabled) {
            airplaneSnapshot = {
                wifi: Networking.wifiEnabled,
                bluetooth: !!Desk.adapter?.enabled
            };
            Networking.wifiEnabled = false;
            if (Desk.adapter)
                Desk.adapter.enabled = false;
        } else {
            Networking.wifiEnabled = airplaneSnapshot?.wifi ?? true;
            if (Desk.adapter)
                Desk.adapter.enabled = airplaneSnapshot?.bluetooth ?? true;
            airplaneSnapshot = null;
        }
    }
    function openWallpaperPicker() {
        wallpaperDialog.browse(settings.details.preferences?.wallpaper || "");
    }
    function status() {
        return JSON.stringify({
            wallpaperPickerVisible: wallpaperDialog.visible,
            wallpaperPreviewReady: wallpaperDialog.imageReady,
            page,
            query,
            x,
            y,
            width: scene.width,
            height: scene.height,
            scale: scene.scale,
            pageWidth: pageFlick.width,
            pageHeight: pageFlick.height,
            pageContentHeight: pageFlick.contentHeight,
            pageScroll: pageFlick.contentY,
            navHeight: navFlick.height,
            navTop: navFlick.y,
            searchTop: searchHousing.y,
            searchWidth: searchHousing.width,
            navScroll: navFlick.contentY,
            navContentHeight: navFlick.contentHeight,
            selectionY: navigationSelection.y,
            selectionTarget: settings.navLayout.rows.find(row => row.id === settings.page)?.y ?? 0,
            groupHeights: filteredGroups.map(g => navigationGroupHeight(g.length)),
            groupCategories: filteredGroups.map(g => g.map(c => c.id)),
            profileFont: Theme.textFont,
            portraitSource: portraitSource.toString(),
            portraitOrigin,
            portraitChooserRequested,
            portraitChooserVisible: portraitDialog.visible,
            nameEditor: nameDialog.visible,
            nameDraft,
            nameValid: validName(nameDraft),
            displayHost,
            categories: categories.length,
            preview: previewMode,
            visible,
            error: Settings.error
        });
    }
    function spacingStatus() {
        const icons = [];
        function visit(item) {
            if (item.objectName === "settings-navigation-icon") {
                const glyph = item.children.find(child => child.objectName === "settings-navigation-glyph");
                icons.push({
                    well: item.width,
                    glyph: glyph?.width ?? 0
                });
            }
            for (const child of item.children || [])
                visit(child);
        }
        visit(nav);
        return {
            rowHeight: navigationRowHeight,
            rowGap: navigationRowGap,
            groupGap: navigationGroupGap,
            icons,
            bodySpacing: body.spacing,
            nameGap: 18
        };
    }
    function publicCaptureItem() {
        // Battery history and display-on time are private. Export charge only.
        if (page !== "battery")
            return settings;
        const summary = pageLoader.item?.children.find(item => item.objectName === "settings-battery-summary");
        return summary?.children.find(item => item.objectName === "settings-battery-charge") ?? null;
    }
    Connections {
        target: Settings
        function onStateChanged() {
            if (nameSubmitted && nameDialog.visible && Settings.state.host === settings.nameDraft)
                nameDialog.close();
        }
    }
    PwObjectTracker {
        objects: settings.outputs.concat(settings.inputs)
    }
    focus: true
    Keys.onEscapePressed: closeRequested()

    component Section: Column {
        spacing: 12
        property string title: ""
        width: parent.width
        Label {
            text: parent.title
            font.pixelSize: 13
            color: settings.secondaryInk
            font.weight: Theme.mediumWeight
            visible: text !== ""
        }
    }
    component Card: G2Surface {
        width: parent.width
        radius: 12
        smoothing: .6
        color: settings.controlSurface
    }
    component ControlGroup: Card {
        objectName: "settings-control-group"
        default property alias controls: groupBody.data
        property int padding: 20
        implicitHeight: groupBody.height + padding * 2
        height: implicitHeight
        Column {
            id: groupBody
            x: parent.padding
            y: parent.padding
            width: parent.width - parent.padding * 2
            spacing: 12
        }
    }
    component Summary: Key {
        objectName: "settings-summary"
        property string icon: "info"
        property string name: ""
        property string value: ""
        property string detail: ""
        property bool actionable: true
        width: (body.width - 16) / 2
        height: 128
        radius: 12
        smoothing: .6
        color: settings.controlSurface
        border.width: activeFocus ? 1 : 0
        border.color: settings.primaryInk
        hint: name
        enabled: actionable
        opacity: 1
        SvgIcon { x: 20; y: 20; width: 18; height: 18; name: parent.icon }
        Label {
            x: 50; y: 20; width: parent.width - 90; height: 20
            text: parent.name; font.pixelSize: 12; color: settings.secondaryInk
        }
        SvgIcon {
            anchors.right: parent.right; anchors.rightMargin: 20
            y: 22; width: 14; height: 14; name: "forward"
            visible: parent.actionable; opacity: .7
        }
        Label {
            x: 20; y: 52; width: parent.width - 40; height: 36
            text: parent.value; font.pixelSize: 26; font.weight: Theme.mediumWeight
            color: settings.primaryInk
        }
        Label {
            x: 20; y: 99; width: parent.width - 40; height: 18
            text: parent.detail; font.pixelSize: 11; color: settings.secondaryInk
        }
    }
    component DeviceRow: Key {
        objectName: "settings-device-row"
        property string icon: ""
        property string name: ""
        property string value: ""
        property bool actionable: true
        readonly property real valueWidth: value ? Math.min(260, Math.max(60, valueLabel.implicitWidth)) : 0
        width: parent.width
        height: settings.controlHeight
        radius: 10
        smoothing: .6
        color: settings.controlSurface
        // Read-only measurements remain legible, unlike unavailable actions.
        opacity: actionable ? (enabled ? 1 : .42) : 1
        activeFocusOnTab: actionable && enabled
        hint: name
        G2Surface {
            x: 16
            y: (parent.height - height) / 2
            width: 32
            height: 32
            radius: 8
            color: "#2d2d2d"
            SvgIcon {
                anchors.centerIn: parent
                width: 18
                height: 18
                name: parent.parent.icon
            }
        }
        FadeLabel {
            x: 64
            y: (parent.height - height) / 2
            width: parent.width - parent.valueWidth - 128
            height: 22
            text: parent.name
            font.pixelSize: 13
            background: settings.controlSurface
        }
        Label {
            id: valueLabel
            anchors.right: parent.right
            anchors.rightMargin: parent.actionable ? 44 : 20
            y: (parent.height - height) / 2
            height: 22
            width: parent.valueWidth
            horizontalAlignment: Text.AlignRight
            text: parent.value
            font.pixelSize: 12
            color: settings.secondaryInk
        }
        SvgIcon {
            anchors.right: parent.right
            anchors.rightMargin: 18
            y: (parent.height - height) / 2
            width: 14
            height: 14
            name: "forward"
            visible: parent.actionable && parent.enabled
            opacity: .7
        }
    }
    component StorageButton: Key {
        property bool primary: false
        property string label: ""
        width: Math.max(88, buttonText.implicitWidth + 32)
        height: 34
        radius: 8
        selected: primary
        color: primary ? Theme.text : "#2d2d2d"
        hint: buttonText.text
        Label {
            id: buttonText
            anchors.centerIn: parent
            text: parent.label
            font.pixelSize: 12
            font.weight: Theme.mediumWeight
            color: parent.primary ? Theme.base : settings.primaryInk
        }
    }
    component StorageRow: Key {
        objectName: "settings-storage-row"
        property string name: ""
        property real size: 0
        property real share: 0
        property bool folder: false
        width: parent.width
        height: 42
        radius: 8
        smoothing: .6
        color: settings.controlSurface
        activeFocusOnTab: folder
        hint: name
        // The filled part of the row is its share of this folder.
        G2Surface {
            width: Math.max(4, parent.width * parent.share)
            height: parent.height
            radius: 8
            color: "#333333"
        }
        SvgIcon {
            x: 14
            y: 13
            width: 16
            height: 16
            name: "folder"
            visible: parent.folder
        }
        Label {
            x: 40
            y: 11
            width: parent.width - 220
            height: 20
            text: parent.name
            font.pixelSize: 13
            color: settings.primaryInk
        }
        Label {
            anchors.right: parent.right
            anchors.rightMargin: 96
            y: 11
            height: 20
            text: Math.round(parent.share * 100) + "%"
            font.pixelSize: 12
            color: settings.secondaryInk
        }
        Label {
            anchors.right: parent.right
            anchors.rightMargin: 34
            y: 11
            width: 60
            height: 20
            horizontalAlignment: Text.AlignRight
            text: settings.bytesLabel(parent.size)
            font.pixelSize: 12
            color: settings.primaryInk
        }
        SvgIcon {
            anchors.right: parent.right
            anchors.rightMargin: 12
            y: 14
            width: 14
            height: 14
            name: "forward"
            visible: parent.folder
            opacity: .7
        }
    }
    component ToggleRow: G2Surface {
        objectName: "settings-toggle-row"
        property string name: ""
        property string icon: "settings"
        property bool checked: false
        signal toggled(bool value)
        width: parent.width
        height: settings.controlHeight
        radius: 10
        smoothing: .6
        color: settings.controlSurface
        SvgIcon {
            x: 16
            y: (parent.height - height) / 2
            width: 18
            height: 18
            name: parent.icon
        }
        Label {
            x: 48
            y: (parent.height - height) / 2
            height: 22
            width: parent.width - 140
            text: parent.name
            font.pixelSize: 13
        }
        SettingsToggle {
            anchors.right: parent.right
            anchors.rightMargin: 16
            y: (parent.height - height) / 2
            checked: parent.checked
            enabled: parent.enabled && !Settings.busy
            hint: parent.name
            onToggled: value => parent.toggled(value)
        }
    }
    component Note: Label {
        width: parent.width
        wrapMode: Text.WordWrap
        elide: Text.ElideNone
        color: "#b8b8b8"
        font.pixelSize: 12
        lineHeight: 1.35
    }
    component SoundControl: Column {
        property string name: ""
        property string icon: "volume"
        property real amount: 0
        signal moved(real value)
        width: parent.width
        spacing: 14
        Row {
            width: parent.width
            spacing: 12
            SvgIcon {
                width: 20
                height: 20
                name: parent.parent.icon
            }
            Label {
                width: parent.width - 88
                text: parent.parent.name
                font.pixelSize: 13
            }
            Label {
                text: Math.round(parent.parent.amount) + "%"
                font.pixelSize: 12
                horizontalAlignment: Text.AlignRight
                width: 44
            }
        }
        SettingsSlider {
            objectName: "settings-level-slider"
            width: parent.width
            value: parent.amount
            label: parent.name
            enabled: parent.enabled
            onMoved: parent.moved(value)
        }
    }

    Item {
        id: scene
        width: settings.width / scale
        height: settings.height / scale
        scale: settings.fit
        transformOrigin: Item.TopLeft
        // The page column stays 690 wide and sits centred in the room beside the sidebar.
        readonly property real pageX: 262 + Math.max(36, Math.round((width - 262 - 690) / 2))
        G2Surface {
            anchors.fill: parent
            radius: 10
            smoothing: .6
            color: "#171717"
        }
        G2Surface {
            x: 262
            width: parent.width - 262
            height: parent.height
            radius: 10
            smoothing: .6
            color: "#111111"
        }
        Label {
            x: 25
            y: 18
            width: 200
            height: 28
            verticalAlignment: Text.AlignVCenter
            text: "Settings"
            font.family: Theme.textFont
            font.pixelSize: 20
            font.weight: Theme.boldWeight
            color: "#ffffff"
        }
        G2Surface {
            id: searchHousing
            x: 17
            y: 56
            width: 227
            height: 30
            radius: 15
            smoothing: .6
            color: "#4a4a4a"
            border.width: search.activeFocus ? 1 : 0
            border.color: settings.secondaryInk
            Label {
                x: 16
                y: 7
                text: "Search here"
                visible: search.text.length === 0
                color: "#979797"
                font.pixelSize: 12
            }
            TextInput {
                id: search
                objectName: "settings-search"
                x: 16
                y: 7
                width: 175
                height: 18
                color: "#ffffff"
                font.family: Theme.font
                font.pixelSize: 12
                text: settings.query
                onTextChanged: settings.query = text
                selectByMouse: true
                clip: true
                Accessible.name: "Find Settings"
            }
            Key {
                objectName: "settings-search-clear"
                x: 199
                y: 5
                width: 20
                height: 20
                radius: 10
                visible: search.text.length > 0
                hint: "Clear search"
                onClicked: settings.query = ""
                SvgIcon {
                    anchors.centerIn: parent
                    width: 12
                    height: 12
                    name: "close"
                }
            }
        }
        Flickable {
            id: navFlick
            x: 17
            y: 98
            width: 231
            height: parent.height - 109
            contentHeight: nav.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            // Curve-rendered G2 wells must be composited before viewport clipping.
            layer.enabled: true
            layer.smooth: true
            layer.textureSize: Qt.size(Math.ceil(width * scene.scale * settings.pixelRatio), Math.ceil(height * scene.scale * settings.pixelRatio))
            Controls.ScrollBar.vertical: Controls.ScrollBar {
                policy: Controls.ScrollBar.AsNeeded
            }
            Item {
                id: nav
                width: 231
                height: settings.navLayout.height
                // Logical groups keep their spacing without housings or lines.
                G2Surface {
                    id: navigationSelection
                    x: 0
                    y: settings.navLayout.rows.find(row => row.id === settings.page)?.y ?? 0
                    visible: settings.navLayout.rows.some(row => row.id === settings.page)
                    width: 227
                    height: settings.navigationRowHeight
                    radius: 10
                    smoothing: .6
                    color: "#303030"
                    Behavior on y {
                        NumberAnimation {
                            duration: Theme.reducedMotion ? 0 : 280
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.22, 1, 0.36, 1, 1, 1]
                        }
                    }
                }
                Repeater {
                    model: settings.navLayout.rows
                    Key {
                        required property var modelData
                        objectName: "settings-navigation-" + modelData.id
                        hoverFeedback: modelData.id !== settings.page
                        y: modelData.y
                        width: 231
                        height: settings.navigationRowHeight
                        radius: 10
                        hint: modelData.name
                        color: "transparent"
                        onClicked: settings.choose(modelData.id)
                        G2Surface {
                            objectName: "settings-navigation-icon"
                            x: 12
                            y: (parent.height - height) / 2
                            width: 28
                            height: 28
                            radius: 8
                            smoothing: .6
                            color: modelData.id === settings.page ? "#191919" : "#242424"
                            SvgIcon {
                                objectName: "settings-navigation-glyph"
                                anchors.centerIn: parent
                                width: parent.width * settings.iconRatio
                                height: width
                                name: modelData.icon
                            }
                        }
                        Label {
                            x: 52
                            y: (parent.height - height) / 2
                            width: modelData.id === "airplane" ? 112 : 162
                            height: 18
                            text: modelData.name
                            font.pixelSize: 12
                            font.weight: modelData.id === settings.page ? Theme.mediumWeight : Font.Normal
                            color: modelData.id === settings.page ? settings.primaryInk : "#d1d1d1"
                        }
                        SettingsToggle {
                            visible: modelData.id === "airplane"
                            x: 165
                            y: (parent.height - height) / 2
                            checked: !Networking.wifiEnabled && !Desk.adapter?.enabled
                            hint: "Airplane Mode"
                            onToggled: settings.toggleAirplane()
                        }
                    }
                }
                Label {
                    visible: settings.filteredCategories.length === 0
                    text: "No results"
                    font.pixelSize: 11
                }
            }
        }

        Flickable {
            id: pageFlick
            x: scene.pageX
            y: 53
            width: 690
            height: parent.height - 97
            clip: true
            layer.enabled: true
            layer.smooth: true
            layer.textureSize: Qt.size(Math.ceil(width * scene.scale * settings.pixelRatio), Math.ceil(height * scene.scale * settings.pixelRatio))
            contentHeight: body.height
            boundsBehavior: Flickable.StopAtBounds
            Controls.ScrollBar.vertical: Controls.ScrollBar {
                policy: Controls.ScrollBar.AsNeeded
            }
            Column {
                id: body
                width: 690
                spacing: 32
                opacity: 1
                NumberAnimation {
                    id: entrance
                    target: body
                    property: "opacity"
                    from: .78
                    to: 1
                    duration: Theme.reducedMotion ? 0 : 140
                }
                Item {
                    visible: settings.page !== "general"
                    width: parent.width
                    height: 32
                    Label {
                        width: parent.width; height: 32
                        verticalAlignment: Text.AlignVCenter
                        text: settings.categories.find(c => c.id === settings.page)?.name || ""
                        font.pixelSize: 22
                        font.weight: Theme.boldWeight
                        color: settings.primaryInk
                    }
                }
                Loader {
                    id: pageLoader
                    objectName: "settings-page-loader"
                    width: body.width
                    sourceComponent: ({
                            general: generalPage,
                            network: networkPage,
                            bluetooth: bluetoothPage,
                            airplane: airplanePage,
                            accessibility: accessibilityPage,
                            sound: soundPage,
                            battery: batteryPage,
                            widgets: widgetsPage,
                            brightness: brightnessPage,
                            wallpaper: wallpaperPage,
                            notifications: notificationsPage,
                            storage: storagePage,
                            applications: applicationsPage,
                            about: aboutPage
                        })[settings.page]
                }
                Note {
                    visible: !settings.previewMode && Settings.error !== ""
                    text: Settings.error
                }
                Note {
                    visible: settings.portraitError !== ""
                    text: settings.portraitError
                }
            }
        }
    }

    Component {
        id: generalPage
        Item {
            width: body.width
            height: 456
            G2Image {
                x: 287
                y: 0
                width: 116
                height: 116
                radius: 21
                source: settings.portraitSource
            }
            Key {
                x: 287
                y: 0
                width: 116
                height: 116
                radius: 21
                smoothing: .6
                hint: "Choose profile picture"
                onClicked: settings.requestPortrait("general")
            }
            Row {
                x: 345 - width / 2
                y: 130
                spacing: 18
                Label {
                    width: Math.min(implicitWidth, 430)
                    height: 28
                    text: settings.displayHost
                    font.family: Theme.textFont
                    font.pixelSize: 20
                    font.weight: Theme.boldWeight
                    color: "#ffffff"
                }
                Key {
                    y: 1
                    width: 26
                    height: 26
                    radius: 8
                    hint: "Rename PC"
                    onClicked: settings.editName()
                    SvgIcon {
                        anchors.centerIn: parent
                        width: 11
                        height: 11
                        name: "edit"
                    }
                }
            }
            Row {
                y: 176
                width: parent.width
                spacing: 16
                Summary {
                    objectName: "settings-overview-battery"
                    icon: "battery"
                    name: "Battery"
                    value: settings.details.battery ? settings.details.battery.percent + "%" : "AC power"
                    detail: settings.details.battery?.status || "No battery detected"
                    onClicked: settings.choose("battery")
                }
                Summary {
                    objectName: "settings-overview-storage"
                    icon: "storage"
                    name: "Storage"
                    value: settings.gigabytes(settings.details.storage?.free)
                    detail: settings.details.storage ? "Free of " + settings.gigabytes(settings.details.storage.total) : "Storage unavailable"
                    onClicked: settings.choose("storage")
                }
            }
            Column {
                y: 320
                width: parent.width
                spacing: 12
                DeviceRow {
                    objectName: "settings-overview-sound"
                    icon: "volume"
                    name: "Sound"
                    value: settings.previewMode ? Math.round(settings.fixtureVolume) + "%" : Desk.audio ? (Desk.muted ? "Muted" : Math.round(Desk.volume) + "%") : "Unavailable"
                    onClicked: settings.choose("sound")
                }
                DeviceRow {
                    icon: "accessibility"
                    name: "Reduced motion"
                    value: Theme.reducedMotion ? "On" : "Off"
                    onClicked: settings.choose("accessibility")
                }
            }
        }
    }
    Component {
        id: soundPage
        Column {
            width: body.width
            spacing: 24
            ControlGroup {
              SoundControl {
                name: "Output volume"
                amount: settings.previewMode ? settings.fixtureVolume : Desk.volume
                enabled: settings.previewMode || !!Desk.audio
                onMoved: value => {
                    if (settings.previewMode)
                        settings.fixtureVolume = value;
                    else
                        Desk.setVolume(value / 100);
                }
              }
              ToggleRow {
                name: "Mute output"
                icon: "mute"
                checked: !settings.previewMode && Desk.muted
                enabled: settings.previewMode || !!Desk.audio
                onToggled: if (!settings.previewMode)
                    Desk.mute()
              }
            }
            Section {
                title: "Output device"
                Repeater {
                    model: settings.previewMode ? [
                        {
                            description: "Speakers",
                            name: "preview"
                        }
                    ] : settings.outputs
                    DeviceRow {
                        required property var modelData
                        icon: "volume"
                        name: modelData.description || modelData.name
                        value: !settings.previewMode && modelData === Pipewire.defaultAudioSink ? "Selected" : ""
                        onClicked: if (!settings.previewMode)
                            Pipewire.preferredDefaultAudioSink = modelData
                    }
                }
                Note {
                    visible: !settings.previewMode && !settings.outputs.length
                    text: "No output devices"
                }
            }
            ControlGroup {
              SoundControl {
                name: "Microphone level"
                icon: "microphone"
                amount: settings.previewMode ? settings.fixtureInput : Math.round((settings.source?.audio?.volume ?? 0) * 100)
                enabled: settings.previewMode || !!settings.source?.audio
                onMoved: value => {
                    if (settings.previewMode)
                        settings.fixtureInput = value;
                    else if (settings.source?.audio)
                        settings.source.audio.volume = value / 100;
                }
              }
              ToggleRow {
                name: "Mute microphone"
                icon: "microphone"
                checked: !settings.previewMode && !!settings.source?.audio?.muted
                enabled: settings.previewMode || !!settings.source?.audio
                onToggled: value => {
                    if (!settings.previewMode && settings.source?.audio)
                        settings.source.audio.muted = value;
                }
              }
            }
            Section {
                title: "Input device"
                Repeater {
                    model: settings.previewMode ? [
                        {
                            description: "Microphone",
                            name: "preview"
                        }
                    ] : settings.inputs
                    DeviceRow {
                        required property var modelData
                        icon: "microphone"
                        name: modelData.description || modelData.name
                        value: !settings.previewMode && modelData === Pipewire.defaultAudioSource ? "Selected" : ""
                        onClicked: if (!settings.previewMode)
                            Pipewire.preferredDefaultAudioSource = modelData
                    }
                }
                Note {
                    visible: !settings.previewMode && !settings.inputs.length
                    text: "No input devices"
                }
            }
            DeviceRow {
                icon: "settings"
                name: "Equalizer"
                value: settings.details.equalizer ? "EasyEffects" : "Unavailable"
                enabled: !!settings.details.equalizer
                onClicked: if (!settings.previewMode)
                    Quickshell.execDetached(["easyeffects"])
            }
        }
    }
    Component {
        id: batteryPage
        Column {
            width: body.width
            spacing: 24
            ControlGroup {
                PowerProfileControls {
                    width: parent.width
                    previewMode: settings.previewMode
                }
            }
            Row {
                objectName: "settings-battery-summary"
                width: parent.width
                spacing: 16
                Summary {
                    objectName: "settings-battery-charge"
                    icon: "battery"
                    name: "Charge"
                    value: settings.details.battery ? settings.details.battery.percent + "%" : "AC power"
                    detail: settings.details.battery?.status || "No battery detected"
                    actionable: false
                }
                Summary {
                    icon: "clock"
                    name: "Display-on time today"
                    value: settings.details.preferences?.usageTracking ? Math.floor((settings.details.usage?.seconds ?? 0) / 3600) + "h " + Math.floor((settings.details.usage?.seconds ?? 0) % 3600 / 60) + "m" : "Not recording"
                    detail: "While ghOSt is running"
                    actionable: false
                }
            }
            ControlGroup {
                ToggleRow {
                    name: "Record battery and display-on time"
                    icon: "clock"
                    checked: !!settings.details.preferences?.usageTracking
                    onToggled: value => settings.preference("usageTracking", value)
                }
                Note { text: "History stays on this computer." }
            }
            Section {
                title: "Battery history"
                Repeater {
                    model: (settings.details.usage?.samples ?? []).filter((_, i, a) => i % Math.max(1, Math.floor(a.length / 8)) === 0).slice(-8)
                    DeviceRow {
                        required property var modelData
                        icon: "battery"
                        name: Qt.formatDateTime(new Date(modelData.time * 1000), "HH:mm")
                        value: modelData.percent + "% · " + modelData.status
                        actionable: false
                        enabled: false
                    }
                }
                Note {
                    visible: !(settings.details.usage?.samples?.length)
                    text: "No history yet"
                }
            }
        }
    }
    Component {
        id: widgetsPage
        ControlGroup {
            padding: 8
            Column {
                width: parent.width
                spacing: 6
                Repeater {
                    model: [
                        {
                            id: "network",
                            name: "Wireless Network",
                            icon: "wifi"
                        },
                        {
                            id: "bluetooth",
                            name: "Bluetooth",
                            icon: "bluetooth"
                        },
                        {
                            id: "volume",
                            name: "Volume",
                            icon: "volume"
                        },
                        {
                            id: "brightness",
                            name: "Brightness",
                            icon: "brightness"
                        },
                        {
                            id: "notifications",
                            name: "Notifications",
                            icon: "notifications"
                        }
                    ]
                    ToggleRow {
                        required property var modelData
                        name: modelData.name
                        icon: modelData.icon
                        checked: Settings.widget(modelData.id)
                        onToggled: value => settings.preference("widgets." + modelData.id, value)
                    }
                }
            }
        }
    }
    Component {
        id: brightnessPage
        Column {
            id: brightnessList
            property int controllable: 0
            width: body.width
            spacing: 24
            // One slider per display that answers: a laptop backlight or a monitor's own setting.
            Repeater {
                model: settings.previewMode ? [{name: "eDP-1"}] : Quickshell.screens
                ControlGroup {
                    id: displayGroup
                    required property var modelData
                    readonly property bool available: settings.previewMode || display.percent !== null
                    visible: available
                    onAvailableChanged: brightnessList.controllable += available ? 1 : -1
                    Component.onCompleted: if (available)
                        brightnessList.controllable++
                    Component.onDestruction: if (available)
                        brightnessList.controllable--
                    DisplayBrightness {
                        id: display
                        screenName: displayGroup.modelData.name
                        active: !settings.previewMode
                    }
                    SoundControl {
                        name: displayGroup.modelData.name.startsWith("eDP-") ? "Laptop display" : displayGroup.modelData.model || displayGroup.modelData.name
                        icon: "brightness"
                        amount: settings.previewMode ? settings.details.brightness?.percent ?? 0 : display.percent ?? 0
                        onMoved: value => display.set(Math.max(1, Math.round(value)))
                    }
                }
            }
            Note {
                visible: brightnessList.controllable === 0
                text: "No controllable display detected"
            }
        }
    }
    Component {
        id: wallpaperPage
        Column {
            width: body.width
            spacing: 24
            Card {
                height: 240
                Image {
                    anchors.fill: parent
                    anchors.margins: 1
                    source: settings.details.preferences?.wallpaper ? "file://" + settings.details.preferences.wallpaper : ""
                    fillMode: Image.PreserveAspectFit
                }
                SvgIcon {
                    visible: !settings.details.preferences?.wallpaper
                    anchors.centerIn: parent
                    width: 48
                    height: 48
                    name: "wallpaper"
                    opacity: .5
                }
            }
            DeviceRow {
                icon: "wallpaper"
                name: "Choose image"
                value: "Browse"
                onClicked: if (!settings.previewMode)
                    settings.openWallpaperPicker()
            }
            Note {
                text: settings.details.preferences?.wallpaper || "Choose an image to apply through awww"
            }
        }
    }
    WallpaperPicker {
        id: wallpaperDialog
        parent: scene
        x: (scene.width - width) / 2
        y: (scene.height - height) / 2
        onImageChosen: file => settings.apply("wallpaper", file.toString())
    }
    FileDialog {
        id: portraitDialog
        title: "Choose profile picture"
        nameFilters: ["Images (*.png *.jpg *.jpeg *.webp *.bmp)"]
        onAccepted: settings.selectPortrait(selectedFile.toString())
        onRejected: settings.portraitChooserRequested = false
    }
    Image {
        id: portraitProbe
        visible: false
        onStatusChanged: {
            if (status === Image.Ready)
                settings.apply("profile-picture", source.toString());
            else if (status === Image.Error)
                settings.portraitError = "Could not open this image. Choose another picture.";
        }
    }
    Controls.Popup {
        id: nameDialog
        parent: scene
        x: 302
        y: 240
        width: 420
        height: 218
        padding: 20
        modal: true
        focus: true
        closePolicy: Controls.Popup.CloseOnEscape | Controls.Popup.CloseOnPressOutside
        background: G2Surface {
            radius: 10
            color: settings.controlSurface
            border.width: 1
            border.color: "#898989"
        }
        onOpened: nameInput.forceActiveFocus()
        onClosed: settings.nameSubmitted = false
        contentItem: Item {
            Label {
                text: "PC name"
                font.pixelSize: 16
                font.weight: Theme.boldWeight
            }
            Controls.TextField {
                id: nameInput
                y: 36
                width: 380
                height: 36
                text: settings.nameDraft
                onTextChanged: settings.nameDraft = text
                font.family: Theme.font
                font.pixelSize: 12
                color: "#ffffff"
                selectByMouse: true
                enabled: !Settings.busy
                Accessible.name: "PC name"
                background: G2Surface {
                    radius: 8
                    color: "#191919"
                    border.width: 1
                    border.color: nameInput.activeFocus ? "#d9d9d9" : "#535353"
                }
                onAccepted: if (settings.validName(text))
                    settings.saveName()
            }
            Label {
                y: 82
                width: 380
                wrapMode: Text.WordWrap
                elide: Text.ElideNone
                font.pixelSize: 10
                color: "#b8b8b8"
                text: settings.nameSubmitted && Settings.error ? Settings.error : "1-63 lowercase letters, numbers or hyphens. No edge hyphens."
            }
            Key {
                x: 180
                y: 140
                width: 92
                height: 34
                radius: 8
                text: "Cancel"
                hint: "Cancel rename"
                onClicked: nameDialog.close()
            }
            Key {
                x: 284
                y: 140
                width: 96
                height: 34
                radius: 8
                text: "Save"
                hint: "Save PC name"
                selected: true
                enabled: settings.validName(settings.nameDraft) && !Settings.busy
                onClicked: settings.saveName()
            }
        }
    }
    Component {
        id: notificationsPage
        Column {
            width: body.width
            spacing: 24
            ToggleRow {
                name: "Do not disturb"
                icon: "notifications"
                checked: Notifications.dnd
                enabled: Notifications.ready
                onToggled: value => Notifications.setDnd(value)
            }
            Note {
                visible: Notifications.mode === "observe"
                text: "History starts when ghOSt opens. Do not disturb silences ghOSt banners only while another notification service is active."
            }
            Note {
                visible: !Notifications.ready
                text: Notifications.error || "Notification connection unavailable"
            }
            Section {
                title: "Notification history"
                NotificationList {
                    width: parent.width
                    height: 320
                    previewMode: settings.previewMode
                }
                Key {
                    width: 110
                    height: 32
                    radius: 8
                    text: "Dismiss all"
                    hint: "Dismiss notifications"
                    enabled: Notifications.count > 0
                    onClicked: Notifications.clear()
                }
            }
        }
    }
    Component {
        id: networkPage
        Column {
            width: body.width
            spacing: 24
            ToggleRow {
                name: "Wi-Fi"
                icon: "wifi"
                checked: settings.previewMode || Networking.wifiEnabled
                onToggled: value => {
                    if (!settings.previewMode)
                        Networking.wifiEnabled = value;
                }
            }
            Section {
                title: "Networks"
                Repeater {
                    model: settings.previewMode ? [
                        {
                            name: "Network 01",
                            connected: true,
                            known: true
                        }
                    ] : Desk.wifi?.networks.values ?? []
                    DeviceRow {
                        required property var modelData
                        icon: "wifi"
                        name: modelData.name
                        value: modelData.connected ? "Connected" : ""
                        onClicked: {
                            if (settings.previewMode || modelData.connected)
                                return;
                            if (modelData.known)
                                modelData.connect();
                            else
                                Quickshell.execDetached(["nm-connection-editor"]);
                        }
                    }
                }
            }
            DeviceRow {
                icon: "network"
                name: "Connection profiles"
                value: "Open"
                onClicked: if (!settings.previewMode)
                    Quickshell.execDetached(["nm-connection-editor"])
            }
        }
    }
    Component {
        id: bluetoothPage
        Column {
            width: body.width
            spacing: 24
            ToggleRow {
                name: "Bluetooth"
                icon: "bluetooth"
                checked: settings.previewMode || !!Desk.adapter?.enabled
                enabled: settings.previewMode || !!Desk.adapter
                onToggled: value => {
                    if (!settings.previewMode && Desk.adapter)
                        Desk.adapter.enabled = value;
                }
            }
            Section {
                title: "Devices"
                Repeater {
                    model: settings.previewMode ? [
                        {
                            name: "Keyboard",
                            connected: true
                        }
                    ] : Desk.adapter?.devices.values ?? []
                    DeviceRow {
                        required property var modelData
                        icon: "bluetooth"
                        name: modelData.name || modelData.address
                        value: modelData.connected ? "Connected" : ""
                        onClicked: if (!settings.previewMode)
                            modelData.connected = !modelData.connected
                    }
                }
            }
            DeviceRow {
                icon: "bluetooth"
                name: "Pair a device"
                value: "Open"
                onClicked: if (!settings.previewMode)
                    Quickshell.execDetached(["blueman-manager"])
            }
        }
    }
    Component {
        id: airplanePage
        Column {
            width: body.width
            spacing: 24
            ToggleRow {
                name: "Airplane Mode"
                icon: "network"
                checked: !Networking.wifiEnabled && !Desk.adapter?.enabled
                onToggled: settings.toggleAirplane()
            }
            Note {
                text: "Turns Wi-Fi and Bluetooth off. Turning it off restores their previous state."
            }
        }
    }
    Component {
        id: accessibilityPage
        Column {
            width: body.width
            spacing: 24
            // Saved when released, so the window does not resize under the pointer.
            Column {
                id: scaleControl
                objectName: "settings-shell-scale"
                property real draft: Math.round(Theme.shellScale * 100)
                function commit(value) {
                    if (value !== Math.round(Theme.shellScale * 100))
                        settings.preference("shellScale", (value / 100).toFixed(2));
                }
                width: parent.width
                spacing: 14
                Connections {
                    target: Theme
                    function onShellScaleChanged() {
                        scaleControl.draft = Math.round(Theme.shellScale * 100);
                    }
                }
                Row {
                    width: parent.width
                    spacing: 12
                    SvgIcon {
                        width: 20
                        height: 20
                        name: "display"
                    }
                    Label {
                        width: parent.width - 88
                        text: "Scale"
                        font.pixelSize: 13
                    }
                    Label {
                        text: scaleControl.draft + "%"
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignRight
                        width: 44
                    }
                }
                SettingsSlider {
                    width: parent.width
                    from: 75
                    to: 150
                    stepSize: 5
                    snapMode: Controls.Slider.SnapAlways
                    value: Math.round(Theme.shellScale * 100)
                    label: "Scale"
                    enabled: !Settings.busy
                    onMoved: {
                        scaleControl.draft = value;
                        if (!pressed)
                            scaleControl.commit(value);
                    }
                    onPressedChanged: if (!pressed)
                        scaleControl.commit(value)
                }
            }
            ToggleRow {
                name: "Reduced motion"
                icon: "accessibility"
                checked: Theme.reducedMotion
                onToggled: value => settings.preference("reducedMotion", value)
            }
            Note {
                text: "Immediate panel transitions; weather flashes stop."
            }
        }
    }
    Component {
        id: storagePage
        Column {
            width: body.width
            spacing: 24
            // A passive measurement, not a disabled slider suggesting a setter.
            ControlGroup {
                Item {
                    width: parent.width
                    height: 34
                    Label {
                        anchors.left: parent.left
                        anchors.baseline: parent.bottom
                        anchors.baselineOffset: -8
                        text: settings.gigabytes(settings.details.storage?.used) + " used"
                        font.pixelSize: 24
                        font.weight: Theme.demiWeight
                        color: settings.primaryInk
                    }
                    Label {
                        anchors.right: parent.right
                        anchors.baseline: parent.bottom
                        anchors.baselineOffset: -8
                        text: settings.gigabytes(settings.details.storage?.free) + " free of " + settings.gigabytes(settings.details.storage?.total)
                        font.pixelSize: 12
                        color: settings.secondaryInk
                    }
                }
                G2Surface {
                    objectName: "settings-storage-meter"
                    width: parent.width; height: 8; radius: 4; color: "#414141"
                    Accessible.role: Accessible.ProgressBar
                    Accessible.name: "Used storage"
                    Accessible.description: settings.details.storage ? Math.round(100 * settings.details.storage.used / settings.details.storage.total) + " percent used" : "Unavailable"
                    G2Surface {
                        objectName: "settings-storage-fill"
                        width: parent.width * Math.max(0, Math.min(1, (settings.details.storage?.used ?? 0) / (settings.details.storage?.total || 1)))
                        height: parent.height; radius: 4; color: "#d9d9d9"
                    }
                }
            }
            Column {
                objectName: "settings-storage-browser"
                width: parent.width
                spacing: 12
                Component.onCompleted: if (!settings.previewMode && !settings.storageResult)
                    storageCached.running = true

                // Title, and when the numbers below were measured.
                Item {
                    width: parent.width
                    height: 34
                    Label {
                        y: 7
                        text: "What's using space"
                        font.pixelSize: 16
                        font.weight: Theme.demiWeight
                        color: settings.primaryInk
                    }
                    Row {
                        anchors.right: parent.right
                        spacing: 12
                        visible: settings.storageResult !== null && !settings.storageScanning
                        Label {
                            y: 8
                            text: settings.storageFailed ? "Scan failed" : "Scanned " + settings.storageAge().toLowerCase()
                            font.pixelSize: 12
                            color: settings.secondaryInk
                        }
                        StorageButton {
                            objectName: "settings-storage-rescan"
                            label: "Scan again"
                            onClicked: settings.startStorageScan()
                        }
                    }
                }

                // Nothing measured yet.
                ControlGroup {
                    objectName: "settings-storage-start"
                    visible: settings.storageResult === null && !settings.storageScanning
                    Note { text: settings.storageFailed ? "Scan failed." : "Scan to see which folders take up the most space." }
                    StorageButton {
                        objectName: "settings-storage-scan"
                        primary: true
                        label: "Scan"
                        onClicked: settings.startStorageScan()
                    }
                }

                // Measuring.
                ControlGroup {
                    objectName: "settings-storage-progress"
                    visible: settings.storageScanning
                    Label {
                        text: "Scanning"
                        font.pixelSize: 13
                        color: settings.primaryInk
                    }
                    Note {
                        text: settings.bytesLabel(settings.storageBytes) + " in " + settings.storageItems.toLocaleString(Qt.locale(), "f", 0) + " items"
                    }
                    StorageButton {
                        objectName: "settings-storage-cancel"
                        label: "Stop"
                        onClicked: {
                            storageScan.wasCancelled = true;
                            storageScan.running = false;
                        }
                    }
                }

                // The folder being viewed.
                Column {
                    visible: settings.storageNode !== null && !settings.storageScanning
                    width: parent.width
                    spacing: 12
                    Item {
                        width: parent.width
                        height: 34
                        StorageButton {
                            id: storageBack
                            objectName: "settings-storage-back"
                            visible: settings.storageTrail.length > 0
                            width: 34
                            hint: "Back"
                            label: ""
                            onClicked: settings.storageTrail = settings.storageTrail.slice(0, -1)
                            SvgIcon {
                                anchors.centerIn: parent
                                width: 14
                                height: 14
                                name: "back"
                            }
                        }
                        Label {
                            objectName: "settings-storage-folder"
                            x: storageBack.visible ? 46 : 0
                            y: 7
                            width: parent.width - x - 90
                            height: 20
                            text: settings.storageFolder.replace(Quickshell.env("HOME"), "Home")
                            font.pixelSize: 13
                            color: settings.primaryInk
                        }
                        Label {
                            anchors.right: parent.right
                            y: 7
                            height: 20
                            text: settings.storageNode ? settings.bytesLabel(settings.storageNode.s) : ""
                            font.pixelSize: 13
                            font.weight: Theme.demiWeight
                            color: settings.primaryInk
                        }
                    }

                    // Actions on this folder, or the question before deleting.
                    Row {
                        visible: !settings.storageConfirmEmpty
                        spacing: 8
                        StorageButton {
                            objectName: "settings-storage-open"
                            label: "Open in Files"
                            onClicked: if (!settings.previewMode)
                                Quickshell.execDetached(["xdg-open", settings.storageFolder])
                        }
                        StorageButton {
                            objectName: "settings-storage-empty"
                            visible: settings.storageCanEmpty
                            enabled: !settings.storageEmptying
                            label: settings.storageEmptying ? "Deleting" : "Delete everything inside"
                            onClicked: settings.storageConfirmEmpty = true
                        }
                    }
                    ControlGroup {
                        objectName: "settings-storage-confirm"
                        visible: settings.storageConfirmEmpty
                        Label {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            elide: Text.ElideNone
                            text: "Delete everything inside " + settings.storageFolder.replace(Quickshell.env("HOME"), "Home") + "?"
                            font.pixelSize: 14
                            font.weight: Theme.demiWeight
                            color: settings.primaryInk
                        }
                        Note {
                            text: settings.bytesLabel(settings.storageNode?.s ?? 0) + " will be permanently deleted. It won't go to the trash and can't be undone."
                        }
                        Row {
                            spacing: 8
                            StorageButton {
                                objectName: "settings-storage-confirm-cancel"
                                label: "Cancel"
                                onClicked: settings.storageConfirmEmpty = false
                            }
                            StorageButton {
                                objectName: "settings-storage-confirm-delete"
                                primary: true
                                label: "Delete permanently"
                                onClicked: settings.emptyStorageFolder()
                            }
                        }
                    }
                    Note {
                        visible: settings.storageEmptyMessage !== ""
                        text: settings.storageEmptyMessage
                    }

                    // Biggest first. Hidden while confirming, so only the question is on screen.
                    Column {
                        visible: !settings.storageConfirmEmpty
                        width: parent.width
                        spacing: 6
                        Repeater {
                            model: settings.storageNode?.c ?? []
                            StorageRow {
                                required property var modelData
                                name: modelData.n
                                size: modelData.s
                                share: settings.storageNode.s > 0 ? modelData.s / settings.storageNode.s : 0
                                folder: modelData.d === 1
                                onClicked: if (folder)
                                    settings.storageTrail = settings.storageTrail.concat([modelData])
                            }
                        }
                        Note {
                            objectName: "settings-storage-others"
                            visible: (settings.storageNode?.m ?? 0) > 0
                            topPadding: 6
                            text: (settings.storageNode?.m ?? 0).toLocaleString(Qt.locale(), "f", 0) + " smaller items, " + settings.bytesLabel(settings.storageNode?.o ?? 0)
                        }
                        Note {
                            visible: (settings.storageResult?.unreadable ?? 0) > 0 && settings.storageTrail.length === 0
                            text: (settings.storageResult?.unreadable ?? 0) + " could not be read"
                        }
                    }
                }
            }
        }
    }
    Component {
        id: applicationsPage
        Column {
            width: body.width
            spacing: 24
            DeviceRow {
                icon: "app"
                name: "Installed applications"
                value: "Open launcher"
                onClicked: if (!settings.previewMode) {
                    Desk.settingsRequested = false;
                    Desk.toggle("launcher", Desk.panelScreen, Math.max(0, scene.width / 2 - 196));
                }
            }
            TopBarEditor {
                width: parent.width
                savedLayout: settings.previewMode ? null : Settings.state.preferences?.railLayout || null
                busy: Settings.busy
                onApplyRequested: value => {
                    if (!settings.previewMode)
                        Settings.preference("rail.layout", value);
                }
            }
        }
    }
    Component {
        id: aboutPage
        Column {
            width: body.width
            spacing: 24
            ControlGroup {
                padding: 8
                Column {
                    width: parent.width
                    spacing: 6
                    DeviceRow {
                        icon: "info"
                        name: "Computer"
                        value: settings.displayHost
                        onClicked: settings.editName()
                    }
                    DeviceRow {
                        icon: "terminal"
                        name: "Kernel"
                        value: settings.details.kernel || "Unavailable"
                        actionable: false
                        enabled: false
                    }
                    DeviceRow {
                        icon: "settings"
                        name: "Desktop"
                        value: "Hyprland / ghOSt"
                        actionable: false
                        enabled: false
                    }
                }
            }
            Label {
                text: settings.creatorAttribution
                font.family: Theme.textFont
                font.pixelSize: 11
                color: "#ffffff"
            }
        }
    }
}
