import QtQuick
import QtQuick.Controls as Controls
import Quickshell
import Quickshell.Services.UPower
import "PanelMotion.js" as Motion

Item {
    id: content
    required property var popup
    property bool previewMode: false
    signal settingsPreviewRequested
    function focusPage() {
        if (pageLoader.item?.beginSession)
            pageLoader.item.beginSession();
        else if (pageLoader.item?.focusSearch)
            pageLoader.item.focusSearch();
        else
            content.forceActiveFocus();
    }
    function launcherAction(action, value) {
        const item = pageLoader.item;
        if (popup.page !== "launcher" || !item)
            return "";
        if (action === "query")
            item.query = value;
        if (action === "move")
            item.move(Number(value));
        if (action === "pin")
            item.pin(item.results.find(e => e.id === value));
        if (action === "launch" && previewMode)
            item.launch(item.results.find(e => e.id === value));
        return item.status();
    }
    function performanceStatus() {
        if (pageLoader.item?.status)
            return pageLoader.item.status();
        const gauge = pageLoader.item?.telemetry;
        return JSON.stringify(gauge ? {
            metric: gauge.metric,
            value: gauge.reading,
            maximum: gauge.maximum,
            active: gauge.active
        } : {
            active: false
        });
    }
    function calendarAction(action, value) {
        const item = pageLoader.item;
        if (popup.page !== "calendar" || !item)
            return "";
        if (action === "reveal")
            item.beginReveal();
        if (action === "month")
            item.monthStep(Number(value));
        if (action === "reduced")
            Theme.reducedMotion = value === "true";
        if (action === "weather" && previewMode)
            item.weather = {
                condition: value,
                temperature: 15,
                days: []
            };
        if (action === "level" && previewMode)
            item.readings = {
                cpu: Number(value),
                gpu: Number(value),
                memory: Number(value),
                processor: 2100,
                maximum: 4500
            };
        if (action === "clock" && previewMode)
            item.clockMetric = value === "true";
        if (action === "action" && previewMode)
            item.actionPage = value;
        if (action === "navigate" && previewMode) {
            const previousStatus = item.status();
            item.navigateRequested(value);
            return previousStatus;
        }
        return item.status();
    }
    // Keep the launcher frame full-size even before its Loader has completed.
    // Calendar and media draw their own header inside the page.
    // The Wi-Fi, Bluetooth and battery menus draw their own header too, on the usual panel frame.
    readonly property bool menuPage: popup.page === "network" || popup.page === "bluetooth" || popup.page === "battery"
    readonly property bool ownHeader: popup.page === "calendar" || popup.page === "media" || menuPage
    implicitHeight: popup.page === "launcher" ? 328 : body.implicitHeight + (ownHeader ? 0 : 46)
    focus: true
    Keys.onEscapePressed: {
        if (popup.page === "calendar" && pageLoader.item?.actionPage)
            pageLoader.item.actionPage = "";
        else if (content.previewMode)
            popup.opened = false;
        else
            Desk.close();
    }
    // Launcher and media travel as full-size windows; other popups retain their motion.
    readonly property bool slides: popup.page === "launcher" || popup.page === "media"
    opacity: slides ? 1 : popup.reveal
    // Popups only slide; nothing grows or shrinks.
    transform: Translate {
        y: content.slides ? Motion.slideOffset(popup.page, popup.reveal, content.height) : (popup.page === "calendar" ? -24 : -8) * (1 - popup.reveal)
    }
    Material {
        visible: !content.ownHeader && popup.page !== "launcher"
        anchors.fill: parent
        anchors.margins: 1
        radius: Theme.outerRadius
    }
    // Wi-Fi and Bluetooth menus: the design's flat frame.
    Rectangle {
        visible: content.menuPage
        anchors.fill: parent
        radius: 10
        color: "#0f0f0f"
        border.width: 1
        border.color: "#252525"
    }
    G2Surface {
        visible: popup.page === "launcher"
        anchors.fill: parent
        color: "#191919"
        radius: 22
        smoothing: 0.6
        border.width: 1
        border.color: "#333333"
    }
    Material {
        visible: popup.page === "calendar"
        anchors.fill: parent
        radius: Theme.outerRadius
    }
    G2Surface {
        id: mediaFrame
        visible: popup.page === "media"
        anchors.fill: parent
        radius: Theme.outerRadius
        color: "#0b0b0b"
        border.color: "#272727"
        border.width: 1
        // Machined top edge, matching the calendar frame.
        Rectangle {
            x: mediaFrame.radius
            y: 1
            width: mediaFrame.width - 2 * mediaFrame.radius
            height: 1
            color: "#ffffff"
            opacity: .06
        }
    }
    Column {
        id: body
        x: content.ownHeader ? 0 : popup.page === "launcher" ? 16 : 22
        y: content.ownHeader ? 0 : popup.page === "launcher" ? 16 : 19
        width: parent.width - (content.ownHeader ? 0 : popup.page === "launcher" ? 32 : 44)
        spacing: content.ownHeader ? 0 : 17
        Row {
            visible: !content.ownHeader && popup.page !== "launcher"
            width: parent.width
            Column {
                width: parent.width - 32
                spacing: 5
                Label {
                    text: "ghOSt / " + popup.page.toUpperCase()
                    color: Theme.muted
                    font.pixelSize: 9
                    font.letterSpacing: 1.1
                }
                Label {
                    text: ({
                            launcher: "Applications",
                            audio: "Sound",
                            network: "Connections",
                            bluetooth: "Bluetooth",
                            calendar: Qt.formatDateTime(Desk.now, "MMMM yyyy"),
                            media: "Now playing",
                            battery: "Power"
                        })[popup.page] || ""
                    font.pixelSize: 19
                    font.weight: Font.Normal
                }
            }
            Key {
                width: 30
                hint: "Close"
                onClicked: Desk.close()
                Icon {
                    anchors.centerIn: parent
                    name: "close"
                    width: 16
                    height: 16
                }
            }
        }
        G2Surface {
            visible: !content.ownHeader && popup.page !== "launcher"
            width: parent.width
            height: 1
            color: Theme.line
        }
        Loader {
            id: pageLoader
            width: parent.width
            sourceComponent: ({
                    launcher: launcherPage,
                    audio: audioPage,
                    network: networkPage,
                    bluetooth: bluetoothPage,
                    calendar: calendarPage,
                    media: mediaPage,
                    battery: batteryPage
                })[popup.page] || null
            onLoaded: {
                if (popup.page !== "calendar" && popup.page !== "launcher")
                    pageEntrance.restart();
                else
                    pageLoader.opacity = 1;
                Qt.callLater(content.focusPage);
            }
            NumberAnimation {
                id: pageEntrance
                target: pageLoader
                property: "opacity"
                from: 0.35
                to: 1
                duration: 120
                easing.type: Easing.OutCubic
            }
        }
        Label {
            width: parent.width
            visible: Desk.notice !== ""
            text: Desk.notice
            wrapMode: Text.WordWrap
            color: Theme.orange
        }
    }
    component Action: Key {
        width: body.width
        height: 36
        color: Theme.surface
        border.color: Theme.line
        border.width: 1
    }
    component Caption: Label {
        font.pixelSize: 9
        font.letterSpacing: 1
        color: Theme.muted
    }
    Component {
        id: launcherPage
        Launcher {
            previewMode: content.previewMode
            onCloseRequested: {
                if (content.previewMode)
                    popup.opened = false;
                else
                    Desk.close();
            }
        }
    }
    Component {
        id: audioPage
        Column {
            spacing: 18
            Row {
                width: parent.width
                Label {
                    width: parent.width - 85
                    text: Desk.sink?.description || "No output device"
                    wrapMode: Text.WordWrap
                    font.pixelSize: 11
                }
                Label {
                    text: String(Desk.volume).padStart(2, "0")
                    font.pixelSize: 32
                    color: Desk.muted ? Theme.faint : Theme.cream
                }
            }
            Controls.Slider {
                id: volumeSlider
                width: parent.width
                height: 34
                from: 0
                to: 1
                stepSize: 0.01
                value: Desk.volume / 100
                enabled: !!Desk.audio
                onMoved: Desk.setVolume(value)
                background: Item {
                    x: volumeSlider.leftPadding
                    y: (volumeSlider.height - height) / 2
                    width: volumeSlider.availableWidth
                    height: 18
                    Meter {
                        count: 40
                        segmentWidth: 5
                        spacing: 3
                        value: volumeSlider.visualPosition
                        ink: Theme.cream
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                handle: G2Surface {
                    x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                    y: (volumeSlider.height - height) / 2
                    width: 4
                    height: 24
                    radius: 1
                    color: Theme.orange
                }
                Accessible.name: "Output volume"
            }
            Row {
                spacing: 8
                Action {
                    width: (body.width - 8) / 2
                    text: Desk.muted ? "Unmute" : "Mute"
                    onClicked: Desk.mute()
                }
                Action {
                    width: (body.width - 8) / 2
                    text: "Audio settings ↗"
                    onClicked: Desk.launch(["pavucontrol"])
                }
            }
            Caption {
                text: "OUTPUT / PIPEWIRE"
            }
        }
    }
    Component {
        id: networkPage
        NetworkMenu {
            previewMode: content.previewMode
            active: popup.opened
        }
    }
    Component {
        id: bluetoothPage
        BluetoothMenu {
            previewMode: content.previewMode
            active: popup.opened
        }
    }
    Component {
        id: calendarPage
        CalendarPanel {
            active: popup.opened && popup.page === "calendar"
            previewMode: content.previewMode
            onNavigateRequested: page => {
                if (page === "settings") {
                    if (content.previewMode)
                        content.settingsPreviewRequested();
                    else
                        Desk.openSettings(Desk.panelScreen);
                } else if (content.previewMode)
                    popup.page = page;
                else
                    Desk.panel = page;
            }
        }
    }
    Component {
        id: mediaPage
        MediaPanel {
            active: content.popup.opened
            width: body.width
        }
    }
    Component {
        id: batteryPage
        BatteryMenu {
            previewMode: content.previewMode
            active: popup.opened
        }
    }
}
