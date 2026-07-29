import QtQuick
import QtQuick.Controls
import "../theme/Theme.js" as Theme

ScrollBar {
    id: root

    policy: root.size < 1.0 ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
    hoverEnabled: true
    minimumSize: 0.12

    width: orientation === Qt.Vertical ? 10 : (parent ? parent.width : 0)
    height: orientation === Qt.Horizontal ? 10 : (parent ? parent.height : 0)
    x: orientation === Qt.Vertical && parent ? parent.width - width : 0
    y: orientation === Qt.Horizontal && parent ? parent.height - height : 0

    contentItem: Rectangle {
        width: root.orientation === Qt.Vertical ? 6 : parent.width
        height: root.orientation === Qt.Horizontal ? 6 : parent.height
        radius: 3
        color: root.pressed ? Theme.borderStrong : (root.hovered ? Theme.textSubtle : Theme.borderStrong)
    }

    background: Rectangle {
        radius: 4
        color: Theme.surfaceSunken
        opacity: 0.9
    }
}
