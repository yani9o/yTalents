local _, localization = ...
local L = localization.L
local _, T = ...

local function Label(parent, text, x, y, template)
    local label = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
    label:SetPoint("TOPLEFT", x, y)
    label:SetJustifyH("LEFT")
    label:SetText(text)
    return label
end

local function Button(parent, text, x, y, width, callback)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", x, y)
    button:SetSize(width or 126, 24)
    button:SetText(text)
    button:SetScript("OnClick", callback)
    return button
end

local function Edit(parent, x, y, width)
    local edit = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    edit:SetPoint("LEFT", x, 0)
    edit:SetSize(width, 24)
    edit:SetAutoFocus(false)
    edit:SetScript("OnEscapePressed", function(owner) owner:ClearFocus() end)
    edit:SetScript("OnEnterPressed", function(owner) owner:ClearFocus() end)
    return edit
end

StaticPopupDialogs.YTALENTS_CONFIRM = {
    text = "%s", button1 = L.YES, button2 = L.NO, timeout = 0,
    whileDead = true, hideOnEscape = true, preferredIndex = 3,
    OnAccept = function(_, callback) callback() end,
}

StaticPopupDialogs.YTALENTS_SHARE = {
    text = L.WHISPER_THIS_TALENT_BUILD_TO, button1 = L.SEND, button2 = L.CANCEL,
    hasEditBox = true, timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
    OnShow = function(dialog)
        local edit = dialog.editBox or dialog.EditBox
        edit:SetText(""); edit:SetFocus()
    end,
    OnAccept = function(dialog, data)
        local edit = dialog.editBox or dialog.EditBox
        T:SendBuildWhisper(data.share, edit:GetText())
    end,
    EditBoxOnEnterPressed = function(edit)
        local dialog = edit:GetParent()
        if T:SendBuildWhisper(dialog.data.share, edit:GetText()) then dialog:Hide() end
    end,
}

function T:ImportFromField()
    local text = self.panel.code:GetText()
    self.panel.code:ClearFocus()
    self:ConfirmDiscard(function()
        local ok, err = self:ImportText(text)
        if ok then
            -- Web imports already have populated ranks. Native imports have no
            -- nodes yet, so RenderDraft will load those only when necessary.
            ok, err = self:RenderDraft(false)
            if ok then err = L.TALENT_BUILD_LOADED end
        end
        self:Result(ok, err)
    end)
end

function T:CopyBuildText()
    local text, err = self:GetExportText()
    if not text or text == "" then self:Message(err or L.OPEN_A_TALENT_BUILD_FIRST, false); return end
    self.panel.code:SetText(text)
    -- Clipboard writes are Blizzard-only. Select everything for the user's Ctrl+C.
    self.panel.code:SetFocus()
    self.panel.code:HighlightText()
    self:Message(L.PRESS_CTRL_C_TO_COPY, true)
end

function T:ConfirmDiscard(callback)
    local saved = self.plannerDraftBeforeSpec
    if (saved and saved.dirty) or (not saved and self:UpdateDraftDirty()) then
        StaticPopup_Show("YTALENTS_CONFIRM", L.DISCARD_UNSAVED_CHANGES_TO_THIS_TALENT_BUILD, nil, callback)
    else
        callback()
    end
end

function T:Result(ok, message, chat)
    self:RefreshPanel()
    if message then self:Message(message, ok, chat)
    elseif not ok then self:Message(L.THE_ACTION_COULD_NOT_BE_COMPLETED, false, chat) end
end

