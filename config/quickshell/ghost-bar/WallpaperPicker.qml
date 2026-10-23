import QtQuick
import QtQuick.Controls as Controls
import Qt.labs.folderlistmodel
import Quickshell

Controls.Popup {
    id: picker

    width: 900
    height: 540
    padding: 20
    modal: true
    focus: true
    scale: parent ? parent.scale : 1
    closePolicy: Controls.Popup.CloseOnEscape
    property string soundGroup: "settings"
    property url selectedFile: ""
    property string selectedName: ""
    readonly property url homeFolder: localUrl(Quickshell.env("HOME"))
    readonly property bool imageReady: preview.status === Image.Ready
    readonly property alias currentFolder: files.folder
    readonly property int fileCount: files.count
    signal imageChosen(url file)

    function localUrl(path) {
        return "file://" + encodeURI(path).replace(/#/g, "%23").replace(/\?/g, "%3F");
    }

    function browse(currentImage) {
        listing.currentIndex = -1;
        const value = (currentImage || "").toString();
        selectedFile = value.startsWith("/") ? localUrl(value) : value;
        const path = selectedFile.toString();
        selectedName = decodeURIComponent(path.substring(path.lastIndexOf("/") + 1));
        files.folder = path ? path.substring(0, path.lastIndexOf("/") + 1) : homeFolder;
        open();
    }

    function navigate(folder) {
        selectedFile = "";
        selectedName = "";
        files.folder = folder;
        listing.currentIndex = -1;
    }

    function selectEntry(index) {
        if (index < 0 || index >= files.count)
            return;
        listing.currentIndex = index;
        if (files.isFolder(index)) {
            selectedFile = "";
            selectedName = "";
        } else {
            selectedFile = files.get(index, "fileUrl");
            selectedName = files.get(index, "fileName");
        }
    }

    function activateEntry(index) {
        if (index >= 0 && files.isFolder(index))
            navigate(files.get(index, "fileUrl"));
    }

    function confirmSelection() {
        if (!imageReady)
            return;
        imageChosen(selectedFile);
        close();
    }

    onOpened: listing.forceActiveFocus()
    // Release the selected image and clear the folder when closed.
    onClosed: {
        selectedFile = "";
        selectedName = "";
        files.folder = "";
    }

    FolderListModel {
        id: files
        folder: ""
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp"]
        caseSensitive: false
        showDirsFirst: true
        showOnlyReadable: true
        showHidden: false
        sortCaseSensitive: false
    }

    background: G2Surface {
        radius: 10
        color: "#1c1c1c"
        border.width: 1
        border.color: "#555555"
    }

    contentItem: Item {
        Rectangle {
            anchors.fill: parent
            color: "#1c1c1c"
        }
        Label {
            text: "Choose wallpaper"
            color: "#f2f2f2"
            font.pixelSize: 18
            font.weight: Font.DemiBold
        }
        Key {
            x: parent.width - 80
            width: 80
            height: 30
            text: "Cancel"
            ink: "#f2f2f2"
            onClicked: picker.close()
        }
        Row {
            y: 44
            spacing: 8
            Key {
                width: 56
                height: 36
                text: "Up"
                ink: "#f2f2f2"
                enabled: files.parentFolder.toString().length > 0
                onClicked: picker.navigate(files.parentFolder)
            }
            Key {
                width: 64
                height: 36
                text: "Home"
                ink: "#f2f2f2"
                onClicked: picker.navigate(picker.homeFolder)
            }
            Controls.TextField {
                id: location
                objectName: "wallpaper-location"
                width: picker.availableWidth - 136
                height: 36
                text: decodeURIComponent(files.folder.toString().replace(/^file:\/\//, ""))
                color: "#f2f2f2"
                selectedTextColor: "#181818"
                selectionColor: "#dddddd"
                placeholderTextColor: "#b8b8b8"
                font.family: Theme.font
                font.pixelSize: 12
                selectByMouse: true
                Accessible.name: "Folder path"
                background: G2Surface {
                    radius: 8
                    color: "#292929"
                    border.width: 1
                    border.color: location.activeFocus ? "#cccccc" : "#484848"
                }
                onAccepted: {
                    const path = text.trim();
                    if (path.startsWith("/"))
                        picker.navigate(picker.localUrl(path));
                    else if (path.startsWith("file://"))
                        picker.navigate(path);
                }
                Connections {
                    target: files
                    function onFolderChanged() {
                        location.text = decodeURIComponent(files.folder.toString().replace(/^file:\/\//, ""));
                    }
                }
            }
        }

        G2Surface {
            id: browserFrame
            y: 96
            width: 404
            height: parent.height - y - 48
            radius: 8
            color: "#222222"
            border.width: 1
            border.color: "#414141"
            ListView {
                id: listing
                objectName: "wallpaper-files"
                anchors.fill: parent
                anchors.margins: 8
                clip: true
                spacing: 6
                model: picker.visible ? files : null
                currentIndex: -1
                boundsBehavior: Flickable.StopAtBounds
                keyNavigationEnabled: false
                Controls.ScrollBar.vertical: Controls.ScrollBar {}
                Keys.onDownPressed: picker.selectEntry(Math.min(count - 1, currentIndex + 1))
                Keys.onUpPressed: picker.selectEntry(Math.max(0, currentIndex - 1))
                Keys.onReturnPressed: picker.activateEntry(currentIndex)
                delegate: G2Surface {
                    id: entry
                    required property int index
                    required property string fileName
                    required property url fileUrl
                    required property bool fileIsDir
                    width: listing.width - 12
                    height: fileIsDir ? 48 : 72
                    radius: 8
                    color: ListView.isCurrentItem ? "#3c3c3c" : hit.containsMouse ? "#303030" : "transparent"
                    Accessible.role: Accessible.ListItem
                    Accessible.name: entry.fileName
                    Accessible.onPressAction: picker.selectEntry(entry.index)
                    SvgIcon {
                        visible: entry.fileIsDir
                        name: "folder-rounded"
                        x: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28
                        height: 28
                    }
                    Image {
                        id: thumbnail
                        visible: !entry.fileIsDir
                        x: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 76
                        height: 56
                        source: entry.fileIsDir ? "" : entry.fileUrl
                        sourceSize: Qt.size(152, 112)
                        asynchronous: true
                        fillMode: Image.PreserveAspectFit
                    }
                    SvgIcon {
                        visible: !entry.fileIsDir && thumbnail.status === Image.Error
                        name: "wallpaper"
                        x: 32
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28
                        height: 28
                        opacity: .65
                    }
                    Label {
                        x: entry.fileIsDir ? 52 : 96
                        width: parent.width - x - 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: entry.fileName
                        color: "#f2f2f2"
                        font.pixelSize: 12
                    }
                    MouseArea {
                        id: hit
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            picker.selectEntry(entry.index);
                            listing.forceActiveFocus();
                        }
                        onDoubleClicked: picker.activateEntry(entry.index)
                    }
                }
            }
            Label {
                anchors.centerIn: parent
                width: parent.width - 32
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                color: "#b8b8b8"
                text: files.status === FolderListModel.Loading ? "Loading…" : "No images or readable folders"
                visible: files.count === 0
            }
        }
        G2Surface {
            x: browserFrame.width + 16
            y: browserFrame.y
            width: parent.width - x
            height: browserFrame.height
            radius: 8
            color: "#141414"
            border.width: 1
            border.color: "#414141"
            Image {
                id: preview
                objectName: "wallpaper-image-preview"
                anchors.fill: parent
                anchors.margins: 12
                source: picker.selectedFile
                sourceSize: Qt.size(1024, 768)
                asynchronous: true
                fillMode: Image.PreserveAspectFit
            }
            Label {
                anchors.centerIn: parent
                color: "#b8b8b8"
                text: preview.status === Image.Error ? "Could not open this image" : preview.status === Image.Loading ? "Loading…" : "Select an image to preview"
                visible: !picker.imageReady
            }
        }
        Label {
            y: parent.height - 32
            width: parent.width - 132
            height: 32
            verticalAlignment: Text.AlignVCenter
            text: picker.selectedName
            color: "#f2f2f2"
            font.pixelSize: 12
        }
        Key {
            objectName: "wallpaper-apply"
            x: parent.width - 116
            y: parent.height - 34
            width: 116
            height: 34
            text: "Use image"
            selected: true
            ink: "#181818"
            enabled: picker.imageReady
            onClicked: picker.confirmSelection()
        }
    }
}
