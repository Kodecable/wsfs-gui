import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property string warningText: ""

    visible: root.warningText.length > 0
    Layout.fillWidth: true
    color: "#fef2f2"
    radius: 8
    border.color: "#fecaca"
    implicitHeight: infoCol.implicitHeight + 16

    ColumnLayout {
        id: infoCol
        anchors.fill: parent
        anchors.margins: 8
        spacing: 4

        Label {
            text: qsTr("Dependency Warning")
            color: "#991b1b"
        }
        Label {
            text: root.warningText
            color: "#7f1d1d"
        }
    }
}