function T:RefreshPanel()
    local panel = self.panel
    if not panel then return end
    if self.specGroupView then
        panel:Hide()
        panel.footer:Hide()
        panel.name:ClearFocus()
        panel.code:ClearFocus()
        self.classPicker:Show()
        self.classPicker:EnableMouse(true)
        self.classArrow:Show()
        self.classArrow:SetEnabled(true)
        if self.classReload then self.classReload:Hide() end
        self:RefreshPlannerDecorations()
        return
    end
    self.classPicker:EnableMouse(true)
    local spec = self.draft and self.draft.spec or T:GetPlayerSpec()
    local hasSaved = self:HasSavedTemplates(spec)
    local caption = hasSaved and L.SAVED_TALENT_BUILDS or L.NO_TALENT_BUILDS
    if panel.templates.SetDefaultText then panel.templates:SetDefaultText(caption)
    else panel.templates:SetText(caption) end
    panel.templates:GenerateMenu()
    panel.templates:SetEnabled(hasSaved)
    local draft = self.draft
    if panel.displayedSelection ~= self.selected or panel.displayedSpec ~= (draft and draft.spec) then
        panel.name:SetText(self.selected ~= self.currentBuildKey and (self:TemplateName(self.selected) or "") or "")
        panel.displayedSelection, panel.displayedSpec = self.selected, draft and draft.spec
    end
    local signature = draft and ((draft.code or "") .. ":" .. (self.exportFormat or "native"))
    if not panel.code:HasFocus() or panel.exportSignature ~= signature then
        local text, err = self:GetExportText()
        if not text and draft then
            text = self:GetExportText("wowhead")
            if panel.exportError ~= err then self:Message(err, false) end
        end
        panel.exportError = err
        panel.exportSignature = signature
        panel.code:SetText(text or "")
    end
    self:RefreshActionButtons()
    self:RefreshSavedIndicator()
    if panel.pointSummary then
        local used, left, neededLevel = self:GetPlannerPointSummary()
        local rows = panel.pointsBox.rows
        rows[1].value:SetText(tostring(neededLevel))
        rows[2].value:SetText(string.format("%d / 51 (%d)", used, left))
    end
    self.classPicker:SetShown(self.plannerTabActive == true)
    self.classArrow:SetShown(self.plannerTabActive == true)
    self.classArrow:SetEnabled(true)
    if self.classReload then
        self.classReload:SetShown(self.plannerTabActive == true)
        self.classReload:SetEnabled((self.selected ~= self.currentBuildKey or self.dirty == true))
    end
    self:RefreshPlannerDecorations()
end

function T:RefreshActionButtons()
    self:UpdateDraftDirty()
    local panel, draft = self.panel, self.draft
    if not panel or not panel.stage then return end
    local name = panel.name:GetText():match("^%s*(.-)%s*$")
    local exists = self.db.templates[name]
    local planning = draft ~= nil and self.planning == true and not self.unreadableTemplate
    panel.save:SetEnabled(planning and name ~= "" and name ~= self.currentBuildName and not exists)
    local saved = self.selected and self.db.templates[self.selected]
    local changed = not self.unreadableTemplate and saved and draft and (saved.code ~= draft.code or name ~= self.selected)
    panel.update:SetEnabled(planning and changed == true and name ~= "" and (not exists or name == self.selected))
    panel.delete:SetEnabled(self.selected ~= nil and self.selected ~= self.currentBuildKey)
    panel.clear:SetEnabled(planning and self:PointCount() > 0)
    if panel.importBuild then panel.importBuild:SetEnabled(panel.code:GetText():match("%S") ~= nil) end
    if panel.copyCode then panel.copyCode:SetEnabled(draft ~= nil and not self.unreadableTemplate) end
    if panel.shareBuild then panel.shareBuild:SetEnabled(draft ~= nil and not self.unreadableTemplate) end
    local config = C_ClassTalents.GetActiveConfigID()
    panel.stage:SetEnabled(planning and self:HasNativeTalents() and draft.spec == T:GetPlayerSpec()
        and config ~= nil and not C_Traits.ConfigHasStagedChanges(config))
end

function T:ShowStatus(message, success)
    if not message or message == "" then return end
    local notice = { text = message, success = success ~= false }
    self.statusNotice = notice
    self:RefreshSavedIndicator()
    C_Timer.After(3, function()
        -- An earlier timer must not clear a newer status message.
        if self.statusNotice == notice then
            self.statusNotice = nil
            self:RefreshSavedIndicator()
        end
    end)
end

function T:FlashSaved(updated)
    self:ShowStatus(updated and L.TALENT_BUILD_UPDATED or L.TALENT_BUILD_SAVED, true)
end

function T:RefreshSavedIndicator()
    local panel, notice = self.panel, self.statusNotice
    if not notice and not self.specGroupView then
        if self.unreadableTemplate then notice = { text = L.SAVED_BUILD_UNREADABLE, success = false }
        elseif self.draft and self.draft.recoveryWarning then
            notice = { text = L.SAVED_BUILD_RECOVERED, success = false }
        end
    end
    if not panel or not panel.saved then return end
    if notice then
        panel.saved:SetText(notice.text)
        if notice.success then panel.saved:SetTextColor(0.2, 1, 0.2)
        else panel.saved:SetTextColor(1, 0.3, 0.3) end
    end
    panel.saved:SetShown(notice ~= nil)
end

function T:SaveNamedBuild()
    local ok, err = self:SaveTemplate(self.panel.name:GetText(), self.selected ~= nil and self.selected ~= self.currentBuildKey)
    self:Result(ok, err)
end

