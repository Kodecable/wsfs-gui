import QtQuick
import QtQuick.Controls
import "../theme/Theme.js" as Theme

Menu {
    id: root

    implicitWidth: Math.max(160, contentItem ? contentItem.implicitWidth + leftPadding + rightPadding : 160)
    topPadding: 6
    bottomPadding: 6
    leftPadding: 6
    rightPadding: 6
    overlap: 1

    background: Rectangle {
        radius: Theme.radiusMedium
        color: Theme.surfaceRaised
        border.width: 1
        border.color: Theme.borderStrong
    }
}
