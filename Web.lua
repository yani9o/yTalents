local _, localization = ...
local L = localization.L
local _, T = ...

T.exportFormats = {
    { key = "native", title = "WoW - Forever" },
    { key = "tf", title = "talentsforever.com" },
    { key = "wowhead", title = "wowhead.com" },
    { key = "wt", title = "warcrafttavern.com" },
}

local function Split(text, separator)
    local result = {}
    for item in (text .. separator):gmatch("(.-)" .. separator) do result[#result + 1] = item end
    return result
end

-- Talents Forever v7 (build 70425): ordered positions, matched to the
-- displayed live tree rather than obsolete calculator node IDs.
local tfLayout = {["warrior"]={{{0,0},{0,1},{0,2},{1,0},{1,1},{1,3},{2,1},{2,2},{3,0},{3,1},{3,2},{4,0},{4,1},{4,2},{5,0},{5,2},{6,1}},{{0,1},{0,2},{1,1},{1,2},{2,0},{2,1},{2,2},{3,0},{3,1},{3,2},{3,3},{4,0},{4,1},{4,3},{5,1},{5,2},{6,1}},{{0,0},{0,1},{0,2},{1,0},{1,2},{1,3},{2,0},{2,1},{2,2},{2,3},{3,0},{3,1},{3,2},{4,0},{4,1},{4,2},{5,2},{6,1}}},["paladin"]={{{0,1},{0,2},{1,0},{1,1},{1,2},{1,3},{2,0},{2,1},{2,2},{3,0},{3,1},{3,2},{4,0},{4,1},{4,2},{5,2},{6,1}},{{0,1},{0,2},{1,0},{1,1},{1,3},{2,0},{2,1},{2,2},{2,3},{3,0},{3,1},{3,2},{4,1},{4,2},{5,2},{6,1}},{{0,1},{0,2},{1,0},{1,1},{1,2},{2,0},{2,1},{2,2},{2,3},{3,0},{3,2},{4,0},{4,1},{4,2},{5,1},{5,2},{6,1}}},["hunter"]={{{0,1},{0,2},{1,0},{1,1},{1,2},{1,3},{2,1},{2,2},{3,0},{3,2},{3,3},{4,0},{4,1},{4,3},{5,2},{6,1}},{{0,0},{0,1},{0,2},{1,0},{1,1},{1,2},{2,0},{2,1},{2,3},{3,1},{3,2},{4,0},{4,2},{4,3},{5,2},{6,1}},{{0,1},{0,2},{1,0},{1,1},{1,2},{1,3},{2,0},{2,1},{2,2},{3,0},{3,1},{3,2},{4,0},{4,1},{4,2},{4,3},{5,2},{6,1}}},["rogue"]={{{0,0},{0,1},{0,2},{1,0},{1,1},{1,3},{2,0},{2,1},{2,2},{3,0},{3,1},{3,2},{4,0},{4,1},{4,2},{5,2},{6,1}},{{0,0},{0,1},{0,2},{1,0},{1,1},{1,2},{2,0},{2,1},{2,3},{3,0},{3,1},{3,2},{4,1},{4,2},{5,1},{5,2},{6,1}},{{0,0},{0,1},{0,2},{1,0},{1,1},{1,2},{1,3},{2,0},{2,1},{2,2},{3,0},{3,1},{3,2},{4,0},{4,1},{4,2},{5,0},{5,2},{6,1}}},["priest"]={{{0,0},{0,1},{0,2},{1,0},{1,1},{1,2},{1,3},{2,0},{2,1},{2,2},{2,3},{3,0},{3,1},{3,2},{4,1},{4,2},{5,2},{6,1}},{{0,0},{0,1},{0,2},{1,1},{1,2},{2,0},{2,1},{2,3},{3,0},{3,1},{3,2},{3,3},{4,0},{4,1},{4,2},{5,2},{6,1}},{{0,0},{0,1},{0,2},{1,0},{1,2},{1,3},{2,1},{2,2},{2,3},{3,0},{3,1},{3,2},{4,0},{4,2},{5,0},{5,2},{6,1}}},["shaman"]={{{0,1},{0,2},{1,0},{1,1},{1,2},{1,3},{2,0},{2,1},{3,0},{3,1},{3,3},{4,0},{4,1},{4,2},{5,2},{6,1}},{{0,0},{0,1},{0,2},{1,0},{1,1},{1,2},{1,3},{2,0},{2,2},{2,3},{3,0},{3,1},{3,2},{4,0},{4,1},{4,2},{5,2},{6,1}},{{0,1},{0,2},{1,0},{1,1},{1,2},{1,3},{2,0},{2,1},{2,2},{3,0},{3,1},{3,2},{4,1},{4,2},{5,2},{6,1}}},["mage"]={{{0,0},{0,1},{0,2},{0,3},{1,0},{1,1},{1,2},{1,3},{2,0},{2,1},{2,3},{3,0},{3,1},{3,2},{3,3},{4,1},{4,2},{5,2},{6,1}},{{0,0},{0,1},{0,2},{1,0},{1,1},{1,2},{2,0},{2,1},{2,2},{3,0},{3,1},{3,2},{3,3},{4,1},{4,2},{5,2},{6,1}},{{0,0},{0,1},{0,2},{1,0},{1,1},{1,2},{1,3},{2,0},{2,1},{2,2},{2,3},{3,0},{3,1},{3,3},{4,0},{4,1},{4,2},{5,2},{6,1}}},["warlock"]={{{0,0},{0,1},{0,2},{1,0},{1,1},{1,2},{2,0},{2,1},{2,2},{2,3},{3,0},{3,1},{3,2},{4,1},{4,2},{5,2},{6,1}},{{0,0},{0,1},{0,2},{0,3},{1,0},{1,1},{1,2},{1,3},{2,0},{2,1},{2,2},{3,0},{3,2},{3,3},{4,0},{4,1},{4,2},{5,2},{6,1}},{{0,0},{0,1},{0,2},{1,0},{1,1},{1,2},{2,1},{2,2},{3,0},{3,1},{3,2},{4,0},{4,1},{4,2},{5,2},{6,1}}},["druid"]={{{0,1},{0,2},{1,0},{1,1},{1,2},{1,3},{2,0},{2,2},{3,0},{3,1},{3,2},{4,0},{4,1},{4,2},{5,1},{6,1}},{{0,1},{0,2},{1,0},{1,1},{1,2},{1,3},{2,0},{2,1},{2,2},{2,3},{3,0},{3,1},{3,2},{3,3},{4,0},{4,1},{4,3},{5,0},{5,2},{6,1}},{{0,1},{0,2},{1,0},{1,1},{1,2},{2,1},{2,2},{2,3},{3,1},{3,2},{3,3},{4,0},{4,1},{4,3},{5,2},{6,1}}}}

function T:GetCurrentWebMapping()
    local class = self.draft and self:ClassForSpec(self.draft.spec)
    local layout = class and tfLayout[class.token:lower()]
    if not layout then return nil end
    local trees, mapping = self:GetPlanTrees(), {}
    for index, positions in ipairs(layout) do
        mapping[index] = {}
        for _, pos in ipairs(positions) do
            local found
            for _, entry in ipairs(trees[index] or {}) do
                if entry.row == pos[1] and entry.col == pos[2] then found = entry; break end
            end
            mapping[index][#mapping[index] + 1] = found or { id = -1 }
        end
    end
    return mapping
end

function T:SpecForSlug(slug)
    for _, class in ipairs(self.classes) do if class.token:lower() == slug then return class.spec end end
end

function T:ResolveWebNode(id, data)
    local draft = self.draft
    local node = draft.nodes[id]
    if node then return id, node end
    -- Definitions/spells provide a fallback when Blizzard assigns another node ID.
    for _, trees in ipairs(self.webData[self:ClassForSpec(draft.spec).token:lower()].wowhead) do
        for _, web in ipairs(trees) do
            if web.id == id then data = web; break end
        end
    end
    if not data or not data.definition then return nil end
    local config = Constants.TraitConsts.VIEW_TRAIT_CONFIG_ID
    for nodeID, candidate in pairs(draft.nodes) do
        for _, entryID in ipairs(candidate.entryIDs) do
            local entry = C_Traits.GetEntryInfo(config, entryID)
            if entry and entry.definitionID == data.definition then return nodeID, candidate end
        end
    end
end

function T:AssignWebRank(id, rank, data)
    if rank == 0 then return true end
    local nodeID, node = self:ResolveWebNode(id, data)
    if not node then return false, L.A_SELECTED_TALENT_FROM_THE_ONLINE_CALCULATOR_NO_LONGER_EXISTS_IN_THE_GAME_UPDATE_THE end
    if rank > node.maxRanks then return false, L.A_TALENT_S_MAXIMUM_RANK_IN_THE_ONLINE_CALCULATOR_DIFFERS_FROM_THE_GAME end
    self.draft.ranks[nodeID] = rank
    return true
end

function T:ApplyDigitTrees(segments, mapping)
    if #segments > 3 then return false, L.INVALID_TALENT_ALLOCATION_FROM_THE_ONLINE_CALCULATOR end
    for tree = 1, 3 do
        local digits = segments[tree] or ""
        if digits:find("[^0-5]") or #digits > #mapping[tree] then return false, L.INVALID_OR_OUTDATED_TALENT_ALLOCATION_FROM_THE_ONLINE_CALCULATOR end
        for i = 1, #digits do
            local talent = mapping[tree][i]
            local id = type(talent) == "table" and talent.id or talent
            local ok, err = self:AssignWebRank(id, tonumber(digits:sub(i, i)), type(talent) == "table" and talent or nil)
            if not ok then return false, err end
        end
    end
    return true
end

function T:ImportText(text)
    text = (text or ""):match("^%s*(.-)%s*$")
    text = text:gsub("%%(%x%x)", function(hex) return string.char(tonumber(hex, 16)) end)
    local host, path = text:match("^https?://([^/]+)/(.+)$")
    if not host then return self:ImportCode(text) end
    host = host:lower():gsub("^www%.", "")
    if host == "wowhead.com" then
        local native = path:match("forever/talent%-calc/blizzard/([^?#/]+)")
        if native then return self:ImportCode(native) end
    end
    local slug, allocation, format, level, mapping
    if host == "talentsforever.com" then
        slug, level, allocation = path:match("^([a-z]+)/(%d+)/([^?#/]+)")
        format = "tf"
    elseif host == "wowhead.com" then
        slug, allocation = path:match("forever/talent%-calc/([a-z]+)/([^/?#]+)")
        format = "wowhead"
    elseif host == "warcrafttavern.com" then
        slug = path:match("^forever/tools/talent%-calculator/([a-z]+)")
        allocation = path:match("[?&]t=([^&#]*)")
        format = "wt"
    else
        return false, L.USE_A_WOW_FOREVER_TALENT_CALCULATOR_LINK_FROM_TALENTS_FOREVER_WOWHEAD_OR_WARCRAFT_TAV
    end
    local spec = slug and self:SpecForSlug(slug)
    if not spec or not allocation then return false, L.THIS_TALENT_CALCULATOR_LINK_CONTAINS_NO_USABLE_TALENT_BUILD end
    local oldDraft, oldSelected, oldDirty = self.draft, self.selected, self.dirty
    -- Prepare metadata without rendering an empty build over the current preview.
    local tree = C_ClassTalents.GetTraitTreeForSpec(spec)
    if not tree then return false, L.THIS_CLASS_S_TALENT_DATA_IS_UNAVAILABLE end
    C_ClassTalents.InitializeViewLoadout(spec, 60)
    self.draft = { spec = spec, tree = tree, level = 60, content = {} }
    local readOK = pcall(self.ReadDraftNodes, self)
    if not readOK then
        self.draft = oldDraft
        if oldDraft and self.planning then self:RenderDraft(false) end
        return false, L.TALENT_DATA_IS_UNAVAILABLE_TRY_AGAIN
    end
    local data = self.webData[slug]
    local ok, err
    if format == "tf" then
        local segments = Split(allocation, "-")
        local last, version = tonumber(segments[#segments]), 1
        if #segments > 3 and last and last >= 2 and last <= 7 then version = last end
        mapping = version == 7 and self:GetCurrentWebMapping() or (version == 6 and data.tf or data.old[version == 2 and 3 or version])
        if not mapping then ok, err = false, L.THIS_VERSION_OF_THE_ONLINE_CALCULATOR_IS_UNSUPPORTED else ok, err = self:ApplyDigitTrees({ segments[1], segments[2], segments[3] }, mapping) end
    elseif format == "wowhead" then
        allocation = allocation:match("^([^_]+)") or ""
        if allocation:sub(1, 2) ~= "v2" then ok, err = false, L.OPEN_THIS_OLD_WOWHEAD_LINK_ON_THE_WEBSITE_AND_COPY_THE_UPDATED_WOW_FOREVER_LINK
        else ok, err = self:ApplyDigitTrees(Split(allocation:sub(3), "-"), data.wowhead) end
    else
        ok = true
        local treeIndex
        for i = 1, #allocation do
            local char = allocation:sub(i, i)
            if char == "A" or char == "B" or char == "C" then treeIndex = char:byte() - 64
            elseif treeIndex and char:match("[0-9a-z]") then
                local value = tonumber(char, 36)
                local row, col = math.floor(value / 4), value % 4
                local talent
                for _, entry in ipairs(self:GetPlanTrees()[treeIndex] or {}) do if entry.row == row and entry.col == col then talent = entry; break end end
                if not talent then ok, err = false, L.UNKNOWN_TALENT_POSITION_IN_THE_WARCRAFT_TAVERN_CALCULATOR; break end
                local nodeID = self:ResolveWebNode(talent.id)
                local rank = nodeID and self.draft.ranks[nodeID] or 0
                ok, err = self:AssignWebRank(talent.id, rank + 1)
                if not ok then break end
            else ok, err = false, L.INVALID_TALENT_CODE_FROM_WARCRAFT_TAVERN; break end
        end
    end
    if ok then
        level = tonumber(level) or 60
        if level < 10 or level > 60 then ok, err = false, L.PLANNING_SUPPORTS_LEVELS_10_60_LEGACY_BONUSES_ARE_NOT_PART_OF_THIS_EDITOR
        elseif self:PointCount() > level - 9 then ok, err = false, L.THIS_TALENT_ALLOCATION_USES_MORE_POINTS_THAN_ARE_AVAILABLE_AT_THE_SPECIFIED_LEVEL end
    end
    if not ok then
        self.draft, self.selected, self.dirty = oldDraft, oldSelected, oldDirty
        if oldDraft and self.planning then self:RenderDraft(false) end
        return false, err
    end
    self.draft.level = 60
    self.draft.code = self:EncodeDraft(self.draft)
    self.selected, self.newSpec = nil, spec
    self:ResetDraftBaseline()
    return true, L.TALENTS_IMPORTED_LEGACY_BONUSES_AND_LEVELING_ORDER_ARE_NOT_IMPORTED
end

function T:GetExportText(format)
    local draft = self.draft
    if not draft then return "" end
    format = format or self.exportFormat or "native"
    if format == "native" then return draft.code or "" end
    if not draft.nodes then
        local ok = pcall(self.ReadDraftNodes, self)
        if not ok then return nil, L.TALENT_DATA_IS_UNAVAILABLE_TRY_AGAIN end
    end
    local slug = self:ClassForSpec(draft.spec).token:lower()
    local data = self.webData[slug]
    -- Wowhead accepts Blizzard's full serialization, including newly added
    -- talents that its separate digit mapping may not yet contain.
    if format == "wowhead" then
        return "https://www.wowhead.com/forever/talent-calc/blizzard/" .. draft.code
    end
    local segments, represented = {}, {}
    if format == "tf" or format == "wowhead" then
        local mapping = format == "tf" and self:GetCurrentWebMapping() or data.wowhead
        if not mapping then return nil, L.TALENT_DATA_IS_UNAVAILABLE_TRY_AGAIN end
        for _, tree in ipairs(mapping) do
            local digits = ""
            for _, talent in ipairs(tree) do
                local id = type(talent) == "table" and talent.id or talent
                local nodeID = self:ResolveWebNode(id, type(talent) == "table" and talent or nil)
                if nodeID then represented[nodeID] = true end
                digits = digits .. tostring(nodeID and draft.ranks[nodeID] or 0)
            end
            segments[#segments + 1] = digits:gsub("0+$", "")
        end
    else
        -- Warcraft Tavern records point-by-point order, not just final ranks.
        local encoded = ""
        for index, tree in ipairs(self:GetPlanTrees()) do
            local owned, targets, byID = {}, {}, {}
            for i, talent in ipairs(tree) do
                local nodeID = self:ResolveWebNode(talent.id)
                if nodeID then represented[nodeID] = true end
                targets[i], owned[i], byID[talent.id] = nodeID and draft.ranks[nodeID] or 0, 0, i
            end
            local added, left = "", 0
            for _, rank in ipairs(targets) do left = left + rank end
            while left > 0 do
                local progress = false
                for i, talent in ipairs(tree) do
                    local lowerPoints = 0
                    for j, other in ipairs(tree) do if other.row < talent.row then lowerPoints = lowerPoints + owned[j] end end
                    local req = byID[talent.req]
                    local required = req and (talent.reqRank > 0 and talent.reqRank or tree[req].max) or 0
                    if owned[i] < targets[i] and lowerPoints >= talent.row * 5 and (not req or owned[req] >= required) then
                        local position = talent.row * 4 + talent.col
                        local char = position < 10 and tostring(position) or string.char(position + 87)
                        added = added .. char
                        owned[i], left, progress = owned[i] + 1, left - 1, true
                    end
                end
                if not progress then return nil, L.THIS_TALENT_BUILD_DOES_NOT_MEET_WARCRAFT_TAVERN_S_TALENT_PREREQUISITES end
            end
            if added ~= "" then encoded = encoded .. string.char(index + 64) .. added end
        end
        segments = { encoded }
    end
    for id, rank in pairs(draft.ranks or {}) do
        if rank > 0 and not represented[id] then return nil, L.A_SELECTED_TALENT_IS_MISSING_FROM_THIS_ONLINE_CALCULATOR_S_CURRENT_DATA end
    end
    if format == "tf" then return "https://talentsforever.com/" .. slug .. "/" .. draft.level .. "/" .. table.concat(segments, "-") .. "-7" end
    if format == "wowhead" then return "https://www.wowhead.com/forever/talent-calc/" .. slug .. "/v2" .. table.concat(segments, "-"):gsub("-+$", "") .. "_t0" end
    return "https://www.warcrafttavern.com/forever/tools/talent-calculator/" .. slug .. "#?t=" .. segments[1]
end
