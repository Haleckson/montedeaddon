local _, LIB = ...

if GetLocale() ~= "ruRU" then return end

local L = LIB.Localization

-- Initialization

L["error.character-identity-unavailable"] = "Запуск прерван: GUID, имя персонажа или игровой мир недоступны. Попробуйте /reload."

-- Dialog

L["dialog.link.text"] = "Чтобы скопировать ссылку, нажмите CTRL + C."

-- Changelog

L["changelog.window.title"] = "Журнал изменений - %s"
L["changelog.window.close"] = "Закрыть"
L["settings.changelog.name"] = "Примечания к версии"
L["settings.changelog.button"] = "Журнал изменений"
L["settings.changelog.tooltip"] = "Открывает окно журнала изменений."

-- Profiles

L["settings.profiles.section-header"] = "Профили"
L["settings.profiles.profile-mode"] = "Активный профиль"
L["settings.profiles.mode.account"] = "Профиль учётной записи"
L["settings.profiles.mode.character"] = "Профиль персонажа"
L["settings.profiles.switch.name"] = "Сменить тип профиля"
L["settings.profiles.switch.tooltip"] = "Переключает между профилем учётной записи и профилем персонажа."
L["settings.profiles.switch.button.account-to-character"] = "Использовать профиль персонажа"
L["settings.profiles.switch.button.character-to-account"] = "Использовать профиль учётной записи"
L["settings.profiles.switch.confirm.account-to-character"] = "После этого персонаж будет использовать собственный профиль. Это изменение требует перезагрузки интерфейса. Продолжить?"
L["settings.profiles.switch.confirm.character-to-account"] = "После этого персонаж будет использовать профиль учётной записи. Это изменение требует перезагрузки интерфейса. Продолжить?"
L["settings.profiles.delete-character-profiles.name"] = "Сбросить профили персонажей"
L["settings.profiles.delete-character-profiles.button"] = "Удалить профили персонажей"
L["settings.profiles.delete-character-profiles.tooltip"] = "Удаляет все профили персонажей и переводит всех персонажей на профиль учётной записи."
L["settings.profiles.delete-character-profiles.confirm"] = "Все профили персонажей будут удалены, и все персонажи будут использовать профиль учётной записи. Продолжить?"

-- About

L["settings.about"] = "О дополнении"
L["settings.about.game-version"] = "Версия игры"
L["settings.about.addon-version"] = "Версия аддона"
L["settings.about.lib-version"] = "Версия библиотеки"
L["settings.about.author"] = "Автор"
L["settings.about.button-curseforge.name"] = "Страница проекта CurseForge"
L["settings.about.button-curseforge.tooltip"] = "Открывает всплывающее окно со ссылкой на CurseForge."
L["settings.about.button-curseforge.button"] = "CurseForge"
L["settings.about.button-wago.name"] = "Страница проекта Wago"
L["settings.about.button-wago.tooltip"] = "Открывает всплывающее окно со ссылкой на Wago."
L["settings.about.button-wago.button"] = "Wago"
L["settings.about.button-github.name"] = "Обратная связь и помощь"
L["settings.about.button-github.tooltip"] = "Открывает всплывающее окно со ссылкой на GitHub."
L["settings.about.button-github.button"] = "GitHub"
