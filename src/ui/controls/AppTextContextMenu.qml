import QtQuick
import QtQuick.Controls
import QtQuick.Controls.impl

AppMenu {
    id: root

    property var editor: null

    AppMenuItem {
        text: qsTr("Undo")
        action: UndoAction {
            editor: root.editor
        }
    }

    AppMenuItem {
        text: qsTr("Redo")
        action: RedoAction {
            editor: root.editor
        }
    }

    AppMenuSeparator {}

    AppMenuItem {
        text: qsTr("Cut")
        action: CutAction {
            editor: root.editor
        }
    }

    AppMenuItem {
        text: qsTr("Copy")
        action: CopyAction {
            editor: root.editor
        }
    }

    AppMenuItem {
        text: qsTr("Paste")
        action: PasteAction {
            editor: root.editor
        }
    }

    AppMenuItem {
        text: qsTr("Delete")
        action: DeleteAction {
            editor: root.editor
        }
    }

    AppMenuSeparator {}

    AppMenuItem {
        text: qsTr("Select All")
        action: SelectAllAction {
            editor: root.editor
        }
    }
}
