import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout{
    id: root
    signal settingsRequested()
    spacing: 0

    Rectangle {
        color: "#dee0e2"
        Layout.fillWidth: true
        height: 50
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

    Rectangle {
        color: "#d1d5db"
        Layout.fillWidth: true
        height: 2
    }
}
