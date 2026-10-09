import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Dialogs
import Quickshell
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire

Item {
    id: settings
    property string soundGroup: "settings"
    // Settings-only tokens. Keep the supplied sidebar and native frame geometry.
    readonly property color primaryInk: "#f1f1f1"
    readonly property color secondaryInk: "#b8b8b8"
    readonly property color controlSurface: "#2f2f2f"
    readonly property color controlBorder: "#444444"
    readonly property int controlHeight: 56
    readonly property string creatorAttribution: "ghOSt - ChatGPT and dsksnkz"
    readonly property real navigationRowHeight: 44
    readonly property real navigationRowGap: 8
    readonly property real navigationStride: navigationRowHeight + navigationRowGap
    readonly property real navigationInset: 0
    readonly property real navigationGroupGap: 16
    // The new screenshot supersedes the old 40% glyph sizing.
    readonly property real iconRatio: 0.6
    function navigationGroupHeight(count) {
        return count * navigationRowHeight + Math.max(0, count - 1) * navigationRowGap + 2 * navigationInset;
    }
    property bool previewMode: false
    property string page: "general"
    property string query: ""
    property real fixtureVolume: 62
    property real fixtureInput: 74
    property var airplaneSnapshot: null
    property real pendingBrightness: 0
    property string fixtureHost: "Unit-01"
    property url fixturePortrait: ""
    property string portraitOrigin: ""
    property bool portraitChooserRequested: false
    property string portraitError: ""
    property string nameDraft: ""
    property bool nameSubmitted: false
    readonly property string displayHost: previewMode ? fixtureHost : details.host || "Computer"
    readonly property url portraitSource: previewMode ? (fixturePortrait.toString() || Qt.resolvedUrl("artwork/profile.jpg")) : (details.preferences?.profilePicture || Qt.resolvedUrl("artwork/profile.jpg"))
    readonly property real fit: Math.min(width / 1024, height / 699)
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
    readonly property var categories: [
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
            id: "general",
            name: "General",
            icon: "settings"
        },
        {
            id: "airplane",
            name: "Airplane Mode",
            icon: "network"
        },
        {
            id: "accessibility",
            name: "Accessibility",
            icon: "accessibility"
        },
        {
            id: "sound",
            name: "Sound",
            icon: "volume"
        },
        {
            id: "battery",
            name: "Battery",
            icon: "battery"
        },
        {
            id: "widgets",
            name: "Sidebar widgets",
            icon: "appearance"
        },
        {
            id: "brightness",
            name: "Brightness",
            icon: "brightness"
        },
        {
            id: "wallpaper",
            name: "Wallpaper",
            icon: "wallpaper"
        },
        {
            id: "notifications",
            name: "Notifications",
            icon: "notifications"
        },
        {
            id: "storage",
            name: "Storage",
            icon: "storage"
        },
        {
            id: "applications",
            name: "Applications",
            icon: "app"
        },
        {
            id: "about",
            name: "System information",
            icon: "info"
        }
    ]
    readonly property var filteredCategories: categories.filter(c => !query || c.name.toLowerCase().includes(query.toLowerCase()))
    readonly property var categoryGroups: [["network", "bluetooth", "general", "airplane", "accessibility"], ["sound", "battery", "brightness"], ["widgets", "wallpaper", "notifications"], ["storage", "applications", "about"]]
    readonly property var filteredGroups: categoryGroups.map(group => group.map(id => filteredCategories.find(c => c.id === id)).filter(c => !!c)).filter(group => group.length)
    readonly property var navLayout: navigationLayout()
    function navigationLayout() {
        const groups = [], rows = [];
        let y = 0;
        for (const group of filteredGroups) {
            const height = navigationGroupHeight(group.length);
            groups.push({
                y,
                height
            });
            group.forEach((category, index) => rows.push(Object.assign({}, category, {
                    y: y + navigationInset + index * navigationStride
                })));
            y += height + navigationGroupGap;
        }
        return {
            groups,
            rows,
            height: Math.max(0, y - navigationGroupGap)
        };
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
    function status() {
        return JSON.stringify({
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
            portraitTop: sidebarPortrait.parent.y,
            portraitSize: sidebarPortrait.width,
            portraitRadius: sidebarPortrait.radius,
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
    Timer {
        id: brightnessCommit
        interval: 180
        onTriggered: settings.apply("brightness", String(settings.pendingBrightness))
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
            font.weight: Font.Medium
            visible: text !== ""
        }
    }
    component Card: G2Surface {
        width: parent.width
        radius: 10
        smoothing: .6
        color: settings.controlSurface
        border.width: 1
        border.color: settings.controlBorder
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
        radius: 10
        smoothing: .6
        color: settings.controlSurface
        border.width: 1
        border.color: activeFocus ? settings.primaryInk : settings.controlBorder
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
            text: parent.value; font.pixelSize: 26; font.weight: Font.Medium
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
            color: "#252525"
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
            width: parent.width
            value: parent.amount
            label: parent.name
            enabled: parent.enabled
            onMoved: parent.moved(value)
        }
    }

    Item {
        id: scene
        width: 1024
        height: 699
        scale: settings.fit
        transformOrigin: Item.TopLeft
        x: (settings.width - width * scale) / 2
        y: (settings.height - height * scale) / 2
        G2Surface {
            anchors.fill: parent
            radius: 10
            smoothing: .6
            color: "#2c2c2c"
        }
        G2Surface {
            x: 262
            width: 762
            height: 699
            radius: 10
            smoothing: .6
            color: "#252525"
        }
        G2Surface {
            id: searchHousing
            x: 17
            y: 84
            width: 227
            height: 32
            radius: 8
            smoothing: .6
            color: "#3b3b3b"
            border.width: search.activeFocus ? 1 : 0
            border.color: settings.secondaryInk
            SvgIcon {
                x: 12
                y: 8
                width: 16
                height: 16
                name: "search"
                opacity: .75
            }
            Label {
                x: 38
                y: 7
                text: "Search settings"
                visible: search.text.length === 0
                color: "#b8b8b8"
                font.pixelSize: 12
            }
            TextInput {
                id: search
                objectName: "settings-search"
                x: 38
                y: 7
                width: 151
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
                y: 6
                width: 20
                height: 20
                radius: 6
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
        Item {
            x: 17
            y: 18
            width: 227
            height: 48
            G2Image {
                id: sidebarPortrait
                width: 48
                height: 48
                radius: 11
                source: settings.portraitSource
            }
            Key {
                width: 48
                height: 48
                radius: 11
                smoothing: .6
                hint: "Choose profile picture"
                onClicked: settings.requestPortrait("sidebar")
            }
            Label {
                x: 65
                y: 4
                width: 104
                height: 22.14
                text: settings.displayHost
                font.family: Theme.textFont
                font.pixelSize: 16
                font.weight: Font.Bold
                color: "#ffffff"
            }
            Label {
                x: 65
                y: 32
                width: 104
                height: 12.9
                text: "Your PC"
                font.family: Theme.textFont
                font.pixelSize: 10
                color: settings.secondaryInk
            }
            Key {
                x: 173
                y: 8
                width: 32
                height: 32
                radius: 8
                hint: "General"
                onClicked: settings.choose("general")
                SvgIcon {
                    anchors.centerIn: parent
                    width: 28
                    height: 28
                    name: "settings"
                }
            }
        }
        Flickable {
            id: navFlick
            x: 17
            y: 145
            width: 231
            height: 530
            contentHeight: nav.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            layer.enabled: false
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
                    color: "#454545"
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
                            color: modelData.id === settings.page ? "#252525" : "#2f2f2f"
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
                            font.weight: modelData.id === settings.page ? Font.Medium : Font.Normal
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
            x: 298
            y: 53
            width: 690
            height: 602
            clip: true
            layer.enabled: true
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
                    SvgIcon {
                        x: 0; y: 6; width: 20; height: 20
                        name: settings.categories.find(c => c.id === settings.page)?.icon || "info"
                    }
                    Label {
                        x: 36; width: parent.width - 36; height: 32
                        verticalAlignment: Text.AlignVCenter
                        text: settings.categories.find(c => c.id === settings.page)?.name || ""
                        font.pixelSize: 22
                        font.weight: Font.Medium
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
            height: 518
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
                    font.weight: Font.Bold
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
            Key {
                x: (parent.width - width) / 2
                y: 172
                width: 245
                height: 18
                hint: "System information"
                onClicked: settings.choose("about")
                SvgIcon {
                    x: 0
                    y: 0
                    width: 18
                    height: 18
                    name: "info"
                }
                Label {
                    x: 27
                    y: 1
                    width: parent.width - 27
                    height: 15
                    text: settings.creatorAttribution
                    font.family: Theme.textFont
                    font.pixelSize: 11
                    color: "#ffffff"
                }
            }
            Row {
                y: 230
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
                y: 382
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
            width: body.width
            spacing: 24
            ControlGroup {
              SoundControl {
                name: "Laptop display"
                icon: "brightness"
                amount: settings.details.brightness?.percent ?? 0
                enabled: !!settings.details.brightness && !Settings.busy
                onMoved: value => {
                    settings.pendingBrightness = Math.max(1, value);
                    brightnessCommit.restart();
                }
              }
            }
            Note {
                text: settings.details.brightness ? "External displays require a supported display control backend." : "No controllable laptop backlight detected"
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
                    wallpaperDialog.open()
            }
            Note {
                text: settings.details.preferences?.wallpaper || "Choose an image to apply through awww"
            }
        }
    }
    FileDialog {
        id: wallpaperDialog
        title: "Choose wallpaper"
        nameFilters: ["Images (*.png *.jpg *.jpeg *.webp *.bmp)"]
        onAccepted: settings.apply("wallpaper", selectedFile.toString())
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
            color: "#2f2f2f"
            border.width: 1
            border.color: "#898989"
        }
        onOpened: nameInput.forceActiveFocus()
        onClosed: settings.nameSubmitted = false
        contentItem: Item {
            Label {
                text: "PC name"
                font.pixelSize: 16
                font.weight: Font.Bold
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
                    color: "#252525"
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
            ToggleRow {
                name: "Reduced motion"
                icon: "accessibility"
                checked: Theme.reducedMotion
                onToggled: value => settings.preference("reducedMotion", value)
            }
            Note {
                text: "Immediate panel transitions; weather flashes and moving liquids stop."
            }
        }
    }
    Component {
        id: storagePage
        Column {
            width: body.width
            spacing: 24
            Row {
                width: parent.width
                spacing: 16
                Summary {
                    icon: "storage"; name: "Used"
                    value: settings.gigabytes(settings.details.storage?.used)
                    detail: settings.details.storage ? "Of " + settings.gigabytes(settings.details.storage.total) : "Storage unavailable"
                    actionable: false
                }
                Summary {
                    icon: "folder"; name: "Free"
                    value: settings.gigabytes(settings.details.storage?.free)
                    detail: "Home filesystem"
                    actionable: false
                }
            }
            // A passive measurement, not a disabled slider suggesting a setter.
            ControlGroup {
                Label { text: "Used storage"; color: settings.secondaryInk; font.pixelSize: 12 }
                G2Surface {
                    objectName: "settings-storage-meter"
                    width: parent.width; height: 8; radius: 4; color: "#414141"
                    Accessible.role: Accessible.ProgressBar
                    Accessible.name: "Used storage"
                    Accessible.description: settings.details.storage ? Math.round(100 * settings.details.storage.used / settings.details.storage.total) + "%" : "Unavailable"
                    G2Surface {
                        objectName: "settings-storage-fill"
                        width: parent.width * Math.max(0, Math.min(1, (settings.details.storage?.used ?? 0) / (settings.details.storage?.total || 1)))
                        height: parent.height; radius: 4; color: "#d9d9d9"
                    }
                }
            }
            DeviceRow {
                icon: "folder"
                name: "Home folder"
                value: "Open"
                onClicked: if (!settings.previewMode)
                    Quickshell.execDetached(["xdg-open", Quickshell.env("HOME")])
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
