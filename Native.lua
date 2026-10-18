local _, localization = ...
local L = localization.L
local _, T = ...

function T:GetNativeFrame()
    return PlayerSpellsFrame and PlayerSpellsFrame.TalentsFrame
end

function T:EnsureNative()
    if not self:GetNativeFrame() then
        if InCombatLockdown() then return false, L.TALENT_PLANNING_IS_UNAVAILABLE_DURING_COMBAT end
        local ok, loaded
        if PlayerSpellsFrame_LoadUI then
            ok, loaded = pcall(securecallfunction, PlayerSpellsFrame_LoadUI)
        else
            ok, loaded = pcall(securecallfunction, C_AddOns.LoadAddOn, "Blizzard_PlayerSpells")
        end
        if not ok or not loaded then return false, L.THE_GAME_S_TALENT_WINDOW_COULD_NOT_BE_LOADED end
    end
    local frame = self:GetNativeFrame()
    if not frame or not frame.ReadLoadoutHeader or not ExportUtil or not C_ClassTalents.GetTraitTreeForSpec then
        return false, L.THIS_ADDON_REQUIRES_WOW_FOREVER_S_TALENT_WINDOW
    end
    self:InstallNativeControls()
    return true
end

function T:GetAvailableTalentPoints()
    if not C_Traits or not C_Traits.GetConfigInfo or not C_Traits.GetTreeCurrencyInfo then return nil end
    local configID = C_ClassTalents.GetActiveConfigID()
    if not configID then return 0 end
    local config = C_Traits.GetConfigInfo(configID)
    local treeID = config and config.treeIDs and config.treeIDs[1]
    if not treeID then return nil end
    local currencies = C_Traits.GetTreeCurrencyInfo(configID, treeID, false)
    if not currencies or #currencies == 0 then return nil end
    local available, spent, hasSpent = 0, 0, false
    for _, currency in ipairs(currencies) do
        available = available + (currency.quantity or 0)
        if currency.spent ~= nil then
            spent = spent + currency.spent
            hasSpent = true
        end
    end
    if not hasSpent then
        for _, id in ipairs(C_Traits.GetTreeNodes(treeID) or {}) do
            local node = C_Traits.GetNodeInfo(configID, id)
            if node then spent = spent + (node.ranksPurchased or node.activeRank or 0) end
        end
    end
    return available + spent
end

function T:HasNativeTalents()
    local budget = self:GetAvailableTalentPoints()
    if budget ~= nil then return budget > 0 end
    if PlayerUtil and PlayerUtil.CanUseClassTalents then
        return PlayerUtil.CanUseClassTalents() == true
    end
    return UnitLevel("player") >= 10
end

-- Below the native unlock level, OnShow selects the spellbook again. Use
-- Blizzard's decorative frame template on an addon-owned host in that case.
function T:GetLowLevelPlannerWindow()
    if self.lowLevelPlannerWindow then return self.lowLevelPlannerWindow end
    local host = CreateFrame("Frame", "yTalentsPlannerWindow", UIParent, "PortraitFrameTemplate")
    host:Hide()
    host:SetSize(1218, 708)
    host:SetPoint("TOP", UIParent, "TOP", 0, -41)
    host:SetFrameStrata("DIALOG")
    -- Match PlayerSpellsFrame: its portrait/rim use absolute decorative levels.
    if host.SetFrameLevelsFromBaseLevel then host:SetFrameLevelsFromBaseLevel(5000) end
    host:EnableMouse(true)
    host:SetTitle(TALENTS)
    -- PortraitFrameTemplate supplies a gray body; use the talent window's
    -- full-height artwork behind the independent tab and bottom controls.
    host.plannerBacking = host:CreateTexture(nil, "BACKGROUND", nil, 6)
    host.plannerBacking:SetPoint("TOPLEFT", host, "TOPLEFT", 3, -24)
    host.plannerBacking:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -3, 4)
    host.plannerBacking:SetColorTexture(0.095, 0.08, 0.067, 1)
    host.plannerBackground = host:CreateTexture(nil, "BACKGROUND", nil, 7)
    host.plannerBackground:SetAtlas("Talents-Background-c60", false)
    host.plannerBackground:SetHorizTile(true)
    host.plannerBackground:SetAllPoints(host.plannerBacking)
    host:SetScript("OnHide", function()
        self.plannerTabActive = false
        self:LeavePlan()
        if self.plannerTab then self.plannerTab:Hide() end
        if self.liveTabProxy then self.liveTabProxy:Hide() end
    end)
    UISpecialFrames = UISpecialFrames or {}
    table.insert(UISpecialFrames, "yTalentsPlannerWindow")
    self.lowLevelPlannerWindow = host
    return host
end

function T:ConfigurePlannerLayout()
    local native, frame = PlayerSpellsFrame, self:GetNativeFrame()
    local separate = self.lowLevelPlannerWindow and self.lowLevelPlannerWindow:IsShown()
    local host = separate and self.lowLevelPlannerWindow or native
    local canvas = self.plannerCanvas
    canvas:SetParent(host)
    canvas:ClearAllPoints()
    if separate then
        canvas:SetPoint("TOPLEFT", host, "TOPLEFT", 3, -70)
        canvas:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -3, 36)
    else
        canvas:SetAllPoints(frame.BackgroundBorder)
    end
    -- Follow the native node container exactly when it is laid out. The
    -- separate low-level window needs its own fixed origin instead.
    canvas.backing:ClearAllPoints()
    canvas.backing:SetPoint("BOTTOMLEFT", host, "BOTTOMLEFT", 3, 4)
    canvas.backing:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -3, 4)
    canvas.nodeLayer:ClearAllPoints()
    if not separate and frame.ButtonsParent then
        canvas.nodeLayer:SetAllPoints(frame.ButtonsParent)
        canvas.nodeLayer:SetScale(frame.ButtonsParent:GetScale() or 1)
    else
        canvas.nodeLayer:SetScale(1)
        canvas.nodeLayer:SetPoint("TOPLEFT", canvas, "TOPLEFT", 2, 46)
        canvas.nodeLayer:SetPoint("BOTTOMRIGHT", canvas, "BOTTOMRIGHT", -2, -4)
    end
    self.panel:ClearAllPoints()
    self.panel:SetPoint("LEFT", canvas, "TOPLEFT", 16, -29)
    self.panel.footer:ClearAllPoints()
    self.panel.footer:SetPoint("TOPLEFT", canvas, "BOTTOMLEFT", 16, 0)
    self.panel.footer:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -20, 8)
    -- The standalone portrait frame has its own gray backdrop. Its footer
    -- artwork must cover the full inner width, outside the inset control row.
    self.panel.footerBackground:SetParent(separate and host or self.panel.footer)
    self.panel.footerBackground:SetHeight(separate and 32 or 701)
    self.panel.footerBackground:ClearAllPoints()
    self.panel.footerBackground:SetPoint("BOTTOMLEFT", host, "BOTTOMLEFT", 3, 4)
    self.panel.footerBackground:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -3, 4)
    self.plannerTab:SetParent(host)
    self.plannerTab:ClearAllPoints()
    if separate then
        self.plannerTab:SetPoint("BOTTOMLEFT", canvas, "TOPLEFT", 70, 0)
        self.liveTabProxy:Hide()
    else
        self.plannerTab:SetPoint("TOPLEFT", frame.TabSystem, "TOPRIGHT", frame.TabSystem.spacing or 1, 0)
    end
    self.classPicker:SetParent(host)
    self.classPicker:ClearAllPoints()
    local portrait = host.GetPortrait and host:GetPortrait()
    if portrait then self.classPicker:SetAllPoints(portrait)
    else self.classPicker:SetPoint("TOPLEFT", host, "TOPLEFT", 9, -3); self.classPicker:SetSize(64, 64) end
    -- Follow the portrait container, not the host's much lower frame level.
    -- Keep the class art beneath NineSlice's round rim, exactly like Blizzard.
    self.classPicker:SetFrameStrata(host:GetFrameStrata())
    local portraitLevel = host.PortraitContainer and host.PortraitContainer:GetFrameLevel()
        or host:GetFrameLevel() + 450
    self.classPicker:SetFrameLevel(portraitLevel + (host.PortraitContainer and 1 or 0))
    self.classPicker.icon:ClearAllPoints()
    self.classPicker.icon:SetAllPoints()
    self.classArrow:SetParent(host)
    self.classArrow:ClearAllPoints()
    if host.TitleContainer then self.classArrow:SetPoint("CENTER", host.TitleContainer, "LEFT", 7.5, 0)
    else self.classArrow:SetPoint("TOPLEFT", host, "TOPLEFT", 53, 1) end
    self.classArrow:SetFrameLevel(host.TitleContainer and host.TitleContainer:GetFrameLevel() + 1
        or self.classPicker:GetFrameLevel() + 60)
    self.classReload:SetParent(self.panel)
    self.classReload:ClearAllPoints()
    self.classReload:SetPoint("LEFT", self.panel, "LEFT", 0, 3)
    self.classReload:SetFrameStrata(self.panel:GetFrameStrata())
    self.classReload:SetFrameLevel(self.panel:GetFrameLevel() + 5)