local function GreyWhenDisabled(button, icon)
    local function Refresh()
        local enabled = button:IsEnabled()
        if icon then icon:SetDesaturated(not enabled); icon:SetAlpha(enabled and 1 or 0.35) end
        local border = button.border
        if border then
            for _, piece in ipairs({border.Left, border.Middle, border.Right}) do
                piece:SetDesaturated(not enabled)
                if enabled and button.neutralArtwork then piece:SetVertexColor(1, 1, 1)
                elseif enabled then piece:SetVertexColor(1, 0.95, 0.35)
                else piece:SetVertexColor(0.72, 0.72, 0.72) end
            end
        end
        -- Keep the rim opaque while its grey tint indicates disabled actions.
        button:SetAlpha(1)
    end
    hooksecurefunc(button, "SetEnabled", Refresh)
    hooksecurefunc(button, "Enable", Refresh)
    hooksecurefunc(button, "Disable", Refresh)
    Refresh()
end

local function Tooltip(owner, title, detail)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetText(title)
    if detail then GameTooltip:AddLine(detail, 1, 1, 1, true) end
    GameTooltip:Show()
end

-- Reuse the exact visual template used by the build-name textbox. Its
-- left/middle/right pieces retain their border thickness at button width.
function T:CreatePlanIconBorder(button)
    local border = CreateFrame("EditBox", nil, button, "InputBoxVisualTemplate")
    border:SetAllPoints(button)
    border:SetFrameLevel(button:GetFrameLevel() + 1)
    border:SetAutoFocus(false)
    border:EnableMouse(false)
    if border.EnableKeyboard then border:EnableKeyboard(false) end
    border:SetText("")
    border.Left:ClearAllPoints()
    border.Left:SetPoint("TOPLEFT", border, "TOPLEFT")
    border.Left:SetPoint("BOTTOMLEFT", border, "BOTTOMLEFT")
    border.Left:SetWidth(8)
    border.Right:ClearAllPoints()
    border.Right:SetPoint("TOPRIGHT", border, "TOPRIGHT")
    border.Right:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT")
    border.Right:SetWidth(8)
    border.Middle:ClearAllPoints()
    border.Middle:SetPoint("TOPLEFT", border.Left, "TOPRIGHT")
    border.Middle:SetPoint("BOTTOMRIGHT", border.Right, "BOTTOMLEFT")
    for _, piece in ipairs({border.Left, border.Middle, border.Right}) do
        piece:SetVertexColor(1, 0.95, 0.35)
    end
    return border
end

local function IconButton(parent, x, texture, title, detail, callback)
    local button = CreateFrame("Button", nil, parent)
    button:SetPoint("LEFT", x, 0)
    button:SetSize(26, 26)
    button:SetFrameLevel(parent:GetFrameLevel() + 5)
    button:EnableMouse(true)
    button:RegisterForClicks("LeftButtonUp")
    local pixel = 1
    if PixelUtil and PixelUtil.GetPixelToUIUnitFactor and button.GetEffectiveScale then
        pixel = PixelUtil.GetPixelToUIUnitFactor() / button:GetEffectiveScale()
    end
    button.border = T:CreatePlanIconBorder(button)
    local icon = button.border:CreateTexture(nil, "BORDER")
    -- Keep the face inside the rim, even when a tree reset is resized to 24.
    local inset = math.max(4, pixel * 2)
    icon:SetPoint("TOPLEFT", button, "TOPLEFT", inset, -inset)
    icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -inset, inset)
    local backing = button.border:CreateTexture(nil, "BACKGROUND")
    backing:SetAllPoints(icon)
    backing:SetColorTexture(0, 0, 0, 1)
    button.iconBacking = backing
    if texture then
        icon:SetTexture(texture)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    else
        icon:SetAtlas("talents-button-undo", false)
    end
    if icon.SetSnapToPixelGrid then icon:SetSnapToPixelGrid(true) end
    if icon.SetTexelSnappingBias then icon:SetTexelSnappingBias(0) end
    icon:SetVertexColor(0.9, 0.9, 0.9)
    -- Tint the artwork itself; no highlight rectangle can spill over the rim.
    button:SetScript("OnEnter", function(owner)
        if owner:IsEnabled() then icon:SetVertexColor(1, 1, 1) end
        Tooltip(owner, title, detail)
    end)
    button:SetScript("OnLeave", function()
        local tint = button.neutralArtwork and 1 or 0.9
        icon:SetVertexColor(tint, tint, tint); GameTooltip:Hide()
    end)
    button:SetScript("OnClick", callback)
    button:SetScript("OnMouseDown", function(owner) if owner:IsEnabled() then icon:SetVertexColor(0.65, 0.65, 0.65) end end)
    button:SetScript("OnMouseUp", function(owner) if owner:IsEnabled() then icon:SetVertexColor(1, 1, 1) end end)
    button.icon = icon
    GreyWhenDisabled(button, icon)
    return button
