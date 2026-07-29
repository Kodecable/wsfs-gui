import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme/Theme.js" as Theme

ColumnLayout {
    id: root
    signal settingsRequested()
    spacing: 0

    AppSectionHeader {
        Layout.fillWidth: true
        title: qsTr("WSFS Mount Manager")

        AppButton {
            text: qsTr("Settings")
            icon.source: "qrc:/assets/icons/settings.svg"
            onClicked: root.settingsRequested()
        }
    }

    Rectangle {
        color: Theme.border
        Layout.fillWidth: true
        height: 1
    }
}
