import QtQuick
import QtQuick.VirtualKeyboard

// On-screen keyboard. Hosting our own InputPanel stops Qt's automatic panel,
// so the keyboard only appears when the user turns it on.
InputPanel {
    property bool open: false
    visible: open
    externalLanguageSwitchEnabled: false
}
