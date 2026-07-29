import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme/Theme.js" as Theme

MenuItem {
    id: root

    implicitHeight: 34
    implicitWidth: leftPadding + rightPadding + contentRow.implicitWidth
    leftPadding: 10
    rightPadding: 10
    topPadding: 7
    bottomPadding: 7
    spacing: 10
    hoverEnabled: true

    contentItem: Item {
        implicitWidth: contentRow.width
        implicitHeight: Math.max(contentRow.height, 16)

        Row {
            id: contentRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.spacing

            Image {
                visible: root.icon.source.toString().length > 0
                source: root.icon.source
                width: 16
                height: 16
                fillMode: Image.PreserveAspectFit
            }

            Text {
                id: label
                text: root.text
                color: root.enabled ? Theme.text : Theme.textSubtle
            }
        }
    }

    background: Rectangle {
        radius: Theme.radiusSmall
        color: root.highlighted ? Theme.selection : "transparent"
    }
}
