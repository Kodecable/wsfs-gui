import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme/Theme.js" as Theme

Switch {
    id: root

    spacing: 10
    implicitHeight: Theme.controlHeight
    implicitWidth: contentItem.implicitWidth

    indicator: Item {
        implicitWidth: 0
        implicitHeight: 0
    }

    contentItem: RowLayout {
        spacing: root.spacing

        Rectangle {
            implicitWidth: 44
            implicitHeight: 26
            radius: height / 2
            color: root.checked ? Theme.accent : Theme.surfaceSunken
            border.width: 1
            border.color: root.checked ? Theme.accent : Theme.borderStrong
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                width: 20
                height: 20
                radius: 10
                anchors.verticalCenter: parent.verticalCenter
                x: root.checked ? parent.width - width - 3 : 3
                color: Theme.surfaceRaised
                border.width: 1
                border.color: root.checked ? Theme.accentPressed : Theme.borderStrong
            }
        }

        Text {
            text: root.text
            font: root.font
            color: root.enabled ? Theme.text : Theme.textSubtle
            verticalAlignment: Text.AlignVCenter
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
