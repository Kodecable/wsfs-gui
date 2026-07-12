import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: root
    title: qsTr("Mount Configuration")
    width: 500
    height: 600
    visible: false
    modality: Qt.ApplicationModal
    color: "#f3f4f6"

    property var profile: ({})
    property bool allowClose: false
    property bool saveInProgress: false
    property bool closeAfterSave: false

    signal saveRequested(var payload)
    signal restartRequested()

    function loadProfile(nextProfile) {
        profile = nextProfile || ({})
        form.loadProfile(profile)
    }

    function hasChanges() {
        return form.hasChanges()
    }

    function saveCurrent() {
        if (!form.hasChanges())
            return false
        if (!form.isComplete())
            return false
        if (saveInProgress)
            return false
        saveInProgress = true
        saveRequested(form.payload())
        return true
    }

    function saveSucceeded() {
        saveInProgress = false
        const shouldClose = closeAfterSave
        closeAfterSave = false
        if (shouldClose) {
            closeWindow(false)
            return false
        }
        return true
    }

    function saveFailed() {
        saveInProgress = false
        closeAfterSave = false
    }

    function closeWindow(discardChanges) {
        if (discardChanges)
            form.loadProfile(profile)
        allowClose = true
        close()
        allowClose = false
    }

    onClosing: function(closeEvent) {
        if (allowClose)
            return
        if (form.hasChanges()) {
            closeEvent.accepted = false
            unsavedChangesDialog.open()
        }
    }

    Dialog {
        id: restartDialog
        parent: root.contentItem
        title: qsTr("Configuration Saved")
        modal: true
        standardButtons: Dialog.Yes | Dialog.No
        width: 300
        height: 160

        padding: 0 // this value will causing ugly duplicate padding between the header and content.
                   // not sure who design this, anyway, fuck you.

        contentItem: Label {
            text: qsTr("Restart current mount now to apply new settings?")
            wrapMode: Text.Wrap
            padding: 16
        }
        onAccepted: root.restartRequested()
    }

    Dialog {
        id: unsavedChangesDialog
        title: qsTr("Unsaved Changes")
        modal: true
        width: 300
        height: 160
        margins: 0
        
        padding: 0 // this value will causing ugly duplicate padding between the header and content.
                   // not sure who design this, anyway, fuck you.

        contentItem: Item {
            ColumnLayout {
                id: contentColumn
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16

                Label {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: qsTr("You have unsaved changes.")
                    wrapMode: Text.Wrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    Item { Layout.fillWidth: true }
                    Button {
                        text: qsTr("Save")
                        enabled: form.hasChanges() && form.isComplete() && !root.saveInProgress
                        onClicked: {
                            root.closeAfterSave = true
                            const ok = root.saveCurrent()
                            if (ok)
                                unsavedChangesDialog.close()
                            else
                                root.closeAfterSave = false
                        }
                    }
                    Button {
                        text: qsTr("Don't Save")
                        onClicked: {
                            unsavedChangesDialog.close()
                            root.closeWindow(true)
                        }
                    }
                    Button {
                        text: qsTr("Cancel")
                        onClicked: unsavedChangesDialog.close()
                    }
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        ToolBar {
            id: toolbar
            Layout.fillWidth: true
            bottomPadding: 8
            RowLayout {
                anchors.fill: parent
                anchors.margins: 8

                Label {
                    text: qsTr("Mount Configuration")
                    Layout.alignment: Qt.AlignVCenter
                }
                Item { Layout.fillWidth: true }
                Button {
                    text: qsTr("Save")
                    icon.source: "qrc:/assets/icons/save.svg"
                    flat: true
                    enabled: form.hasChanges() && form.isComplete() && !root.saveInProgress
                    onClicked: root.saveCurrent()
                }
            }
        }

        ScrollView {
            id: formScroll
            Layout.fillWidth: true
            Layout.fillHeight: true

            ProfileForm {
                id: form
                width: Math.max(implicitWidth, formScroll.availableWidth)
            }
        }
    }

    function promptRestartIfNeeded() {
        if (profile && profile.enabled === true)
            restartDialog.open()
    }
}
