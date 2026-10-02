import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: cal
    property bool active: false
    property bool previewMode: false
    property bool fixtureMode: previewMode && Quickshell.env("GHOST_CALENDAR_FIXTURE") === "1"
    property bool reducedMotion: Theme.reducedMotion
    property date now: fixtureMode ? new Date(2026,8,29,9,21) : Desk.now
    property date month: new Date(now.getFullYear(), now.getMonth(), 1)
    property date selectedDate: now
    readonly property int offset: (month.getDay()+6)%7
    property var readings: fixtureMode ? ({cpu:20,gpu:2,memory:12,processor:2100,maximum:4500}) : ({})
    property var weather: fixtureMode ? ({condition:"storm",temperature:15,days:[{date:"2026-09-27",condition:"rain",temperature:15},{date:"2026-09-28",condition:"rain",temperature:16},{date:"2026-09-29",condition:"storm",temperature:15},{date:"2026-09-30",condition:"clear",temperature:20},{date:"2026-10-01",condition:"clear",temperature:15}]}) : ({condition:"unknown",days:[]})
    property bool clockMetric: false
    signal navigateRequested(string page)
    onWeatherChanged: if(!previewMode)Desk.weatherSummary=weather
    property string actionPage: ""
    property string notice: ""
    property int elapsed: 1500
    property var order: [0,1,2,3,4,5]
    implicitHeight: width * 505 / 1200
    function beginReveal() {
        let shuffled = [0,1,2,3,4,5];
        for (let i=shuffled.length-1;i>0;i--) { const j=Math.floor(Math.random()*(i+1)); const t=shuffled[i];shuffled[i]=shuffled[j];shuffled[j]=t; }
        if (shuffled.join() === order.join()) shuffled.push(shuffled.shift());
        order=shuffled; elapsed=reducedMotion?1500:0;
        if (!reducedMotion) entrance.restart(); else entrance.stop();
    }
    onReducedMotionChanged: if(reducedMotion) { entrance.stop(); elapsed=1500; }
    function groupOpacity(index) {
        if (reducedMotion || elapsed >= 1500) return 1;
        const t=elapsed-280-order.indexOf(index)*200;
        if(t<0)return 0;
        if(t<80)return .25+.75*t/80;
        if(t<120)return 1-.18*(t-80)/40;
        if(t<180)return .82+.18*(t-120)/60;
        return 1;
    }
    function labelDay(dateString) {
        const d=new Date(dateString+"T12:00:00"); const today=new Date(now.getFullYear(),now.getMonth(),now.getDate(),12);
        const delta=Math.round((d-today)/86400000);
        return delta===0?"Today":delta===-1?"Yesterday":delta===1?"Tomorrow":Qt.formatDateTime(d,"dd MMM");
    }
    function status() { return JSON.stringify({active:active,fixture:fixtureMode,elapsed:elapsed,order:order,readings:readings,weather:weather.condition,weatherMotion:weatherArt.motionState,month:Qt.formatDateTime(month,"yyyy-MM"),action:actionPage,width:width,height:height}); }
    function monthStep(step) { month=new Date(month.getFullYear(),month.getMonth()+step,1); }
    onActiveChanged: {
        if(active) { beginReveal(); if(!fixtureMode) { telemetry.running=true; weatherProcess.running=true; } }
        else { entrance.stop(); telemetry.running=false; weatherProcess.running=false; stale.stop(); actionPage=""; notice=""; if(!fixtureMode)readings={}; }
    }
    Component.onCompleted: if(active) { beginReveal(); if(!fixtureMode){telemetry.running=true;weatherProcess.running=true;} }
    NumberAnimation { id: entrance; target: cal; property: "elapsed"; from: 0; to: 1500; duration: 1500 }
    Timer { id: stale; interval: 4000; onTriggered: cal.readings={} }
    Timer { running: cal.active && !cal.fixtureMode; interval: 900000; repeat: true; onTriggered: if(!weatherProcess.running)weatherProcess.running=true }
    Process {
        id: telemetry
        command: ["python3",Quickshell.shellPath("metrics.py"),"all"]
        stdout: SplitParser { onRead: data => { try { cal.readings=JSON.parse(data);stale.restart(); } catch(e){cal.readings={};} } }
        onExited: if(!cal.fixtureMode)cal.readings={}
    }
    Process {
        id: weatherProcess
        command: ["python3",Quickshell.shellPath("weather.py")]
        stdout: StdioCollector { onStreamFinished: { try{cal.weather=JSON.parse(text);}catch(e){cal.weather={condition:"unknown",days:[]};} } }
    }
    Item {
        width: 1200; height: 505; scale: cal.width/1200; transformOrigin: Item.TopLeft
        // Positions match the user's mainDesigns composition; all text is functional.
        Item {
            x: 72; y: 70; width: 294; height: 325; opacity: cal.groupOpacity(0)
            WeatherGlyph { id:weatherArt; x: 0; y: 0; condition: cal.weather.condition; active: cal.active; reducedMotion: cal.reducedMotion }
            Column { x: 124; y: 8; spacing: 13
                Label { text: cal.weather.condition === "unknown" ? "WEATHER" : cal.weather.condition.toUpperCase(); font.pixelSize: 31 }
                Rectangle { width: 102; height: 2; color: Theme.text }
                Label { text: typeof cal.weather.temperature === "number" ? Math.round(cal.weather.temperature)+"°" : "—"; font.pixelSize: 34; anchors.horizontalCenter: parent.horizontalCenter }
            }
            Column { x: 0; y: 155; spacing: 20
                Repeater {
                    model: cal.weather.days || []
                    Row { required property var modelData; required property int index; spacing: 10; opacity: index===2?1:index===0||index===4?.45:.75
                        SvgIcon { width: 23; height: 23; name: modelData.condition === "clear" ? "brightness" : modelData.condition === "unknown" ? "cloud" : modelData.condition }
                        Label { anchors.verticalCenter: parent.verticalCenter; text: cal.labelDay(modelData.date)+" · "+modelData.condition+" "+Math.round(modelData.temperature)+"°"; font.pixelSize: index===2?19:16 }
                    }
                }
                Label { visible: !(cal.weather.days?.length); text: cal.weather.error || "Weather unavailable"; font.pixelSize: 12; color: Theme.muted; width: 270; wrapMode: Text.WordWrap }
            }
        }
        LiquidMeter { x: 391; y: 47; width: 194; height: 194; title: "GPU"; value: cal.readings.gpu ?? null; active: cal.active; reducedMotion: cal.reducedMotion; opacity: cal.groupOpacity(1); onClicked: cal.notice = "GPU · " + (available ? Math.round(value)+"%" : "Unavailable") }
        LiquidMeter { x: 623; y: 47; width: 194; height: 194; title: "RAM"; value: cal.readings.memory ?? null; active: cal.active; reducedMotion: cal.reducedMotion; opacity: cal.groupOpacity(2); onClicked: cal.notice = "RAM · " + (available ? Math.round(value)+"%" : "Unavailable") }
        LiquidMeter { x: 507; y: 163; width: 194; height: 194; title: cal.clockMetric?"CLOCK":"CPU"; value: cal.clockMetric ? cal.readings.processor ?? null : cal.readings.cpu ?? null; maximum: cal.clockMetric ? cal.readings.maximum ?? 0 : 100; unit: cal.clockMetric?"MHz":"%"; active: cal.active; reducedMotion: cal.reducedMotion; opacity: cal.groupOpacity(3); onClicked: cal.clockMetric = !cal.clockMetric }
        Item {
            x: 839; y: 87; width: 316; height: 308; opacity: cal.groupOpacity(4)
            Row { width: parent.width; y: -20
                Key { width: 24; height: 25; text:"‹"; fontSize:19; hint:"Previous month"; onClicked: cal.monthStep(-1) }
                Label { width: 268; height: 25; text: Qt.formatDateTime(cal.month,"MMMM yyyy"); font.pixelSize: 17; color: Theme.muted; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                Key { width: 24; height: 25; text:"›"; fontSize:19; hint:"Next month"; onClicked: cal.monthStep(1) }
            }
            Grid { y: 16; columns: 7; columnSpacing: 4; rowSpacing: 7
                Repeater { model:["M","T","W","T","F","S","S"]; Label { required property string modelData; text:modelData; width:41; height:22; horizontalAlignment:Text.AlignHCenter; color:Theme.muted; font.pixelSize:15 } }
                Repeater { model:42
                    Key { required property int index; readonly property date day:new Date(cal.month.getFullYear(),cal.month.getMonth(),index-cal.offset+1); width:41; height:29; text:day.getDate(); fontSize:16; selected: day.toDateString()===cal.selectedDate.toDateString(); ink: selected?Theme.base:day.getMonth()===cal.month.getMonth()?Theme.text:Theme.faint; hint:Qt.formatDateTime(day,"dddd dd MMMM yyyy"); onClicked:cal.selectedDate=day }
                }
            }
            Label { y: 293; width: parent.width; horizontalAlignment:Text.AlignHCenter; text:Qt.formatDateTime(cal.selectedDate,"dddd, dd MMMM").toUpperCase(); font.pixelSize:14; color:Theme.muted; font.letterSpacing:1 }
        }
        Row { x: 516; y: 405; height: 58; spacing: 17; opacity: cal.groupOpacity(5)
            Key { width:40; height:40; anchors.bottom:parent.bottom; color:"#d8d8d8"; radius:14; hint:"Applications"; onClicked: cal.navigateRequested("launcher"); SvgIcon { anchors.centerIn:parent; width:27; height:27; name:"search"; black:true } }
            Key { width:58; height:58; color:"#d8d8d8"; radius:16; hint:"Settings"; onClicked:cal.navigateRequested("settings");
                Canvas { anchors.centerIn:parent; width:35;height:35;onPaint:{const c=getContext("2d");c.reset();c.translate(17.5,17.5);c.beginPath();for(let i=0;i<32;i++){const a=i*Math.PI/16;const r=i%4===0||i%4===3?16:12;const x=Math.cos(a)*r,y=Math.sin(a)*r;if(i===0)c.moveTo(x,y);else c.lineTo(x,y);}c.closePath();c.fillStyle="#151515";c.fill();c.globalCompositeOperation="destination-out";c.beginPath();c.arc(0,0,6,0,Math.PI*2);c.fill();} }
            }
            Key { width:40; height:40; anchors.bottom:parent.bottom; color:"#d8d8d8"; radius:14; hint:"Power"; onClicked:cal.navigateRequested("session"); SvgIcon { anchors.centerIn:parent; width:27; height:27; name:"power"; black:true } }
        }
        Label { x:410; y:476; width:390; horizontalAlignment:Text.AlignHCenter; text:cal.notice; font.pixelSize:10; color:Theme.muted }
        Rectangle {
            visible:cal.actionPage!==""; x:400;y:115;width:410;height:250;radius:Theme.outerRadius;color:"#181818";border.color:Theme.line
            Label { x:24;y:20;text:cal.actionPage==="power"?"Power":"Settings";font.pixelSize:21 }
            Key { x:356;y:16;width:32;text:"×";hint:"Close";onClicked:cal.actionPage="" }
            Column { x:24;y:67;spacing:12
                Key { visible:cal.actionPage==="settings";width:362;height:40;text:"Reduced motion · "+(cal.reducedMotion?"On":"Off");onClicked:Theme.reducedMotion=!Theme.reducedMotion }
                Label { visible:cal.actionPage==="settings";text:"Weather location: ghost/weather.json";font.pixelSize:11;color:Theme.muted }
                Repeater { model:cal.actionPage==="power"?["Lock","Sleep","Restart","Shut down"]:[]
                    Key { required property string modelData;width:362;height:29;text:modelData;onClicked:cal.notice="Session actions unavailable in staging" }
                }
            }
        }
    }
}
