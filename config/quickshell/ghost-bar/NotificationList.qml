import QtQuick
import QtQuick.Controls as Controls

Flickable {
    id:list
    property var entries: Notifications.items
    property bool previewMode: false
    contentHeight: Math.max(height,cards.height)
    clip:true
    boundsBehavior:Flickable.StopAtBounds
    Controls.ScrollBar.vertical:Controls.ScrollBar { policy:Controls.ScrollBar.AsNeeded }
    Column {
        id:cards; width:list.width; spacing:6
        Repeater {
            model:list.entries
            G2Surface {
                id:noticeCard
                required property var modelData
                width:cards.width; height:texts.height+24;radius:15
                color:"#2b2b2b";border.width:1;border.color:"#343434"
                Column {
                    id:texts;x:12;y:12;width:parent.width-48;spacing:5
                    Label { width:parent.width;text:modelData.app;font.pixelSize:9;color:Theme.muted;textFormat:Text.PlainText }
                    Label { width:parent.width;text:modelData.summary;font.pixelSize:11;font.weight:Font.Bold;wrapMode:Text.Wrap;textFormat:Text.PlainText;elide:Text.ElideNone }
                    Label { width:parent.width;text:modelData.body;font.pixelSize:10;wrapMode:Text.Wrap;textFormat:Text.PlainText;elide:Text.ElideNone;visible:text!=="" }
                    Label { width:parent.width;visible:!modelData.owned&&modelData.active&&modelData.actions.length>0;text:"Open the app for actions";font.pixelSize:9;color:Theme.muted;wrapMode:Text.Wrap }
                    Flow {
                        width:parent.width;spacing:5;visible:modelData.owned&&modelData.active
                        Repeater {
                            model:modelData.actions||[]
                            Key {
                                required property var modelData
                                text:modelData.label;hint:modelData.label;radius:8;fontSize:9
                                onClicked:if(!list.previewMode)Notifications.invoke(noticeCard.modelData.key,modelData.key)
                            }
                        }
                    }
                }
                Key {
                    x:parent.width-30;y:7;width:24;height:24;radius:8;text:"×";hint:"Dismiss notification"
                    onClicked:Notifications.dismiss(parent.modelData.key)
                }
            }
        }
    }
    Item {
        width:list.width;height:list.height;visible:list.entries.length===0
        SvgIcon { anchors.horizontalCenter:parent.horizontalCenter;y:Math.max(10,(parent.height-100)/2);width:37;height:37;name:"notifications";opacity:.6 }
        Label { anchors.centerIn:parent;anchors.verticalCenterOffset:25;text:Notifications.ready||list.previewMode?"No more messages":"Notification connection unavailable";font.pixelSize:10;color:Theme.muted }
    }
}
