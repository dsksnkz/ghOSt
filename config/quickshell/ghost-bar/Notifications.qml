pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: notices
    readonly property bool fixture: Quickshell.env("GHOST_CALENDAR_FIXTURE")==="1" || Quickshell.env("GHOST_SETTINGS_FIXTURE")==="1"
    property bool ready: fixture
    property string mode: "observe"
    property bool dnd: false
    property var items: []
    property var toast: null
    property string error: ""
    readonly property int count: items.length
    function send(value) { if(!fixture && bridge.running)bridge.write(JSON.stringify(value)+"\n"); }
    function setDnd(value) { if(fixture)dnd=value;else send({operation:"dnd",value}); }
    function dismiss(key) { if(fixture)items=items.filter(item=>item.key!==key);else send({operation:"dismiss",key}); }
    function clear() { if(fixture)items=[];else send({operation:"clear"}); }
    function invoke(key,action) { send({operation:"action",key,action}); }
    function receive(data) {
        try {
            const state=JSON.parse(data);
            ready=!!state.ready;mode=state.mode||"observe";dnd=!!state.dnd;items=state.items||[];error=state.error||"";
            if(dnd || toast&&!items.some(item=>item.key===toast.key&&item.active))toast=null;
            if(state.toast){toast=state.toast;expiry.restart();}
        } catch(_){error="Could not read notifications";}
    }
    function sample() { if(fixture)items=[{key:"sample:1",id:1,app:"ghOSt",summary:"Desktop update",body:"Rail, calendar, sidebar and Settings are ready.",time:0,owned:true,active:true,actions:[]}]; }
    Timer { id:expiry;interval:6000;onTriggered:notices.toast=null }
    Process {
        id:bridge;command:["python3",Quickshell.shellPath("notifications.py")]
        running:!notices.fixture;stdinEnabled:true
        stdout:SplitParser { onRead:data=>notices.receive(data) }
        onExited: { notices.ready=false;notices.error="Notification connection stopped"; }
    }
}
