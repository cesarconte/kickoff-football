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
            NumberAnimation { target: ballIcon; property: "rotation"; from: 0; to: 360; duration: 420; easing.type: Easing.OutCubic }
            NumberAnimation { target: shoutLabel; property: "scale"; from: 0.9; to: 1.05; duration: 220; easing.type: Easing.OutCubic }
        }
        PauseAnimation { duration: 1200 }
        NumberAnimation { target: shoutLabel; property: "scale"; to: 1.0; duration: 120 }
        onFinished: root.playNextCelebration()
    }

    Layout.minimumWidth: vertical ? Kirigami.Units.iconSizes.small : contentRow.implicitWidth + 12
    Layout.minimumHeight: Kirigami.Units.iconSizes.small
    Layout.preferredWidth: Layout.minimumWidth
    Layout.preferredHeight: Layout.minimumHeight

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
            Layout.preferredWidth: iconSize
            Layout.preferredHeight: iconSize
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
            visible: !root.vertical && root.shoutText === "" && backend.barText !== ""
            text: backend.barText
            color: root.foreground
            font.bold: false
            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
            verticalAlignment: Text.AlignVCenter
        }

    }
}
