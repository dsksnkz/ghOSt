import QtQuick
import QtQuick.Controls as Controls
import Quickshell
import Quickshell.Io

// Separate entry point: never shares the production ShellId or Wayland connection.
ShellRoot {
    SettingsWindow {}
    FloatingWindow {
        id: preview
        property bool composition: false
        visible: true
        implicitWidth: 1920
        implicitHeight: 1080
        color: "#151515"
        Item {
            id: frame
            anchors.fill: parent
            // Keep the real Qt popup overlay inside the captureable fixture root.
            function attachOverlay() { if (Controls.Overlay.overlay) Controls.Overlay.overlay.parent = frame; }
            Timer { interval:100;running:true;onTriggered:frame.attachOverlay() }
            Rectangle { anchors.fill:parent;color:"#151515" }
            Image { anchors.fill: parent; source: Quickshell.env("GHOST_WALLPAPER") || ""; fillMode: Image.PreserveAspectCrop }
            Rail { id: rail; z:10;anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; previewMode: true }
            SettingsPanel {
                id:settingsPreview
                visible:controller.page==="settings"
                x:524;y:212;width:1024;height:699;previewMode:true
                onCloseRequested:controller.page="rail"
            }
            SidebarFigmaBody {
                id: sidebarPreview
                visible: controller.page === "sidebar" || preview.composition
                x: 0; y: 146; width: 354; height: 790
                screen: ({name:"HDMI-A-1"})
                previewMode: true
            }
            PanelContent {
                id: panel
                previewMode: true
                onSettingsPreviewRequested: { settingsPreview.choose("general"); controller.page="settings"; }
                x: frame.width / 2 - width / 2
                y: controller.page === "calendar" ? 82 : 68
                width: controller.page === "calendar" ? Math.floor(Math.min(frame.width * 733/1920, (frame.height - 100) * 733 / 310)) : 392
                height: implicitHeight
                visible: controller.page !== "rail" && controller.page !== "icons" && controller.page !== "sidebar" && controller.page !== "settings"
                popup: QtObject {
                    id: controller
                    property string page: "calendar"
                    property bool opened: true
                    property real reveal: opened ? 1 : 0
                    Behavior on reveal { NumberAnimation { duration: Theme.reducedMotion ? 0 : Theme.panel; easing.type: Easing.OutCubic } }
                }
            }
            Material {
                visible: controller.page === "icons"
                width: 620; height: 320
                anchors.centerIn: parent
                Label { x: 28; y: 24; text: "ghOSt / ICONS"; font.pixelSize: 11; color: Theme.muted }
                BrandMark { x: 28; y: 65; width: 48; height: 48 }
                Row {
                    x: 106; y: 78; spacing: 22
                    Repeater {
                        model: ["wifi", "bluetooth", "volume", "battery", "network", "calendar", "power", "cpu", "gpu"]
                        Icon { required property string modelData; name: modelData; width: 28; height: 28 }
                    }
                }
                G2Surface {
                    x: 22; y: 140; width: parent.width - 44; height: 80; radius: 5; color: Theme.text
                    BrandMark { x: 10; y: 12; width: 48; height: 48; ink: Theme.base }
                    Row {
                        x: 84; y: 24; spacing: 22
                        Repeater {
                            model: ["wifi", "bluetooth", "volume", "battery", "network", "calendar", "power", "cpu", "gpu"]
                            Icon { required property string modelData; name: modelData; width: 28; height: 28; ink: Theme.base }
                        }
                    }
                }
                Row {
                    x: 28; y: 255; spacing: 24
                    Repeater {
                        model: ["search", "app", "terminal", "browser", "folder", "pin"]
                        Icon { required property string modelData; name: modelData; width: 28; height: 28 }
                    }
                    G2Surface {
                        width: 258; height: 40; radius: 4; color: Theme.text
                        Row {
                            anchors.centerIn: parent; spacing: 14
                            Repeater {
                                model: ["search", "app", "terminal", "browser", "folder", "pin"]
                                Icon { required property string modelData; name: modelData; width: 24; height: 24; ink: Theme.base }
                            }
                        }
                    }
                }
            }
            Label { x: 28; anchors.bottom: parent.bottom; anchors.bottomMargin: 24; text: "ghOSt / STAGED RENDER / " + controller.page.toUpperCase() + (Quickshell.env("GHOST_CALENDAR_FIXTURE") === "1" ? " / SAMPLE DATA" : ""); font.pixelSize: 10; color: "white" }
        }
        IpcHandler {
            target: "preview"
            function page(name: string): void { preview.composition = name === "desktop"; controller.page = preview.composition ? "calendar" : name; }
            function metric(name: string): void { Desk.setPerformanceMetric(name); }
            function geometry(): string { return JSON.stringify({page:controller.page,composition:preview.composition,rail:{visible:rail.visible,opacity:rail.opacity,width:rail.width,height:rail.height,z:rail.z}}); }
            function polish(): string {
                function inspect(item, fonts, controls) {
                    if(item.font && typeof item.text==="string" && item.text)fonts.push({text:item.text,family:item.font.family});
                    if(item.hint)controls.push({hint:item.hint,radius:item.radius,width:item.width,height:item.height,offset:item.transform?.[0]?.x ?? 0});
                    for(const child of item.children ?? [])inspect(child,fonts,controls);
                }
                const railFonts=[],railControls=[],sidebarFonts=[],sidebarControls=[],panelFonts=[],panelControls=[];
                inspect(rail,railFonts,railControls);inspect(sidebarPreview,sidebarFonts,sidebarControls);inspect(panel,panelFonts,panelControls);
                return JSON.stringify({railFonts,sidebarControls,panelControls});
            }
            function telemetry(): string { return panel.performanceStatus(); }
            function calendar(action: string, value: string): string { return panel.calendarAction(action,value); }
            function settings(action: string, value: string): string {
                if(action==="page")settingsPreview.choose(value);
                if(action==="query")settingsPreview.query=value;
                if(action==="portrait")settingsPreview.requestPortrait(value);
                if(action==="portrait-select")settingsPreview.selectPortrait(value);
                if(action==="name-open")settingsPreview.editName();
                if(action==="name-draft")settingsPreview.nameDraft=value;
                if(action==="name-save")settingsPreview.saveName();
                if(action==="name-cancel")settingsPreview.cancelName();
                if(action==="reset"){settingsPreview.fixtureHost="Unit-01";settingsPreview.fixturePortrait="";settingsPreview.portraitChooserRequested=false;}
                return settingsPreview.status();
            }
            function sidebar(action: string): string {
                if(action==="reveal")sidebarPreview.beginEntrance();
                if(action==="long")sidebarPreview.previewLongNames=true;
                if(action==="normal")sidebarPreview.previewLongNames=false;
                return JSON.stringify({order:sidebarPreview.entranceOrder,elapsed:sidebarPreview.entranceTime});
            }
            function opened(value: bool): void { controller.opened = value; }
            function launcher(action: string, value: string): string { return panel.launcherAction(action, value); }
            function capture(path: string): void { frame.grabToImage(result => { result.saveToFile(path); }); }
            function stop(): void { Qt.quit(); }
        }
    }
}
