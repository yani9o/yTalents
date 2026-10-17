local _, localization = ...
local L = localization.L
local _, T = ...
_G.yTalents = T
_G.TalentedForever = T
T.title = "|cff4b7dccy|r|cffffffffTalents|r"
T.currentBuildKey = "\001current"
T.currentBuildName = L.CURRENT_TALENTS
T.classes = {
    { id = 1, token = "WARRIOR", spec = 1491 },
    { id = 2, token = "PALADIN", spec = 1486 },
    { id = 3, token = "HUNTER", spec = 1485 },
    { id = 4, token = "ROGUE", spec = 1488 },
    { id = 5, token = "PRIEST", spec = 1487 },
    { id = 7, token = "SHAMAN", spec = 1489 },
    { id = 8, token = "MAGE", spec = 1482 },
    { id = 9, token = "WARLOCK", spec = 1490 },
    { id = 11, token = "DRUID", spec = 1484 },
}

function T:GetPlayerSpec()
    local spec = PlayerUtil and PlayerUtil.GetCurrentSpecID and PlayerUtil.GetCurrentSpecID()
    if self:ClassForSpec(spec) then return spec end
    local _, token = UnitClass("player")
    for _, class in ipairs(self.classes) do
        if class.token == token then return class.spec end
    end
    return spec
end

function T:HasSavedTemplates(spec)
    for _, template in pairs(self.db.templates) do
        if type(template) == "table" and type(template.code) == "string"
            and (not spec or template.spec == spec) then return true end
    end
    return false
end

function T:ClassForSpec(spec)
    for _, class in ipairs(self.classes) do
        if class.spec == spec then return class end
    end
end

function T:ClassName(spec)
    local class = self:ClassForSpec(spec)
    return class and ((LOCALIZED_CLASS_NAMES_MALE or {})[class.token] or class.token) or tostring(spec)
end

function T:InitializeDB()
    -- Also migrate copied legacy SavedVariables files on the first load.
    yTalentsDB = type(yTalentsDB) == "table" and yTalentsDB
        or (type(TalentedForeverDB) == "table" and TalentedForeverDB or {})
    self.db = yTalentsDB
    self.db.templates = type(self.db.templates) == "table" and self.db.templates or {}
    self.db.enabled = self.db.enabled ~= false
    self.db.version = 1
    self.db.taintDiagnostics = nil -- discard the temporary troubleshooting report
    yTalentsCharacterDB = type(yTalentsCharacterDB) == "table" and yTalentsCharacterDB
        or (type(TalentedForeverCharacterDB) == "table" and TalentedForeverCharacterDB or {})
    self.characterDB = yTalentsCharacterDB
end

function T:Message(message, success, chat)
    if self.ShowStatus then self:ShowStatus(message, success) end
    if chat and message and message ~= "" then print(self.title .. ": " .. message) end
end

function T:GetTemplate(name)
    if name == self.currentBuildKey then return self.characterDB and self.characterDB.currentTalents end
    return self.db.templates[name]
end

function T:TemplateName(name)
    return name == self.currentBuildKey and self.currentBuildName or name
end

