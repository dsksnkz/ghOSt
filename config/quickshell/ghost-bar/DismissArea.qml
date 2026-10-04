import QtQuick

// The same event route is exercised with real Qt pointer events in tests.
MouseArea {
    signal dismissed
    acceptedButtons: Qt.AllButtons
    onPressed: dismissed()
    TapHandler {
        acceptedDevices: PointerDevice.TouchScreen
        onTapped: parent.dismissed()
    }
}
