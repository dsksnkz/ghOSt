import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: cal
    property bool active: false
    property bool previewMode: false
    property bool fixtureMode: previewMode && Quickshell.env("GHOST_CALENDAR_FIXTURE") === "1"
    property bool reducedMotion: Theme.reducedMotion
    property date now: fixtureMode ? new Date(2026, 8, 29, 9, 21) : Desk.now
    property date month: new Date(now.getFullYear(), now.getMonth(), 1)
    property date selectedDate: now
    readonly property int offset: (month.getDay() + 6) % 7
    property var readings: fixtureMode ? ({
            cpu: 20,
            gpu: 2,
            memory: 12,
            processor: 2100,
            maximum: 4500
        }) : ({})
    property var weather: fixtureMode ? ({
            condition: "storm",
            temperature: 15,
            days: [
                {
                    date: "2026-09-27",
                    condition: "rain",
                    temperature: 15
                },
                {
                    date: "2026-09-28",
                    condition: "rain",
                    temperature: 16
                },
                {
                    date: "2026-09-29",
                    condition: "storm",
                    temperature: 15
                },
                {
                    date: "2026-09-30",
                    condition: "clear",
                    temperature: 20
                },
                {
                    date: "2026-10-01",
                    condition: "clear",
                    temperature: 15
                }
            ]
        }) : ({
            condition: "unknown",
            days: []
        })
    property bool clockMetric: false
    property int forecastIndex: 2
    property bool forecastSelected: false
    signal navigateRequested(string page)
    onWeatherChanged: if (!previewMode)
        Desk.weatherSummary = weather
    property string actionPage: ""
    property string notice: ""
    property int elapsed: 1500
    property var order: [0, 1, 2, 3, 4, 5]
    implicitHeight: width * 310 / 733
    function beginReveal() {
        let shuffled = [0, 1, 2, 3, 4, 5];
        for (let i = shuffled.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            const t = shuffled[i];
            shuffled[i] = shuffled[j];
            shuffled[j] = t;
        }
        if (shuffled.join() === order.join())
            shuffled.push(shuffled.shift());
        order = shuffled;
        elapsed = reducedMotion ? 1500 : 0;
        if (!reducedMotion)
            entrance.restart();
        else
            entrance.stop();
    }
    onReducedMotionChanged: if (reducedMotion) {
        entrance.stop();
        elapsed = 1500;
    }
    function groupOpacity(index) {
        if (reducedMotion || elapsed >= 1500)
            return 1;
        const t = elapsed - 280 - order.indexOf(index) * 200;
        if (t < 0)
            return 0;
        if (t < 80)
            return .25 + .75 * t / 80;
        if (t < 120)
            return 1 - .18 * (t - 80) / 40;
        if (t < 180)
            return .82 + .18 * (t - 120) / 60;
        return 1;
    }
    function dayOffset(dateString) {
        const d = new Date(dateString + "T12:00:00");
        const today = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 12);
        return Math.round((d - today) / 86400000);
    }
    function forecastScale(dateString) {
        const distance = Math.abs(dayOffset(dateString));
        return distance === 0 ? 1 : distance === 1 ? 0.7 : 0.6;
    }
    function labelDay(dateString) {
        const delta = dayOffset(dateString);
        const d = new Date(dateString + "T12:00:00");
        return delta === 0 ? "Today" : delta === -1 ? "Yesterday" : delta === 1 ? "Tomorrow" : Qt.formatDateTime(d, "dd MMM");
    }
    function status() {
        return JSON.stringify({
            active: active,
            fixture: fixtureMode,
            elapsed: elapsed,
            order: order,
            readings: readings,
            weather: weather.condition,
            weatherMotion: weatherArt.motionState,
            month: Qt.formatDateTime(month, "yyyy-MM"),
            action: actionPage,
            width: width,
            height: height
        });
    }
    function renderingStatus() {
        return {
            active: active,
            reducedMotion: reducedMotion,
            elapsed: elapsed,
            meters: [gpuMeter.renderingStatus(), ramMeter.renderingStatus(), cpuMeter.renderingStatus()]
        };
    }
    function monthStep(step) {
        month = new Date(month.getFullYear(), month.getMonth() + step, 1);
    }
    onActiveChanged: {
        if (active) {
            beginReveal();
            if (!fixtureMode) {
                telemetry.running = true;
                weatherProcess.running = true;
            }
        } else {
            entrance.stop();
            telemetry.running = false;
            weatherProcess.running = false;
            stale.stop();
            actionPage = "";
            notice = "";
            if (!fixtureMode)
                readings = {};
        }
    }
    Component.onCompleted: if (active) {
        beginReveal();
        if (!fixtureMode) {
            telemetry.running = true;
            weatherProcess.running = true;
        }
    }
    NumberAnimation {
        id: entrance
        target: cal
        property: "elapsed"
        from: 0
        to: 1500
        duration: 1500
    }
    Timer {
        id: stale
        interval: 4000
        onTriggered: cal.readings = {}
    }
    Timer {
        running: cal.active && !cal.fixtureMode
        interval: 900000
        repeat: true
        onTriggered: if (!weatherProcess.running)
            weatherProcess.running = true
    }
    Process {
        id: telemetry
        command: ["python3", Quickshell.shellPath("metrics.py"), "all"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    cal.readings = JSON.parse(data);
                    stale.restart();
                } catch (e) {
                    cal.readings = {};
                }
            }
        }
        onExited: if (!cal.fixtureMode)
            cal.readings = {}
    }
    Process {
        id: weatherProcess
        command: ["python3", Quickshell.shellPath("weather.py")]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    cal.weather = JSON.parse(text);
                } catch (e) {
                    cal.weather = {
                        condition: "unknown",
                        days: []
                    };
                }
            }
        }
    }
    Item {
        width: 733
        height: 310
        scale: cal.width / 733
        transformOrigin: Item.TopLeft
        // Positions match the user's mainDesigns composition; all text is functional.
        Item {
            id: weatherSection
            x: 43
            y: 44
            width: 194
            height: 208
            opacity: cal.groupOpacity(0)
            // Scrolling forecasts never changes the current-weather headline.
            readonly property string condition: cal.weather.condition
            readonly property var temperature: cal.weather.temperature
            WeatherGlyph {
                id: weatherArt
                x: 0
                y: 0
                scale: 63 / 108
                transformOrigin: Item.TopLeft
                condition: weatherSection.condition
                active: cal.active
                reducedMotion: cal.reducedMotion
            }
            Label {
                x: 77
                y: 0
                width: 117
                height: 26
                text: weatherSection.condition === "unknown" ? "WEATHER" : weatherSection.condition.toUpperCase()
                font.family: Theme.textFont
                font.pixelSize: 20
                font.weight: Font.Light
                color: "#ffffff"
            }
            G2Surface {
                x: 77
                y: 32
                width: 60
                height: 1
                color: "#ffffff"
            }
            Label {
                x: 81
                y: 41
                width: 48
                height: 26
                text: typeof weatherSection.temperature === "number" ? Math.round(weatherSection.temperature) + "°" : "—"
                font.family: Theme.textFont
                font.pixelSize: 20
                font.weight: Font.Light
                color: "#ffffff"
                horizontalAlignment: Text.AlignHCenter
            }
            Item {
                x: 0
                y: 83
                width: 194
                height: 130
                clip: true
                Column {
                    width: parent.width
                    y: (2 - cal.forecastIndex) * 26
                    Behavior on y {
                        NumberAnimation {
                            duration: cal.reducedMotion ? 0 : 180
                            easing.type: Easing.OutCubic
                        }
                    }
                    Repeater {
                        model: cal.weather.days || []
                        Key {
                            required property var modelData
                            required property int index
                            width: 194
                            height: 26
                            color: "transparent"
                            opacity: index === cal.forecastIndex ? 1 : Math.abs(index - cal.forecastIndex) > 1 ? .45 : .75
                            hint: cal.labelDay(modelData.date) + " forecast"
                            onClicked: {
                                cal.forecastIndex = index;
                                cal.forecastSelected = true;
                            }
                            Item {
                                width: parent.width
                                height: parent.height
                                scale: cal.forecastScale(modelData.date)
                                transformOrigin: Item.TopLeft
                                y: (parent.height - height * scale) / 2
                                SvgIcon {
                                    x: 0
                                    y: 0
                                    width: 17
                                    height: 17
                                    name: modelData.condition === "clear" ? "brightness" : modelData.condition === "unknown" ? "cloud" : modelData.condition
                                }
                                Label {
                                    x: 24
                                    y: 0
                                    width: 170
                                    height: 26
                                    text: cal.labelDay(modelData.date) + " - " + modelData.condition + " " + Math.round(modelData.temperature) + "°"
                                    font.family: Theme.textFont
                                    font.pixelSize: 13
                                    font.weight: Font.Light
                                    color: "#ffffff"
                                }
                            }
                        }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    onWheel: event => {
                        cal.forecastIndex = Math.max(0, Math.min((cal.weather.days?.length || 1) - 1, cal.forecastIndex + (event.angleDelta.y > 0 ? -1 : 1)));
                        cal.forecastSelected = true;
                    }
                }
                Label {
                    visible: !(cal.weather.days?.length)
                    text: cal.weather.error || "Weather unavailable"
                    font.pixelSize: 10
                    color: Theme.muted
                    width: 190
                    wrapMode: Text.WordWrap
                }
            }
        }
        LiquidMeter {
            id: gpuMeter
            x: 235
            y: 27
            title: "GPU"
            value: cal.readings.gpu ?? null
            active: cal.active
            reducedMotion: cal.reducedMotion
            opacity: cal.groupOpacity(1)
            onClicked: cal.notice = "GPU · " + (available ? Math.round(value) + "%" : "Unavailable")
        }
        LiquidMeter {
            id: ramMeter
            x: 375.01
            y: 27
            title: "RAM"
            value: cal.readings.memory ?? null
            active: cal.active
            reducedMotion: cal.reducedMotion
            opacity: cal.groupOpacity(2)
            onClicked: cal.notice = "RAM · " + (available ? Math.round(value) + "%" : "Unavailable")
        }
        LiquidMeter {
            id: cpuMeter
            x: 305
            y: 97
            valueY: 80
            title: cal.clockMetric ? "CLOCK" : "CPU"
            value: cal.clockMetric ? cal.readings.processor ?? null : cal.readings.cpu ?? null
            maximum: cal.clockMetric ? cal.readings.maximum ?? 0 : 100
            unit: cal.clockMetric ? "MHz" : "%"
            active: cal.active
            reducedMotion: cal.reducedMotion
            opacity: cal.groupOpacity(3)
            onClicked: cal.clockMetric = !cal.clockMetric
        }
        Item {
            x: 498
            y: 73
            width: 231
            height: 173
            opacity: cal.groupOpacity(4)
            Keys.onPressed: event => {
                if (event.key === Qt.Key_PageUp) {
                    cal.monthStep(-1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_PageDown) {
                    cal.monthStep(1);
                    event.accepted = true;
                }
            }
            Row {
                x: 15
                y: -18
                width: 205
                Key {
                    width: 20
                    height: 18
                    text: "‹"
                    fontSize: 10
                    hint: "Previous month"
                    onClicked: cal.monthStep(-1)
                }
                Label {
                    width: 165
                    height: 18
                    text: Qt.formatDateTime(cal.month, "MMMM yyyy")
                    font.pixelSize: 7
                    color: Theme.muted
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                Key {
                    width: 20
                    height: 18
                    text: "›"
                    fontSize: 10
                    hint: "Next month"
                    onClicked: cal.monthStep(1)
                }
            }
            Grid {
                x: 15
                y: 7
                columns: 7
                columnSpacing: 5
                rowSpacing: 3
                Repeater {
                    model: ["M", "T", "W", "T", "F", "S", "S"]
                    Label {
                        required property string modelData
                        text: modelData
                        width: 25
                        height: 16
                        horizontalAlignment: Text.AlignHCenter
                        color: Theme.muted
                        font.pixelSize: 6
                    }
                }
                Repeater {
                    model: 42
                    Key {
                        required property int index
                        readonly property date day: new Date(cal.month.getFullYear(), cal.month.getMonth(), index - cal.offset + 1)
                        width: 25
                        height: 18
                        radius: 2
                        text: day.getDate()
                        fontSize: 7
                        selected: day.toDateString() === cal.selectedDate.toDateString()
                        ink: selected ? Theme.base : day.getMonth() === cal.month.getMonth() ? Theme.text : Theme.faint
                        hint: Qt.formatDateTime(day, "dddd dd MMMM yyyy")
                        onClicked: cal.selectedDate = day
                    }
                }
            }
            Label {
                y: 163
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: Qt.formatDateTime(cal.selectedDate, "dddd, dd MMMM").toUpperCase()
                font.pixelSize: 5
                color: Theme.muted
                font.letterSpacing: .5
            }
        }
        Item {
            x: 314
            y: 245
            width: 105
            height: 36
            opacity: cal.groupOpacity(5)
            Key {
                x: 0
                y: 11
                width: 24
                height: 24
                color: "#d9d9d9"
                radius: 7
                hint: "Applications"
                onClicked: cal.navigateRequested("launcher")
                SvgIcon {
                    anchors.centerIn: parent
                    width: 17
                    height: 17
                    name: "search"
                    black: true
                }
            }
            Key {
                x: 35
                y: 0
                width: 36
                height: 36
                color: "#d9d9d9"
                radius: 7
                hint: "Settings"
                onClicked: cal.navigateRequested("settings")
                SvgIcon {
                    anchors.centerIn: parent
                    width: 25
                    height: 25
                    name: "settings"
                    black: true
                }
            }
            Key {
                x: 81
                y: 11
                width: 24
                height: 24
                color: "#d9d9d9"
                radius: 7
                hint: "Power"
                onClicked: cal.navigateRequested("session")
                SvgIcon {
                    anchors.centerIn: parent
                    width: 17
                    height: 17
                    name: "power"
                    black: true
                }
            }
        }
        Label {
            x: 250
            y: 291
            width: 240
            horizontalAlignment: Text.AlignHCenter
            text: cal.notice
            font.pixelSize: 7
            color: Theme.muted
        }
        G2Surface {
            visible: cal.actionPage !== ""
            x: 250
            y: 70
            width: 410
            height: 230
            radius: Theme.outerRadius
            color: "#181818"
            border.color: Theme.line
            Label {
                x: 24
                y: 20
                text: cal.actionPage === "power" ? "Power" : "Settings"
                font.pixelSize: 21
            }
            Key {
                x: 356
                y: 16
                width: 32
                text: "×"
                hint: "Close"
                onClicked: cal.actionPage = ""
            }
            Column {
                x: 24
                y: 67
                spacing: 12
                Key {
                    visible: cal.actionPage === "settings"
                    width: 362
                    height: 40
                    text: "Reduced motion · " + (cal.reducedMotion ? "On" : "Off")
                    onClicked: Theme.reducedMotion = !Theme.reducedMotion
                }
                Label {
                    visible: cal.actionPage === "settings"
                    text: "Weather location: ghost/weather.json"
                    font.pixelSize: 11
                    color: Theme.muted
                }
                Repeater {
                    model: cal.actionPage === "power" ? ["Lock", "Sleep", "Restart", "Shut down"] : []
                    Key {
                        required property string modelData
                        width: 362
                        height: 29
                        text: modelData
                        onClicked: cal.notice = "Session actions unavailable in staging"
                    }
                }
            }
        }
    }
}