function T:ListTemplates(spec)
    local names = {}
    for name, template in pairs(self.db.templates) do
        if type(name) == "string" and type(template) == "table" and type(template.code) == "string" and (not spec or template.spec == spec) then
            names[#names + 1] = name
        end
    end
    table.sort(names, function(a, b) return a:lower() < b:lower() end)
    local current = self:GetTemplate(self.currentBuildKey)
    if current and current.spec == T:GetPlayerSpec() and (not spec or spec == current.spec) then
        table.insert(names, 1, self.currentBuildKey)
    end
    return names
end

function T:ResetDraftBaseline()
    local draft = self.draft
    if draft then
        draft.baselineCode = draft.code
        draft.baselineAllocation = draft.nodes and self:EncodeDraft(draft) or nil
    end
    self.dirty = false
end

function T:UpdateDraftDirty()
    local draft = self.draft
    if not draft then self.dirty = false; return false end
    if draft.baselineAllocation and draft.nodes then
        self.dirty = self:EncodeDraft(draft) ~= draft.baselineAllocation
    elseif draft.baselineCode then
        self.dirty = draft.code ~= draft.baselineCode
    end
    return self.dirty
end

function T:SaveTemplate(name, overwrite)
    name = (name or ""):match("^%s*(.-)%s*$")
    if name == "" then return false, L.ENTER_A_NAME_FOR_THE_TALENT_BUILD end
    if name == self.currentBuildKey or name == self.currentBuildName then
        return false, L.CHOOSE_A_NEW_NAME_FOR_YOUR_COPY
    end
    if overwrite and self.selected == self.currentBuildKey then
        return false, L.CURRENT_TALENTS_UPDATE_AUTOMATICALLY_SAVE_YOUR_CHANGES_AS_A_NEW_TALENT_BUILD
    end
    if #name > 80 then return false, L.NAMES_MUST_BE_AT_MOST_80_CHARACTERS_LONG end
    if not self.draft then return false, L.OPEN_A_TALENT_BUILD_FIRST end
    local previous = overwrite and self.selected or nil
    if overwrite and (not previous or not self.db.templates[previous]) then return false, L.SELECT_A_SAVED_TALENT_BUILD_FIRST end
    if self.db.templates[name] and (not overwrite or name ~= previous) then
        return false, L.A_TALENT_BUILD_WITH_THIS_NAME_ALREADY_EXISTS_CHOOSE_ANOTHER_NAME
    end
    if previous and previous ~= name then self.db.templates[previous] = nil end
    self.db.templates[name] = { code = self.draft.code, spec = self.draft.spec, level = self.draft.level }
    self.selected = name
    self:ResetDraftBaseline()
    if self.FlashSaved then self:FlashSaved(overwrite) end
    return true, overwrite and L.TALENT_BUILD_UPDATED or L.TALENT_BUILD_SAVED
end

function T:LoadTemplate(name)
    local template = self:GetTemplate(name)
    if not template then return false, L.TALENT_BUILD_NOT_FOUND end
    local ok, err = self:ImportCode(template.code, template.level)
    if ok then
        self.selected = name; self.dirty = false
        if self.panel then self.panel.name:SetText(name ~= self.currentBuildKey and self:TemplateName(name) or "") end
    end
    return ok, err
end

function T:DeleteTemplate(name)
    if name == self.currentBuildKey then return false, L.CURRENT_TALENTS_CANNOT_BE_DELETED end
    if not self.db.templates[name] then return false, L.TALENT_BUILD_NOT_FOUND end
    if InCombatLockdown() then return false, L.EDIT_THE_TALENT_BUILD_AFTER_COMBAT end
    -- Load the player's own talents before dropping the saved build.
    local ok, err = self:CaptureCurrent()
    if not ok then return false, err end
    self.db.templates[name] = nil
    return true, L.TALENT_BUILD_DELETED
end

-- Build strings are the game's own serialization, not WotLK's class/index codes.
function T:DecodeCode(text)
    text = (text or ""):gsub("%s+", "")
    if text == "" or #text > 16000 or text:find("[^%w+/=]") then
        return nil, L.PASTE_A_TALENT_CODE_FROM_WOW_FOREVER
    end
    local frame = self:GetNativeFrame()
    if not frame then return nil, L.THE_GAME_S_TALENT_WINDOW_IS_UNAVAILABLE end
    local stream = ExportUtil.MakeImportDataStream(text)
    local valid, version, spec, hash = frame:ReadLoadoutHeader(stream)
    if not valid or version ~= C_Traits.GetLoadoutSerializationVersion() then
        return nil, L.INVALID_OR_OUTDATED_TALENT_CODE_WOTLK_CODES_ARE_INCOMPATIBLE
    end
    if not self:ClassForSpec(spec) then return nil, L.THIS_IS_NOT_A_WOW_FOREVER_CLASS_TALENT_BUILD end
    local tree = C_ClassTalents.GetTraitTreeForSpec(spec)
    if not tree then return nil, L.THIS_CLASS_S_TALENT_DATA_IS_UNAVAILABLE end
    if stream:GetNumberOfBits() < frame.bitWidthHeaderVersion + frame.bitWidthSpecID + 128 + #C_Traits.GetTreeNodes(tree) then
        return nil, L.THE_TALENT_CODE_IS_INCOMPLETE
    end
    if not frame:IsHashEmpty(hash) and not frame:HashEquals(hash, C_Traits.GetTreeHash(tree)) then
        return nil, L.THE_TALENT_TREE_HAS_CHANGED_EXPORT_THIS_TALENT_BUILD_AGAIN
    end
    local content = frame:ReadLoadoutContent(stream, tree)
    return { code = text, spec = spec, tree = tree, content = content, level = 60 }
end

function T:ImportCode(text, level)
    local callOK, draft, err = pcall(self.DecodeCode, self, text)
    if not callOK then return false, L.INVALID_TALENT_CODE_OR_UNAVAILABLE_TALENT_DATA end
    if not draft then return false, err end
    draft.level = 60
    self.draft = draft
    self.newSpec = draft.spec
    self.selected = nil
    self:ResetDraftBaseline()
    return true, L.TALENT_BUILD_LOADED
end

-- Same bit layout as Blizzard's WriteLoadoutContent. Only the local plan is read.
function T:EncodeDraft(draft)
    local frame = self:GetNativeFrame()
    local stream = ExportUtil.MakeExportDataStream()
    frame:WriteLoadoutHeader(stream, C_Traits.GetLoadoutSerializationVersion(), draft.spec, C_Traits.GetTreeHash(draft.tree))
    for _, id in ipairs(draft.order) do
        local node = draft.nodes[id]
        local rank = draft.ranks[id] or 0
        local granted = (node.activeRank or 0) - (node.ranksPurchased or 0) > 0
        local selected = rank > 0 or granted
        local choice = node.type == Enum.TraitNodeType.Selection or node.type == Enum.TraitNodeType.SubTreeSelection
        stream:AddValue(1, selected and 1 or 0)
        if selected then
            stream:AddValue(1, rank > 0 and 1 or 0)
            if rank > 0 then
                local partial = rank ~= node.maxRanks
                stream:AddValue(1, partial and 1 or 0)
                if partial then stream:AddValue(frame.bitWidthRanksPurchased, rank) end
                stream:AddValue(1, choice and 1 or 0)
                if choice then
                    local index = draft.choices[id] or 1
                    stream:AddValue(2, index - 1)
                end
            end
        end
    end
    return stream:GetExportString()
end

function T:ReadDraftNodes()
    local draft = self.draft
    -- Populate the public view-data cache only. Never put PlayerSpellsFrame
    -- into inspection mode: its close handler also updates protected bars.
    C_ClassTalents.InitializeViewLoadout(draft.spec, draft.level or 60)
    local config = Constants.TraitConsts.VIEW_TRAIT_CONFIG_ID
    draft.configID = config
    draft.order = C_Traits.GetTreeNodes(draft.tree)
    draft.nodes, draft.ranks, draft.choices = {}, {}, {}
    for i, id in ipairs(draft.order) do
        local node = C_Traits.GetNodeInfo(config, id)
        if not node then error(L.TALENT_DATA_IS_STILL_LOADING) end
        draft.nodes[id] = node
        local entry = draft.content[i]
        local rank = entry and entry.isNodeSelected and not entry.isNodeGranted
            and (entry.isPartiallyRanked and entry.partialRanksPurchased or node.maxRanks) or 0
        if type(rank) ~= "number" or rank < 0 or rank > node.maxRanks then error(L.INVALID_TALENT_RANK) end
        local index = entry and entry.choiceNodeSelection or 1
        if rank > 0 and not node.entryIDs[index] then error(L.INVALID_TALENT_SELECTION) end
        draft.ranks[id] = rank
        draft.choices[id] = index
    end
    draft.planTrees = nil
end

function T:PointCount()
    local total = 0
    for _, rank in pairs(self.draft and self.draft.ranks or {}) do total = total + rank end
    return total
end

function T:ChangeRank(id, delta)
    if InCombatLockdown() or not self.planning or not self.draft or not self.draft.nodes then return end
    local draft = self.draft
    local node = draft.nodes[id]
    if not node then return end
    local old = draft.ranks[id] or 0
    local rank = math.max(0, math.min(node.maxRanks, old + delta))
    if rank == old then return end
    if delta > 0 and self:PointCount() + rank - old > draft.level - 9 then
        self:Message(L.NO_MORE_TALENT_POINTS_ARE_AVAILABLE_AT_THIS_LEVEL, false)
        return
    end
    -- The click handler must enforce the same rules as the green border.
    -- Preview serialization alone accepts ranks in otherwise locked talents.
    if delta > 0 and not self:CanPlanRank(id, self:GetPlanTrees()) then
        self:Message(L.TALENT_LOCKED_SPEND_POINTS_IN_EARLIER_ROWS_AND_MEET_THE_PREREQUISITE, false)
        return
    end
    local previousRanks = {}
    for nodeID, previous in pairs(draft.ranks) do previousRanks[nodeID] = previous end
    draft.ranks[id] = rank
    if delta < 0 and not self:IsPlanValid() then
        draft.ranks = previousRanks
        self:Message(L.REMOVE_DEPENDENT_TALENTS_FIRST, false)
        return
    end
    local previousCode = draft.code
    draft.code = self:EncodeDraft(draft)
    self:UpdateDraftDirty()
    local ok, err = self:RenderDraft(false)
    if not ok then
        draft.ranks, draft.code = previousRanks, previousCode
        self:RenderDraft(false)
        self:Message(err, false)
    end
end
