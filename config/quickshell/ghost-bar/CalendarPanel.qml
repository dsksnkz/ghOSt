import QtQuick
import QtQuick.Effects
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
    property real weatherBlur: 0
    property bool weatherReady: false
    property bool weatherTransitionQueued: false
    property string displayedCondition: headlineCondition
    property var displayedTemperature: headlineTemperature
    function syncWeatherHeadline() {
        displayedCondition = headlineCondition;
        displayedTemperature = headlineTemperature;
    }
    function queueWeatherTransition() {
        if (!weatherReady || weatherTransitionQueued)
            return;
        weatherTransitionQueued = true;
        Qt.callLater(() => {
            weatherTransitionQueued = false;
            if (!active || reducedMotion) {
                weatherTransition.stop();
                weatherBlur = 0;
                syncWeatherHeadline();
            } else {
                weatherTransition.restart();
            }
        });
    }
    function selectForecast(index) {
        forecastIndex = Math.max(0, Math.min((weather.days?.length || 1) - 1, index));
        forecastSelected = true;
        queueWeatherTransition();
    }
    readonly property var selectedForecast: forecastSelected ? weather.days?.[forecastIndex] : null
    readonly property string headlineCondition: selectedForecast?.condition ?? weather.condition
    readonly property var headlineTemperature: selectedForecast?.temperature ?? weather.temperature
    onHeadlineConditionChanged: queueWeatherTransition()
    onHeadlineTemperatureChanged: queueWeatherTransition()
    signal navigateRequested(string page)
    onWeatherChanged: if (!previewMode)
        Desk.weatherSummary = weather
    property string actionPage: ""
    property string notice: ""
    property int elapsed: 1500
    property var order: [0, 1, 2, 3, 4, 5]
    implicitHeight: width * Theme.calendarPlaneHeight / Theme.calendarPlaneWidth
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
        weatherTransition.stop();
        weatherBlur = 0;
        syncWeatherHeadline();
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
            meters: [gpuMeter.renderingStatus(), ramMeter.renderingStatus(), cpuMeter.renderingStatus()],
            weatherBlur: weatherBlur,
            weatherTransition: weatherTransition.running,
            displayedCondition: displayedCondition,
            displayedTemperature: displayedTemperature
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
            weatherTransition.stop();
            weatherBlur = 0;
            syncWeatherHeadline();
            telemetry.running = false;
            weatherProcess.running = false;
            stale.stop();
            actionPage = "";
            notice = "";
            if (!fixtureMode)
                readings = {};
        }
    }
    Component.onCompleted: {
        weatherReady = true;
        syncWeatherHeadline();
        if (active) {
            beginReveal();
            if (!fixtureMode) {
                telemetry.running = true;
                weatherProcess.running = true;
            }
        }
    }
    SequentialAnimation {
        id: weatherTransition
        NumberAnimation {
            target: cal
            property: "weatherBlur"
            to: 1
            duration: 110
            easing.type: Easing.InOutCubic
        }
        ScriptAction {
            script: cal.syncWeatherHeadline()
        }
        NumberAnimation {
            target: cal
            property: "weatherBlur"
            to: 0
            duration: 190
            easing.type: Easing.OutCubic
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
    // Rounded fill bar with label and mono readout.
    component Gauge: Item {
        id: gauge
        property string title: ""
        property var value: null
        property real maximum: 100
        property string unit: "%"
        signal clicked
        readonly property bool available: typeof value === "number" && isFinite(value)
        readonly property real level: available && maximum > 0 ? Math.max(0, Math.min(1, value / maximum)) : 0
        property real shown: level
        Behavior on shown {
            NumberAnimation {
                duration: Theme.reducedMotion ? 0 : 420
                easing.type: Easing.OutCubic
            }
        }
        function renderingStatus() {
            return {
                backend: "static",
                moving: false,
                level: shown
            };
        }
        width: 220
        height: 52
        activeFocusOnTab: true
        Keys.onReturnPressed: clicked()
        Keys.onSpacePressed: clicked()
        Accessible.role: Accessible.Button
        Accessible.name: title + ": " + (available ? Math.round(value) + unit : "Unavailable")
        Label {
            y: 6
            text: gauge.title
            font.pixelSize: 12
            color: hover.hovered || gauge.activeFocus ? Theme.text : Theme.muted
            Behavior on color {
                ColorAnimation {
                    duration: Theme.reducedMotion ? 0 : Theme.fast
                }
            }
        }
        Row {
            anchors.right: parent.right
            y: 0
            spacing: 3
            Text {
                text: gauge.available ? Math.round(gauge.value) : "—"
                font.family: Theme.jetRegular.name
                font.pixelSize: 20
                font.weight: Font.Light
                color: Theme.text
                renderType: Text.QtRendering
            }
            Text {
                visible: gauge.available
                y: 8
                text: gauge.unit
                font.family: Theme.jetRegular.name
                font.pixelSize: 10
                color: Theme.muted
                renderType: Text.QtRendering
            }
        }
        Rectangle {
            y: 36
            width: parent.width
            height: 4
            radius: 2
            color: "#1d1d1d"
            Rectangle {
                width: Math.max(gauge.shown > 0 ? height : 0, parent.width * gauge.shown)
                height: parent.height
                radius: 2
                color: Theme.text
            }
        }
        HoverHandler {
            id: hover
            cursorShape: Qt.PointingHandCursor
        }
        TapHandler {
            onTapped: {
                UiSounds.play("rail");
                gauge.clicked();
            }
        }
    }
    component Caption: Label {
        font.pixelSize: 12
        color: Theme.muted
    }
    // Tonal square button used for the header actions and month arrows.
    component Tile: Key {
        property string icon: ""
        property real iconSize: 18
        width: 36
        height: 36
        radius: 7
        color: "#151515"
        SvgIcon {
            anchors.centerIn: parent
            width: parent.iconSize
            height: parent.iconSize
            name: parent.icon
        }
    }
    readonly property string mono: Theme.jetRegular.name
    Item {
        width: Theme.calendarPlaneWidth
        height: Theme.calendarPlaneHeight
        scale: cal.width / Theme.calendarPlaneWidth
        transformOrigin: Item.TopLeft
        // Header: the selected date, with actions on the right.
        Item {
            x: 32
            y: 28
            width: 756
            height: 44
            Text {
                objectName: "calendar-date-title"
                y: -2
                text: Qt.formatDateTime(cal.selectedDate, "dddd d MMMM")
                font.family: Theme.font
                font.pixelSize: 26
                font.weight: Font.Light
                color: Theme.text
                renderType: Text.QtRendering
            }
            Caption {
                y: 32
                text: cal.selectedDate.toDateString() === cal.now.toDateString() ? "Today" : Qt.formatDateTime(cal.selectedDate, "yyyy")
            }
            Row {
                anchors.right: parent.right
                spacing: 8
                opacity: cal.groupOpacity(5)
                Repeater {
                    model: [
                        {icon: "search", hint: "Applications", page: "launcher"},
                        {icon: "settings", hint: "Settings", page: "settings"},
                        {icon: "power", hint: "Power", page: "session"}
                    ]
                    Tile {
                        required property var modelData
                        icon: modelData.icon
                        hint: modelData.hint
                        onClicked: cal.navigateRequested(modelData.page)
                    }
                }
            }
        }
        Rectangle {
            x: 32
            y: 96
            width: 756
            height: 1
            color: "#1b1b1b"
        }
        Item {
            id: weatherSection
            x: 32
            y: 120
            width: 220
            height: 230
            opacity: cal.groupOpacity(0)
            readonly property string condition: cal.displayedCondition
            readonly property var temperature: cal.displayedTemperature
            Caption {
                text: "Weather"
            }
            // Wheel anywhere over the weather column steps through the forecast.
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                onWheel: event => {
                    cal.selectForecast(cal.forecastIndex + (event.angleDelta.y > 0 ? -1 : 1));
                }
            }
            Item {
                id: weatherHeadline
                objectName: "weather-headline"
                y: 30
                width: 220
                height: 60
                opacity: 1 - 0.7 * cal.weatherBlur
                layer.enabled: cal.weatherBlur > 0
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blurMax: 24
                    blur: cal.weatherBlur
                }
                WeatherGlyph {
                    id: weatherArt
                    y: 2
                    scale: 52 / 108
                    transformOrigin: Item.TopLeft
                    condition: weatherSection.condition
                    active: cal.active
                    reducedMotion: cal.reducedMotion
                }
                Text {
                    x: 70
                    y: -8
                    text: typeof weatherSection.temperature === "number" ? Math.round(weatherSection.temperature) : "—"
                    font.family: cal.mono
                    font.pixelSize: 44
                    font.weight: Font.Light
                    color: Theme.text
                    renderType: Text.QtRendering
                    Text {
                        x: parent.contentWidth + 3
                        y: 9
                        visible: typeof weatherSection.temperature === "number"
                        text: "°C"
                        font.family: cal.mono
                        font.pixelSize: 12
                        color: Theme.muted
                    }
                }
                Label {
                    x: 72
                    y: 46
                    text: weatherSection.condition === "unknown" ? "No data" : weatherSection.condition.charAt(0).toUpperCase() + weatherSection.condition.slice(1)
                    font.pixelSize: 12
                    color: Theme.muted
                }
            }
            Item {
                objectName: "weather-forecast-list"
                y: 104
                width: 220
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
                            id: day
                            required property var modelData
                            required property int index
                            readonly property bool current: index === cal.forecastIndex
                            width: 220
                            height: 26
                            radius: 6
                            color: current ? "#151515" : "transparent"
                            opacity: current ? 1 : Math.abs(index - cal.forecastIndex) > 1 ? .35 : .6
                            hint: cal.labelDay(modelData.date) + " forecast"
                            onClicked: cal.selectForecast(index)
                            Label {
                                x: 10
                                anchors.verticalCenter: parent.verticalCenter
                                width: 96
                                text: cal.labelDay(day.modelData.date)
                                font.pixelSize: 12
                            }
                            SvgIcon {
                                x: 118
                                anchors.verticalCenter: parent.verticalCenter
                                width: 15
                                height: 15
                                name: "weather-" + (day.modelData.condition === "clear" ? "brightness" : day.modelData.condition === "unknown" ? "cloud" : day.modelData.condition)
                            }
                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: Math.round(day.modelData.temperature) + "°"
                                font.family: cal.mono
                                font.pixelSize: 12
                                color: Theme.text
                                renderType: Text.QtRendering
                            }
                        }
                    }
                }
                Label {
                    visible: !(cal.weather.days?.length)
                    y: 4
                    text: cal.weather.error || "Weather unavailable"
                    font.pixelSize: 11
                    color: Theme.muted
                    width: 210
                    wrapMode: Text.WordWrap
                }
            }
        }
        Caption {
            x: 300
            y: 120
            text: "System"
            opacity: Math.max(cal.groupOpacity(1), cal.groupOpacity(2), cal.groupOpacity(3))
        }
        Gauge {
            id: gpuMeter
            x: 300
            y: 150
            title: "GPU"
            value: cal.readings.gpu ?? null
            opacity: cal.groupOpacity(1)
            onClicked: cal.notice = "GPU · " + (available ? Math.round(value) + "%" : "Unavailable")
        }
        Gauge {
            id: ramMeter
            x: 300
            y: 226
            title: "Memory"
            value: cal.readings.memory ?? null
            opacity: cal.groupOpacity(2)
            onClicked: cal.notice = "RAM · " + (available ? Math.round(value) + "%" : "Unavailable")
        }
        Gauge {
            id: cpuMeter
            x: 300
            y: 300
            title: cal.clockMetric ? "CPU clock" : "CPU"
            value: cal.clockMetric ? cal.readings.processor ?? null : cal.readings.cpu ?? null
            maximum: cal.clockMetric ? cal.readings.maximum ?? 0 : 100
            unit: cal.clockMetric ? "MHz" : "%"
            opacity: cal.groupOpacity(3)
            onClicked: cal.clockMetric = !cal.clockMetric
        }
        Label {
            x: 300
            y: 344
            width: 220
            text: cal.notice
            font.pixelSize: 10
            color: Theme.muted
        }
        Item {
            id: monthView
            x: 552
            y: 120
            width: 236
            height: 236
            opacity: cal.groupOpacity(4)
            readonly property real cell: width / 7
            Keys.onPressed: event => {
                if (event.key === Qt.Key_PageUp) {
                    cal.monthStep(-1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_PageDown) {
                    cal.monthStep(1);
                    event.accepted = true;
                }
            }
            Caption {
                text: Qt.formatDateTime(cal.month, "MMMM yyyy")
                color: Theme.text
            }
            Row {
                anchors.right: parent.right
                y: -6
                spacing: 4
                Tile {
                    width: 26
                    height: 26
                    iconSize: 12
                    icon: "back"
                    hint: "Previous month"
                    onClicked: cal.monthStep(-1)
                }
                Tile {
                    width: 26
                    height: 26
                    iconSize: 12
                    icon: "forward"
                    hint: "Next month"
                    onClicked: cal.monthStep(1)
                }
            }
            Grid {
                y: 30
                columns: 7
                Repeater {
                    model: ["M", "T", "W", "T", "F", "S", "S"]
                    Label {
                        required property string modelData
                        required property int index
                        text: modelData
                        width: monthView.cell
                        height: 22
                        horizontalAlignment: Text.AlignHCenter
                        color: index > 4 ? Theme.faint : Theme.muted
                        font.pixelSize: 10
                    }
                }
                Repeater {
                    model: 42
                    Item {
                        id: dayCell
                        required property int index
                        readonly property date day: new Date(cal.month.getFullYear(), cal.month.getMonth(), index - cal.offset + 1)
                        readonly property bool today: day.toDateString() === cal.now.toDateString()
                        readonly property bool picked: day.toDateString() === cal.selectedDate.toDateString()
                        readonly property bool inMonth: day.getMonth() === cal.month.getMonth()
                        width: monthView.cell
                        height: 30
                        Key {
                            anchors.centerIn: parent
                            width: 28
                            height: 28
                            radius: 14
                            selected: dayCell.today
                            color: dayCell.today ? Theme.text : dayCell.picked ? "#1d1d1d" : "transparent"
                            hint: Qt.formatDateTime(dayCell.day, "dddd dd MMMM yyyy")
                            onClicked: cal.selectedDate = dayCell.day
                            Text {
                                anchors.centerIn: parent
                                text: dayCell.day.getDate()
                                font.family: cal.mono
                                font.pixelSize: 11
                                font.weight: dayCell.today ? Font.Medium : Font.Normal
                                color: dayCell.today ? Theme.base : !dayCell.inMonth ? "#3a3a3a" : dayCell.index % 7 > 4 ? Theme.muted : Theme.text
                                renderType: Text.QtRendering
                            }
                        }
                    }
                }
            }
        }
        G2Surface {
            visible: cal.actionPage !== ""
            x: 205
            y: 100
            width: 410
            height: 230
            radius: Theme.outerRadius
            color: "#0e0e0e"
            border.color: "#2c2c2c"
            border.width: 1
            Label {
                x: 24
                y: 20
                text: cal.actionPage === "power" ? "Power" : "Settings"
                font.pixelSize: 18
                font.weight: Font.Light
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
