import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: root

    property real iconSize: 18

    width: iconSize
    height: iconSize

    Kirigami.Icon {
        anchors.fill: parent
        source: "games-highscores-symbolic"
        color: Kirigami.Theme.textColor
    }

}
