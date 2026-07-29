import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme/Theme.js" as Theme

Rectangle {
    id: root

    property alias title: titleLabel.text
    property alias subtitle: subtitleLabel.text
    default property alias actions: actionRow.data

    color: Theme.surfaceSunken
    implicitHeight: Theme.headerHeight

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.panelPadding
        anchors.rightMargin: Theme.panelPadding
        spacing: Theme.panelGap

        ColumnLayout {
            spacing: 2

            Label {
                id: titleLabel
                color: Theme.text
                font.pixelSize: 20
                font.bold: false
            }

            Label {
                id: subtitleLabel
                visible: text.length > 0
                color: Theme.textSubtle
                font.pixelSize: 12
            }
        }

        Item {
            Layout.fillWidth: true
        }

        RowLayout {
            id: actionRow
            spacing: 8
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
        }
    }
}