end

function T:OpenNative()
    if InCombatLockdown() then return false, L.TALENT_PLANNING_IS_UNAVAILABLE_DURING_COMBAT end
    local ok, err = self:EnsureNative()
    if not ok then return false, err end
    if InCombatLockdown() then return false, L.TALENT_PLANNING_IS_UNAVAILABLE_DURING_COMBAT end
    local parent = PlayerSpellsFrame
    if not self:HasNativeTalents() then
        if parent:IsShown() then securecallfunction(HideUIPanel, parent) end
        self:GetLowLevelPlannerWindow():Show()
        return true
    end
    if self.lowLevelPlannerWindow then self.lowLevelPlannerWindow:Hide() end
    -- Native OnShow/OnHide update actionbar grids. Preserve the native callee
    -- context instead of carrying addon execution into those shared counters.
    local openTalents = self.nativeOpenTalents or (PlayerSpellsUtil and PlayerSpellsUtil.OpenToClassTalentsTab)
    if openTalents then
        -- The native helper also fires our default-entry post-hook. This call
        -- belongs to the explicit caller; it must not queue a tab switch.
        local previous = self.openingNativeWindow
        self.openingNativeWindow = true
        local opened = pcall(securecallfunction, openTalents)
        self.openingNativeWindow = previous
        if not opened then return false, L.THE_GAME_S_TALENT_WINDOW_COULD_NOT_BE_LOADED end
    else
        return false, L.THE_GAME_S_TALENT_WINDOW_COULD_NOT_BE_LOADED
    end
    return true
end

-- These names remain for the shared editor/event code; all affected objects
-- are now owned by yTalents, never native talent/action buttons.
function T:HideOverlays()
    for _, button in pairs(self.plannerCanvas and self.plannerCanvas.buttons or {}) do
        if button.plannerHovered then self:LeavePlannerTooltip(button) end
    end
    if self.plannerCanvas then self.plannerCanvas:Hide() end
    if self.plannerTooltip then self.plannerTooltip:Hide() end
    self.plannerTooltipOwner = nil
end

function T:LeavePlan()
    self.leavePlanPending = nil
    self.planning = false
    self.ownsPreview = false
    self:HideOverlays()
    if self.panel then self.panel:Hide() end
end

function T:RenderDraft(readNodes)
    if InCombatLockdown() then return false, L.TALENT_PLANNING_IS_UNAVAILABLE_DURING_COMBAT end
    local draft = self.draft
    if not draft then return false, L.OPEN_A_TALENT_BUILD_FIRST end
    if readNodes or not draft.nodes then
        local readOK = pcall(self.ReadDraftNodes, self)
        if not readOK then return false, L.TALENT_DATA_IS_UNAVAILABLE_OR_THE_TALENT_BUILD_CONTAINS_INVALID_RANKS end
    end
    if draft.baselineCode == draft.code and not draft.baselineAllocation then
        draft.baselineAllocation = self:EncodeDraft(draft)
    end
    self:UpdateDraftDirty()
    self.planning = true
    self.ownsPreview = false
    self:RefreshOverlays()
    self:RefreshPanel()
    return true
end

local function CleanCaption(text)
    return tostring(text or ""):gsub("[|%[%]%{%}%c]", "")
end

function T:CharacterFullName(unit)
    local rawName, surname = (UnitNameUnmodified or UnitName)(unit)
    if rawName and surname and surname ~= "" and RegionalUniqueNamesEnabled and RegionalUniqueNamesEnabled() then
        local separator = Constants and Constants.CharacterNameSeparatorConsts and Constants.CharacterNameSeparatorConsts.CHARACTERNAME_SURNAME_SEPARATOR or " "
        local ending = separator .. surname
        if rawName:sub(-#ending) ~= ending then rawName = rawName .. ending end
        return rawName
    end
    if GetUnitName then
        local ok, fullName = pcall(GetUnitName, unit, false)
        if ok and fullName and fullName ~= "" then return fullName end
    end
    if UnitFullName then
        local fullName = UnitFullName(unit)
        if fullName and fullName:find(" ", 1, true) then return fullName end
    end
    return rawName
end

function T:GetBuildShareCaption()
    local name = self:TemplateName(self.selected)
    if self.selected == self.currentBuildKey then
        name = L.TALENT_BUILD_FROM .. (self:CharacterFullName("player") or L.CHARACTER)
    elseif not name then
        name = self.panel and self.panel.name:GetText():match("%S") and self.panel.name:GetText() or L.UNSAVED_TALENT_BUILD
    end
    local counts, trees = {}, self:GetPlanTrees()
    for index = 1, 3 do
        local points = 0
        for _, entry in ipairs(trees[index] or {}) do points = points + (self.draft.ranks[entry.id] or 0) end
        counts[index] = points
    end
    return "yTalents: " .. CleanCaption(self:ClassName(self.draft.spec)) .. " - " .. CleanCaption(name)
        .. " (" .. table.concat(counts, "/") .. ")"
end

function T:GetBuildChatLink()
    if not self.draft then return nil, L.OPEN_A_TALENT_BUILD_FIRST end
    return "[" .. self:GetBuildShareCaption() .. "] {yTalents:" .. self.draft.spec .. ":" .. self.draft.code .. "}"
end

function T:GetBuildShareData()
    local link, err = self:GetBuildChatLink()
    if not link then return nil, err end
    local url = self:GetExportText("tf")
    if not url or url == "" then url = self:GetExportText("wowhead") end
    if not url or url == "" then return nil, L.TALENT_DATA_IS_UNAVAILABLE_TRY_AGAIN end
    return { link = link, fallback = self:GetBuildShareCaption() .. ": " .. url }
end

local sharePrefix = "yTalentsShare1"
local shareRequests, shareSequence = {}, 0
local function ShareRecipientKey(name)
    return name:lower():gsub(" +", " ")
end

function T:SendSharedBuildText(text, recipient)
    if #text > 255 then
        self:Message(L.THE_TALENT_BUILD_LINK_IS_TOO_LONG_TO_WHISPER_USE_A_SHORTER_NAME, false)
        return false
    end
    local send = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage
    if not send then self:Message(L.WHISPERING_IS_UNAVAILABLE_IN_THIS_GAME_CLIENT, false); return false end
    local ok = pcall(send, text, "WHISPER", nil, recipient)
    self:Message(ok and L.TALENT_BUILD_LINK_SENT or L.THE_TALENT_BUILD_LINK_COULD_NOT_BE_SENT, ok)
    return ok
end

function T:SendBuildWhisper(data, recipient)
    recipient = (recipient or ""):match("^%s*(.-)%s*$"):gsub(" +", " ")
    if recipient == "" or recipient:find("[|%c]") then
        self:Message(L.ENTER_THE_CHARACTER_S_FIRST_AND_LAST_NAME, false)
        return false
    end
    if type(data) ~= "table" then return false end
    if not C_ChatInfo or not C_ChatInfo.SendAddonMessage or not self.shareProtocolReady then
        return self:SendSharedBuildText(data.fallback, recipient)
    end
    shareSequence = shareSequence + 1
    local nonce = tostring(math.floor(GetTime() * 1000)) .. tostring(shareSequence)
    local request = { recipient = recipient, data = data }
    shareRequests[nonce] = request
    local function Finish(hasAddon)
        if shareRequests[nonce] ~= request then return end
        shareRequests[nonce] = nil
        self:SendSharedBuildText(hasAddon and data.link or data.fallback, recipient)
    end
    request.finish = Finish
    local ok = pcall(C_ChatInfo.SendAddonMessage, sharePrefix, "Q:" .. nonce, "WHISPER", recipient)
    if not ok then Finish(false); return true end
    -- Silence is inconclusive (offline, old addon, blocked channel). A normal
    -- web link remains useful in every case and exposes no addon-only code.
    C_Timer.After(3, function() Finish(false) end)
    return true
end

local shareEvents = CreateFrame("Frame")
shareEvents:RegisterEvent("PLAYER_LOGIN")
shareEvents:RegisterEvent("CHAT_MSG_ADDON")
shareEvents:SetScript("OnEvent", function(_, event, prefix, message, channel, sender)
    if event == "PLAYER_LOGIN" then
        if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
            T.shareProtocolReady = C_ChatInfo.RegisterAddonMessagePrefix(sharePrefix)
        end
        return
    end
    if prefix ~= sharePrefix or channel ~= "WHISPER" or type(sender) ~= "string" or type(message) ~= "string" then return end
    local kind, nonce = message:match("^([QA]):(%d+)$")
    if not nonce then return end
    if kind == "Q" then
        if T.db and T.db.enabled and C_ChatInfo and C_ChatInfo.SendAddonMessage then
            pcall(C_ChatInfo.SendAddonMessage, sharePrefix, "A:" .. nonce, "WHISPER", sender)
        end
    else
        local request = shareRequests[nonce]
        if request then
            local key = ShareRecipientKey(sender)
            local expected = ShareRecipientKey(request.recipient)
            local realm = GetNormalizedRealmName and GetNormalizedRealmName()
            if key == expected or (realm and key == expected .. "-" .. realm:lower()) then request.finish(true) end
        end
    end
end)

function T:ShareBuild()
    local data, err = self:GetBuildShareData()
    if not data then self:Message(err, false); return end
    if UnitIsPlayer("target") and UnitIsFriend("player", "target") then
        local name = self:CharacterFullName("target")
        if name and name ~= "" then self:SendBuildWhisper(data, name); return end
    end
    StaticPopup_Show("TALENTED_FOREVER_SHARE", nil, nil, { share = data })
end

function T:LinkifyBuildMessage(message)
    return (message:gsub("(%[yTalents: [^%]%c]+%]) {%s*yTalents:(%d+):([A-Za-z0-9+/=]+)}", function(caption, spec, code)
        if not self:ClassForSpec(tonumber(spec)) or #code > 1800 then return end
        return "|cff71d5ff|Haddon:yTalents:" .. spec .. ":" .. code .. "|h" .. caption .. "|h|r"
    end))
end

function T:OpenExternalBuild(code, name, request)
    local valid, draft = pcall(self.DecodeCode, self, code)
    if not valid or not draft then self:Message(L.INVALID_TALENT_BUILD, false); return end
    self:ConfirmDiscard(function()
        if request and self.inspectionRequest ~= request then return end
        if not self.db.enabled or InCombatLockdown() then return end
        local ok, err = self:ImportCode(code)
        if ok then
            -- Loaded allocations are unsaved, but are only dirty after editing.
            self.dirty = false
            self.ownsPreview = false
            if request then self.inspectionRequest = nil end
            ok, err = self:OpenNative()
            if ok then
                self:EnterPlannerTab()
                ok, err = self:RenderDraft(true)
                if ok then err = L.TALENT_BUILD_LOADED end
            end
        end
        self:Result(ok, err)
        if ok and self.panel then self.panel.name:SetText(name or "") end
    end)
end

function T:OpenBuildLink(link, text)
    if not self.db or not self.db.enabled or type(link) ~= "string" then return end
    if IsModifiedClick and IsModifiedClick() then return end
    local spec, code = link:match("^addon:yTalents:(%d+):([A-Za-z0-9+/=]+)$")
    if not code then return end
    local ok, err = self:EnsureNative()
    if not ok or InCombatLockdown() then
        self:Message(err or L.OPEN_YTALENTS_AFTER_COMBAT, false)
        return
    end
    local decodedOK, draft = pcall(self.DecodeCode, self, code)
    if not decodedOK or not draft or draft.spec ~= tonumber(spec) then
        self:Message(L.INVALID_TALENT_BUILD_LINK, false)
        return
    end
    local name = type(text) == "string" and text:match("%[yTalents: .- %- (.-)%]") or nil
    self.inspectionRequest = nil
    if name then name = name:gsub(" %(%d+/%d+/%d+%)$", "") end
    self:OpenExternalBuild(code, name and CleanCaption(name))
end

function T:QueueInspectedString(code)
    if self.renderingPreview or not code or code == "" or not self.db or not self.db.enabled then return end
    local parent = PlayerSpellsFrame
    local request = { code = code }
    self.inspectionRequest = request
    self.ownsPreview = false
    C_Timer.After(0, function()
        if self.inspectionRequest ~= request or InCombatLockdown() or not self.db.enabled or not parent:IsShown() then return end
        self:OpenExternalBuild(code, nil, request)
    end)
end

function T:QueueInspectedPlan()
    local parent = PlayerSpellsFrame
    if not self.db or not self.db.enabled or not parent or not parent.GetInspectUnit then return end
    local request = self.inspectionRequest
    if not request then
        local unit = parent:GetInspectUnit()
        if not unit then return end
        request = { unit = unit, guid = UnitGUID(unit), name = self:CharacterFullName(unit) }
        self.inspectionRequest = request
    end
    if not request.unit or request.processing or not parent:IsShown() or InCombatLockdown()
        or not C_Traits.GenerateInspectImportString then return end
    C_Timer.After(0, function()
        if self.inspectionRequest ~= request or request.processing or not self.db.enabled or InCombatLockdown()
            or not parent:IsShown() or UnitGUID(request.unit) ~= request.guid then return end
        local ok, code = pcall(C_Traits.GenerateInspectImportString, request.unit)
        if not ok or not code or code == "" then return end -- wait for INSPECT_READY
        request.processing = true
        self:OpenExternalBuild(code, request.name and (L.TALENT_BUILD_FROM .. request.name), request)
    end)
end

function T:InstallChatLinkHandler()
    if self.chatLinkHooked or type(SetItemRef) ~= "function" then return end
    self.chatLinkHooked = true
    hooksecurefunc(_G, "SetItemRef", function(link, text) self:OpenBuildLink(link, text) end)
    if ChatFrame_AddMessageEventFilter then
        local function Filter(_, _, message, ...)
            if not self.db or not self.db.enabled then return false end
            return false, self:LinkifyBuildMessage(message), ...
        end
        ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", Filter)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", Filter)
    end
