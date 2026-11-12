import QtQuick
import org.kde.kirigami as Kirigami
import CachyOS.UI

Item {
    id: root

    property real iconSize: 18

    width: iconSize
    height: iconSize
    implicitWidth: iconSize
    implicitHeight: iconSize

    Kirigami.Icon {
        anchors.fill: parent
        source: "games-highscores-symbolic"
        color: CachyTheme.textPrimary
    }

}
