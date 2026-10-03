import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Dialogs
import Quickshell
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire

Item {
    id:settings
    property bool previewMode:false
    property string page:"general"
    property string query:""
    property real fixtureVolume:62
    property real fixtureInput:74
    property var airplaneSnapshot:null
    property real pendingBrightness:0
    readonly property real fit:Math.min(width/1024,height/699)
    readonly property var details:previewMode?({host:"unit-001",kernel:"Linux",battery:{percent:82,status:"Discharging"},brightness:{percent:69,device:"Laptop display"},equalizer:true,notifications:{count:0,dnd:false},storage:{used:120e9,total:512e9,free:392e9},usage:{seconds:0,samples:[]},preferences:{usageTracking:false,reducedMotion:false,widgets:{}}}):Settings.state
    readonly property var outputs:Pipewire.nodes.values.filter(n=>!n.isStream&&n.isSink&&n.audio)
    readonly property var inputs:Pipewire.nodes.values.filter(n=>!n.isStream&&!n.isSink&&n.audio)
    readonly property var source:Pipewire.defaultAudioSource
    readonly property var categories:[
        {id:"network",name:"Wireless Network",icon:"wifi"},
        {id:"bluetooth",name:"Bluetooth",icon:"bluetooth"},
        {id:"general",name:"General",icon:"settings"},
        {id:"airplane",name:"Airplane Mode",icon:"network"},
        {id:"accessibility",name:"Accessibility",icon:"accessibility"},
        {id:"sound",name:"Sound",icon:"volume"},
        {id:"battery",name:"Battery",icon:"battery"},
        {id:"widgets",name:"Sidebar widgets",icon:"appearance"},
        {id:"brightness",name:"Brightness",icon:"brightness"},
        {id:"wallpaper",name:"Wallpaper",icon:"wallpaper"},
        {id:"notifications",name:"Notifications",icon:"notifications"},
        {id:"storage",name:"Storage",icon:"storage"},
        {id:"applications",name:"Applications",icon:"app"},
        {id:"about",name:"System information",icon:"info"}]
    readonly property var filteredCategories:categories.filter(c=>!query||c.name.toLowerCase().includes(query.toLowerCase()))
    signal closeRequested()
    function choose(id) {
        if(!categories.some(c=>c.id===id))return;
        page=id;pageFlick.contentY=0;entrance.restart();
        const index=filteredCategories.findIndex(c=>c.id===id), y=index*43;
        if(index>=0) {
            if(y<navFlick.contentY)navFlick.contentY=y;
            else if(y+42>navFlick.contentY+navFlick.height)navFlick.contentY=y+42-navFlick.height;
        }
    }
    function apply(name,value) { if(!previewMode)Settings.apply(name,value); }
    function preference(name,value) { if(!previewMode)Settings.preference(name,value); }
    function gigabytes(value) { return typeof value==="number"?(value/1e9).toFixed(1)+" GB":"Unavailable"; }
    function toggleAirplane() {
        if(previewMode)return;
        if(Networking.wifiEnabled||Desk.adapter?.enabled){
            airplaneSnapshot={wifi:Networking.wifiEnabled,bluetooth:!!Desk.adapter?.enabled};
            Networking.wifiEnabled=false;if(Desk.adapter)Desk.adapter.enabled=false;
        }else{
            Networking.wifiEnabled=airplaneSnapshot?.wifi??true;
            if(Desk.adapter)Desk.adapter.enabled=airplaneSnapshot?.bluetooth??true;
            airplaneSnapshot=null;
        }
    }
    function status() { return JSON.stringify({page,query,width:scene.width,height:scene.height,categories:categories.length,preview:previewMode,visible,error:Settings.error}); }
    Timer { id:brightnessCommit;interval:180;onTriggered:settings.apply("brightness",String(settings.pendingBrightness)) }
    PwObjectTracker { objects:settings.outputs.concat(settings.inputs) }
    focus:true
    Keys.onEscapePressed:closeRequested()

    component Section:Column {
        spacing:12
        property string title:""
        width:body.width
        Label { text:parent.title;font.pixelSize:11;color:"#b8b8b8";font.weight:Font.Medium;visible:text!=="" }
    }
    component Card:G2Surface {
        width:body.width;radius:10;color:"#2f2f2f";border.width:1;border.color:"#3b3b3b"
    }
    component DeviceRow:Key {
        property string icon:""
        property string name:""
        property string value:""
        width:body.width;height:48;radius:8;hint:name
        SvgIcon { x:16;y:15;width:18;height:18;name:parent.icon }
        FadeLabel { x:48;y:16;width:parent.width-284;height:18;text:parent.name;font.pixelSize:11;background:"#252525" }
        Label { anchors.right:parent.right;anchors.rightMargin:16;y:16;width:230;horizontalAlignment:Text.AlignRight;text:parent.value;font.pixelSize:10;color:"#b8b8b8" }
    }
    component ToggleRow:Item {
        property string name:""
        property string icon:"settings"
        property bool checked:false
        signal toggled(bool value)
        width:body.width;height:48
        SvgIcon { x:16;y:15;width:18;height:18;name:parent.icon }
        Label { x:48;y:16;width:parent.width-140;text:parent.name;font.pixelSize:11 }
        SettingsToggle { anchors.right:parent.right;anchors.rightMargin:16;y:14;checked:parent.checked;enabled:parent.enabled&&!Settings.busy;hint:parent.name;onToggled:value=>parent.toggled(value) }
    }
    component Note:Label { width:body.width;wrapMode:Text.WordWrap;elide:Text.ElideNone;color:"#b8b8b8";font.pixelSize:11 }
    component SoundControl:Column {
        property string name:""
        property string icon:"volume"
        property real amount:0
        signal moved(real value)
        width:body.width;spacing:10
        Row {
            width:parent.width;spacing:12
            SvgIcon { width:20;height:20;name:parent.parent.icon }
            Label { width:parent.width-88;text:parent.parent.name;font.pixelSize:12 }
            Label { text:Math.round(parent.parent.amount)+"%";font.pixelSize:12;horizontalAlignment:Text.AlignRight;width:44 }
        }
        SettingsSlider { width:parent.width;value:parent.amount;label:parent.name;enabled:parent.enabled;onMoved:parent.moved(value) }
    }

    Item {
        id:scene;width:1024;height:699;scale:settings.fit;transformOrigin:Item.TopLeft
        x:(settings.width-width*scale)/2;y:(settings.height-height*scale)/2
        G2Surface { anchors.fill:parent;radius:10;color:"#2c2c2c" }
        G2Surface { x:262;width:762;height:699;radius:10;color:"#252525" }
        SvgIcon { x:17;y:24;width:32;height:32;name:"settings" }
        G2Surface {
            x:62;y:29;width:186;height:24.17;radius:3;color:"#4c4c4c"
            SvgIcon { x:7;y:6;width:12;height:12;name:"search" }
            TextInput {
                id:search;x:26;y:4;width:152;height:17;color:"#ffffff";font.family:Theme.font;font.pixelSize:11
                text:settings.query;onTextChanged:settings.query=text
                selectByMouse:true;clip:true;Accessible.name:"Find Settings"
            }
        }
        Key {
            x:17;y:78;width:231;height:82;radius:10;color:"#6b6b6b";border.width:1;border.color:"#898989"
            hint:"General";onClicked:settings.choose("general")
            G2Surface { x:10;y:10;width:62;height:62;radius:12;color:"#393939";BrandMark { anchors.centerIn:parent;width:38;height:38 } }
            Label { x:88;y:27;width:134;text:settings.details.host||"Computer";font.pixelSize:15;font.weight:Font.Bold }
            Label { x:88;y:49;text:"Your PC";font.pixelSize:10;color:"#ffffff" }
        }
        Flickable {
            id:navFlick
            x:17;y:175;width:231;height:493;contentHeight:nav.height;clip:true;boundsBehavior:Flickable.StopAtBounds
            layer.enabled:true
            Controls.ScrollBar.vertical:Controls.ScrollBar { policy:Controls.ScrollBar.AsNeeded }
            G2Surface { width:231;height:nav.height;radius:10;color:"#6b6b6b";border.width:1;border.color:"#898989" }
            Column {
                id:nav;width:231;spacing:1
                Repeater {
                    model:settings.filteredCategories
                    Key {
                        required property var modelData
                        width:231;height:42;radius:0
                        hint:modelData.name;color:settings.page===modelData.id?"#535353":"transparent"
                        onClicked:settings.choose(modelData.id)
                        G2Surface { x:10;y:10;width:28;height:28;radius:8;color:"#2f2f2f";SvgIcon { anchors.centerIn:parent;width:19;height:19;name:modelData.icon } }
                        Label { x:50;y:15;width:modelData.id==="airplane"?112:166;text:modelData.name;font.pixelSize:11 }
                        SettingsToggle { visible:modelData.id==="airplane";x:165;y:12;checked:!Networking.wifiEnabled&&!Desk.adapter?.enabled;hint:"Airplane Mode";onToggled:settings.toggleAirplane() }
                    }
                }
                Label { visible:settings.filteredCategories.length===0;text:"No results";font.pixelSize:11 }
            }
        }
        Key { x:974;y:18;width:30;height:30;hint:"Close Settings";onClicked:settings.closeRequested();SvgIcon { anchors.centerIn:parent;width:16;height:16;name:"close" } }

        Flickable {
            id:pageFlick;x:298;y:53;width:690;height:602;clip:true
            layer.enabled:true
            contentHeight:body.height;boundsBehavior:Flickable.StopAtBounds
            Controls.ScrollBar.vertical:Controls.ScrollBar { policy:Controls.ScrollBar.AsNeeded }
            Column {
                id:body;width:690;spacing:24
                opacity:1
                NumberAnimation { id:entrance;target:body;property:"opacity";from:.5;to:1;duration:Theme.reducedMotion?0:140 }
                Label { visible:settings.page!=="general";text:settings.categories.find(c=>c.id===settings.page)?.name||"";font.pixelSize:20;font.weight:Font.Medium }
                Loader {
                    width:body.width
                    sourceComponent:({general:generalPage,network:networkPage,bluetooth:bluetoothPage,airplane:airplanePage,accessibility:accessibilityPage,sound:soundPage,battery:batteryPage,widgets:widgetsPage,brightness:brightnessPage,wallpaper:wallpaperPage,notifications:notificationsPage,storage:storagePage,applications:applicationsPage,about:aboutPage})[settings.page]
                }
                Note { visible:!settings.previewMode&&Settings.error!=="";text:Settings.error }
                Note { visible:settings.previewMode;text:"Preview — sample data; system actions disabled" }
            }
        }
    }

    Component { id:generalPage
        Column {
            width:body.width;spacing:24
            Item {
                width:parent.width;height:204
                G2Surface { x:(parent.width-116)/2;y:0;width:116;height:116;radius:21;color:"#393939";BrandMark { anchors.centerIn:parent;width:66;height:66 } }
                Label { y:138;anchors.horizontalCenter:parent.horizontalCenter;text:settings.details.host||"Computer";font.pixelSize:20;font.weight:Font.Bold }
            }
            Card {
                height:144
                Column {
                    width:parent.width
                    DeviceRow { icon:"volume";name:"Sound";value:settings.previewMode?"62%":Desk.volume+"%";onClicked:settings.choose("sound") }
                    DeviceRow { icon:"battery";name:"Battery";value:settings.details.battery?settings.details.battery.percent+"%":"AC power";onClicked:settings.choose("battery") }
                    DeviceRow { icon:"storage";name:"Storage";value:settings.gigabytes(settings.details.storage?.free)+" free";onClicked:settings.choose("storage") }
                }
            }
        }
    }
    Component { id:soundPage
        Column {
            width:body.width;spacing:24
            SoundControl { name:"Output volume";amount:settings.previewMode?settings.fixtureVolume:Desk.volume;enabled:settings.previewMode||!!Desk.audio;onMoved:value=>{if(settings.previewMode)settings.fixtureVolume=value;else Desk.setVolume(value/100);} }
            ToggleRow { name:"Mute output";icon:"mute";checked:!settings.previewMode&&Desk.muted;enabled:settings.previewMode||!!Desk.audio;onToggled:if(!settings.previewMode)Desk.mute() }
            Section {
                title:"Output device"
                Repeater {
                    model:settings.previewMode?[{description:"Speakers",name:"preview"}]:settings.outputs
                    DeviceRow {
                        required property var modelData
                        icon:"volume";name:modelData.description||modelData.name;value:!settings.previewMode&&modelData===Pipewire.defaultAudioSink?"Selected":""
                        onClicked:if(!settings.previewMode)Pipewire.preferredDefaultAudioSink=modelData
                    }
                }
                Note { visible:!settings.previewMode&&!settings.outputs.length;text:"No output devices" }
            }
            SoundControl { name:"Microphone level";icon:"microphone";amount:settings.previewMode?settings.fixtureInput:Math.round((settings.source?.audio?.volume??0)*100);enabled:settings.previewMode||!!settings.source?.audio;onMoved:value=>{if(settings.previewMode)settings.fixtureInput=value;else if(settings.source?.audio)settings.source.audio.volume=value/100;} }
            ToggleRow { name:"Mute microphone";icon:"microphone";checked:!settings.previewMode&&!!settings.source?.audio?.muted;enabled:settings.previewMode||!!settings.source?.audio;onToggled:value=>{if(!settings.previewMode&&settings.source?.audio)settings.source.audio.muted=value;} }
            Section {
                title:"Input device"
                Repeater {
                    model:settings.previewMode?[{description:"Microphone",name:"preview"}]:settings.inputs
                    DeviceRow {
                        required property var modelData
                        icon:"microphone";name:modelData.description||modelData.name;value:!settings.previewMode&&modelData===Pipewire.defaultAudioSource?"Selected":""
                        onClicked:if(!settings.previewMode)Pipewire.preferredDefaultAudioSource=modelData
                    }
                }
                Note { visible:!settings.previewMode&&!settings.inputs.length;text:"No input devices" }
            }
            DeviceRow { icon:"settings";name:"Equalizer";value:settings.details.equalizer?"EasyEffects":"Unavailable";enabled:!!settings.details.equalizer;onClicked:if(!settings.previewMode)Quickshell.execDetached(["easyeffects"]) }
        }
    }
    Component { id:batteryPage
        Column {
            width:body.width;spacing:24
            Label { text:settings.details.battery?settings.details.battery.percent+"%":"AC power";font.pixelSize:42 }
            Note { text:settings.details.battery?.status||"No battery detected" }
            ToggleRow { name:"Record battery and display-on time";icon:"clock";checked:!!settings.details.preferences?.usageTracking;onToggled:value=>settings.preference("usageTracking",value) }
            Note { text:"Local history only. Counts display-on time while ghOSt is running." }
            Card {
                height:96
                Label { x:20;y:18;text:"Today";color:"#b8b8b8" }
                Label { x:20;y:43;text:Math.floor((settings.details.usage?.seconds??0)/3600)+"h "+Math.floor((settings.details.usage?.seconds??0)%3600/60)+"m";font.pixelSize:26 }
            }
            Section {
                title:"Battery history"
                Repeater {
                    model:(settings.details.usage?.samples??[]).filter((_,i,a)=>i%Math.max(1,Math.floor(a.length/8))===0).slice(-8)
                    DeviceRow { required property var modelData;icon:"battery";name:Qt.formatDateTime(new Date(modelData.time*1000),"HH:mm");value:modelData.percent+"% · "+modelData.status;enabled:false }
                }
                Note { visible:!(settings.details.usage?.samples?.length);text:"No history yet" }
            }
        }
    }
    Component { id:widgetsPage
        Card {
            height:240
            Column { width:parent.width
                Repeater {
                    model:[{id:"network",name:"Wireless Network",icon:"wifi"},{id:"bluetooth",name:"Bluetooth",icon:"bluetooth"},{id:"volume",name:"Volume",icon:"volume"},{id:"brightness",name:"Brightness",icon:"brightness"},{id:"notifications",name:"Notifications",icon:"notifications"}]
                    ToggleRow { required property var modelData;name:modelData.name;icon:modelData.icon;checked:Settings.widget(modelData.id);onToggled:value=>settings.preference("widgets."+modelData.id,value) }
                }
            }
        }
    }
    Component { id:brightnessPage
        Column {
            width:body.width;spacing:24
            SoundControl { name:"Laptop display";icon:"brightness";amount:settings.details.brightness?.percent??0;enabled:!!settings.details.brightness&&!Settings.busy;onMoved:value=>{settings.pendingBrightness=Math.max(1,value);brightnessCommit.restart();} }
            Note { text:settings.details.brightness?"External displays require a supported display control backend.":"No controllable laptop backlight detected" }
        }
    }
    Component { id:wallpaperPage
        Column {
            width:body.width;spacing:24
            Card {
                height:240
                Image { anchors.fill:parent;anchors.margins:1;source:settings.details.preferences?.wallpaper?"file://"+settings.details.preferences.wallpaper:"";fillMode:Image.PreserveAspectFit }
                SvgIcon { visible:!settings.details.preferences?.wallpaper;anchors.centerIn:parent;width:48;height:48;name:"wallpaper";opacity:.5 }
            }
            DeviceRow { icon:"wallpaper";name:"Choose image";value:"Browse";onClicked:if(!settings.previewMode)wallpaperDialog.open() }
            Note { text:settings.details.preferences?.wallpaper||"Choose an image to apply through awww" }
        }
    }
    FileDialog { id:wallpaperDialog;title:"Choose wallpaper";nameFilters:["Images (*.png *.jpg *.jpeg *.webp *.bmp)"];onAccepted:settings.apply("wallpaper",selectedFile.toString()) }
    Component { id:notificationsPage
        Column {
            width:body.width;spacing:24
            ToggleRow { name:"Do not disturb";icon:"notifications";checked:!!settings.details.notifications?.dnd;enabled:!!settings.details.notifications;onToggled:value=>settings.apply("dnd",String(value)) }
            DeviceRow { icon:"notifications";name:"Notification history";value:settings.details.notifications?String(settings.details.notifications.count):"Unavailable";enabled:!!settings.details.notifications;onClicked:settings.apply("notifications","") }
            Note { visible:!settings.details.notifications;text:"No independent notification service is running" }
        }
    }
    Component { id:networkPage
        Column {
            width:body.width;spacing:24
            ToggleRow { name:"Wi-Fi";icon:"wifi";checked:settings.previewMode||Networking.wifiEnabled;onToggled:value=>{if(!settings.previewMode)Networking.wifiEnabled=value;} }
            Section {
                title:"Networks"
                Repeater {
                    model:settings.previewMode?[{name:"Network 01",connected:true,known:true}]:Desk.wifi?.networks.values??[]
                    DeviceRow {
                        required property var modelData
                        icon:"wifi";name:modelData.name;value:modelData.connected?"Connected":""
                        onClicked:{if(settings.previewMode||modelData.connected)return;if(modelData.known)modelData.connect();else Quickshell.execDetached(["nm-connection-editor"]);}
                    }
                }
            }
            DeviceRow { icon:"network";name:"Connection profiles";value:"Open";onClicked:if(!settings.previewMode)Quickshell.execDetached(["nm-connection-editor"]) }
        }
    }
    Component { id:bluetoothPage
        Column {
            width:body.width;spacing:24
            ToggleRow { name:"Bluetooth";icon:"bluetooth";checked:settings.previewMode||!!Desk.adapter?.enabled;enabled:settings.previewMode||!!Desk.adapter;onToggled:value=>{if(!settings.previewMode&&Desk.adapter)Desk.adapter.enabled=value;} }
            Section {
                title:"Devices"
                Repeater {
                    model:settings.previewMode?[{name:"Keyboard",connected:true}]:Desk.adapter?.devices.values??[]
                    DeviceRow { required property var modelData;icon:"bluetooth";name:modelData.name||modelData.address;value:modelData.connected?"Connected":"";onClicked:if(!settings.previewMode)modelData.connected=!modelData.connected }
                }
            }
            DeviceRow { icon:"bluetooth";name:"Pair a device";value:"Open";onClicked:if(!settings.previewMode)Quickshell.execDetached(["blueman-manager"]) }
        }
    }
    Component { id:airplanePage
        Column {
            width:body.width;spacing:24
            ToggleRow { name:"Airplane Mode";icon:"network";checked:!Networking.wifiEnabled&&!Desk.adapter?.enabled;onToggled:settings.toggleAirplane() }
            Note { text:"Turns Wi-Fi and Bluetooth off. Turning it off restores their previous state." }
        }
    }
    Component { id:accessibilityPage
        Column {
            width:body.width;spacing:24
            ToggleRow { name:"Reduced motion";icon:"accessibility";checked:Theme.reducedMotion;onToggled:value=>settings.preference("reducedMotion",value) }
            Note { text:"Immediate panel transitions; weather flashes and moving liquids stop." }
        }
    }
    Component { id:storagePage
        Column {
            width:body.width;spacing:24
            Label { text:settings.gigabytes(settings.details.storage?.used);font.pixelSize:32 }
            Note { text:"Used of "+settings.gigabytes(settings.details.storage?.total) }
            SettingsSlider { width:parent.width;enabled:false;value:100*(settings.details.storage?.used??0)/(settings.details.storage?.total||1);label:"Used storage" }
            DeviceRow { icon:"folder";name:"Home folder";value:"Open";onClicked:if(!settings.previewMode)Quickshell.execDetached(["xdg-open",Quickshell.env("HOME")]) }
        }
    }
    Component { id:applicationsPage
        Column {
            width:body.width;spacing:24
            DeviceRow { icon:"app";name:"Installed applications";value:"Open launcher";onClicked:if(!settings.previewMode){Desk.settingsRequested=false;Desk.toggle("launcher",Desk.panelScreen,Math.max(0,scene.width/2-196));} }
        }
    }
    Component { id:aboutPage
        Card {
            height:144
            Column { width:parent.width
                DeviceRow { icon:"info";name:"Computer";value:settings.details.host||"Unavailable";enabled:false }
                DeviceRow { icon:"terminal";name:"Kernel";value:settings.details.kernel||"Unavailable";enabled:false }
                DeviceRow { icon:"settings";name:"Desktop";value:"Hyprland / ghOSt";enabled:false }
            }
        }
    }
}
