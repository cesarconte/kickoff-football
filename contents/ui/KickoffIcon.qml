import QtQuick

Item {
    id: root

    property real iconSize: 18
    property bool lively: false
    property real tilt: 0

    width: iconSize
    height: iconSize

    Image {
        anchors.fill: parent
        source: Qt.resolvedUrl("../images/kickoff-football.svg")
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
    }

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