end

local function Dropdown(parent, x, y, width, default, generator)
    local dropdown = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
    dropdown:SetPoint("LEFT", x, 0)
    dropdown:SetWidth(width)
    if dropdown.SetDefaultText then dropdown:SetDefaultText(default) else dropdown:SetText(default) end
    dropdown:SetupMenu(generator)
    return dropdown
end

function T:BuildPanel()
    if self.panel then return end
    local frame, parent = self:GetNativeFrame(), self:GetPlannerWindow()
    local canvas = self:BuildPlannerDisplay()
    local panel = CreateFrame("Frame", nil, canvas)
    self.panel = panel
    panel:SetPoint("LEFT", frame.BackgroundBorder, "TOPLEFT", 16, -29)
    panel:SetSize(770, 30)
    panel:SetFrameLevel(canvas:GetFrameLevel() + 100)
    local footer = CreateFrame("Frame", nil, canvas)
    panel.footer = footer
    footer:SetPoint("TOPLEFT", frame.BackgroundBorder, "BOTTOMLEFT", 16, 0)
    footer:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -20, 8)
    footer:SetFrameLevel(panel:GetFrameLevel())
    panel:SetScript("OnShow", function()
        footer:Show()
    end)
    panel:SetScript("OnHide", function()
        footer:Hide(); panel.name:ClearFocus(); panel.code:ClearFocus()
        self.classPicker:Hide()
        self.classArrow:Hide()
        self.classReload:Hide()
        for _, reset in ipairs(self.treeResets or {}) do reset:Hide() end
    end)

    local picker = CreateFrame("Button", nil, parent)
    self.classPicker = picker
    picker.icon = picker:CreateTexture(nil, "OVERLAY")
    picker.icon:SetAllPoints()
    local portraitMask = picker:CreateMaskTexture(nil, "OVERLAY")
    portraitMask:SetAllPoints(picker.icon)
    portraitMask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    picker.icon:AddMaskTexture(portraitMask)
    local portrait = parent.PortraitContainer and (parent.PortraitContainer.portrait or parent.PortraitContainer.Portrait)
        or parent.portrait or parent.Portrait
    if portrait then picker:SetAllPoints(portrait)
    else
        local corner = parent.NineSlice and parent.NineSlice.TopLeftCorner
        picker:SetPoint("TOPLEFT", corner or parent, "TOPLEFT", 9, -3)
        picker:SetSize(64, 64)
    end
    picker:SetFrameStrata("DIALOG")
    picker:SetFrameLevel(parent:GetFrameLevel() + 450)
    picker:EnableMouse(true)
    picker:RegisterForClicks("LeftButtonUp")
    picker:SetScript("OnEnter", function(owner) Tooltip(owner, L.SELECT_CLASS, L.SELECT_A_CLASS_FOR_A_NEW_LEVEL_60_TALENT_BUILD) end)
    picker:SetScript("OnLeave", function() GameTooltip:Hide() end)
    local arrow = CreateFrame("DropdownButton", nil, parent, "WowStyle1ArrowDropdownTemplate")
    self.classArrow = arrow
    arrow:ClearAllPoints()
    if parent.TitleContainer then
        -- The stock arrow artwork sits two units below its frame center.
        arrow:SetPoint("CENTER", parent.TitleContainer, "LEFT", 7.5, 0)
    else
        arrow:SetPoint("TOPLEFT", parent, "TOPLEFT", 53, 1)
    end
    arrow:SetSize(25, 25)
    arrow:SetFrameStrata("DIALOG"); arrow:SetFrameLevel(picker:GetFrameLevel())
    arrow:SetupMenu(function(_, root)
        local classes = {}
        for _, class in ipairs(self.classes) do classes[#classes + 1] = class end
        table.sort(classes, function(a, b)
            return self:ClassName(a.spec):lower() < self:ClassName(b.spec):lower()
        end)
        for _, class in ipairs(classes) do
            local spec = class.spec
            root:CreateRadio(self:ClassName(spec), function() return self.draft and self.draft.spec == spec end,
                function()
                    self:ConfirmDiscard(function()
                        -- Class browsing belongs to the planner. Leave the live
                        -- spec before replacing its displayed draft so a class
                        -- selection can never be treated as a live talent edit.
                        if self.specGroupView then self:EnterPlannerTab() end
                        self.inspectionRequest = nil
                        if spec == T:GetPlayerSpec() then
                            self:Result(self:CaptureCurrent())
                        else
                            self:Result(self:NewBuild(spec))
                        end
                    end)
                end)
        end
    end)
    local reload = IconButton(parent, 0, "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up",
        L.RELOAD_CURRENT_TALENTS, nil, function()
            self:ConfirmDiscard(function()
                self.inspectionRequest = nil
                self:Result(self:CaptureCurrent())
            end)
        end)
    self.classReload = reload
    reload:SetSize(25, 25) -- identical to the class-dropdown button
    reload.neutralArtwork = true
    reload.border:Hide()
    local arrowFace = reload:CreateTexture(nil, "ARTWORK")
    arrowFace:SetPoint("CENTER", reload, "CENTER", 0, -2)
    arrowFace:SetRotation(-math.pi / 2)
    reload.icon = arrowFace
    local function RefreshReload(hover)
        arrowFace:SetAtlas(not reload:IsEnabled() and "common-dropdown-a-button-disabled"
            or hover and "common-dropdown-a-button-hover" or "common-dropdown-a-button", true)
        arrowFace:SetVertexColor(1, 1, 1)
        arrowFace:SetAlpha(1)
    end
    hooksecurefunc(reload, "SetEnabled", function() RefreshReload(false) end)
    hooksecurefunc(reload, "Enable", function() RefreshReload(false) end)
    hooksecurefunc(reload, "Disable", function() RefreshReload(false) end)
    reload:SetScript("OnEnter", function(owner) RefreshReload(true); Tooltip(owner, L.RELOAD_CURRENT_TALENTS) end)
    reload:SetScript("OnLeave", function() RefreshReload(false); GameTooltip:Hide() end)
    reload:SetScript("OnMouseDown", function(owner)
        if owner:IsEnabled() then arrowFace:SetAtlas("common-dropdown-a-button-pressed", true) end
    end)
    reload:SetScript("OnMouseUp", function() RefreshReload(true) end)
    RefreshReload(false)
    picker:SetScript("OnClick", function()
        arrow:OpenMenu()
    end)
    arrow:HookScript("OnEnter", picker:GetScript("OnEnter"))
    arrow:HookScript("OnLeave", picker:GetScript("OnLeave"))

    panel.templates = Dropdown(panel, 40, -3, 212, L.SAVED_TALENT_BUILDS, function(_, root)
        local spec = self.draft and self.draft.spec or T:GetPlayerSpec()
        if not self:HasSavedTemplates(spec) then root:CreateTitle(L.NO_TALENT_BUILDS); return end
        local builds = self:ListTemplates(spec)
        for _, entry in ipairs(builds) do
            local name = entry
            root:CreateRadio(self:TemplateName(name), function() return self.selected == name end, function()
                self:ConfirmDiscard(function() self:Result(self:PreviewTemplate(name)) end)
            end)
        end
        if #builds == 0 then root:CreateTitle(L.NO_TALENT_BUILDS) end
    end)
    panel.name = Edit(panel, 268, -3, 156)
    panel.name:SetMaxLetters(80)
    panel.name:SetScript("OnEnterPressed", function(owner) owner:ClearFocus(); self:SaveNamedBuild() end)
    panel.name:SetScript("OnEnter", function(owner) Tooltip(owner, L.TALENT_BUILD_NAME) end)
    panel.name:SetScript("OnLeave", function() GameTooltip:Hide() end)
    panel.save = IconButton(panel, 442, "Interface\\Icons\\INV_Misc_Note_05", L.SAVE_AS_A_NEW_TALENT_BUILD, L.SAVE_THE_CURRENT_TALENT_BUILD_USING_THE_ENTERED_NAME, function() self:Result(self:SaveTemplate(panel.name:GetText(), false)) end)
    panel.update = IconButton(panel, 474, "Interface\\Icons\\INV_Misc_EngGizmos_19", L.UPDATE, L.OVERWRITE_THE_SELECTED_SAVED_TALENT_BUILD_WITH_THE_CURRENT_PLAN, function() self:Result(self:SaveTemplate(panel.name:GetText(), true)) end)
    panel.delete = IconButton(panel, 506, "Interface\\Icons\\Ability_Rogue_FeignDeath", L.DELETE_TALENT_BUILD, L.DELETE_THE_SELECTED_SAVED_TALENT_BUILD, function()
        local name = self.selected
        if name then StaticPopup_Show("YTALENTS_CONFIRM", L.DELETE_TALENT_BUILD_2 .. name .. L.TEXT, nil,
            function() self:Result(self:DeleteTemplate(name)) end) end
    end)
    panel.clear = IconButton(panel, 538, nil, L.RESET_ALL_TALENT_TREES, L.REMOVE_ALL_TALENT_POINTS_FROM_THIS_PLAN, function()
        local draft = self.draft
        StaticPopup_Show("YTALENTS_CONFIRM", L.RESET_ALL_TALENT_POINTS_IN_ALL_THREE_TALENT_TREES, nil, function()
            if self.draft == draft then self:Result(self:ClearBuild()) end
        end)
    end)
    panel.clear:SetScript("OnEnter", function(owner)
        Tooltip(owner, L.RESET_ALL_TALENT_TREES, L.REMOVE_ALL_TALENT_POINTS_FROM_THIS_PLAN)
    end)
    panel.stage = IconButton(panel, 570, "Interface\\Icons\\Spell_Holy_MagicalSentry", L.PREPARE_TALENTS, L.PREPARE_YOUR_TALENT_BUILD_THEN_REVIEW_IT_AND_CONFIRM_IT_WITH_THE_GAME_S_APPLY_BUTTON, function()
        local ok, message = self:StageBuild()
        self:Result(ok, message, true)
    end)
    panel.saved = Label(panel, L.SAVED_INDICATOR, 606, -7, "GameFontHighlightSmall")
    panel.saved:ClearAllPoints()
    panel.saved:SetPoint("LEFT", panel, "LEFT", 606, 0)
    panel.saved:SetHeight(20)
    panel.saved:SetWordWrap(false)
    panel.saved:SetTextColor(0.2, 1, 0.2)
    panel.pointsBox = CreateFrame("Frame", nil, panel)
    panel.pointsBox:SetPoint("RIGHT", canvas, "TOPRIGHT", -20, -29)
    panel.pointsBox:SetSize(140, 40)
    -- Stretch only the middle of Blizzard's remaining-points artwork. Keep
    -- its original beveled corners and colors, rather than an input-box rim.
    local box = panel.pointsBox
    box.border = CreateFrame("Frame", nil, box)
    box.border:SetAllPoints(box)
    local atlas = C_Texture and C_Texture.GetAtlasInfo("Talents-Square-Box-c60")
    local probe = box.border:CreateTexture(nil, "ARTWORK")
    probe:SetAtlas("Talents-Square-Box-c60", false)
    local file = probe:GetTexture() or (atlas and (atlas.file or atlas.fileID or atlas.filename))
    probe:Hide()
    box:SetHeight(atlas and atlas.height or 40)
    local l, r, t, b = atlas and atlas.leftTexCoord or 0, atlas and atlas.rightTexCoord or 1,
        atlas and atlas.topTexCoord or 0, atlas and atlas.bottomTexCoord or 1
    -- GetTexCoord on an atlas texture can describe local 0..1 coordinates.
    -- After SetTexture, the UVs must instead address the atlas's actual sheet.
    local cap = 10
    local sourceWidth = atlas and atlas.width or 48
    -- Exclude the label gutter and its four-unit gap before the square rim.
    local labelSpace = sourceWidth > 80 and 64 or 0
    l = l + (r-l) * labelSpace / sourceWidth
    local fraction = cap / (sourceWidth - labelSpace)
    -- Use fresh raw textures for every slice. Reusing the atlas probe keeps
    -- its atlas mapping and can apply the sheet coordinates twice.
    local pieces = {box.border:CreateTexture(nil, "ARTWORK"),
        box.border:CreateTexture(nil, "ARTWORK"), box.border:CreateTexture(nil, "ARTWORK")}
    for _, piece in ipairs(pieces) do piece:SetTexture(file); piece:SetVertexColor(1, 1, 1) end
    -- Mirror the clean right cap, avoiding the atlas's label-gutter artwork.
    pieces[1]:SetTexCoord(r, r - (r-l)*fraction, t, b)
    -- Stretch a narrow straight segment beside the right cap. A wider
    -- sample includes the original left rim, producing a second vertical bar.
    local pixel = (atlas and (atlas.rightTexCoord - atlas.leftTexCoord) or 1) / sourceWidth
    local straightRight = r - (r-l)*fraction
    pieces[2]:SetTexCoord(straightRight - 2*pixel, straightRight - pixel, t, b)
    pieces[3]:SetTexCoord(r - (r-l)*fraction, r, t, b)
    pieces[1]:SetPoint("TOPLEFT", box, "TOPLEFT"); pieces[1]:SetPoint("BOTTOMLEFT", box, "BOTTOMLEFT"); pieces[1]:SetWidth(cap)
    pieces[3]:SetPoint("TOPRIGHT", box, "TOPRIGHT"); pieces[3]:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT"); pieces[3]:SetWidth(cap)
    pieces[2]:SetPoint("TOPLEFT", pieces[1], "TOPRIGHT")
    pieces[2]:SetPoint("BOTTOMRIGHT", pieces[3], "BOTTOMLEFT")
    box.border.Left, box.border.Middle, box.border.Right = pieces[1], pieces[2], pieces[3]
    box.backing = box.border:CreateTexture(nil, "BACKGROUND", nil, -8)
    box.backing:SetPoint("TOPLEFT", box, "TOPLEFT", 4, -4)
    box.backing:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -4, 4)
    box.backing:SetColorTexture(0.055, 0.045, 0.035, 1)
    box.rows = {}
    local labels = {L.PLANNER_COUNTER_LEVEL_LABEL, L.PLANNER_COUNTER_TALENTS_LABEL}
    for index, text in ipairs(labels) do
        local row = {}
        row.label = box.border:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.label:SetPoint("LEFT", box, "LEFT", 12, 8 - (index - 1) * 16)
        row.label:SetJustifyH("LEFT")
        row.label:SetText(text)
        row.label:SetWordWrap(false)
        row.value = box.border:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.value:SetPoint("RIGHT", box, "RIGHT", -12, 8 - (index - 1) * 16)
        row.value:SetJustifyH("RIGHT")
        row.value:SetWordWrap(false)
        box.rows[index] = row
    end
    -- Reserve the widest two-digit summary once, independent of this build.
    local measure = box.border:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    measure:SetText("51 / 51 (51)")
    local labelWidth = math.max(box.rows[1].label:GetStringWidth(), box.rows[2].label:GetStringWidth())
    box:SetWidth(math.max(140, labelWidth + measure:GetStringWidth() + 28))
    measure:Hide()
    panel.saved:SetPoint("RIGHT", box, "LEFT", -12, 0)
    panel.pointSummary = box.rows[2].value
    box:EnableMouse(true)
    box:SetScript("OnEnter", function(owner)
        Tooltip(owner, L.PLANNER_COUNTER_TITLE, L.PLANNER_COUNTER_EXPLANATION)
    end)
    box:SetScript("OnLeave", function() GameTooltip:Hide() end)
    panel.name:SetScript("OnTextChanged", function() self:RefreshSavedIndicator(); self:RefreshActionButtons() end)

    panel.formats = Dropdown(footer, 0, -3, 185, L.WOW_FOREVER_CODE, function(_, root)
        for _, item in ipairs(self.exportFormats) do
            local key, title = item.key, item.title
            root:CreateRadio(title, function() return (self.exportFormat or "native") == key end, function()
                self.exportFormat = key; panel.code:ClearFocus(); self:RefreshPanel()
            end)
        end
    end)
    panel.code = Edit(footer, 205, -3, 830)
    panel.code:SetMaxLetters(16000); panel.code:SetMultiLine(false)
    panel.code:SetScript("OnEnterPressed", function() self:ImportFromField() end)
    panel.code:SetScript("OnTextChanged", function() self:RefreshActionButtons() end)
    panel.importBuild = IconButton(footer, 1048, "Interface\\Icons\\Spell_Arcane_PortalStormWind", L.IMPORT, L.IMPORT_THE_CODE_OR_TALENT_CALCULATOR_LINK_FROM_THIS_FIELD_PRESSING_ENTER_DOES_THE_SAM, function() self:ImportFromField() end)
    panel.copyCode = IconButton(footer, 1080, "Interface\\Icons\\INV_Misc_Book_09", L.COPY, L.COPY_THIS_TALENT_BUILD_IN_THE_SELECTED_EXPORT_FORMAT, function() self:CopyBuildText() end)
    panel.shareBuild = IconButton(footer, 1112, "Interface\\Icons\\INV_Letter_15", L.SHARE, L.WHISPER_A_CLICKABLE_TALENT_BUILD_LINK_TO_YOUR_FRIENDLY_PLAYER_TARGET_OR_ENTER_A_RECIP, function() self:ShareBuild() end)
    -- Anchor to the actual footer edge, allowing the edit box to fill the gap.
    panel.shareBuild:ClearAllPoints(); panel.shareBuild:SetPoint("RIGHT", footer, "RIGHT", 0, 0)
    panel.copyCode:ClearAllPoints(); panel.copyCode:SetPoint("RIGHT", panel.shareBuild, "LEFT", -6, 0)
    panel.importBuild:ClearAllPoints(); panel.importBuild:SetPoint("RIGHT", panel.copyCode, "LEFT", -6, 0)
    panel.code:ClearAllPoints()
    panel.code:SetPoint("LEFT", footer, "LEFT", 205, 0)
    panel.code:SetPoint("RIGHT", panel.importBuild, "LEFT", -12, 0)
    panel.code:SetScript("OnEnter", function(owner) Tooltip(owner, L.IMPORT_EXPORT, L.PASTE_A_CODE_OR_TALENT_CALCULATOR_LINK_AND_PRESS_ENTER_TO_IMPORT_SELECT_THE_TEXT_AND) end)
    panel.code:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.treeResets = {}
    for i = 1, 3 do
        local index = i
        local reset = IconButton(canvas, 0, nil, L.RESET_TALENT_TREE, L.RESET_ONLY_THIS_TALENT_TREE_THE_OTHER_TWO_ARE_PRESERVED, nil)
        reset:ClearAllPoints()
        reset:SetSize(24, 24)
        reset:SetFrameLevel(panel:GetFrameLevel())
        reset:SetPoint("TOPRIGHT", canvas.trees[i], "TOPRIGHT", -6, -6)
        reset:SetScript("OnClick", function()
            local draft = self.draft
            StaticPopup_Show("YTALENTS_CONFIRM", L.RESET_TALENTS_IN .. self:PlanTreeName(index), nil, function()
                -- A different plan may have been opened while the prompt was visible.
                if self.draft == draft then self:Result(self:ClearTree(index)) end
            end)
        end)
        reset:SetScript("OnEnter", function(owner) Tooltip(owner, L.RESET_TALENT_TREE, L.RESET_ONLY_THIS_TALENT_TREE_THE_OTHER_TWO_ARE_PRESERVED) end)
        reset:SetScript("OnLeave", function() GameTooltip:Hide() end)
        self.treeResets[i] = reset
    end
    panel:Hide()
