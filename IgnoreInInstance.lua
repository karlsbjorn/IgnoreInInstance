---@diagnostic disable: duplicate-set-field, undefined-field
local AceAddon = LibStub("AceAddon-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local addonName = "IgnoreInInstance"
local addon = AceAddon:NewAddon(addonName, "AceEvent-3.0")

local defaultIgnoreList = {}

local function IgnoreCharacter(characterName)
    local numIgnores = C_FriendList.GetNumIgnores()
    for i = 1, numIgnores do
        local ignoreName = C_FriendList.GetIgnoreName(i)
        if ignoreName == characterName then
            return
        end
    end
    C_FriendList.AddIgnore(characterName)
end

local function UnignoreCharacter(characterName)
    local numIgnores = C_FriendList.GetNumIgnores()
    for i = 1, numIgnores do
        local ignoreName = C_FriendList.GetIgnoreName(i)
        if ignoreName == characterName then
            C_FriendList.DelIgnore(characterName)
            print("[IgnoreInInstance] Unignored " .. characterName)
            return
        end
    end
end

local function OnEnterInstance()
    print("[IgnoreInInstance] Ignoring characters.")
    for _, characterName in ipairs(addon.db.profile.ignoreList) do
        IgnoreCharacter(characterName)
    end
end

local function OnLeaveInstance()
    for _, characterName in ipairs(addon.db.profile.ignoreList) do
        UnignoreCharacter(characterName)
    end
end

function addon:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("IgnoreInInstanceDB", { profile = { ignoreList = defaultIgnoreList } }, true)
    self:RegisterEvent("PLAYER_ENTERING_WORLD", self.OnPlayerEnteringWorld)
    self:RegisterEvent("PLAYER_LEAVING_WORLD", self.OnZoneChanged)

    AceConfig:RegisterOptionsTable(addonName, {
        name = "Ignore In Instance",
        type = "group",
        args = {
            ignoreList = {
                name = "Ignored Characters",
                desc = "Characters that are ignored while in an instance.\n\nEach character name should be on a separate line.",
                type = "input",
                multiline = true,
                width = "full",
                get = function(info) return table.concat(addon.db.profile.ignoreList, "\n") end,
                set = function(info, value)
                    local ignoreList = {}
                    for characterName in value:gmatch("[^\r\n]+") do
                        characterName = strtrim(characterName)
                        if characterName ~= "" then
                            table.insert(ignoreList, characterName)
                        end
                    end
                    addon.db.profile.ignoreList = ignoreList
                end,
            }
        }
    })

    AceConfigDialog:AddToBlizOptions(addonName, "Ignore In Instance")
end

function addon:OnPlayerEnteringWorld()
    local isInInstance, instanceType = IsInInstance()
    if isInInstance then
        OnEnterInstance()
    end
end

function addon:OnZoneChanged()
    local isInInstance, instanceType = IsInInstance()
    if isInInstance then
        OnEnterInstance()
    else
        OnLeaveInstance()
    end
end
