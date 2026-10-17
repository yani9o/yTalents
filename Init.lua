local _, localization = ...
local L = localization.L
local addonName, T = ...

-- Normal talent entry points retain live talents once they are unlocked.
-- Explicit planner buttons/commands still call Open directly.
function T:InstallTalentToggleHook()
    if self.talentToggleHooked or not PlayerSpellsUtil or not PlayerSpellsUtil.TogglePlayerSpellsFrame then return end
    -- Capture the native function before hooksecurefunc installs its wrapper.
    -- Addon entry points must call the original through the secure boundary.
    self.nativeOpenTalents = PlayerSpellsUtil.OpenToClassTalentsTab
    self.talentToggleHooked = true
    local function DefaultTalents(isToggle, inspectUnit)
        if self.openingNativeWindow or not self.db or not self.db.enabled or inspectUnit then return end
        if InCombatLockdown() then
            local parent = PlayerSpellsFrame
            if parent and parent:IsShown() and parent:IsFrameTabActive(PlayerSpellsUtil.FrameTabs.ClassTalents) then
                self:Message(L.TALENT_PLANNING_IS_UNAVAILABLE_DURING_COMBAT, false, true)
            end
            return
        end
        local generation = self.plannerGeneration
        C_Timer.After(0, function()
            -- A newer explicit planner request supersedes this default-tab request.
            if generation ~= self.plannerGeneration or not self.db.enabled or InCombatLockdown() then return end
            local parent = PlayerSpellsFrame
            if self:HasNativeTalents() then
                if parent and parent:IsShown()
                    and parent:IsFrameTabActive(PlayerSpellsUtil.FrameTabs.ClassTalents)
                    and self.plannerTabActive then self:ShowLiveTalents() end
            elseif isToggle and self.lowLevelPlannerWindow and self.lowLevelPlannerWindow:IsShown() then
                self.lowLevelPlannerWindow:Hide()
                if parent and parent:IsShown() then securecallfunction(HideUIPanel, parent) end
            else
                self:Open()
            end
        end)
    end
    hooksecurefunc(PlayerSpellsUtil, "TogglePlayerSpellsFrame", function(suggestedTab, inspectUnit)
        local parent = PlayerSpellsFrame
        local talentsTab = PlayerSpellsUtil.FrameTabs.ClassTalents
        if suggestedTab ~= talentsTab and (suggestedTab ~= nil or not parent or not parent:IsFrameTabActive(talentsTab)) then return end
        DefaultTalents(true, inspectUnit)
    end)
    if PlayerSpellsUtil.OpenToClassTalentsTab then
        hooksecurefunc(PlayerSpellsUtil, "OpenToClassTalentsTab", function(inspectUnit)
            DefaultTalents(false, inspectUnit)
        end)
    end
end

-- Keep Blizzard's talent binding for unlocked characters. Only characters
-- without talent points need the addon-owned planner entry point.
-- Reuse the player's assignments without changing their saved bindings.
function T:UpdateTalentKeyBindings()
    if InCombatLockdown() then return end
    self:InstallTalentToggleHook()
    if not self.talentBindingOwner then
        local button = CreateFrame("Button", "yTalentsLowLevelTalentKey", UIParent)
        button:RegisterForClicks("AnyUp")
        button:SetScript("OnClick", function()
            if InCombatLockdown() then T:Message(L.TALENT_PLANNING_IS_UNAVAILABLE_DURING_COMBAT, false, true); return end
            if T.lowLevelPlannerWindow and T.lowLevelPlannerWindow:IsShown() then
                T.lowLevelPlannerWindow:Hide()
                return
            end
            local parent = PlayerSpellsFrame
            if parent and parent:IsShown() and PlayerSpellsUtil and parent.IsFrameTabActive
                and parent:IsFrameTabActive(PlayerSpellsUtil.FrameTabs.ClassTalents) then
                securecallfunction(HideUIPanel, parent)
            else
                T:OpenDefaultTalents()
            end
        end)
        self.talentBindingOwner = button
    end
    ClearOverrideBindings(self.talentBindingOwner)
    if not self.db or not self.db.enabled or self:HasNativeTalents() then return end
    for _, key in ipairs({ GetBindingKey("TOGGLETALENTS") }) do
        SetOverrideBindingClick(self.talentBindingOwner, false, key, "yTalentsLowLevelTalentKey", "LeftButton")
    end
