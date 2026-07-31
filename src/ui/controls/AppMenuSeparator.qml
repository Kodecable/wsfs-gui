import QtQuick
import QtQuick.Controls
import "../theme/Theme.js" as Theme

MenuSeparator {
    id: root

    topPadding: 5
    bottomPadding: 5
    leftPadding: 10
    rightPadding: 10

    contentItem: Rectangle {
        implicitHeight: 1
        color: Theme.border
    }
}
