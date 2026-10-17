import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import "Model.js" as Model

MouseArea {
    id: root

    required property var backend

    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property color foreground: Kirigami.Theme.textColor
    readonly property color accent: Kirigami.Theme.highlightColor
    readonly property color dim: Kirigami.Theme.disabledTextColor

    signal toggleRequested()
    signal refreshRequested()

    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    cursorShape: Qt.PointingHandCursor

    // Celebration state
    property var currentCelebration: null
    property var celebrationQueue: []
    property string shoutText: ""

    function queueCelebration(event) {
        if (!event) return;
        celebrationQueue.push(event);
        if (!celebrationAnimation.running) {
            playNextCelebration();
        }
    }

    function playNextCelebration() {
        if (celebrationQueue.length === 0) {
            currentCelebration = null;
            shoutText = "";
            return;
        }
        currentCelebration = celebrationQueue.shift();
        shoutText = Model.celebrationLine(currentCelebration, Math.floor(Math.random() * 5));
        celebrationAnimation.restart();
    }

    Connections {
        target: backend
        function onGoalScored(event) {
            root.queueCelebration(event);
        }
        function onMatchEnded(event) {
            root.shoutText = event.headline || "FULL TIME";
            fullTimeTimer.restart();
        }
    }

    Timer {
        id: fullTimeTimer
        interval: 4000
        onTriggered: root.shoutText = ""
    }

    SequentialAnimation {
        id: celebrationAnimation
        PropertyAction { target: ballIcon; property: "rotation"; value: 0 }
        ParallelAnimation {
            NumberAnimation { target: ballIcon; property: "rotation"; from: 0; to: 720; duration: 900; easing.type: Easing.OutCubic }
            NumberAnimation { target: shoutLabel; property: "scale"; from: 0.7; to: 1.1; duration: 300; easing.type: Easing.OutBack }
        }
        PauseAnimation { duration: 2500 }
        NumberAnimation { target: shoutLabel; property: "scale"; to: 1.0; duration: 200 }
        onFinished: root.playNextCelebration()
    }

    Layout.minimumWidth: vertical ? Kirigami.Units.iconSizes.small : contentRow.implicitWidth + 12
    Layout.minimumHeight: Kirigami.Units.iconSizes.small

    onClicked: mouse => {
        if (mouse.button === Qt.MiddleButton) {
            refreshRequested();
        } else {
            toggleRequested();
        }
    }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 6

        KickoffIcon {
            id: ballIcon
            iconSize: vertical ? Math.min(root.width, root.height) - 4 : 16
            iconColor: backend.barLive ? root.accent : root.foreground
            lively: backend.barLive && !celebrationAnimation.running
        }

        // Pill / Text label (only in horizontal panel)
        Text {
            id: shoutLabel
            visible: !root.vertical && root.shoutText !== ""
            text: root.shoutText
            color: root.accent
            font.bold: true
            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            id: normalLabel
            visible: !root.vertical && root.shoutText === ""
            text: backend.barText
            color: backend.barLive ? root.accent : root.foreground
            font.bold: backend.barLive
            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
            verticalAlignment: Text.AlignVCenter
        }

        // Tiny refresh spinner if refreshing
        Kirigami.Icon {
            visible: !root.vertical && backend.refreshing
            source: "view-refresh"
            width: 12
            height: 12
            Layout.alignment: Qt.AlignVCenter
            RotationAnimator on rotation {
                running: backend.refreshing
                from: 0
                to: 360
                duration: 1000
                loops: Animation.Infinite
            }
        }
    }
}
