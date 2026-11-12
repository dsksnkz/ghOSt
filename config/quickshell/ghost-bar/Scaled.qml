import QtQuick

// Lays its children out at design size and scales them to fill the parent.
Item {
    property real factor: 1
    width: parent ? parent.width / factor : 0
    height: parent ? parent.height / factor : 0
    scale: factor
    transformOrigin: Item.TopLeft
}
