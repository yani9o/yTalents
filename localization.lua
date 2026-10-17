-- Edit each term's enUS and deDE text below. Other client locales use English.
-- Keep internal IDs, commands and saved values out of translated UI text.
local _, addon = ...
local terms = {
    ["PLANNER_SPELL_ID"] = {
        enUS = "Spell ID:",
        deDE = "Zauber-ID:",
    },
    ["REMOVE_DEPENDENT_TALENTS_FIRST"] = {
        enUS = "Remove dependent talents first.",
        deDE = "Zuerst abhängige Talente entfernen.",
    },
    ["PLANNER_COUNTER_LEVEL_LABEL"] = {
        enUS = "Level:",
        deDE = "Stufe :",
    },
    ["PLANNER_COUNTER_TALENTS_LABEL"] = {
        enUS = "Talents:",
        deDE = "Talente:",
    },
    ["PLANNER_COUNTER_REMAINING_LABEL"] = {
        enUS = "Remaining:",
        deDE = "Verbleibend:",
    },
    ["PLANNER_COUNTER_TITLE"] = {
        enUS = "Talent points",
        deDE = "Talentpunkte",
    },
    ["PLANNER_COUNTER_EXPLANATION"] = {
        enUS = "Required level, allocated talent points, and remaining points.\nThe required level excludes early legacy talent points.",
        deDE = "Benötigte Stufe, verteilte Talentpunkte und verbleibende Punkte.\nDie benötigte Stufe berücksichtigt keine vorzeitig erhaltenen Legacy-Talentpunkte.",
    },
    ["PLANNER_NEXT_RANK"] = {
        enUS = "Next rank:",
        deDE = "Nächster Rang:",
    },
    ["PLANNER_POINTS_USED"] = {
        enUS = "Talent points: %d/51",
        deDE = "Talentpunkte: %d/51",
    },
    ["PLANNER_POINTS_REMAINING"] = {
        enUS = "Remaining: %d",
        deDE = "Verbleibend: %d",
    },
    ["PLANNER_REQUIRED_LEVEL"] = {
        enUS = "Required level: %d",
        deDE = "Benötigte Stufe: %d",
    },
    ["CURRENT_TALENTS"] = {
        enUS = "Current talents",
        deDE = "Aktuelle Talente",
    },
    ["ENTER_A_NAME_FOR_THE_TALENT_BUILD"] = {
        enUS = "Enter a build name",
        deDE = "Buildnamen eingeben",
    },
    ["CHOOSE_A_NEW_NAME_FOR_YOUR_COPY"] = {
        enUS = "Choose a new name",
        deDE = "Neuen Namen wählen",
    },
    ["CURRENT_TALENTS_UPDATE_AUTOMATICALLY_SAVE_YOUR_CHANGES_AS_A_NEW_TALENT_BUILD"] = {
        enUS = "Save as a new build",
        deDE = "Als neuen Build speichern",
    },
    ["NAMES_MUST_BE_AT_MOST_80_CHARACTERS_LONG"] = {
        enUS = "Name too long (max. 80)",
        deDE = "Name zu lang (max. 80)",
    },
    ["OPEN_A_TALENT_BUILD_FIRST"] = {
        enUS = "Open a build first",
        deDE = "Zuerst einen Build öffnen",
    },
    ["SELECT_A_SAVED_TALENT_BUILD_FIRST"] = {
        enUS = "Select a saved build",
        deDE = "Gespeicherten Build wählen",
    },
    ["A_TALENT_BUILD_WITH_THIS_NAME_ALREADY_EXISTS_CHOOSE_ANOTHER_NAME"] = {
        enUS = "Name already taken",
        deDE = "Name bereits vergeben",
    },
    ["TALENT_BUILD_UPDATED"] = {
        enUS = "Build updated",
        deDE = "Build aktualisiert",
    },
    ["TALENT_BUILD_SAVED"] = {
        enUS = "Build saved",
        deDE = "Build gespeichert",
    },
    ["TALENT_BUILD_NOT_FOUND"] = {
        enUS = "Build not found",
        deDE = "Build nicht gefunden",
    },
    ["CURRENT_TALENTS_CANNOT_BE_DELETED"] = {
        enUS = "Current talents: no deletion",
        deDE = "Aktuelle Talente: geschützt",
    },
    ["TALENT_BUILD_DELETED"] = {
        enUS = "Build deleted",
        deDE = "Build gelöscht",
    },
    ["PASTE_A_TALENT_CODE_FROM_WOW_FOREVER"] = {
        enUS = "Paste a Forever code",
        deDE = "Forever-Code einfügen",
    },
    ["THE_GAME_S_TALENT_WINDOW_IS_UNAVAILABLE"] = {
        enUS = "Talent window unavailable",
        deDE = "Talentfenster nicht verfügbar",
    },
    ["INVALID_OR_OUTDATED_TALENT_CODE_WOTLK_CODES_ARE_INCOMPATIBLE"] = {
        enUS = "Invalid / outdated code",
        deDE = "Ungültiger / veralteter Code",
    },
    ["THIS_IS_NOT_A_WOW_FOREVER_CLASS_TALENT_BUILD"] = {
        enUS = "Not a Forever build",
        deDE = "Kein Forever-Build",
    },
    ["THIS_CLASS_S_TALENT_DATA_IS_UNAVAILABLE"] = {
        enUS = "Talent data unavailable",
        deDE = "Talentdaten nicht verfügbar",
    },
    ["THE_TALENT_CODE_IS_INCOMPLETE"] = {
        enUS = "Incomplete talent code",
        deDE = "Talentcode unvollständig",
    },
    ["THE_TALENT_TREE_HAS_CHANGED_EXPORT_THIS_TALENT_BUILD_AGAIN"] = {
        enUS = "Tree changed: export again",
        deDE = "Baum geändert: neu exportieren",
    },
    ["INVALID_TALENT_CODE_OR_UNAVAILABLE_TALENT_DATA"] = {
        enUS = "Code / data unavailable",
        deDE = "Code / Daten nicht verfügbar",
    },
    ["TALENT_BUILD_LOADED"] = {
        enUS = "Build loaded",
        deDE = "Build geladen",
    },
    ["TALENT_DATA_IS_STILL_LOADING"] = {
        enUS = "Talent data loading",
        deDE = "Talentdaten werden geladen",
    },
    ["INVALID_TALENT_RANK"] = {
        enUS = "Invalid talent build",
        deDE = "Ungültiger Talentbuild",
    },
    ["INVALID_TALENT_SELECTION"] = {
        enUS = "Invalid talent build",
        deDE = "Ungültiger Talentbuild",
    },
    ["NO_MORE_TALENT_POINTS_ARE_AVAILABLE_AT_THIS_LEVEL"] = {
        enUS = "No talent points left",
        deDE = "Keine Talentpunkte übrig",
    },
    ["TALENT_LOCKED_SPEND_POINTS_IN_EARLIER_ROWS_AND_MEET_THE_PREREQUISITE"] = {
        enUS = "Talent requirements not met",
        deDE = "Voraussetzungen nicht erfüllt",
    },
    ["OPEN_YTALENTS"] = {
        enUS = "Open yTalents",
        deDE = "yTalents öffnen",
    },
    ["PLANNING_PAUSES_DURING_COMBAT_YOUR_TALENT_BUILD_IS_PRESERVED"] = {
        enUS = "Combat: plan saved",
        deDE = "Kampf: Plan bleibt erhalten",
    },
    ["YES"] = {
        enUS = "Yes",
        deDE = "Ja",
    },
    ["NO"] = {
        enUS = "No",
        deDE = "Nein",
    },
    ["SEND"] = {
        enUS = "Send",
        deDE = "Senden",
    },
    ["CANCEL"] = {
        enUS = "Cancel",
        deDE = "Abbrechen",
    },
    ["WHISPER_THIS_TALENT_BUILD_TO"] = {
        enUS = "Whisper this talent build to:",
        deDE = "Diesen Talentbuild flüstern an:",
    },
    ["PRESS_CTRL_C_TO_COPY"] = {
        enUS = "Press Ctrl+C to copy",
        deDE = "Zum Kopieren Strg+C drücken",
    },
    ["DISCARD_UNSAVED_CHANGES_TO_THIS_TALENT_BUILD"] = {
        enUS = "Discard unsaved changes to this talent build?",
        deDE = "Ungespeicherte Änderungen an diesem Talentbuild verwerfen?",
    },
    ["THE_ACTION_COULD_NOT_BE_COMPLETED"] = {
        enUS = "Action failed",
        deDE = "Aktion fehlgeschlagen",
    },
    ["SELECT_CLASS"] = {
        enUS = "Select class",
        deDE = "Klasse auswählen",
    },
    ["SELECT_A_CLASS_FOR_A_NEW_LEVEL_60_TALENT_BUILD"] = {
        enUS = "Change class in the talent planner",
        deDE = "Klasse im Talentplaner ändern",
    },
    ["SELECT_THE_CLASS_AFTER_COMBAT"] = {
        enUS = "Available after combat",
        deDE = "Nach dem Kampf verfügbar",
    },
    ["SAVED_TALENT_BUILDS"] = {
        enUS = "Saved talent builds",
        deDE = "Gespeicherte Talentbuilds",
    },
    ["NO_TALENT_BUILDS"] = {
        enUS = "No Talentbuilds",
        deDE = "Keine Talentbuilds",
    },
    ["TALENT_BUILD_NAME"] = {
        enUS = "Talent build name",
        deDE = "Name des Talentplans",
    },
    ["SAVE_AS_A_NEW_TALENT_BUILD"] = {
        enUS = "Save as a new talent build",
        deDE = "Als neuen Talentbuild speichern",
    },
    ["SAVE_THE_CURRENT_TALENT_BUILD_USING_THE_ENTERED_NAME"] = {
        enUS = "Save the current talent build using the entered name.",
        deDE = "Speichere den aktuellen Talentbuild unter dem eingegebenen Namen.",
    },
    ["UPDATE"] = {
        enUS = "Update talent build",
        deDE = "Talentbuild aktualisieren",
    },
    ["OVERWRITE_THE_SELECTED_SAVED_TALENT_BUILD_WITH_THE_CURRENT_PLAN"] = {
        enUS = "Overwrite the current talent build",
        deDE = "Aktuellen Talentbuild überschreiben",
    },
    ["DELETE_TALENT_BUILD"] = {
        enUS = "Delete talent build",
        deDE = "Talentbuild löschen",
    },
    ["DELETE_THE_SELECTED_SAVED_TALENT_BUILD"] = {
        enUS = "Delete the current talent build.",
        deDE = "Aktuellen Talentbuild löschen.",
    },
    ["DELETE_TALENT_BUILD_2"] = {
        enUS = "Delete talent build “",
        deDE = "Talentbuild „",
    },
    ["TEXT"] = {
        enUS = "”?",
        deDE = "“ löschen?",
    },
    ["RESET_ALL_TALENT_TREES"] = {
        enUS = "Reset talents",
        deDE = "Talente zurücksetzen",
    },
    ["REMOVE_ALL_TALENT_POINTS_FROM_THIS_PLAN"] = {
        enUS = "Remove all talent points.",
        deDE = "Entferne alle Talentpunkte.",
    },
    ["RESET_ALL_TALENT_POINTS_IN_ALL_THREE_TALENT_TREES"] = {
        enUS = "Reset all talent points in all three talent trees?",
        deDE = "Alle Talentpunkte in allen drei Talentbäumen zurücksetzen?",
    },
    ["PREPARE_TALENTS"] = {
        enUS = "Apply talent build",
        deDE = "Talente übernehmen",
    },
    ["PREPARE_YOUR_TALENT_BUILD_THEN_REVIEW_IT_AND_CONFIRM_IT_WITH_THE_GAME_S_APPLY_BUTTON"] = {
        enUS = "Stage the selected talent build for this character. Review it and confirm with \"Apply Changes\".",
        deDE = "Ausgewählten Talentbuild für diesen Charakter übernehmen. Prüfe ihn anschließend und bestätige mit \"Änderungen anwenden\".",
    },
    ["SAVED_INDICATOR"] = {
        enUS = "Saved |TInterface\\RaidFrame\\ReadyCheck-Ready:14:14|t",
        deDE = "Gespeichert |TInterface\\RaidFrame\\ReadyCheck-Ready:14:14|t",
    },
    ["WOW_FOREVER_CODE"] = {
        enUS = "WoW Forever code",
        deDE = "WoW-Forever-Code",
    },
    ["IMPORT"] = {
        enUS = "Import",
        deDE = "Importieren",
    },
    ["IMPORT_THE_CODE_OR_TALENT_CALCULATOR_LINK_FROM_THIS_FIELD_PRESSING_ENTER_DOES_THE_SAM"] = {
        enUS = "Import the code or talent calculator link from this field. Pressing Enter does the same.",
        deDE = "Importiere den Code oder den Talentplaner-Link im Textfeld. Die Eingabetaste führt dieselbe Aktion aus.",
    },
    ["COPY"] = {
        enUS = "Copy",
        deDE = "Kopieren",
    },
    ["COPY_THIS_TALENT_BUILD_IN_THE_SELECTED_EXPORT_FORMAT"] = {
        enUS = "Copy this talent build in the selected export format.",
        deDE = "Kopiere diesen Talentbuild im ausgewählten Exportformat.",
    },
    ["SHARE"] = {
        enUS = "Share",
        deDE = "Teilen",
    },
    ["WHISPER_A_CLICKABLE_TALENT_BUILD_LINK_TO_YOUR_FRIENDLY_PLAYER_TARGET_OR_ENTER_A_RECIP"] = {
        enUS = "Whisper a clickable talent build link to your friendly player target or enter a recipient. yTalents can open the link in the talent planner.",
        deDE = "Flüstere deinem freundlichen Spielerziel einen anklickbaren Talentbuild-Link oder gib einen Empfänger ein. Mit yTalents lässt sich der Link im Talentplaner öffnen.",
    },
    ["IMPORT_EXPORT"] = {
        enUS = "Import / Export",
        deDE = "Importieren / Exportieren",
    },
    ["PASTE_A_CODE_OR_TALENT_CALCULATOR_LINK_AND_PRESS_ENTER_TO_IMPORT_SELECT_THE_TEXT_AND"] = {
        enUS = "Paste a code or talent calculator link and press Enter to import. Select the text and press Ctrl+C to copy.",
        deDE = "Füge einen Code oder Talentplaner-Link ein und drücke zum Importieren die Eingabetaste. Markiere den Text und drücke zum Kopieren Strg+C.",
    },
    ["RESET_TALENT_TREE"] = {
        enUS = "Reset talent tree",
        deDE = "Talentbaum zurücksetzen",
    },
    ["RESET_ONLY_THIS_TALENT_TREE_THE_OTHER_TWO_ARE_PRESERVED"] = {
        enUS = "Reset only this talent tree. The other two are preserved.",
        deDE = "Setze nur diesen Talentbaum zurück. Die beiden anderen bleiben erhalten.",
    },
    ["RESET_TALENTS_IN"] = {
        enUS = "Reset talents in: ",
        deDE = "Talente zurücksetzen in: ",
    },
    ["ENABLE_YTALENTS_IN_THE_ADDON_OPTIONS_FIRST"] = {
        enUS = "Enable yTalents first",
        deDE = "Zuerst yTalents aktivieren",
    },
    ["ENABLE_ADDON"] = {
        enUS = "Enable %s",
        deDE = "%s aktivieren",
    },
    ["OPTIONS_DESCRIPTION"] = {
        enUS = "Save, share and plan talent builds in WoW Forever's talent window.",
        deDE = "Speichere, teile und plane Talentbuilds im Talentfenster von WoW Forever.",
    },
    ["SAVED_TALENT_BUILDS_ARE_AVAILABLE_TO_ALL_CHARACTERS_ON_THIS_ACCOUNT_PLANNING_DOES_NOT"] = {
        enUS = "Saved talent builds are available to all characters on this account.\nPlanning does not spend your character's talent points.\nPrepare a talent build and confirm it with Apply in the game.\n\nCommands: /ytalents or /ytools talents",
        deDE = "Gespeicherte Talentbuilds stehen allen Charakteren dieses Accounts zur Verfügung.\nDie Planung verbraucht keine Talentpunkte deines Charakters.\nBereite einen Talentbuild vor und bestätige ihn im Spiel mit „Anwenden“.\n\nBefehle: /ytalents oder /ytools talents",
    },
    ["OPEN_ADDON"] = {
        enUS = "Open %s",
        deDE = "%s öffnen",
    },
    ["OPEN_TALENT_PLANNER"] = {
        enUS = "Open talent planner",
        deDE = "Talentplaner öffnen",
    },
    ["OPEN_YTALENTS_AFTER_COMBAT"] = {
        enUS = "Available after combat",
        deDE = "Nach dem Kampf verfügbar",
    },
    ["THE_GAME_S_TALENT_WINDOW_COULD_NOT_BE_LOADED"] = {
        enUS = "Talent window not loaded",
        deDE = "Talentfenster nicht geladen",
    },
    ["THIS_ADDON_REQUIRES_WOW_FOREVER_S_TALENT_WINDOW"] = {
        enUS = "Forever client required",
        deDE = "Forever-Client benötigt",
    },
    ["TALENT_PLANNING_IS_UNAVAILABLE_DURING_COMBAT"] = {
        enUS = "Talent planner is not available during combat.",
        deDE = "Der Talentplaner ist während des Kampfes nicht verfügbar.",
    },
    ["THE_GAME_COULD_NOT_DISPLAY_THIS_TALENT_BUILD"] = {
        enUS = "The game could not display this talent build.",
        deDE = "Das Spiel konnte diesen Talentbuild nicht anzeigen.",
    },
    ["TALENT_PREVIEW_UNAVAILABLE"] = {
        enUS = "Talent preview unavailable: ",
        deDE = "Talentvorschau nicht verfügbar: ",
    },
    ["TALENT_DATA_IS_UNAVAILABLE_OR_THE_TALENT_BUILD_CONTAINS_INVALID_RANKS"] = {
        enUS = "Talent data unavailable",
        deDE = "Talentdaten nicht verfügbar",
    },
    ["TALENT_BUILD_FROM"] = {
        enUS = "Talent build from ",
        deDE = "Talentbuild von ",
    },
    ["UNSAVED_TALENT_BUILD"] = {
        enUS = "Unsaved talent build",
        deDE = "Ungespeicherter Talentbuild",
    },
    ["CHARACTER"] = {
        enUS = "Character",
        deDE = "Charakter",
    },
    ["ENTER_THE_CHARACTER_S_FIRST_AND_LAST_NAME"] = {
        enUS = "Enter full character name",
        deDE = "Vollständigen Namen eingeben",
    },
    ["THE_TALENT_BUILD_LINK_IS_TOO_LONG_TO_WHISPER_USE_A_SHORTER_NAME"] = {
        enUS = "Link too long: shorten name",
        deDE = "Link zu lang: Namen kürzen",
    },
    ["WHISPERING_IS_UNAVAILABLE_IN_THIS_GAME_CLIENT"] = {
        enUS = "Whisper unavailable",
        deDE = "Flüstern nicht verfügbar",
    },
    ["TALENT_BUILD_LINK_SENT"] = {
        enUS = "Build link sent",
        deDE = "Buildlink gesendet",
    },
    ["THE_TALENT_BUILD_LINK_COULD_NOT_BE_SENT"] = {
        enUS = "Could not send build link",
        deDE = "Buildlink nicht gesendet",
    },
    ["INVALID_TALENT_BUILD"] = {
        enUS = "Invalid talent build",
        deDE = "Ungültiger Talentbuild",
    },
    ["INVALID_TALENT_BUILD_LINK"] = {
        enUS = "Invalid talent build",
        deDE = "Ungültiger Talentbuild",
    },
    ["IMPORT_YOUR_CURRENT_TALENTS_AFTER_COMBAT"] = {
        enUS = "Available after combat",
        deDE = "Nach dem Kampf verfügbar",
    },
    ["YOUR_TALENT_DATA_IS_NOT_AVAILABLE_YET_APPLY_OR_DISCARD_PENDING_TALENT_CHANGES_FIRST"] = {
        enUS = "Apply / undo changes first",
        deDE = "Änderungen anwenden / verwerfen",
    },
    ["CREATE_THE_TALENT_BUILD_AFTER_COMBAT"] = {
        enUS = "Available after combat",
        deDE = "Nach dem Kampf verfügbar",
    },
    ["THIS_CLASS_S_TALENT_TREE_IS_UNAVAILABLE"] = {
        enUS = "Talent tree unavailable",
        deDE = "Talentbaum nicht verfügbar",
    },
    ["THIS_CLASS_S_TALENT_DATA_IS_NOT_AVAILABLE_YET"] = {
        enUS = "Talent data unavailable",
        deDE = "Talentdaten nicht verfügbar",
    },
    ["EDIT_THE_TALENT_BUILD_AFTER_COMBAT"] = {
        enUS = "Available after combat",
        deDE = "Nach dem Kampf verfügbar",
    },
    ["PREPARE_THE_TALENT_BUILD_AFTER_COMBAT"] = {
        enUS = "Available after combat",
        deDE = "Nach dem Kampf verfügbar",
    },
    ["YOU_CAN_ONLY_LEARN_TALENTS_FOR_YOUR_OWN_CLASS"] = {
        enUS = "Only your own class",
        deDE = "Nur die eigene Klasse",
    },
    ["YOUR_ACTIVE_TALENT_CONFIGURATION_IS_UNAVAILABLE"] = {
        enUS = "Current talents unavailable",
        deDE = "Aktuelle Talente fehlen",
    },
    ["APPLY_OR_UNDO_PENDING_TALENT_CHANGES_IN_THE_GAME_FIRST"] = {
        enUS = "Apply / undo changes first",
        deDE = "Änderungen anwenden / verwerfen",
    },
    ["THE_SAVED_TALENT_BUILD_NO_LONGER_MATCHES_THIS_TALENT_TREE"] = {
        enUS = "Build no longer matches",
        deDE = "Build passt nicht mehr",
    },
    ["THE_GAME_REJECTED_THE_TALENT_RESET_YOU_MAY_NEED_TO_RESET_YOUR_TALENTS_AT_A_TRAINER"] = {
        enUS = "The game rejected the talent reset. You may need to reset your talents at a trainer.",
        deDE = "Das Spiel hat das Zurücksetzen der Talente abgelehnt. Möglicherweise musst du sie bei einem Lehrer zurücksetzen lassen.",
    },
    ["THIS_TALENT_BUILD_COULD_NOT_BE_LEARNED"] = {
        enUS = "This talent build could not be applied.",
        deDE = "Dieser Talentbuild konnte nicht übernommen werden.",
    },
    ["THE_PREPARED_TALENTS_IN_THE_GAME_DO_NOT_MATCH_THIS_TALENT_BUILD"] = {
        enUS = "The prepared talents in the game do not match this talent build.",
        deDE = "Die vorbereiteten Talente im Spiel stimmen nicht mit dem Talentbuild überein.",
    },
    ["THE_GAME_REJECTED_THE_TALENT_BUILD"] = {
        enUS = "Game rejected build",
        deDE = "Spiel lehnt den Build ab",
    },
    ["TALENTS_PREPARED_REVIEW_THEM_AND_CONFIRM_WITH_APPLY_IN_THE_GAME"] = {
        enUS = "Talents staged: confirm with \"Apply Changes\"!",
        deDE = "Talente übernommen: Mit \"Änderungen anwenden\" bestätigen!",
    },
    ["TALENT_TREE"] = {
        enUS = "Talent tree ",
        deDE = "Talentbaum ",
    },
    ["RESET_TALENT_TREES_AFTER_COMBAT"] = {
        enUS = "Available after combat",
        deDE = "Nach dem Kampf verfügbar",
    },
    ["THIS_TALENT_TREE_S_DATA_IS_UNAVAILABLE"] = {
        enUS = "Talent data unavailable",
        deDE = "Talentdaten nicht verfügbar",
    },
    ["TALENT_PLANNER"] = {
        enUS = "Talent planner",
        deDE = "Talentplaner",
    },
    ["OPEN_THE_TALENT_PLANNER_AFTER_COMBAT"] = {
        enUS = "Available after combat",
        deDE = "Nach dem Kampf verfügbar",
    },
    ["A_SELECTED_TALENT_FROM_THE_ONLINE_CALCULATOR_NO_LONGER_EXISTS_IN_THE_GAME_UPDATE_THE"] = {
        enUS = "Talent outdated in calculator",
        deDE = "Talent im Planer veraltet",
    },
    ["A_TALENT_S_MAXIMUM_RANK_IN_THE_ONLINE_CALCULATOR_DIFFERS_FROM_THE_GAME"] = {
        enUS = "Calculator rank mismatch",
        deDE = "Planer-Talentrang abweichend",
    },
    ["INVALID_TALENT_ALLOCATION_FROM_THE_ONLINE_CALCULATOR"] = {
        enUS = "Invalid talent build",
        deDE = "Ungültiger Talentbuild",
    },
    ["INVALID_OR_OUTDATED_TALENT_ALLOCATION_FROM_THE_ONLINE_CALCULATOR"] = {
        enUS = "Invalid talent build",
        deDE = "Ungültiger Talentbuild",
    },
    ["USE_A_WOW_FOREVER_TALENT_CALCULATOR_LINK_FROM_TALENTS_FOREVER_WOWHEAD_OR_WARCRAFT_TAV"] = {
        enUS = "Use a Forever planner link",
        deDE = "Forever-Planer-Link verwenden",
    },
    ["THIS_TALENT_CALCULATOR_LINK_CONTAINS_NO_USABLE_TALENT_BUILD"] = {
        enUS = "Link contains no build",
        deDE = "Link enthält keinen Build",
    },
    ["IMPORT_TALENT_BUILDS_AFTER_COMBAT"] = {
        enUS = "Available after combat",
        deDE = "Nach dem Kampf verfügbar",
    },
    ["TALENT_DATA_IS_UNAVAILABLE_TRY_AGAIN"] = {
        enUS = "Talent data unavailable",
        deDE = "Talentdaten nicht verfügbar",
    },
    ["THIS_VERSION_OF_THE_ONLINE_CALCULATOR_IS_UNSUPPORTED"] = {
        enUS = "This version of the online calculator is unsupported.",
        deDE = "Diese Version des Online-Talentplaners wird nicht unterstützt.",
    },
    ["OPEN_THIS_OLD_WOWHEAD_LINK_ON_THE_WEBSITE_AND_COPY_THE_UPDATED_WOW_FOREVER_LINK"] = {
        enUS = "Open this old Wowhead link on the website and copy the updated WoW Forever link.",
        deDE = "Öffne diesen alten Wowhead-Link auf der Webseite und kopiere den aktualisierten WoW-Forever-Link.",
    },
    ["UNKNOWN_TALENT_POSITION_IN_THE_WARCRAFT_TAVERN_CALCULATOR"] = {
        enUS = "Unknown talent position in the Warcraft Tavern calculator.",
        deDE = "Unbekannte Talentposition im Warcraft-Tavern-Talentplaner.",
    },
    ["INVALID_TALENT_CODE_FROM_WARCRAFT_TAVERN"] = {
        enUS = "Invalid talent build",
        deDE = "Ungültiger Talentbuild",
    },
    ["PLANNING_SUPPORTS_LEVELS_10_60_LEGACY_BONUSES_ARE_NOT_PART_OF_THIS_EDITOR"] = {
        enUS = "Planning supports levels 10–60. Legacy bonuses are not part of this editor.",
        deDE = "Die Planung unterstützt die Stufen 10–60. Vermächtnisboni sind nicht Teil dieses Editors.",
    },
    ["THIS_TALENT_ALLOCATION_USES_MORE_POINTS_THAN_ARE_AVAILABLE_AT_THE_SPECIFIED_LEVEL"] = {
        enUS = "This talent allocation uses more points than are available at the specified level.",
        deDE = "Diese Talentverteilung verwendet mehr Punkte, als auf der angegebenen Stufe verfügbar sind.",
    },
    ["TALENTS_IMPORTED_LEGACY_BONUSES_AND_LEVELING_ORDER_ARE_NOT_IMPORTED"] = {
        enUS = "Talents imported",
        deDE = "Talente importiert",
    },
    ["THIS_TALENT_BUILD_DOES_NOT_MEET_WARCRAFT_TAVERN_S_TALENT_PREREQUISITES"] = {
        enUS = "Calculator requirements unmet",
        deDE = "Planer-Voraussetzungen fehlen",
    },
    ["A_SELECTED_TALENT_IS_MISSING_FROM_THIS_ONLINE_CALCULATOR_S_CURRENT_DATA"] = {
        enUS = "Talent missing in calculator",
        deDE = "Talent fehlt im Planer",
    },
    ["RELOAD_CURRENT_TALENTS"] = {
        enUS = "Reload current talents",
        deDE = "Aktuelle Talente laden",
    },
}

local locale = GetLocale() == "deDE" and "deDE" or "enUS"
addon.localization = terms
addon.L = setmetatable({}, {
    __index = function(_, key)
        local term = terms[key]
        return term and (term[locale] or term.enUS) or key
    end,
})