end

function T:PreviewTemplate(name)
    local ok, err = self:LoadTemplate(name)
    if not ok then return false, err end
    ok, err = self:RenderDraft(true)
    return ok, ok and L.TALENT_BUILD_LOADED or err
end

function T:SyncCurrentTalents()
    local frame = self:GetNativeFrame()
    local config = C_ClassTalents.GetActiveConfigID()
    if not self.characterDB or not frame or not config or InCombatLockdown()
        or C_Traits.ConfigHasStagedChanges(config) then return false end
    local spec = T:GetPlayerSpec()
    local tree = C_ClassTalents.GetTraitTreeForSpec(spec)
    if not tree then return false end
    -- Read the active character configuration, never the planner's preview.
    local ok, code = pcall(function()
        local stream = ExportUtil.MakeExportDataStream()
        frame:WriteLoadoutHeader(stream, C_Traits.GetLoadoutSerializationVersion(), spec, C_Traits.GetTreeHash(tree))
        frame:WriteLoadoutContent(stream, config, tree)
        return stream:GetExportString()
    end)
    if not ok or not code then return false end
    local previous = self.characterDB.currentTalents
    self.characterDB.currentTalents = { code = code, spec = spec, level = 60 }
    self.currentTalentsPending = nil
    if self.plannerTabActive and self.selected == self.currentBuildKey and not self.dirty
        and (not previous or previous.code ~= code or previous.spec ~= spec) then
        self:PreviewTemplate(self.currentBuildKey)
    elseif self.panel and self.panel:IsShown() then self:RefreshPanel() end
    return true
end

function T:QueueCurrentTalentsSync()
    self.currentTalentsPending = true
    if self.currentTalentsSyncQueued then return end
    self.currentTalentsSyncQueued = true
    C_Timer.After(0, function()
        self.currentTalentsSyncQueued = nil
        self:SyncCurrentTalents()
    end)
end

function T:CaptureCurrent()
    if InCombatLockdown() then return false, L.IMPORT_YOUR_CURRENT_TALENTS_AFTER_COMBAT end
    self:SyncCurrentTalents()
    local current = self:GetTemplate(self.currentBuildKey)
    if (not current or current.spec ~= T:GetPlayerSpec()) and UnitLevel("player") < 10 then
        local ok, err = self:NewBuild(T:GetPlayerSpec())
        if not ok then return false, err end
        self.characterDB.currentTalents = { code = self.draft.code, spec = self.draft.spec, level = 60 }
        self.selected = self.currentBuildKey
        self:ResetDraftBaseline()
        return true, L.TALENT_BUILD_LOADED
    end
    if not current or current.spec ~= T:GetPlayerSpec() then
        return false, L.YOUR_TALENT_DATA_IS_NOT_AVAILABLE_YET_APPLY_OR_DISCARD_PENDING_TALENT_CHANGES_FIRST
    end
    return self:PreviewTemplate(self.currentBuildKey)
end

function T:NewBuild(spec)
    if InCombatLockdown() then return false, L.CREATE_THE_TALENT_BUILD_AFTER_COMBAT end
    local tree = C_ClassTalents.GetTraitTreeForSpec(spec)
    if not tree then return false, L.THIS_CLASS_S_TALENT_TREE_IS_UNAVAILABLE end
    C_ClassTalents.InitializeViewLoadout(spec, 60)
    local draft = { spec = spec, tree = tree, level = 60, content = {} }
    self.draft = draft
    local ok = pcall(self.ReadDraftNodes, self)
    if not ok then return false, L.THIS_CLASS_S_TALENT_DATA_IS_NOT_AVAILABLE_YET end
    draft.code = self:EncodeDraft(draft)
    self.selected = nil
    self.newSpec = spec
    self:ResetDraftBaseline()
    return self:RenderDraft(false)
