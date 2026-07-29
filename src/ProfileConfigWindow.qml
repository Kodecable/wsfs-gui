import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import "ui/controls"
import "ui/theme/Theme.js" as Theme

Window {
    id: root
    title: qsTr("Mount Configuration")
    width: 500
    height: 600
    visible: false
    modality: Qt.ApplicationModal
    color: Theme.window

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

    AppDialog {
        id: restartDialog
        width: 320
        dialogTitle: qsTr("Configuration Saved")
        messageText: qsTr("Restart current mount now to apply new settings?")

        buttons: [
            AppButton {
                text: qsTr("No")
                onClicked: restartDialog.close()
            },
            AppButton {
                text: qsTr("Yes")
                onClicked: {
                    restartDialog.close()
                    root.restartRequested()
                }
            }
        ]
    }

    AppDialog {
        id: unsavedChangesDialog
        width: 340
        dialogTitle: qsTr("Unsaved Changes")
        messageText: qsTr("You have unsaved changes.")
        bodySpacing: 16

        buttons: [
            AppButton {
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
            },
            AppButton {
                text: qsTr("Don't Save")
                onClicked: {
                    unsavedChangesDialog.close()
                    root.closeWindow(true)
                }
            },
            AppButton {
                text: qsTr("Cancel")
                onClicked: unsavedChangesDialog.close()
            }
        ]
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        AppSectionHeader {
            Layout.fillWidth: true
            title: qsTr("Mount Configuration")

            AppButton {
                text: qsTr("Save")
                icon.source: "qrc:/assets/icons/save.svg"
                enabled: form.hasChanges() && form.isComplete() && !root.saveInProgress
                onClicked: root.saveCurrent()
            }
        }

        Rectangle {
            color: Theme.border
            Layout.fillWidth: true
            height: 1
        }

        AppPanel {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 16

            ScrollView {
                id: formScroll
                anchors.fill: parent
                anchors.margins: 8
                ScrollBar.vertical: AppScrollBar {}

                ProfileForm {
                    id: form
                    width: Math.max(implicitWidth, formScroll.availableWidth)
                }
            }
        }
    }

    function promptRestartIfNeeded() {
        if (profile && profile.enabled === true)
            restartDialog.open()
    }
}
