import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme/Theme.js" as Theme

ComboBox {
    id: root

    implicitHeight: Theme.controlHeight
    leftPadding: 12
    rightPadding: 36
    topPadding: 9
    bottomPadding: 9

    contentItem: Text {
        leftPadding: 0
        rightPadding: 0
        text: root.displayText
        font: root.font
        color: Theme.text
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    indicator: Canvas {
        x: root.width - width - 12
        y: root.height / 2 - height / 2
        width: 12
        height: 8
        contextType: "2d"
        onPaint: {
            context.reset()
            context.moveTo(0, 0)
            context.lineTo(width, 0)
            context.lineTo(width / 2, height)
            context.closePath()
            context.fillStyle = Theme.textMuted
            context.fill()
        }
    }

    background: Rectangle {
        radius: Theme.radiusMedium
        border.width: 1
        border.color: root.activeFocus ? Theme.accent : (root.hovered ? Theme.borderStrong : Theme.border)
        color: Theme.surfaceRaised
    }

    delegate: ItemDelegate {
        width: root.width
        implicitHeight: 34
        leftPadding: 10
        rightPadding: 10
        topPadding: 7
        bottomPadding: 7
        hoverEnabled: true

        contentItem: Text {
            text: modelData[root.textRole] !== undefined ? modelData[root.textRole] : modelData
            color: Theme.text
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            leftPadding: 0
            rightPadding: 0
        }
        background: Rectangle {
            radius: Theme.radiusSmall
            color: (highlighted || parent.hovered) ? Theme.selection : "transparent"
        }
    }

    popup: Popup {
        y: root.height + 4
        width: root.width
        padding: 6
        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: root.delegateModel
            currentIndex: root.highlightedIndex
        }
        background: Rectangle {
            radius: Theme.radiusMedium
            color: Theme.surfaceRaised
            border.width: 1
            border.color: Theme.borderStrong
        }
    }
}
