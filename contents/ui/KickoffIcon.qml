import QtQuick
import "Model.js" as Model

Text {
    id: root

    textFormat: Text.PlainText
    property real iconSize: 18
    property color iconColor: "#ffffff"
    property string emojiFamily: "Noto Color Emoji"
    property bool lively: false
    property real tilt: 0

    text: Model.BALL_GLYPH
    color: iconColor
    font.family: emojiFamily
    font.pixelSize: iconSize
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    width: iconSize
    height: iconSize
    transformOrigin: Item.Center
    rotation: tilt

    SequentialAnimation on tilt {
        running: root.lively
        loops: Animation.Infinite
        NumberAnimation { from: -9; to: 9; duration: 1500; easing.type: Easing.InOutSine }
        NumberAnimation { from: 9; to: -9; duration: 1500; easing.type: Easing.InOutSine }
    }

    onLivelyChanged: if (!lively) tilt = 0
}
