import QtQuick
import QtQuick.Controls as Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// Battery menu under the top bar battery: level, charge and drain rates, power
// profiles, the charge limit and a few health figures. battery.py reads what
// UPower does not report and runs only while the menu is open.
Item {
    id: menu
    property bool previewMode: false
    property bool active: true
    readonly property var battery: Desk.battery
    readonly property int level: previewMode ? 60 : Desk.charge
    readonly property int state: previewMode ? UPowerDeviceState.Charging : battery?.state ?? UPowerDeviceState.Unknown
    readonly property bool charging: state === UPowerDeviceState.Charging || state === UPowerDeviceState.PendingCharge
    readonly property bool discharging: state === UPowerDeviceState.Discharging
    readonly property real rate: previewMode ? 18.4 : Math.abs(battery?.changeRate ?? 0)
    property var info: previewMode ? ({present: true, cycles: 10, health: 94, voltage: 12.15, start: 50, end: 75, type: "Trickle", typeName: "Slow charging", technology: "Li-poly", adapter: true}) : ({})
    property string error: ""
    readonly property int profile: previewMode ? PowerProfile.Balanced : PowerProfiles.profile
    width: Theme.menuWidth
    implicitHeight: stats.y + stats.height + Theme.menuTop

    function stateText() {
        if (!Desk.hasBattery && !previewMode)
            return "No battery";
        if (charging)
            return "Charging";
        if (state === UPowerDeviceState.FullyCharged)
            return "Fully charged";
        if (discharging)
            return "On battery";
        return info.adapter ? "Plugged in, not charging" : "Idle";
    }
    function duration(seconds) {
        if (!(seconds > 0 && seconds < 259200))
            return "";
        const h = Math.floor(seconds / 3600), m = Math.floor(seconds % 3600 / 60);
        return h ? h + "h " + m + "m" : m + "m";
    }
    function watts(value) {
        return value > 0 ? (value < 10 ? value.toFixed(1) : Math.round(value)) + "W" : "0W";
    }

    Process {
        id: watcher
        command: ["python3", Quickshell.shellPath("battery.py"), "watch"]
        running: menu.active && !menu.previewMode
        stdout: SplitParser {
            onRead: line => {
                try {
                    menu.info = JSON.parse(line);
                } catch (_) {}
            }
        }
    }
    Process {
        id: limiter
        stderr: StdioCollector { id: limitFailure }
        onExited: code => {
            menu.error = code ? limitFailure.text.trim() || "Could not change the charge limit" : "";
            // Read the thresholds again, whichever way it went.
            watcher.running = false;
            watcher.running = Qt.binding(() => menu.active && !menu.previewMode);
        }
    }
    Process {
        id: profileSetter
        stderr: StdioCollector { id: profileFailure }
        onExited: code => menu.error = code ? profileFailure.text.trim() || "Could not change power profile" : ""
    }

    // Section heading; the next item sits one item gap below it.
    component Heading: Text {
        x: Theme.menuEdge
        font.family: Theme.font
        font.pixelSize: Theme.menuHeading
        color: Theme.menuHeadingInk
        readonly property real end: y + height
    }
    // Lightning bolt in a battery's open outline, as in the design's rate cards.
    component ChargeGlyph: Canvas {
        property color ink: "#9be59b"
        width: 24
        height: 18
        onInkChanged: requestPaint()
        onPaint: {
            const c = getContext("2d");
            c.reset();
            c.strokeStyle = ink;
            c.lineWidth = 1.8;
            c.lineCap = "round";
            c.lineJoin = "round";
            c.beginPath();
            // Left bracket, right bracket and the terminal.
            c.moveTo(7, 2); c.lineTo(3, 2); c.lineTo(3, 16); c.lineTo(7, 16);
            c.moveTo(16, 2); c.lineTo(20, 2); c.lineTo(20, 16); c.lineTo(16, 16);
            c.moveTo(22.5, 7); c.lineTo(22.5, 11);
            // Bolt.
            c.moveTo(13, 3); c.lineTo(9, 9.5); c.lineTo(14, 9.5); c.lineTo(10, 15);
            c.stroke();
        }
    }
    component RateCard: Rectangle {
        id: card
        property string value: ""
        property string label: ""
        property color ink: "#9be59b"
        property bool lit: false
        width: (Theme.menuInner - Theme.menuGap) / 2
        height: 58
        radius: 6
        color: lit ? "#3a3a3a" : "#222222"
        Behavior on color {
            ColorAnimation { duration: Theme.reducedMotion ? 0 : 200 }
        }
        ChargeGlyph {
            x: 18
            anchors.verticalCenter: parent.verticalCenter
            ink: card.ink
            opacity: card.lit ? 1 : .45
        }
        Column {
            x: 56
            anchors.verticalCenter: parent.verticalCenter
            Text {
                text: card.value
                font.family: Theme.font
                font.pixelSize: 16
                font.weight: Theme.boldWeight
                color: card.lit ? "#ffffff" : "#8a8a8a"
            }
            Text {
                text: card.label
                font.family: Theme.font
                font.pixelSize: 13
                color: card.lit ? "#bdbdbd" : "#6a6a6a"
            }
        }
    }

    // Header: a battery filled to the level, its state, and the level itself.
    Item {
        x: Theme.menuEdge + 8
        y: Theme.menuTop
        width: 26
        height: 42
        Rectangle {
            x: 8
            width: 10
            height: 4
            radius: 1.5
            color: "#ffffff"
        }
        Rectangle {
            id: cell
            y: 3
            width: 26
            height: 39
            radius: 4
            color: "transparent"
            border.width: 2
            border.color: "#ffffff"
            Rectangle {
                x: 3
                width: parent.width - 6
                height: Math.max(0, (parent.height - 6) * menu.level / 100)
                y: parent.height - 3 - height
                radius: 2
                color: "#ffffff"
                Behavior on height {
                    NumberAnimation { duration: Theme.reducedMotion ? 0 : 300; easing.type: Easing.OutCubic }
                }
            }
        }
    }
    Column {
        x: Theme.menuTextX
        y: Theme.menuTop + 4
        Text {
            text: "Battery"
            font.family: Theme.font
            font.pixelSize: 17
            font.weight: Theme.boldWeight
            color: "#ffffff"
        }
        Text {
            text: menu.stateText()
            font.family: Theme.font
            font.pixelSize: 14
            color: "#a0a0a0"
        }
    }
    Text {
        anchors.right: parent.right
        anchors.rightMargin: Theme.menuEdge
        y: Theme.menuTop
        text: menu.level + "%"
        font.family: Theme.font
        font.pixelSize: 34
        font.weight: Theme.boldWeight
        color: "#ffffff"
    }

    // Level bar.
    Rectangle {
        id: levelTrack
        x: Theme.menuEdge
        y: Theme.menuRule
        width: Theme.menuInner
        height: 12
        radius: 6
        color: "#2a2a2a"
        Rectangle {
            width: Math.max(height, parent.width * menu.level / 100)
            height: parent.height
            radius: 6
            color: menu.level <= 15 && !menu.charging ? "#e08a8a" : "#d9d9d9"
            Behavior on width {
                NumberAnimation { duration: Theme.reducedMotion ? 0 : 300; easing.type: Easing.OutCubic }
            }
        }
    }

    // Charge and drain rates; the one happening now is lit.
    Row {
        id: rates
        x: Theme.menuEdge
        y: levelTrack.y + levelTrack.height + Theme.menuSection
        spacing: Theme.menuGap
        RateCard {
            lit: menu.charging
            value: menu.charging ? menu.watts(menu.rate) : menu.info.adapter ? "Plugged in" : "—"
            label: menu.charging ? (menu.duration(menu.battery?.timeToFull) ? menu.duration(menu.battery.timeToFull) + " to full" : "Charging")
                : menu.info.adapter ? (menu.state === UPowerDeviceState.FullyCharged ? "Full" : "Not charging") : "Charging"
            ink: "#9be59b"
        }
        RateCard {
            lit: menu.discharging
            value: menu.discharging ? menu.watts(menu.rate) : "—"
            label: menu.discharging && menu.duration(menu.battery?.timeToEmpty) ? menu.duration(menu.battery.timeToEmpty) + " left" : "Discharging"
            ink: "#f08f8f"
        }
    }

    // Power profiles: one track with a sliding highlight.
    Heading {
        id: profilesHeading
        y: rates.y + rates.height + Theme.menuSection
        text: "Power profiles"
    }
    Rectangle {
        id: profiles
        x: Theme.menuEdge
        y: profilesHeading.end + Theme.menuGap
        width: Theme.menuInner
        height: 44
        radius: 6
        color: "#2a2a2a"
        readonly property var choices: [
            {label: "Saver", id: "power-saver", value: PowerProfile.PowerSaver},
            {label: "Balanced", id: "balanced", value: PowerProfile.Balanced},
            {label: "Performance", id: "performance", value: PowerProfile.Performance}
        ]
        readonly property int index: Math.max(0, choices.findIndex(c => c.value === menu.profile))
        Rectangle {
            x: 4 + profiles.index * (profiles.width - 8) / 3
            y: 4
            width: (profiles.width - 8) / 3
            height: profiles.height - 8
            radius: 4
            color: "#7a7a7a"
            Behavior on x {
                NumberAnimation { duration: Theme.reducedMotion ? 0 : 220; easing.type: Easing.OutCubic }
            }
        }
        Row {
            x: 4
            Repeater {
                model: profiles.choices
                Item {
                    id: choice
                    required property var modelData
                    required property int index
                    readonly property bool available: modelData.value !== PowerProfile.Performance || menu.previewMode || PowerProfiles.hasPerformanceProfile
                    width: (profiles.width - 8) / 3
                    height: profiles.height
                    opacity: available ? 1 : .4
                    Accessible.role: Accessible.RadioButton
                    Accessible.name: modelData.label
                    Accessible.checked: profiles.index === index
                    Text {
                        anchors.centerIn: parent
                        text: choice.modelData.label
                        font.family: Theme.font
                        font.pixelSize: 13
                        font.weight: Theme.mediumWeight
                        color: profiles.index === choice.index ? "#ffffff" : choiceArea.containsMouse ? "#d0d0d0" : "#9a9a9a"
                    }
                    MouseArea {
                        id: choiceArea
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: choice.available && !profileSetter.running
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (menu.previewMode || profiles.index === choice.index)
                                return;
                            profileSetter.command = ["powerprofilesctl", "set", choice.modelData.id];
                            profileSetter.running = true;
                        }
                    }
                }
            }
        }
    }

    // Battery care: the charge type and a charge limit set by sliding.
    Heading {
        id: careHeading
        y: profiles.y + profiles.height + Theme.menuSection
        text: "Battery Care"
    }
    Text {
        id: chargeType
        x: Theme.menuEdge
        y: careHeading.end + Theme.menuGap
        text: menu.info.typeName || "Charge limit"
        font.family: Theme.font
        font.pixelSize: 12
        color: "#ffffff"
    }
    Controls.Slider {
        id: limit
        readonly property bool available: menu.info.end !== undefined && menu.info.end !== null
        // The knob's value label rides above the track; the track sits an item gap below the mode.
        x: Theme.menuEdge
        y: chargeType.y + chargeType.height + Theme.menuTight
        width: Theme.menuInner
        height: 36
        leftPadding: 0
        rightPadding: 0
        from: 55
        to: 100
        stepSize: 5
        snapMode: Controls.Slider.SnapAlways
        enabled: available && !limiter.running
        opacity: available ? 1 : .4
        value: menu.info.end ?? 100
        Accessible.name: "Charge limit"
        onPressedChanged: {
            if (pressed || !available || value === menu.info.end)
                return;
            if (menu.previewMode) {
                menu.info = Object.assign({}, menu.info, {end: value, typeName: "Charge limit"});
                return;
            }
            limiter.command = ["python3", Quickshell.shellPath("battery.py"), "limit", String(value)];
            limiter.running = true;
        }
        background: Item {
            x: limit.leftPadding
            y: (limit.height - height) / 2 + 6
            width: limit.availableWidth
            height: 3
            Rectangle {
                anchors.fill: parent
                radius: 1.5
                color: "#555555"
            }
            Rectangle {
                width: limit.visualPosition * parent.width
                height: parent.height
                radius: 1.5
                color: "#9a9a9a"
            }
        }
        handle: Item {
            x: limit.leftPadding + limit.visualPosition * (limit.availableWidth - 14)
            y: (limit.height - 14) / 2 + 6
            width: 14
            height: 14
            Rectangle {
                anchors.fill: parent
                radius: 7
                color: limit.pressed ? "#ffffff" : "#d9d9d9"
            }
            // The limit, written above the knob.
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.top
                anchors.bottomMargin: 6
                text: Math.round(limit.value) + "%"
                font.family: Theme.font
                font.pixelSize: 11
                color: "#ffffff"
            }
        }
    }
    Text {
        id: note
        x: Theme.menuEdge
        y: limit.y + limit.height + Theme.menuTight
        width: Theme.menuInner
        wrapMode: Text.WordWrap
        text: menu.error || (limiter.running ? "Waiting for permission…" : limit.available ? "Charging stops at " + Math.round(limit.value) + "% and resumes below " + Math.max(50, Math.round(limit.value) - 10) + "%." : "This battery has no charge limit.")
        font.family: Theme.font
        font.pixelSize: 11
        color: menu.error ? "#e08a8a" : "#6f6f6f"
    }

    // Stats.
    Heading {
        id: statsHeading
        y: note.y + note.height + Theme.menuSection
        text: "Stats"
    }
    Column {
        id: stats
        x: Theme.menuEdge
        y: statsHeading.end + Theme.menuGap
        spacing: Theme.menuGap
        Repeater {
            model: [
                ["Battery cycles", menu.info.cycles !== undefined && menu.info.cycles !== null ? String(Math.round(menu.info.cycles)) : "—"],
                ["Health", menu.info.health ? menu.info.health + "%" : menu.battery?.healthSupported ? Math.round(menu.battery.healthPercentage) + "%" : "—"],
                ["Capacity", menu.previewMode ? "41.2 of 54.0 Wh" : menu.battery?.energyCapacity > 0 ? menu.battery.energy.toFixed(1) + " of " + menu.battery.energyCapacity.toFixed(1) + " Wh" : "—"],
                ["Voltage", menu.info.voltage ? menu.info.voltage.toFixed(2) + " V" : "—"],
                ["Cell", menu.info.technology || "—"]
            ]
            Text {
                required property var modelData
                text: modelData[0] + "  -  " + modelData[1]
                font.family: Theme.font
                font.pixelSize: 15
                color: "#ffffff"
            }
        }
    }
}
