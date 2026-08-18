/*
    Pixie SDDM - KDE Plasma 5 lock screen port
    Copyright (c) 2026 xCaptaiN09
    License: MIT
*/
import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.12 as Kirigami
import org.kde.kcm 1.5 as KCM

Kirigami.FormLayout {
    property alias cfg_use24HourClock: use24.checked
    property alias cfg_showMediaControls: showMedia.checked

    twinFormLayouts: parentLayout

    QQC2.CheckBox {
        id: use24
        Kirigami.FormData.label: i18ndc("plasma_lookandfeel_org.kde.lookandfeel",
                                        "@title: group",
                                        "Clock:")
        text: i18ndc("plasma_lookandfeel_org.kde.lookandfeel",
                     "@option:check",
                     "Use 24-hour clock")
    }

    QQC2.CheckBox {
        id: showMedia
        Kirigami.FormData.label: i18ndc("plasma_lookandfeel_org.kde.lookandfeel",
                                        "@title: group",
                                        "Media controls:")
        text: i18ndc("plasma_lookandfeel_org.kde.lookandfeel",
                     "@option:check",
                     "Show under unlocking prompt")
    }
}
