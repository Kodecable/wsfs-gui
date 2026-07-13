function Component() {}

Component.prototype.createOperations = function() {
    component.createOperations();
    component.addOperation(
        "CreateShortcut",
        "@TargetDir@/wsfs-gui.exe",
        "@StartMenuDir@/WSFS GUI.lnk",
        "workingDirectory=@TargetDir@",
        "description=WSFS GUI"
    );
}
