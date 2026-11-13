import QtQuick
import CachyOS.UI

Item {
    id: root

    property real iconSize: 18

    width: iconSize
    height: iconSize
    implicitWidth: iconSize
    implicitHeight: iconSize

    // CachyPlasmoidIcon resuelve el icono en el tema de iconos de Plasma y lo
    // tiñe con el primer plano del tema anfitrión (blanco en el tema de
    // escritorio macOS-GoldenGate), de modo que sigue el Tema Automático y
    // es siempre legible sobre el panel.
    CachyPlasmoidIcon {
        anchors.fill: parent
        iconName: "games-highscores-symbolic"
        iconSize: root.iconSize
    }

}
