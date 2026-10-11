import QtQuick
import Quickshell.Io
import Quickshell.Services.UPower

Column {
    id: controls
    property bool previewMode: false
    property int previewProfile: PowerProfile.Balanced
    property bool previewPerformanceAvailable: true
    property string error: ""
    readonly property int activeProfile: previewMode ? previewProfile : PowerProfiles.profile
    readonly property bool performanceAvailable: previewMode ? previewPerformanceAvailable : PowerProfiles.hasPerformanceProfile
    readonly property bool busy: setter.running
    signal profileRequested(string profile)
    spacing: 10

    function choose(profile, value) {
        if (busy || (value === PowerProfile.Performance && !performanceAvailable)) return;
        error = "";
        profileRequested(profile);
        if (previewMode) {
            previewProfile = value;
            return;
        }
        setter.command = ["powerprofilesctl", "set", profile];
        setter.running = true;
    }
    Process {
        id: setter
        stderr: StdioCollector { id: failure }
        onExited: (code, status) => {
            if (code !== 0)
                controls.error = failure.text.trim() || "Could not change power profile";
        }
    }
    Row {
        width: parent.width
        spacing: 8
        Repeater {
            model: [
                {label: "Saver", profile: "power-saver", value: PowerProfile.PowerSaver},
                {label: "Normal", profile: "balanced", value: PowerProfile.Balanced},
                {label: "Performance", profile: "performance", value: PowerProfile.Performance}
            ]
            Key {
                required property var modelData
                objectName: "power-profile-" + modelData.profile
                width: (parent.width - 16) / 3
                height: 38
                radius: 10
                smoothing: 0.6
                text: modelData.label
                hint: modelData.label
                selected: controls.activeProfile === modelData.value
                enabled: !controls.busy && (modelData.value !== PowerProfile.Performance || controls.performanceAvailable)
                onClicked: controls.choose(modelData.profile, modelData.value)
            }
        }
    }
    Label {
        width: parent.width
        visible: text !== ""
        wrapMode: Text.WordWrap
        text: controls.error || (controls.busy ? "Changing profile…" : !controls.performanceAvailable ? "Performance profile unavailable" : "")
        color: Theme.muted
    }
}
