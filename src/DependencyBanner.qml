import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "ui/controls"
import "ui/theme/Theme.js" as Theme

AppPanel {
    id: root

    property string warningText: ""

    visible: root.warningText.length > 0
    Layout.fillWidth: true
    color: Theme.warningSoft
    border.color: Theme.warning
    implicitHeight: infoCol.implicitHeight + 16

    ColumnLayout {
        id: infoCol
        anchors.fill: parent
        anchors.margins: 8
        spacing: 4

        Label {
            text: qsTr("Dependency Warning")
            color: Theme.warning
            font.bold: true
        }
        Label {
            text: root.warningText
            color: Theme.text
            wrapMode: Text.Wrap
        }
    }
}
