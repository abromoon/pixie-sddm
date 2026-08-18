/*
    Pixie SDDM - KDE Plasma 5 lock screen port
    Copyright (c) 2026 xCaptaiN09
    License: MIT
*/
import QtQuick 2.15

Item {
    id: root

    property bool debug: false
    property string notification
    signal clearPassword()

    // These are magical properties that kscreenlocker looks for
    property bool viewVisible: false
    property bool suspendToRamSupported: false
    property bool suspendToDiskSupported: false

    // These are magical signals that kscreenlocker looks for
    signal suspendToDisk()
    signal suspendToRam()

    LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    implicitWidth: 800
    implicitHeight: 600

    LockScreenUi {
        anchors.fill: parent
    }
}
