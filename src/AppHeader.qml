import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ToolBar {
    id: root
    bottomPadding: 8

    signal settingsRequested()

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8

        Label {
            text: qsTr("WSFS Mount Manager")
            Layout.alignment: Qt.AlignVCenter
        }
        Item { Layout.fillWidth: true }
        Button {
            text: qsTr("Settings")
            icon.source: "qrc:/assets/icons/settings.svg"
            flat: true
            onClicked: root.settingsRequested()
        }
    }
}
