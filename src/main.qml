import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root
    width: 450
    height: 600
    visible: true
    color: "#f3f4f6"
    title: qsTr("WSFS Mount Manager")

    required property var appModel
    property string pendingDeleteProfileId: ""
    property string errorMessage: ""
    readonly property bool hasModel: root.appModel !== null

    function profileNameById(profileId) {
        if (!root.hasModel)
            return profileId
        const list = root.appModel.profiles
        for (let i = 0; i < list.length; i++) {
            if (list[i].id === profileId)
                return list[i].name || profileId
        }
        return profileId
    }

    function reloadSelected() {
        configWindow.loadProfile(root.hasModel ? root.appModel.selectedProfile : ({}))
    }

    function showConfig(profileId) {
        if (!root.hasModel)
            return
        root.appModel.selectedProfileId = profileId
        root.reloadSelected()
        configWindow.show()
        configWindow.raise()
        configWindow.requestActivate()
    }

    function showLogs(profileId) {
        if (!root.hasModel)
            return
        root.appModel.selectedProfileId = profileId
        logsWindow.profileId = profileId
        logsWindow.profileName = root.profileNameById(profileId)
        logsWindow.show()
        logsWindow.raise()
        logsWindow.requestActivate()
    }

    Connections {
        target: root.hasModel ? root.appModel : null
        function onSelectedProfileChanged() {
            root.reloadSelected()
        }
        function onProfilesChanged() {
            if (!root.hasModel)
                return
            if (!root.appModel.selectedProfileId && root.appModel.profiles.length > 0)
                root.appModel.selectedProfileId = root.appModel.profiles[0].id
        }
        function onProfileSaveFinished(ok, error) {
            if (ok) {
                configWindow.loadProfile(root.appModel.selectedProfile)
                if (configWindow.saveSucceeded())
                    configWindow.promptRestartIfNeeded()
                return
            }
            configWindow.saveFailed()
            root.errorMessage = error
            errorDialog.open()
        }
        function onCredentialMigrationFinished(ok, error) {
            if (ok)
                return
            root.errorMessage = error
            errorDialog.open()
        }
    }

    Component.onCompleted: root.reloadSelected()

    Dialog {
        id: deleteConfirmDialog
        title: qsTr("Confirm Delete")
        modal: true
        standardButtons: Dialog.Yes | Dialog.No
        width: 380
        contentItem: Label {
            text: qsTr("Delete this mount profile?")
            wrapMode: Text.Wrap
            padding: 12
        }
        onAccepted: {
            if (!root.hasModel || !root.pendingDeleteProfileId.length)
                return
            root.appModel.selectedProfileId = root.pendingDeleteProfileId
            root.appModel.removeSelectedProfile()
            root.pendingDeleteProfileId = ""
        }
        onRejected: root.pendingDeleteProfileId = ""
    }

    Dialog {
        id: errorDialog
        title: qsTr("Error")
        modal: true
        standardButtons: Dialog.Ok
        width: 420
        contentItem: Label {
            text: root.errorMessage
            wrapMode: Text.Wrap
            padding: 12
        }
    }

    ProfileConfigWindow {
        id: configWindow
        onSaveRequested: function(payload) {
            if (!root.hasModel)
                return
            root.appModel.saveSelectedProfile(payload)
        }
        onRestartRequested: {
            if (root.hasModel)
                root.appModel.restartSelected()
        }
    }

    LogsWindow {
        id: logsWindow
        hasModel: root.hasModel
        appModel: root.appModel
    }

    SettingsWindow {
        id: settingsWindow
        hasModel: root.hasModel
        appModel: root.appModel
    }

    header: AppHeader {
        onSettingsRequested: {
            settingsWindow.show()
            settingsWindow.raise()
            settingsWindow.requestActivate()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 8
        spacing: 10

        DependencyBanner {
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            warningText: root.hasModel ? root.appModel.dependencyWarning : ""
        }

        ProfileList {
            hasModel: root.hasModel
            profiles: root.hasModel ? root.appModel.profiles : []
            selectedProfileId: root.hasModel ? root.appModel.selectedProfileId : ""
            onCreateRequested: {
                if (!root.hasModel)
                    return
                const id = root.appModel.createProfile()
                root.appModel.selectedProfileId = id
                root.showConfig(id)
            }
            onStopAllRequested: {
                if (root.hasModel)
                    root.appModel.stopAll()
            }
            onProfileEnabledToggled: function(profileId, enabled) {
                if (root.hasModel)
                    root.appModel.setProfileEnabled(profileId, enabled)
            }
            onConfigureRequested: function(profileId) {
                root.showConfig(profileId)
            }
            onLogsRequested: function(profileId) {
                root.showLogs(profileId)
            }
            onDeleteRequested: function(profileId) {
                if (!root.hasModel)
                    return
                root.pendingDeleteProfileId = profileId
                deleteConfirmDialog.open()
            }
            onSelectedRequested: function(profileId) {
                if (root.hasModel)
                    root.appModel.selectedProfileId = profileId
            }
        }
    }
}
