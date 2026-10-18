local _, localization = ...
local L = localization.L
local addonName, T = ...

-- Keep talent keys and micromenu routed to yTalents in combat.
function T:InstallTalentToggleHook()
    if InCombatLockdown() then return end
    self.talentMicroOverlays = self.talentMicroOverlays or {}
    for _, name in ipairs({ "TalentMicroButton", "PlayerSpellsMicroButton" }) do
        local native = _G[name]
        if native then
            local overlay = self.talentMicroOverlays[native]
            if not overlay then
                -- Own the click without replacing Blizzard's handler.
                -- Parenting follows micromenu visibility.
                overlay = CreateFrame("Button", nil, native, "SecureHandlerStateTemplate")
                overlay:SetAllPoints(native)
                overlay:SetFrameLevel(native:GetFrameLevel() + 5)
                overlay:RegisterForClicks("AnyUp")
                overlay:SetScript("OnClick", function()
                    if self.db and self.db.enabled then
                        self:ToggleTalentWindow()
                    end
                end)
                overlay:SetScript("OnEnter", function(owner)
                    native:LockHighlight()
                    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
                    GameTooltip:SetText(native.tooltipText or TALENTS)
                    GameTooltip:Show()
                end)
                overlay:SetScript("OnLeave", function() native:UnlockHighlight(); GameTooltip:Hide() end)
                overlay:SetScript("OnHide", function() native:UnlockHighlight() end)
                self.talentMicroOverlays[native] = overlay
            end
            if self.db and self.db.enabled then
                -- Keep the cover available during combat too.
                RegisterStateDriver(overlay, "visibility", "show")
            else
                UnregisterStateDriver(overlay, "visibility")
                overlay:Hide()
            end
        end
    end
end

function T:UpdateTalentKeyBindings()
    if InCombatLockdown() then return end
    if not self.talentBindingOwner then
        local button = CreateFrame("Button", "yTalentsTalentKey", UIParent)
        button:RegisterForClicks("AnyDown", "AnyUp")
        button:SetScript("OnClick", function(_, _, down)
            -- CLICK bindings follow ActionButtonUseKeyDown. Listening only for
            -- release loses the key on clients configured to execute on press.
            if down == GetCVarBool("ActionButtonUseKeyDown") then
                self:ToggleTalentWindow()
            end
        end)
        self.talentKeyButton = button
        self.talentBindingOwner = CreateFrame("Frame", "yTalentsTalentBindingOwner", UIParent)
    end
    local owner = self.talentBindingOwner
    ClearOverrideBindings(owner)
    local keys = {GetBindingKey("TOGGLETALENTS")}
    for _, key in ipairs(keys) do
        if self.db and self.db.enabled then
            SetOverrideBindingClick(owner, true, key, "yTalentsTalentKey", "LeftButton")
        end
    end
    self:InstallTalentToggleHook()
end

function T:SetEnabled(value)
    self.db.enabled = value == true
    if not self.db.enabled and self.plannerWindow then self.plannerWindow:Hide() end
    self:UpdateTalentKeyBindings()
    if self.db.enabled then self:PrepareReplacement() end
    if self.settingsPanel then self.settingsPanel.RefreshForm() end
end

local function AttachCommand()
    if not yTools or not yTools.commands then return end
    local owner = { id = "yTalents", IsEnabled = function() return true end, GetTitle = function() return T.title end }
    local command = { module = owner, callback = function() T:Open() end, help = L.OPEN_YTALENTS }
    if not yTools.commands.talents then yTools.commands.talents = command end
end

SLASH_YTALENTS1 = "/ytalents"
SlashCmdList.YTALENTS = function() T:Open() end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_LOGIN")
loader:RegisterEvent("PLAYER_LEVEL_UP")
loader:RegisterEvent("UPDATE_BINDINGS")
loader:RegisterEvent("PLAYER_ENTERING_WORLD")
loader:RegisterEvent("INSPECT_READY")
loader:RegisterEvent("PLAYER_TALENT_UPDATE")
loader:RegisterEvent("TRAIT_CONFIG_UPDATED")
loader:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
loader:RegisterEvent("PLAYER_REGEN_DISABLED")
loader:RegisterEvent("PLAYER_REGEN_ENABLED")
loader:RegisterEvent("CONFIG_COMMIT_FAILED")
loader:SetScript("OnEvent", function(_, event, name, action)
    if event == "ADDON_LOADED" then
        if name == addonName then
            T:InitializeDB()
            T.lastTalentTab = nil
            T.characterDB.lastTalentTab = nil
            AttachCommand()
        end
        if name == "yTools" then AttachCommand() end
        T:InstallTalentEntryRoutes()
        if name == "Blizzard_MicroMenu" then
            C_Timer.After(0, function() T:UpdateTalentKeyBindings() end)
        end
        if name == "Blizzard_PlayerSpells" then
            -- Wait until the native addon has completed its initialization.
            C_Timer.After(0, function() if T.db and T.db.enabled then T:PrepareReplacement(); T:QueueCurrentTalentsSync() end end)
        end
    elseif event == "PLAYER_LOGIN" then
        T:InstallChatLinkHandler()
        T:UpdateTalentKeyBindings()
        T:RegisterSettings()
        AttachCommand()
        C_Timer.After(0, function() if T.db and T.db.enabled then T:PrepareReplacement(); T:QueueCurrentTalentsSync() end end)
    elseif event == "PLAYER_LEVEL_UP" or event == "UPDATE_BINDINGS" or event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(0, function() T:UpdateTalentKeyBindings(); if T.db and T.db.enabled then T:PrepareReplacement() end end)
    elseif event == "CONFIG_COMMIT_FAILED" then
        T.liveCommitPending = nil
        if T.db and T.db.enabled then
            T:Message(L.THE_GAME_REJECTED_THE_TALENT_BUILD, false, true)
            T:CacheLiveSpecs(); if T.specGroupView then T:ShowLiveTalents() end
        end
    elseif event == "INSPECT_READY" then
        T:QueueInspectedPlan()
    elseif event == "PLAYER_TALENT_UPDATE" or event == "PLAYER_SPECIALIZATION_CHANGED"
        or (event == "TRAIT_CONFIG_UPDATED" and name == C_ClassTalents.GetActiveConfigID()) then
        if T.db and T.db.enabled then
            T:UpdateTalentKeyBindings()
            local config = C_ClassTalents.GetActiveConfigID()
            if config and not C_Traits.ConfigHasStagedChanges(config) then T.liveCommitPending = nil end
            T:CacheLiveSpecs()
            if T.specGroupView and T.plannerWindow and T.plannerWindow:IsShown() then T:ShowSpecGroup(T.specGroupView) end
            T:QueueCurrentTalentsSync()
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        if T.specActionBar then T.specActionBar.apply:SetEnabled(false) end
    elseif event == "PLAYER_REGEN_ENABLED" then
        T:UpdateTalentKeyBindings()
        if T.db and T.db.enabled then
            T:CacheLiveSpecs()
            if T.plannerWindow and T.plannerWindow:IsShown() then
                if T.specGroupView then T:ShowSpecGroup(T.specGroupView)
                else T:RefreshPanel(); T:RefreshSpecTabs() end
            end
            T:QueueCurrentTalentsSync()
        end
    end
end)

-- Blizzard addon-compartment entry.
function yTalents_OnAddonCompartmentClick()
    T:Open()
end
