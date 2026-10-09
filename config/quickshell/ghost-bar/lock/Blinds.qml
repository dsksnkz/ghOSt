import QtQuick

Item {
    id: blinds
    property real drop: 1
    property real opening: 0
    property bool force3D: false
    readonly property int count: Math.max(1, Math.ceil((height - 52) / 36))
    readonly property bool hardware: GraphicsInfo.api !== GraphicsInfo.Software
    readonly property bool uses3D: physical.status === Loader.Ready
    readonly property real renderedOpening: physical.item ? physical.item.opening : fallback.opening
    y: (drop - 1) * height

    Loader {
        id: physical
        anchors.fill: parent
        active: blinds.hardware || blinds.force3D
        source: "Blinds3D.qml"
    }
    Binding {
        target: physical.item
        property: "opening"
        value: blinds.opening
        when: physical.status === Loader.Ready
    }
    BlindsFallback {
        id: fallback
        anchors.fill: parent
        visible: !blinds.uses3D
        opening: blinds.opening
    }
}
