import QtQuick
import QtQuick.Controls
import "../theme/Theme.js" as Theme

CheckBox {
    id: root

    spacing: 10

    indicator: Rectangle {
        implicitWidth: 22
        implicitHeight: 22
        x: root.leftPadding
        y: parent.height / 2 - height / 2
        radius: 6
        border.width: 1
        border.color: root.checked || root.checkState === Qt.PartiallyChecked ? Theme.accent : Theme.borderStrong
        color: root.checked || root.checkState === Qt.PartiallyChecked ? Theme.accent : Theme.surfaceRaised

        Canvas {
            anchors.centerIn: parent
            width: 12
            height: 12
            visible: root.checked || root.checkState === Qt.PartiallyChecked
            contextType: "2d"
            onPaint: {
                context.reset()
                context.strokeStyle = Theme.surfaceRaised
                context.fillStyle = Theme.surfaceRaised
                context.lineWidth = 2.8
                context.lineCap = "round"
                context.lineJoin = "round"

                if (root.checkState === Qt.PartiallyChecked) {
                    context.fillRect(0.5, 4.6, 11, 2.8)
                } else {
                    context.beginPath()
                    context.moveTo(1.3, 6.4)
                    context.lineTo(4.6, 9.9)
                    context.lineTo(10.6, 2.1)
                    context.stroke()
                }
            }
        }
    }

    contentItem: Text {
        text: root.text
        font: root.font
        color: root.enabled ? Theme.text : Theme.textSubtle
        verticalAlignment: Text.AlignVCenter
        leftPadding: root.indicator.width + root.spacing
    }
}
