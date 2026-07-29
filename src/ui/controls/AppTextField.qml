import QtQuick
import QtQuick.Controls
import "../theme/Theme.js" as Theme

TextField {
    id: root

    implicitHeight: Theme.controlHeight
    color: Theme.text
    selectedTextColor: Theme.surfaceRaised
    selectionColor: Theme.accent
    placeholderTextColor: Theme.textSubtle
    leftPadding: 12
    rightPadding: 12
    topPadding: 9
    bottomPadding: 9

    background: Rectangle {
        radius: Theme.radiusMedium
        border.width: 1
        border.color: root.activeFocus ? Theme.accent : (root.hovered ? Theme.borderStrong : Theme.border)
        color: root.enabled ? Theme.surfaceRaised : Theme.surfaceSunken
    }
}
