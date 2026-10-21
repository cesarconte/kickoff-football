import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: root

    property alias cfg_notify: notifyCheckBox.checked

    Kirigami.FormLayout {
        QQC2.CheckBox {
            id: notifyCheckBox
            Kirigami.FormData.label: i18n("Notifications:")
            text: i18n("Goal notifications (desktop alert when followed club scores)")
        }

    }
}
