import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "Model.js" as Model

Item {
    id: root

    property var match: null
    property bool selected: false
    property var goalFlashIds: ({})
    property bool showCompetition: false

    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: match ? match.home.name + " " + Model.compactScore(match) + " " + match.away.name + ", " + root.clock : ""
    Keys.onReturnPressed: root.clicked()
    Keys.onEnterPressed: root.clicked()
    Keys.onSpacePressed: root.clicked()

    signal clicked()
    signal hovered(bool isHovered)

    readonly property color foreground: Kirigami.Theme.textColor
    readonly property color dim: Kirigami.Theme.disabledTextColor
    readonly property color accent: Kirigami.Theme.highlightColor
    readonly property string emojiFamily: "Noto Color Emoji"

    readonly property bool live: match && match.state === "live"
    readonly property bool upcoming: match && match.state === "upcoming"
    readonly property string clock: Model.matchClock(match)
    readonly property color clockColor: live ? accent : dim
    readonly property string winner: Model.winnerSide(match)
    readonly property bool justScored: !!(match && goalFlashIds && goalFlashIds[String(match.id)] !== undefined)

    property real goalFlash: 0

    onJustScoredChanged: {
        if (justScored) goalFlashAnimation.restart();
        else { goalFlashAnimation.stop(); goalFlash = 0; }
    }

    SequentialAnimation {
        id: goalFlashAnimation
        loops: 3
        NumberAnimation { target: root; property: "goalFlash"; to: 1; duration: 240; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "goalFlash"; to: 0; duration: 460; easing.type: Easing.InQuad }
    }

    Layout.fillWidth: true
    Layout.preferredHeight: 52
    width: parent ? parent.width : implicitWidth
    implicitWidth: 380
    implicitHeight: 52

    transformOrigin: Item.Center
    scale: mouse.containsMouse ? 1.012 : 1
    Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 6
        color: root.live || root.justScored
            ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.08 + root.goalFlash * 0.18)
            : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, mouse.containsMouse ? 0.08 : 0.03)
        border.width: root.activeFocus ? 2 : 1
        border.color: root.activeFocus
            ? root.accent
            : root.live || root.justScored
            ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.6 + root.goalFlash * 0.4)
            : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, mouse.containsMouse ? 0.25 : 0.1)

        Behavior on color { ColorAnimation { duration: 180 } }
        Behavior on border.color { ColorAnimation { duration: 180 } }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.topMargin: 6
        anchors.bottomMargin: 6
        spacing: 8

        // Status / live indicator gutter
        Item {
            visible: root.live || root.showCompetition
            Layout.preferredWidth: 16
            Layout.fillHeight: true

            Text {
                textFormat: Text.PlainText
                id: liveBall
                anchors.centerIn: parent
                visible: root.live
                text: Model.BALL_GLYPH
                font.family: root.emojiFamily
                font.pixelSize: 12

                SequentialAnimation on opacity {
                    running: root.live
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 0.35; duration: 900; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 0.35; to: 1.0; duration: 900; easing.type: Easing.InOutQuad }
                }
            }

            Image {
                anchors.centerIn: parent
                width: 14
                height: 14
                source: root.showCompetition && root.match ? Model.leagueLogoUrl(root.match.primaryLeagueId || root.match.leagueId) : ""
                sourceSize.width: 48
                sourceSize.height: 48
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                visible: !root.live && status === Image.Ready
            }
        }

        // Team logos column
        ColumnLayout {
            Layout.preferredWidth: 16
            Layout.alignment: Qt.AlignVCenter
            spacing: 4

            Item {
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

                Image {
                    anchors.fill: parent
                    source: match && match.home ? Model.teamLogoUrl(match.home.id) : ""
                    sourceSize.width: 48
                    sourceSize.height: 48
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    visible: status === Image.Ready
                }
            }

            Item {
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

                Image {
                    anchors.fill: parent
                    source: match && match.away ? Model.teamLogoUrl(match.away.id) : ""
                    sourceSize.width: 48
                    sourceSize.height: 48
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    visible: status === Image.Ready
                }
            }
        }

        // Team names column
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 4

            Text {
                textFormat: Text.PlainText
                Layout.fillWidth: true
                Layout.preferredHeight: 16
                verticalAlignment: Text.AlignVCenter
                text: match && match.home ? match.home.name : ""
                color: root.winner === "away" ? root.dim : root.foreground
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                font.bold: root.winner === "home"
                elide: Text.ElideRight
            }

            Text {
                textFormat: Text.PlainText
                Layout.fillWidth: true
                Layout.preferredHeight: 16
                verticalAlignment: Text.AlignVCenter
                text: match && match.away ? match.away.name : ""
                color: root.winner === "home" ? root.dim : root.foreground
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                font.bold: root.winner === "away"
                elide: Text.ElideRight
            }
        }

        // Scores column (strictly aligned in its own vertical column)
        ColumnLayout {
            visible: !root.upcoming
            Layout.preferredWidth: 26
            Layout.alignment: Qt.AlignVCenter
            spacing: 4
            transformOrigin: Item.Right
            scale: 1 + root.goalFlash * 0.15

            Text {
                textFormat: Text.PlainText
                Layout.fillWidth: true
                Layout.preferredHeight: 16
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
                text: match && match.home && match.home.score !== null ? String(match.home.score) : ""
                color: root.winner === "away" ? root.dim : root.foreground
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                font.bold: root.live || root.winner === "home"
            }

            Text {
                textFormat: Text.PlainText
                Layout.fillWidth: true
                Layout.preferredHeight: 16
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
                text: match && match.away && match.away.score !== null ? String(match.away.score) : ""
                color: root.winner === "home" ? root.dim : root.foreground
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                font.bold: root.live || root.winner === "away"
            }
        }

        // Match Status / Clock badge column
        Item {
            visible: root.clock !== ""
            Layout.preferredWidth: Math.max(statusBadge.width, 42)
            Layout.fillHeight: true

            Rectangle {
                id: statusBadge
                anchors.centerIn: parent
                width: Math.max(statusText.implicitWidth + 12, 38)
                height: 22
                radius: 4
                color: root.live
                    ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.15)
                    : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)
                border.width: root.live ? 1 : 0
                border.color: root.live ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.5) : "transparent"

                Text {
                    id: statusText
                    textFormat: Text.PlainText
                    anchors.centerIn: parent
                    text: root.clock
                    color: root.live ? root.accent : root.dim
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    font.bold: root.live
                }
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        onContainsMouseChanged: root.hovered(containsMouse)
    }
}
