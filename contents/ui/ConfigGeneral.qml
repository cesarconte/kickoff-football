import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: root

    property alias cfg_notify: notifyCheckBox.checked
    property string cfg_matchesFilter: matchesFilterCombo.currentValue

    Kirigami.FormLayout {
        QQC2.CheckBox {
            id: notifyCheckBox
            Kirigami.FormData.label: i18n("Notifications:")
            text: i18n("Goal notifications (desktop alert when followed club scores)")
        }

        QQC2.ComboBox {
            id: matchesFilterCombo
            Kirigami.FormData.label: i18n("Matches list:")
            model: [
                { text: i18n("Featured leagues only"), value: "featured" },
                { text: i18n("All competitions"), value: "all" }
            ]
            textRole: "text"
            valueRole: "value"
            Component.onCompleted: {
                for (var i = 0; i < model.length; ++i) {
                    if (model[i].value === plasmoid.configuration.matchesFilter) {
                        currentIndex = i;
                        break;
                    }
                }
            }
        }
    }
}