end


function T:Open()
    if not self.db or not self.db.enabled then self:Message(L.ENABLE_YTALENTS_IN_THE_ADDON_OPTIONS_FIRST, false); return end
    local ok, err = self:OpenNative()
    if not ok then self:Message(err, false, false); return end
    self:EnterPlannerTab()
end

function T:RegisterSettings()
    if self.category or not Settings or not Settings.RegisterCanvasLayoutCategory then return end
    local optionsTitle = "|cff4b7dccy|rTalents"
    local panel = CreateFrame("Frame")
    panel:SetSize(700, 560)
    Label(panel, optionsTitle, 32, -24, "GameFontNormalLarge")
    local enabled = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    enabled:SetSize(18,18)
    enabled:SetNormalAtlas("questlog-icon-ticksquare")
    enabled:GetCheckedTexture():SetAtlas("questlog-icon-checkmark-yellow")
    enabled:GetNormalTexture():SetAllPoints(enabled)
    enabled:GetCheckedTexture():SetAllPoints(enabled)
    local pushed=enabled:GetPushedTexture();if pushed then pushed:SetAlpha(0) end
    enabled:SetPoint("TOPLEFT", 400, -18)
    local enabledText = enabled:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    enabledText:SetPoint("LEFT", enabled, "RIGHT", 2, 0)
    enabledText:SetText(string.format(L.ENABLE_ADDON, T.title))
    enabled:SetScript("OnClick", function(owner) self:SetEnabled(owner:GetChecked()) end)
    local description = Label(panel, L.OPTIONS_DESCRIPTION, 32, -80, "GameFontHighlight")
    description:SetWidth(600)
    local details = Label(panel, L.SAVED_TALENT_BUILDS_ARE_AVAILABLE_TO_ALL_CHARACTERS_ON_THIS_ACCOUNT_PLANNING_DOES_NOT, 32, -122, "GameFontHighlight")
    details:SetWidth(600)
    local open = Button(panel, L.OPEN_TALENT_PLANNER, 32, -245, 160, function()
        if SettingsPanel then HideUIPanel(SettingsPanel) end
        if GameMenuFrame then HideUIPanel(GameMenuFrame) end
        C_Timer.After(0, function() self:Open() end)
    end)
    open:ClearAllPoints()
    open:SetPoint("TOPLEFT", details, "BOTTOMLEFT", 0, -32)
    panel.RefreshForm = function()
        enabled:SetChecked(self.db.enabled)
        description:SetShown(self.db.enabled)
        details:SetShown(self.db.enabled)
        open:SetShown(self.db.enabled)
    end
    panel:SetScript("OnShow", panel.RefreshForm)
    panel.RefreshForm()
    self.settingsPanel = panel
    self.category = Settings.RegisterCanvasLayoutCategory(panel, optionsTitle)
    Settings.RegisterAddOnCategory(self.category)
end
