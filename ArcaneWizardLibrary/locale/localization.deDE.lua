local _, LIB = ...

if GetLocale() ~= "deDE" then return end

local L = LIB.Localization

-- Initialization

L["error.character-identity-unavailable"] = "Start abgebrochen: Spieler-GUID, Name oder Realm ist nicht verfügbar. Bitte versuche /reload."

-- Dialog

L["dialog.link.text"] = "Um den Link zu kopieren, drücke STRG + C."

-- Changelog

L["changelog.window.title"] = "%s - Changelog"
L["changelog.window.close"] = "Schließen"
L["settings.changelog.name"] = "Versionshinweise"
L["settings.changelog.button"] = "Changelog"
L["settings.changelog.tooltip"] = "Öffnet das Changelog-Fenster."

-- Profiles

L["settings.profiles.section-header"] = "Profile"
L["settings.profiles.profile-mode"] = "Aktives Profil"
L["settings.profiles.mode.account"] = "Accountprofil"
L["settings.profiles.mode.character"] = "Charakterprofil"
L["settings.profiles.switch.name"] = "Profiltyp wechseln"
L["settings.profiles.switch.tooltip"] = "Wechselt zwischen Accountprofil und Charakterprofil."
L["settings.profiles.switch.button.account-to-character"] = "Charakterprofil nutzen"
L["settings.profiles.switch.button.character-to-account"] = "Accountprofil nutzen"
L["settings.profiles.switch.confirm.account-to-character"] = "Dieser Charakter nutzt danach ein eigenes Charakterprofil. Diese Änderung erfordert ein Neuladen der Benutzeroberfläche. Möchtest du fortfahren?"
L["settings.profiles.switch.confirm.character-to-account"] = "Dieser Charakter nutzt danach das Accountprofil. Diese Änderung erfordert ein Neuladen der Benutzeroberfläche. Möchtest du fortfahren?"
L["settings.profiles.delete-character-profiles.name"] = "Charakterprofile zurücksetzen"
L["settings.profiles.delete-character-profiles.button"] = "Charakterprofile löschen"
L["settings.profiles.delete-character-profiles.tooltip"] = "Löscht alle Charakterprofile und setzt alle Charaktere auf das Accountprofil."
L["settings.profiles.delete-character-profiles.confirm"] = "Alle Charakterprofile werden gelöscht und alle Charaktere nutzen danach das Accountprofil. Möchtest du fortfahren?"

-- About

L["settings.about"] = "Über"
L["settings.about.game-version"] = "Spielversion"
L["settings.about.addon-version"] = "Addonversion"
L["settings.about.lib-version"] = "Bibliotheksversion"
L["settings.about.author"] = "Autor"
L["settings.about.button-curseforge.name"] = "CurseForge-Projektseite"
L["settings.about.button-curseforge.tooltip"] = "Öffnet ein Popup-Fenster mit einem Link zu CurseForge."
L["settings.about.button-curseforge.button"] = "CurseForge"
L["settings.about.button-wago.name"] = "Wago-Projektseite"
L["settings.about.button-wago.tooltip"] = "Öffnet ein Popup-Fenster mit einem Link zu Wago."
L["settings.about.button-wago.button"] = "Wago"
L["settings.about.button-github.name"] = "Feedback & Hilfe"
L["settings.about.button-github.tooltip"] = "Öffnet ein Popup-Fenster mit einem Link zu GitHub."
L["settings.about.button-github.button"] = "GitHub"