end

function T:SetEnabled(value)
    self.db.enabled = value == true
    self:UpdateTalentKeyBindings()
    if not self.db.enabled then
        self:ShowLiveTalents()
        if self.panel then self.panel:Hide() end
    end
    if self.plannerTab and not InCombatLockdown() then self.plannerTab:SetShown(self.db.enabled and self:GetNativeFrame():IsVisible()) end
    if self.settingsPanel then self.settingsPanel.RefreshForm() end
end

local function AttachCommand()
    if not yTools or not yTools.commands then return end
    local owner = { id = "yTalents", IsEnabled = function() return true end, GetTitle = function() return T.title end }
    local command = { module = owner, callback = function() T:Open() end, help = L.OPEN_YTALENTS }
    if not yTools.commands.talents then yTools.commands.talents = command end
    if not yTools.commands.talented then
        yTools.commands.talented = { module = owner, callback = command.callback, help = command.help, hidden = true }
    end
end

SLASH_YTALENTS1 = "/ytalents"
SLASH_YTALENTS2 = "/talented"
SLASH_YTALENTS3 = "/talentedforever"
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
loader:SetScript("OnEvent", function(_, event, name, action)
    if event == "ADDON_LOADED" then
        if name == addonName then T:InitializeDB(); AttachCommand() end
        if name == "yTools" then AttachCommand() end
        if name == "Blizzard_PlayerSpells" then
            -- Wait until the native addon has completed its initialization.
            C_Timer.After(0, function() T:InstallNativeControls(); T:QueueCurrentTalentsSync() end)
        end
    elseif event == "PLAYER_LOGIN" then
        T:InstallChatLinkHandler()
        T:UpdateTalentKeyBindings()
        T:RegisterSettings()
        AttachCommand()
        T:InstallNativeControls()
        T:QueueCurrentTalentsSync()
    elseif event == "PLAYER_LEVEL_UP" or event == "UPDATE_BINDINGS" or event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(0, function() T:UpdateTalentKeyBindings() end)
    elseif event == "INSPECT_READY" then
        T:QueueInspectedPlan()
    elseif event == "PLAYER_TALENT_UPDATE" or event == "PLAYER_SPECIALIZATION_CHANGED"
        or (event == "TRAIT_CONFIG_UPDATED" and name == C_ClassTalents.GetActiveConfigID()) then
        if T.db then T:UpdateTalentKeyBindings(); T:QueueCurrentTalentsSync() end
    elseif event == "PLAYER_REGEN_DISABLED" then
        if T.panel and T.panel:IsVisible() then
            T:RefreshActionButtons()
            T:RefreshPlannerDecorations()
            T:Message(L.TALENT_PLANNING_IS_UNAVAILABLE_DURING_COMBAT, false, true)
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        T:UpdateTalentKeyBindings()
        T:InstallNativeControls()
        if T.plannerTab then T.plannerTab:SetShown(T.db and T.db.enabled and T:GetNativeFrame():IsVisible()) end
        if T.leavePlanPending then T:ShowLiveTalents() end
        T:RefreshPlannerTabVisuals()
        if T.currentTalentsPending then T:QueueCurrentTalentsSync() end
        if T.panel and T.panel:IsVisible() then
            if T.planning then T:RenderDraft(false) end
            T:RefreshPanel()
        end
    end
end)

-- Blizzard addon-compartment entry.
function yTalents_OnAddonCompartmentClick()
    T:Open()
end
