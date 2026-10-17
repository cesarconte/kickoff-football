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
        border.width: 1
        border.color: root.live || root.justScored
            ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.6 + root.goalFlash * 0.4)
            : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, mouse.containsMouse ? 0.25 : 0.1)

        Behavior on color { ColorAnimation { duration: 180 } }
        Behavior on border.color { ColorAnimation { duration: 180 } }
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 10
        spacing: 8

        // Status / live indicator gutter
        Item {
            width: 18
            height: parent.height

            Text {
                textFormat: Text.PlainText
                id: liveBall
                anchors.centerIn: parent
                visible: root.live
                text: Model.BALL_GLYPH
                font.family: root.emojiFamily
                font.pixelSize: 13

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
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Image {
                width: 16
                height: 16
                source: match && match.home ? Model.teamLogoUrl(match.home.id) : ""
                sourceSize.width: 48
                sourceSize.height: 48
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                visible: status === Image.Ready
            }

            Image {
                width: 16
                height: 16
                source: match && match.away ? Model.teamLogoUrl(match.away.id) : ""
                sourceSize.width: 48
                sourceSize.height: 48
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                visible: status === Image.Ready
            }
        }

        // Team names column
        Column {
            width: parent.width - 150
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Row {
                width: parent.width
                spacing: 6

                Text {
                    textFormat: Text.PlainText
                    width: parent.width - (homeNet.visible ? homeNet.width + 6 : 0)
                    text: match && match.home ? match.home.name : ""
                    color: root.foreground
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                    font.bold: root.live || root.winner === "home"
                    elide: Text.ElideRight
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    textFormat: Text.PlainText
                    id: homeNet
                    visible: root.winner === "home"
                    text: Model.NET_GLYPH
                    font.family: root.emojiFamily
                    font.pixelSize: 11
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Row {
                width: parent.width
                spacing: 6

                Text {
                    textFormat: Text.PlainText
                    width: parent.width - (awayNet.visible ? awayNet.width + 6 : 0)
                    text: match && match.away ? match.away.name : ""
                    color: root.foreground
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                    font.bold: root.live || root.winner === "away"
                    elide: Text.ElideRight
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    textFormat: Text.PlainText
                    id: awayNet
                    visible: root.winner === "away"
                    text: Model.NET_GLYPH
                    font.family: root.emojiFamily
                    font.pixelSize: 11
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // Scores and Clock column
        Column {
            width: 80
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            transformOrigin: Item.Right
            scale: 1 + root.goalFlash * 0.15

            Text {
                textFormat: Text.PlainText
                width: parent.width
                text: root.upcoming ? "" : (match && match.home && match.home.score !== null ? String(match.home.score) : "")
                color: root.foreground
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                font.bold: true
                horizontalAlignment: Text.AlignRight
            }

            Row {
                width: parent.width
                spacing: 6
                layoutDirection: Qt.RightToLeft

                Text {
                    textFormat: Text.PlainText
                    text: root.clock
                    color: root.clockColor
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    font.bold: root.live
                }

                Text {
                    textFormat: Text.PlainText
                    visible: !root.upcoming
                    text: match && match.away && match.away.score !== null ? String(match.away.score) : ""
                    color: root.foreground
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                    font.bold: true
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