end

function T:ClearBuild()
    if not self.draft or not self.draft.ranks then return false, L.OPEN_A_TALENT_BUILD_FIRST end
    if InCombatLockdown() then return false, L.EDIT_THE_TALENT_BUILD_AFTER_COMBAT end
    for id in pairs(self.draft.ranks) do self.draft.ranks[id] = 0 end
    self.draft.code = self:EncodeDraft(self.draft)
    self.selected = nil
    self:UpdateDraftDirty()
    return self:RenderDraft(false)
end

-- Stage changes using the same public trait APIs as Blizzard's buttons.
-- Never commit automatically, switch specializations, or erase a pending player edit.
function T:StageBuild()
    if InCombatLockdown() then return false, L.PREPARE_THE_TALENT_BUILD_AFTER_COMBAT end
    local draft = self.draft
    if not draft then return false, L.OPEN_A_TALENT_BUILD_FIRST end
    if draft.spec ~= T:GetPlayerSpec() then return false, L.YOU_CAN_ONLY_LEARN_TALENTS_FOR_YOUR_OWN_CLASS end
    local config = C_ClassTalents.GetActiveConfigID()
    if not config then return false, L.YOUR_ACTIVE_TALENT_CONFIGURATION_IS_UNAVAILABLE end
    if C_Traits.ConfigHasStagedChanges(config) then
        return false, L.APPLY_OR_UNDO_PENDING_TALENT_CHANGES_IN_THE_GAME_FIRST
    end
    local frame = self:GetNativeFrame()
    local ok, entries = pcall(function()
        local decoded, err = self:DecodeCode(draft.code)
        if not decoded then error(err) end
        return frame:ConvertToImportLoadoutEntryInfo(config, draft.tree, decoded.content)
    end)
    if not ok then return false, L.THE_SAVED_TALENT_BUILD_NO_LONGER_MATCHES_THIS_TALENT_TREE end
    local success, message = pcall(function()
        if not C_Traits.ResetTree(config, draft.tree) then
            return L.THE_GAME_REJECTED_THE_TALENT_RESET_YOU_MAY_NEED_TO_RESET_YOUR_TALENTS_AT_A_TRAINER
        end
        -- Retry by dependency order: prerequisites and tier spending must come first.
        local remaining = {}
        for _, entry in ipairs(entries) do remaining[#remaining + 1] = entry end
        local progress, passes = true, 0
        while #remaining > 0 and progress and passes < 500 do
            passes = passes + 1
            progress = false
            for i = #remaining, 1, -1 do
                local entry = remaining[i]
                local node = C_Traits.GetNodeInfo(config, entry.nodeID)
                local target = entry.ranksPurchased or 0
                if node and node.ranksPurchased >= target then
                    table.remove(remaining, i)
                    progress = true
                elseif node then
                    if entry.selectionEntryID and #node.entryIDs > 1 then
                        C_Traits.SetSelection(config, entry.nodeID, entry.selectionEntryID)
                        node = C_Traits.GetNodeInfo(config, entry.nodeID)
                    end
                    if node.ranksPurchased >= target then
                        progress = true
                    elseif C_Traits.PurchaseRank(config, entry.nodeID) then
                        local updated = C_Traits.GetNodeInfo(config, entry.nodeID)
                        progress = updated and updated.ranksPurchased > node.ranksPurchased or progress
                    end
                end
            end
        end
        if #remaining > 0 then
            C_Traits.RollbackConfig(config)
            return L.THIS_TALENT_BUILD_COULD_NOT_BE_LEARNED
        end
        for _, entry in ipairs(entries) do
            local node = C_Traits.GetNodeInfo(config, entry.nodeID)
            if not node or node.ranksPurchased ~= (entry.ranksPurchased or 0)
                or ((entry.ranksPurchased or 0) > 0 and entry.selectionEntryID
                    and (not node.activeEntry or node.activeEntry.entryID ~= entry.selectionEntryID)) then
                C_Traits.RollbackConfig(config)
                return L.THE_PREPARED_TALENTS_IN_THE_GAME_DO_NOT_MATCH_THIS_TALENT_BUILD
            end
        end
    end)
    if not success then
        C_Traits.RollbackConfig(config)
        frame:RefreshConfigID()
        return false, L.THE_GAME_REJECTED_THE_TALENT_BUILD
    end
    frame:RefreshConfigID()
    if message then return false, message end
    self:ShowLiveTalents()
    return true, L.TALENTS_PREPARED_REVIEW_THEM_AND_CONFIRM_WITH_APPLY_IN_THE_GAME
end

-- Tree positions and prerequisites are local metadata. Known calculator
-- coordinates preserve the familiar four-column grid; live groups also include
-- newly added nodes that are not in a calculator's mapping yet.
function T:GetPlanTrees()
    local draft = self.draft
    if not draft or not draft.nodes then return {} end
    if draft.planTrees then return draft.planTrees end
    local class = self:ClassForSpec(draft.spec)
    local data = class and self.webData[class.token:lower()]
    local trees, byID, byGroup = {}, {}, {}
    local groups = {}
    for _, group in ipairs(C_Traits.GetGroupDisplayInfoByTreeID(draft.tree) or {}) do groups[#groups + 1] = group end
    table.sort(groups, function(a, b) return (a.orderIndex or 0) < (b.orderIndex or 0) end)
    for index = 1, 3 do
        local group = groups[index]
        trees[index] = { name = group and group.displayName }
        if group then byGroup[group.groupID] = index end
        for _, web in ipairs(data and data.wt[index] or {}) do
            local id = self:ResolveWebNode(web.id)
            if id then
                local entry = { id = id, row = web.row, col = web.col, req = web.req or 0,
                    reqRank = web.reqRank or 0, max = draft.nodes[id].maxRanks }
                trees[index][#trees[index] + 1] = entry
                byID[id] = entry
            end
        end
    end
    -- Infer a grid from mapped live positions, independently for each tree.
    for index, tree in ipairs(trees) do
        local originX, originY, stepX, stepY
        local rowSteps, firstLiveRow = {}, nil
        for _, a in ipairs(tree) do
            local na = draft.nodes[a.id]
            if na.posY then firstLiveRow = math.min(firstLiveRow or na.posY, na.posY) end
            for _, b in ipairs(tree) do
                local nb = draft.nodes[b.id]
                if na.posX and nb.posX and a.col ~= b.col then
                    local step = (nb.posX - na.posX) / (b.col - a.col)
                    if step > 0 then stepX = stepX or step end
                end
                if na.posY and nb.posY and a.row ~= b.row then
                    local step = (nb.posY - na.posY) / (b.row - a.row)
                    if step > 0 then rowSteps[#rowSteps + 1] = step end
                end
            end
        end
        table.sort(rowSteps)
        stepX, stepY = stepX or 600, rowSteps[math.ceil(#rowSteps / 2)] or 600
        for _, entry in ipairs(tree) do
            local node = draft.nodes[entry.id]
            if node.posX then originX = originX or node.posX - entry.col * stepX end
            if node.posY then originY = originY or node.posY - entry.row * stepY end
        end
        -- Drawn nodes already use live positions. Use the live tier for their
        -- requirements too: calculator metadata can lag behind moved talents.
        if firstLiveRow then
            originY = firstLiveRow
            for _, entry in ipairs(tree) do
                local node = draft.nodes[entry.id]
                if node.posY then
                    local row = math.floor((node.posY - originY) / stepY + 0.5)
                    if row >= 0 and row <= 8 then entry.row = row end
                end
            end
        end
        for id, node in pairs(draft.nodes) do
            local member = false
            for _, groupID in ipairs(node.groupIDs or {}) do
                if byGroup[groupID] == index then member = true end
            end
            if member and not byID[id] and (node.maxRanks or 0) > 0 and node.isVisible ~= false then
                local entry = { id = id, row = math.max(0, math.floor(((node.posY or 0) - (originY or 0)) / stepY + 0.5)),
                    col = math.max(0, math.floor(((node.posX or 0) - (originX or 0)) / stepX + 0.5)),
                    req = 0, reqRank = 0, max = node.maxRanks }
                -- A malformed live position must not squeeze the whole tree
                -- into one column (some Forever nodes have outlier positions).
                if entry.col <= 3 and entry.row <= 8 then
                    tree[#tree + 1], byID[id] = entry, entry
                end
            end
        end
        table.sort(tree, function(a, b) return a.row == b.row and a.col < b.col or a.row < b.row end)
    end
    -- Native availability edges replace stale calculator prerequisites.
    for id, node in pairs(draft.nodes) do
        for _, edge in ipairs(node.visibleEdges or {}) do
            local types = Enum.TraitEdgeType or {}
            if byID[id] and byID[edge.targetNode] and
                (edge.type == types.RequiredForAvailability or edge.type == types.SufficientForAvailability) then
                local target = byID[edge.targetNode]
                target.prereqs = target.prereqs or {}
                target.prereqs[#target.prereqs + 1] = { id = id, rank = node.maxRanks,
                    sufficient = edge.type == types.SufficientForAvailability }
            end
        end
    end
    draft.planTrees = trees
    return trees
end

function T:MeetsPlanRequirements(id, trees)
    local draft = self.draft
    local node = draft and draft.nodes[id]
    if not node then return false end
    for _, tree in ipairs(trees) do
        for _, entry in ipairs(tree) do
            if entry.id == id then
                local lowerPoints = 0
                for _, other in ipairs(tree) do
                    if other.row < entry.row then lowerPoints = lowerPoints + (draft.ranks[other.id] or 0) end
                end
                if lowerPoints < entry.row * 5 then return false end
                local hasSufficient, sufficientMet = false, false
                for _, req in ipairs(entry.prereqs or {}) do
                    local met = (draft.ranks[req.id] or 0) >= req.rank
                    if req.sufficient then hasSufficient = true; sufficientMet = sufficientMet or met
                    elseif not met then return false end
                end
                if hasSufficient and not sufficientMet then return false end
                if not entry.prereqs and entry.req ~= 0 then
                    local reqID, reqNode = self:ResolveWebNode(entry.req)
                    local needed = entry.reqRank > 0 and entry.reqRank or (reqNode and reqNode.maxRanks or 1)
                    if not reqID or (draft.ranks[reqID] or 0) < needed then return false end
                end
                return true
            end
        end
    end
    return false
end

function T:CanPlanRank(id, trees)
    local draft = self.draft
    local node = draft and draft.nodes[id]
    return node ~= nil and (draft.ranks[id] or 0) < node.maxRanks
        and self:PointCount() < draft.level - 9 and self:MeetsPlanRequirements(id, trees)
end

function T:IsPlanValid()
    local trees = self:GetPlanTrees()
    for _, tree in ipairs(trees) do
        for _, entry in ipairs(tree) do
            if (self.draft.ranks[entry.id] or 0) > 0 and not self:MeetsPlanRequirements(entry.id, trees) then
                return false
            end
        end
    end
    return true
end

function T:PlanTreeName(index)
    local tree = self:GetPlanTrees()[index]
    return tree and tree.name or (L.TALENT_TREE .. index)
end

function T:ClearTree(index)
    if InCombatLockdown() then return false, L.RESET_TALENT_TREES_AFTER_COMBAT end
    local tree = self:GetPlanTrees()[index]
    if not tree or #tree == 0 then return false, L.THIS_TALENT_TREE_S_DATA_IS_UNAVAILABLE end
    for _, entry in ipairs(tree) do self.draft.ranks[entry.id] = 0 end
    self.draft.code = self:EncodeDraft(self.draft)
    self:UpdateDraftDirty()
    return self:RenderDraft(false)
end

function T:BuildPlannerDisplay()
    if self.plannerCanvas then return self.plannerCanvas end
    local frame = self:GetNativeFrame()
    local canvas = CreateFrame("Frame", nil, PlayerSpellsFrame)
    canvas:SetAllPoints(frame.BackgroundBorder)
    canvas:SetFrameLevel(frame:GetFrameLevel() + 5000)
    canvas:EnableMouse(true)
    -- Class/background atlases contain translucent areas. Cover the native
    -- nodes and edges underneath before compositing the planner's artwork.
    canvas.opaqueBacking = canvas:CreateTexture(nil, "BACKGROUND", nil, -8)
    canvas.opaqueBacking:SetAllPoints()
    canvas.opaqueBacking:SetColorTexture(0.095, 0.08, 0.067, 1)
    local background = canvas:CreateTexture(nil, "BACKGROUND")
    background:SetPoint("BOTTOMLEFT", PlayerSpellsFrame, "BOTTOMLEFT", 3, 4)
    background:SetPoint("BOTTOMRIGHT", PlayerSpellsFrame, "BOTTOMRIGHT", -3, 4)
    background:SetHeight(701)
    background:SetAtlas("Talents-Background-c60", false)
    background:SetHorizTile(true)
    canvas.backing = background
    canvas.background = canvas:CreateTexture(nil, "BACKGROUND", nil, 1)
    canvas.background:SetPoint("TOPLEFT", canvas, "TOPLEFT", 2, -4)
    canvas.background:SetPoint("BOTTOMRIGHT", canvas, "BOTTOMRIGHT", -2, 4)
    canvas.border = canvas:CreateTexture(nil, "OVERLAY")
    canvas.border:SetAllPoints()
    canvas.border:SetAtlas("Talents-inner-frame-c60")
    -- Native full-width points banner/divider, above the class artwork.
    canvas.bannerLeft = canvas:CreateTexture(nil, "ARTWORK")
    canvas.bannerLeft:SetAtlas("Talents-divider-left-c60", true)
    canvas.bannerLeft:SetPoint("RIGHT", canvas, "CENTER")
    canvas.bannerLeft:SetPoint("TOP", canvas, "TOP", 0, -4)
    canvas.bannerRight = canvas:CreateTexture(nil, "ARTWORK")
    canvas.bannerRight:SetAtlas("Talents-divider-right-c60", true)
    canvas.bannerRight:SetPoint("LEFT", canvas, "CENTER")
    canvas.bannerRight:SetPoint("TOP", canvas, "TOP", 0, -4)
    canvas.nodeLayer = CreateFrame("Frame", nil, canvas)
    canvas.nodeLayer:SetAllPoints(frame.ButtonsParent or frame.BackgroundBorder)
    canvas.nodeLayer:SetFrameLevel(canvas:GetFrameLevel() + 20)
    self.plannerCanvas = canvas
    canvas.trees, canvas.buttons = {}, {}
    -- Match the native decorative dividers, including their artwork offsets.
    canvas.separators = {}
    for index = 1, 2 do
        local seam = canvas:CreateTexture(nil, "ARTWORK", nil, -1)
        seam:SetAtlas("Talents-divider-vertical-c60", true)
        seam:SetPoint("TOP", index == 1 and canvas.bannerLeft or canvas.bannerRight,
            "CENTER", index == 1 and 95 or -95, -60)
        canvas.separators[index] = seam
    end
    for index = 1, 3 do
        local tree = CreateFrame("Frame", nil, canvas)
        tree:SetPoint("TOPLEFT", canvas, "TOPLEFT", 12 + (index - 1) * 400, -60)
        tree:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", 12 + (index - 1) * 400, 12)
        tree:SetWidth(388)
        tree.header = CreateFrame("Frame", nil, canvas, "ClassTalentTreeHeaderTemplate")
        tree.header:SetFrameLevel(canvas:GetFrameLevel() + 30)
        tree.header:SetPoint("CENTER", canvas, "TOPLEFT", 140 + (index - 1) * 400, -100)
        tree.name, tree.points = tree.header.Name, tree.header.Text
        tree.lines = {}
        canvas.trees[index] = tree
    end
    canvas:Hide()
    return canvas
end

function T:GetPlannerTalentInfo(id)
    local draft = self.draft
    local node = draft and draft.nodes[id]
    if not node then return end
    local entryID = node.entryIDs[draft.choices[id] or 1] or node.entryIDs[1]
    local entry = C_Traits.GetEntryInfo(draft.configID, entryID)
    local definition = entry and C_Traits.GetDefinitionInfo(entry.definitionID)
    if not definition then return end
    local spellID = definition.spellID
    local name = definition.overrideName
    if not name or name == "" then name = spellID and C_Spell.GetSpellName(spellID) end
    local icon = definition.overrideIcon
    if (not icon or icon == 0) and spellID then
        local basic, talentIcon = C_Spell.GetSpellTexture(spellID)
        icon = talentIcon or basic
    end
    if spellID and C_Spell.RequestLoadSpellData then C_Spell.RequestLoadSpellData(spellID) end
    return name or L.TALENT_TREE .. id, icon or 134400, entryID, spellID
end

-- Read the same trait tooltip data as Blizzard, without calling its talent
-- button handlers or putting the native talent frame into inspection mode.
local function AppendTraitTooltip(tooltip, entryID, rank)
    local getter = C_TooltipInfo and C_TooltipInfo.GetTraitEntry
    if not getter then return false end
    local ok, data = pcall(getter, entryID, rank)
    if not ok or not data or not data.lines then return false end
    local added = false
    local function RGB(color, r, g, b)
        if color then
            if color.GetRGB then return color:GetRGB() end
            return color.r or r, color.g or g, color.b or b
        end
        return r, g, b
    end
    for _, line in ipairs(data.lines) do
        if type(line.leftText) == "string" then
            local r, g, b = RGB(line.leftColor, 1, 1, 1)
            if type(line.rightText) == "string" and line.rightText ~= "" then
                local rr, rg, rb = RGB(line.rightColor, 1, 1, 1)
                tooltip:AddDoubleLine(line.leftText, line.rightText, r, g, b, rr, rg, rb)
            else
                tooltip:AddLine(line.leftText, r, g, b, line.wrapText ~= false)
            end
            added = true
        end
    end
    return added
end

function T:ShowPlannerTooltip(button)
    if not self.planning or not self.draft or InCombatLockdown() then return end
    if not self.plannerTooltip then
        -- The planner owns this frame completely. Do not leave addon-created
        -- tooltip data or formatting on Blizzard's shared GameTooltip, which
        -- protected action buttons also reuse during combat.
        self.plannerTooltip = CreateFrame("GameTooltip", "yTalentsPlannerTooltip", UIParent, "GameTooltipTemplate")
        self.plannerTooltip:SetFrameStrata("TOOLTIP")
    end
    local id, tooltip = button.nodeID, self.plannerTooltip
    local node = self.draft.nodes[id]
    local name, _, entryID, spellID = self:GetPlannerTalentInfo(id)
    if not node or not name then return end
    self.plannerTooltipOwner = button
    tooltip:SetOwner(button, "ANCHOR_RIGHT")
    tooltip:ClearLines()
    tooltip:SetText(name, 1, 1, 1)
    local rank = self.draft.ranks[id] or 0
    tooltip:AddLine((TOOLTIP_TALENT_RANK or "%d/%d"):format(rank, node.maxRanks), 1, 1, 1)
    tooltip:AddLine(" ")
    local function AddDescription(value)
        if not AppendTraitTooltip(tooltip, entryID, value) then
            if spellID and C_Spell.IsSpellPassive and C_Spell.IsSpellPassive(spellID) then
                tooltip:AddLine(SPELL_PASSIVE or PASSIVE or "Passive", 1, 1, 1)
            end
            local description = C_Traits.GetTraitDescription(entryID, value)
            if description and description ~= "" then tooltip:AddLine(description, 1, 0.82, 0, true) end
        end
    end
    AddDescription(math.max(1, rank))
    local ids = yTools and yTools.GetModule and yTools:GetModule("Tooltip_SpellID")
    if spellID and (not ids or ids:IsEnabled()) then
        tooltip:AddDoubleLine(L.PLANNER_SPELL_ID, tostring(spellID), 1, 0.82, 0, 1, 1, 1)
    end
    if rank > 0 and rank < node.maxRanks then
        local nextDescription = C_Traits.GetTraitDescription(entryID, rank + 1)
        if nextDescription and nextDescription ~= "" then
            tooltip:AddLine(" ")
            tooltip:AddLine(TALENT_BUTTON_TOOLTIP_NEXT_RANK or L.PLANNER_NEXT_RANK, 1, 1, 1)
            AddDescription(rank + 1)
        end
    end
    if rank < node.maxRanks and not self:CanPlanRank(id, self:GetPlanTrees()) then
        tooltip:AddLine(" ")
        tooltip:AddLine(L.TALENT_LOCKED_SPEND_POINTS_IN_EARLIER_ROWS_AND_MEET_THE_PREREQUISITE, 1, 0.25, 0.25, true)
    end
    tooltip:Show()
end

function T:EnterPlannerTooltip(button)
    button.plannerHovered = true
    self:ShowPlannerTooltip(button)
    local _, _, _, spellID = self:GetPlannerTalentInfo(button.nodeID)
    if spellID and Spell and Spell.CreateFromSpellID then
        local spell = Spell:CreateFromSpellID(spellID)
        local draft, nodeID = self.draft, button.nodeID
        if spell and not spell:IsSpellEmpty() then
            button.spellLoadCancel = spell:ContinueWithCancelOnSpellLoad(function()
                if button.plannerHovered and self.plannerTabActive and self.draft == draft and button.nodeID == nodeID then
                    self:ShowPlannerTooltip(button)
                end
            end)
        end
    end
end

function T:LeavePlannerTooltip(button)
    button.plannerHovered = false
    if button.spellLoadCancel then button.spellLoadCancel(); button.spellLoadCancel = nil end
    if self.plannerTooltip and self.plannerTooltip:IsOwned(button) then self.plannerTooltip:Hide() end
    if self.plannerTooltipOwner == button then self.plannerTooltipOwner = nil end
    if button.hover then button.hover:Hide() end
end

function T:RefreshOverlays()
    if not self.plannerTabActive or not self.planning or not self.draft or InCombatLockdown() then return end
    local canvas = self:BuildPlannerDisplay()
    local trees = self:GetPlanTrees()
    local used = {}
    local class = self:ClassForSpec(self.draft.spec)
    local native = self:GetNativeFrame()
    local separate = self.lowLevelPlannerWindow and self.lowLevelPlannerWindow:IsShown()
    local size, panX, panY = 40, -11, -7
    if not separate then
        size = native.GetButtonSize and native:GetButtonSize() or size
        if native.GetPanOffset then
            local ok, x, y = pcall(native.GetPanOffset, native)
            if ok and type(x) == "number" and type(y) == "number" then panX, panY = x, y end
        end
    end
    if class then canvas.background:SetAtlas("talent-background-" .. class.token:lower()) end
    for index, entries in ipairs(trees) do
        local tree = canvas.trees[index]
        tree.name:SetText(self:PlanTreeName(index))
        local points, maxRow, maxCol = 0, 6, 3
        for _, entry in ipairs(entries) do
            points = points + (self.draft.ranks[entry.id] or 0)
            maxRow, maxCol = math.max(maxRow, entry.row), math.max(maxCol, entry.col)
        end
        tree.points:SetText(points)
        local stepX = 60
        local stepY = 60
        local groups = C_Traits.GetGroupDisplayInfoByTreeID(self.draft.tree) or {}
        for _, group in ipairs(groups) do
            if group.displayName == tree.name:GetText() then tree.header.Icon:SetTexture(group.icon); break end
        end
        for _, entry in ipairs(entries) do
            local button = canvas.buttons[entry.id]
            if not button then
                button = CreateFrame("Button", nil, canvas.nodeLayer)
                button:SetSize(40, 40)
                button.shadow = button:CreateTexture(nil, "BACKGROUND")
                button.shadow:SetPoint("CENTER")
                button.shadow:SetAtlas("talents-node-square-shadow", true)
                button.icon = button:CreateTexture(nil, "BORDER")
                button.icon:SetPoint("CENTER")
                button.icon:SetSize(36, 36)
                button.dim = button:CreateTexture(nil, "BORDER", nil, 1)
                button.dim:SetPoint("CENTER")
                button.dim:SetSize(36, 36)
                button.dim:SetColorTexture(0, 0, 0, 1)
                button.dim:Hide()
                button.border = button:CreateTexture(nil, "ARTWORK")
                button.border:SetPoint("CENTER")
                button.hover = button:CreateTexture(nil, "ARTWORK", nil, 1)
                button.hover:SetPoint("CENTER")
                button.hover:SetBlendMode("ADD")
                button.hover:SetAlpha(0.5)
                button.hover:Hide()
                button.rank = button:CreateFontString(nil, "OVERLAY", "SystemFont16_Shadow_ThickOutline")
                button.rank:SetPoint("BOTTOM", button, "BOTTOM", 11, 4)
                button.rank:SetJustifyH("CENTER")
                button.rankShadows = {}
                for _, offset in ipairs({{-1, 1}, {1, 1}, {-1, -1}, {1, -1}}) do
                    local shadow = button:CreateFontString(nil, "ARTWORK", "SystemFont16_Shadow_ThickOutline")
                    shadow:SetPoint("CENTER", button.rank, "CENTER", offset[1], offset[2])
                    shadow:SetTextColor(0, 0, 0)
                    button.rankShadows[#button.rankShadows + 1] = shadow
                end
                button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
                button:SetScript("OnClick", function(owner, mouseButton)
                    self:ChangeRank(owner.nodeID, mouseButton == "RightButton" and -1 or 1)
                    if self.plannerTooltip and self.plannerTooltip:IsOwned(owner) then self:ShowPlannerTooltip(owner) end
                end)
                button:SetScript("OnEnter", function(owner) owner.hover:Show(); self:EnterPlannerTooltip(owner) end)
                button:SetScript("OnLeave", function(owner) self:LeavePlannerTooltip(owner) end)
                canvas.buttons[entry.id] = button
            end
            used[entry.id] = true
            button.treeIndex = index
            button.nodeID = entry.id
            button:SetSize(size, size)
            button.icon:SetSize(size - 4, size - 4)
            button.dim:SetSize(size - 4, size - 4)
            button:ClearAllPoints()
            -- Forever positions are in tenths of a pixel. Use its actual
            -- coordinate space and the class pan offset (49-60, 24-31).
            local node = self.draft.nodes[entry.id]
            local x, y = node.posX and node.posX / 10 - panX, node.posY and -node.posY / 10 + panY
            if not x or not y or x < 0 or x > 1200 or y > 0 or y < -700 then
                x, y = 110 + (index - 1) * 400 + entry.col * stepX, -165 - entry.row * stepY
            end
            button:SetPoint("CENTER", canvas.nodeLayer, "TOPLEFT", x, y)
            local _, icon = self:GetPlannerTalentInfo(entry.id)
            button.icon:SetTexture(icon)
            local node, rank = self.draft.nodes[entry.id], self.draft.ranks[entry.id] or 0
            local eligible = self:CanPlanRank(entry.id, trees)
            local full = rank >= node.maxRanks
            local color = DISABLED_FONT_COLOR
            local r, g, b = 0.5, 0.5, 0.5
            if full then color = YELLOW_FONT_COLOR; r, g, b = 1, 1, 0
            elseif rank > 0 or eligible then color = GREEN_FONT_COLOR; r, g, b = 0.1, 1, 0.1 end
            if color then r, g, b = color:GetRGB() end
            button.icon:SetDesaturated(rank == 0 and not eligible)
            button.icon:SetAlpha(1)
            button.icon:SetVertexColor(1, 1, 1)
            local lowerPoints = 0
            for _, other in ipairs(entries) do
                if other.row < entry.row then lowerPoints = lowerPoints + (self.draft.ranks[other.id] or 0) end
            end
            local dimmed = rank == 0 and not eligible
            local gated = dimmed and lowerPoints < entry.row * 5
            button.dim:SetAlpha(gated and 0.7 or 0.25)
            button.dim:SetShown(dimmed)
            local atlas = full and "talents-node-square-yellow"
                or ((rank > 0 or eligible) and "talents-node-square-green"
                    or (gated and "talents-node-square-locked" or "talents-node-square-gray"))
            button.border:SetAtlas(atlas, true)
            button.border:SetVertexColor(1, 1, 1)
            button.hover:SetAtlas(atlas, true)
            button.hover:SetVertexColor(1, 1, 1)
            button.hover:SetAlpha(dimmed and 0.4 or 1)
            local rankText = (rank > 0 or eligible) and tostring(rank) or ""
            button.rank:SetText(rankText)
            for _, shadow in ipairs(button.rankShadows) do shadow:SetText(rankText) end
            button.rank:SetTextColor(r, g, b)
            button:Show()
        end
        for _, line in ipairs(tree.lines) do line:Hide(); if line.arrow then line.arrow:Hide() end end
        local lineIndex = 0
        for _, entry in ipairs(entries) do
            local reqID = entry.prereqs and entry.prereqs[1] and entry.prereqs[1].id
                or (entry.req ~= 0 and self:ResolveWebNode(entry.req) or nil)
            local source, target = canvas.buttons[reqID], canvas.buttons[entry.id]
            if source and target and source.treeIndex == index then
                lineIndex = lineIndex + 1
                local line = tree.lines[lineIndex]
                if not line then
                    -- Use only the native artwork/template on an addon-owned frame.
                    -- Never initialize an edge with Blizzard's live talent buttons.
                    local edge = CreateFrame("Frame", nil, canvas.nodeLayer, "TalentEdgeArrowTemplate")
                    line = edge.Line
                    line.edge, line.arrow = edge, edge.ArrowHead
                    tree.lines[lineIndex] = line
                end
                -- Keep connectors above every planner decoration and talent button.
                -- Use the planner's strata so tooltips still appear above the tree.
                line.edge:SetFrameStrata(canvas:GetFrameStrata())
                line.edge:SetFrameLevel(canvas:GetFrameLevel() + 1000)
                line:SetDrawLayer("OVERLAY", 7)
                line.arrow:SetDrawLayer("OVERLAY", 7)
                local purchased = (self.draft.ranks[reqID] or 0) >= self.draft.nodes[reqID].maxRanks
                local lowerPoints = 0
                for _, other in ipairs(entries) do
                    if other.row < entry.row then lowerPoints = lowerPoints + (self.draft.ranks[other.id] or 0) end
                end
                local gated = lowerPoints < entry.row * 5
                local state = gated and "locked" or (purchased and "yellow" or "gray")
                line:SetThickness(6)
                line:SetAtlas("talents-arrow-line-" .. state, false)
                local a = self.draft.nodes[reqID]
                local b = self.draft.nodes[entry.id]
                local dx, dy = (a.posX or 0) - (b.posX or 0), (b.posY or 0) - (a.posY or 0)
                local length = math.sqrt(dx * dx + dy * dy)
                local angle = math.atan2 and math.atan2(dy, dx) or math.atan(dy, dx)
                local quarter, eighth = math.pi / 2, math.pi / 4
                local progress = math.abs(((eighth + angle) % quarter) - eighth)
                local minimum = TalentButtonUtil and TalentButtonUtil.SquareEdgeMinDiameterOffset or 1.2
                local maximum = TalentButtonUtil and TalentButtonUtil.SquareEdgeMaxDiameterOffset or 1.5
                local radius = target:GetWidth() / 2 * (minimum + (maximum - minimum) * progress)
                -- Higher edges can no longer rely on the source icon hiding the
                -- centre of the line. Start at its border instead.
                -- The source has no arrowhead: intersect its square border
                -- directly rather than applying the destination head offset.
                local sourceRadius = length > 0 and source:GetWidth() / 2
                    * length / math.max(math.abs(dx), math.abs(dy)) or source:GetWidth() / 2
                local sx, sy = length > 0 and -dx / length * sourceRadius or 0,
                    length > 0 and -dy / length * sourceRadius or -sourceRadius
                line:SetStartPoint("CENTER", source, sx, sy)
                local ox, oy = length > 0 and dx / length * radius or 0,
                    length > 0 and dy / length * radius or radius
                line:SetEndPoint("CENTER", target, ox, oy)
                line.arrow:SetAtlas("talents-arrow-head-" .. state, true)
                line.arrow:ClearAllPoints()
                line.arrow:SetPoint("CENTER", target, "CENTER", ox, oy)
                line.arrow:SetRotation(angle - math.pi / 2)
                line.arrow:Show()
                line:Show()
            end
        end
    end
    for id, button in pairs(canvas.buttons) do
        if not used[id] then self:LeavePlannerTooltip(button); button:Hide() end
    end
    canvas:Show()
    self:RefreshPlannerDecorations()
end

function T:GetPlannerPointSummary()
    local used = self:PointCount()
    return used, math.max(0, 51 - used), used > 0 and used + 9 or 1
end

function T:RefreshPlannerDecorations()
    local active = self.plannerTabActive == true and self.planning == true
    local class = self.draft and self:ClassForSpec(self.draft.spec)
    if self.classPicker and self.classPicker.icon and class then
        self.classPicker.icon:SetTexture("Interface/TargetingFrame/UI-Classes-Circles")
        local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class.token]
        if coords then self.classPicker.icon:SetTexCoord(unpack(coords)) end
    end
    for index, reset in ipairs(self.treeResets or {}) do
        reset:SetShown(active)
        local points = 0
        for _, entry in ipairs(self:GetPlanTrees()[index] or {}) do points = points + (self.draft.ranks[entry.id] or 0) end
        reset:SetEnabled(active and not InCombatLockdown() and points > 0)
    end
end

function T:QueuePlannerVisualRefresh()
    if self.overlayRefreshQueued then return end
    self.overlayRefreshQueued = true
    C_Timer.After(0, function()
        self.overlayRefreshQueued = nil
        if self.plannerTabActive and self.plannerCanvas and self.plannerCanvas:IsVisible() then self:RefreshOverlays() end
    end)
end

function T:RestorePlannerArtwork()
    -- Class artwork stays native. Decorative background animations are disabled
    -- consistently in both tabs, so returning to live talents needs no restore.
end

function T:FixPlannerSearch()
    -- Search and disabled overlays belong to the native display underneath.
end

local TAB_ART_KEYS = { "Left", "Middle", "Right", "LeftActive", "MiddleActive", "RightActive",
    "LeftHighlight", "MiddleHighlight", "RightHighlight" }

function T:CopyNativeTabStyle(tab, reference)
    if not reference then return end
    tab.nativeReference = reference
    if reference.GetWidth then tab:SetWidth(reference:GetWidth()) end
    tab:SetHeight(reference:GetHeight())
    for _, key in ipairs(TAB_ART_KEYS) do
        local source, dest = reference[key], tab[key]
        if source and dest then
            local atlas = source.GetAtlas and source:GetAtlas()
            if atlas and atlas ~= "" then
                dest:SetAtlas(atlas)
            elseif source.GetTexture then
                dest:SetTexture(source:GetTexture())
                if source.GetTexCoord then dest:SetTexCoord(source:GetTexCoord()) end
            end
            if source.GetHeight then dest:SetHeight(source:GetHeight()) end
            if not key:find("Middle") and source.GetWidth then dest:SetWidth(source:GetWidth()) end
            if source.GetVertexColor then dest:SetVertexColor(source:GetVertexColor()) end
            if source.GetBlendMode then dest:SetBlendMode(source:GetBlendMode()) end
            if source.GetRotation then dest:SetRotation(source:GetRotation()) end
            if source.GetNumPoints and source.GetPoint then
                dest:ClearAllPoints()
                for index = 1, source:GetNumPoints() do
                    local point, relative, relativePoint, x, y = source:GetPoint(index)
                    local relativeClone
                    if relative == reference then relativeClone = tab end
                    for _, otherKey in ipairs(TAB_ART_KEYS) do
                        if relative == reference[otherKey] then relativeClone = tab[otherKey]; break end
                    end
                    dest:SetPoint(point, relativeClone or tab, relativePoint, x, y)
                end
            end
        end
    end
    if reference.Text and reference.Text.GetFont then
        tab.nativeFont, tab.nativeFontSize, tab.nativeFontFlags = reference.Text:GetFont()
    end
end

function T:SelectPlannerTabArt(tab, selected)
    tab:SetTabSelected(selected)
    if tab.nativeFont then tab.Text:SetFont(tab.nativeFont, tab.nativeFontSize, tab.nativeFontFlags) end
    local reference = tab.nativeReference
    if reference and reference.GetTextYOffset then
        tab.Text:ClearAllPoints()
        tab.Text:SetPoint("CENTER", tab, "CENTER", 0, reference:GetTextYOffset(selected))
    end
end

-- Use Blizzard's tab art on addon-owned controls. The native tab remains
-- logically selected; an independent proxy makes it clickable while planning.
function T:RefreshPlannerTabVisuals()
    if InCombatLockdown() or not self.plannerTab then return end
    local active = self.plannerTabActive == true
    self:SelectPlannerTabArt(self.plannerTab, active)
    local frame = self:GetNativeFrame()
    local live = frame.TabSystem:GetTabButton(frame:GetActiveTab())
    if active and live and not (self.lowLevelPlannerWindow and self.lowLevelPlannerWindow:IsShown()) then
        self.liveTabProxy:ClearAllPoints()
        self.liveTabProxy:SetAllPoints(live)
        self.liveTabProxy:SetText(live:GetText() or TALENTS)
        self:SelectPlannerTabArt(self.liveTabProxy, false)
        self.liveTabProxy:Show()
    else
        self.liveTabProxy:Hide()
    end
end

function T:EnterPlannerTab()
    if not self.db.enabled or InCombatLockdown() then return end
    self.plannerGeneration = (self.plannerGeneration or 0) + 1
    self.plannerTabActive = true
    self.plannerTab:Show()
    self:RefreshPlannerTabVisuals()
    self.enteringPlanner = true
    self:BuildPanel()
    self:ConfigurePlannerLayout()
    self:RefreshPlannerTabVisuals()
    self:SyncCurrentTalents()
    self.panel:Show()
    local ok, err
    if not self.draft or self.selected == self.currentBuildKey then
        ok, err = self:CaptureCurrent()
    else
        ok, err = self:RenderDraft(not self.draft.nodes)
    end
    self.enteringPlanner = nil
    self:FixPlannerSearch()
    self:Result(ok, err)
    self:RefreshPlannerDecorations()
    self:QueuePlannerVisualRefresh()
end

function T:ShowLiveTalents()
    if InCombatLockdown() then self.leavePlanPending = true; return end
    self.plannerGeneration = (self.plannerGeneration or 0) + 1
    self.plannerTabActive = false
    self:RefreshPlannerTabVisuals()
    self:LeavePlan()
    self:RestorePlannerArtwork()
    if self.panel then self.panel:Hide() end
    -- The native tab selection was never changed while planning.
end

-- These are decorative texture animations only. Their masked spec-art can
-- leave a straight vertical seam in Forever. Stop them without touching the
-- talent configuration, inspection state, buttons, or protected frame state.
function T:DisableBackgroundAnimations()
    local frame = self:GetNativeFrame()
    if not frame or self.backgroundAnimationsDisabled then return end
    self.backgroundAnimationsDisabled = true
    for _, animation in ipairs(frame.backgroundAnims or {}) do
        hooksecurefunc(animation, "Play", function(owner) owner:Stop() end)
        animation:Stop()
    end
    -- Hiding once is insufficient: native tab/spec refreshes can show these
    -- masked additive textures again. Empty only their cosmetic artwork, and
    -- keep it empty when the native class-art atlas is refreshed later.
    for _, key in ipairs({"OverlayBackgroundRight", "OverlayBackgroundMid"}) do
        local texture = frame[key]
        if texture then
            hooksecurefunc(texture, "SetAtlas", function(owner) owner:SetTexture(nil) end)
            texture:SetTexture(nil)
        end
    end
    for _, key in ipairs({"OverlayBackgroundRight", "OverlayBackgroundMid", "Clouds1", "Clouds2", "AirParticlesClose", "AirParticlesFar"}) do
        if frame[key] then frame[key]:Hide() end
    end
end

function T:InstallNativeControls()
    if self.nativeHooked or InCombatLockdown() then return end
    local frame, parent = self:GetNativeFrame(), PlayerSpellsFrame
    if not frame or not frame.TabSystem then return end
    self.nativeHooked = true
    self:DisableBackgroundAnimations()

    -- A separate button alongside the native tabs. Registering an addon tab or
    -- replacing SetTab/callbacks taints the native tab system's execution.
    local reference = frame.TabSystem:GetTabButton(frame:GetActiveTab())
    local function NewTab(text)
        local tab = CreateFrame("Button", nil, parent, "TabSystemButtonArtTemplate")
        tab:SetFrameStrata("DIALOG")
        tab:SetFrameLevel(parent:GetFrameLevel() + 1200)
        tab:EnableMouse(true)
        tab.isTabOnTop = reference and reference.isTabOnTop or false
        tab.textOffsetY = reference and reference.textOffsetY or 0
        tab.selectedFontObject = reference and reference.selectedFontObject
        tab.unselectedFontObject = reference and reference.unselectedFontObject
        tab:HandleRotation()
        tab:SetText(text)
        tab:SetHeight(reference and reference:GetHeight() or 32)
        tab:SetWidth(math.max(130, tab.Text:GetStringWidth() + 30))
        self:CopyNativeTabStyle(tab, reference)
        self:SelectPlannerTabArt(tab, false)
        return tab
    end
    local plannerButton = NewTab(L.TALENT_PLANNER)
    plannerButton:SetPoint("TOPLEFT", frame.TabSystem, "TOPRIGHT", frame.TabSystem.spacing or 1, 0)
    plannerButton:SetScript("OnClick", function() self:Open() end)
    plannerButton:SetShown(self.db and self.db.enabled and frame:IsVisible())
    self.plannerTab = plannerButton
    local liveProxy = NewTab(reference and reference:GetText() or TALENTS)
    local backing = liveProxy:CreateTexture(nil, "BACKGROUND", nil, -8)
    backing:SetPoint("TOPLEFT", liveProxy.LeftActive, "TOPLEFT")
    backing:SetPoint("BOTTOMRIGHT", liveProxy.RightActive, "BOTTOMRIGHT")
    backing:SetColorTexture(0.055, 0.055, 0.07, 1)
    liveProxy:SetScript("OnClick", function() self:ShowLiveTalents() end)
    liveProxy:Hide()
    self.liveTabProxy = liveProxy

    local function ExitPlanner()
        self.inspectionRequest = nil
        self.plannerTabActive = false
        self:LeavePlan()
        if not InCombatLockdown() then self:RefreshPlannerTabVisuals() end
    end
    -- Leave both native SetTab methods untouched. Their shared tracker is
    -- used by the secure talent key during combat. OnHide handles navigation
    -- away from the talent page; native spec-tab clicks only leave our plan.
    for _, tabID in ipairs(frame:GetTabSet()) do
        local nativeTab = frame.TabSystem:GetTabButton(tabID)
        if nativeTab then
            nativeTab:HookScript("OnClick", function()
                if self.plannerTabActive then ExitPlanner() end
            end)
        end
    end
    -- Read incoming inspection strings, without ever writing inspection state.
    hooksecurefunc(parent, "SetInspectString", function(_, code) self:QueueInspectedString(code) end)
    if parent.SetInspectUnit then
        hooksecurefunc(parent, "SetInspectUnit", function(_, unit)
            if unit and not InCombatLockdown() then
                self.inspectionRequest = { unit = unit, guid = UnitGUID(unit), name = self:CharacterFullName(unit) }
                self:QueueInspectedPlan()
            end
        end)
    end
    frame:HookScript("OnShow", function()
        if not InCombatLockdown() then plannerButton:SetShown(self.db and self.db.enabled) end
    end)
    frame:HookScript("OnHide", function()
        -- IsShown on a child remains true when its parent closes. Reset our
        -- state directly on hide; no inspection cleanup needs to be deferred.
        ExitPlanner()
        plannerButton:Hide()
        liveProxy:Hide()
    end)
    parent:HookScript("OnHide", ExitPlanner)
end
