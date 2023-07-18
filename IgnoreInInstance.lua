---@diagnostic disable: duplicate-set-field, undefined-field
local AceAddon = LibStub("AceAddon-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local addonName = "IgnoreInInstance"
IgnoreInInstance = AceAddon:NewAddon(addonName, "AceEvent-3.0")

local function IgnoreCharacter(characterName)
    local numIgnores = C_FriendList.GetNumIgnores()
    for i = 1, numIgnores do
        local ignoreName = C_FriendList.GetIgnoreName(i)
        if ignoreName == characterName then return end
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
    for _, characterName in ipairs(IgnoreInInstance.db.profile.ignoreList) do
        if IgnoreInInstance.db.profile.groupCheck then
            local numGroupMembers = GetNumGroupMembers()
            for i = 1, numGroupMembers do
                local name, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
                if name == characterName then
                    IgnoreCharacter(characterName)
                end
            end
        else
            IgnoreCharacter(characterName)
        end
    end
end

local function OnLeaveInstance()
    for _, characterName in ipairs(IgnoreInInstance.db.profile.ignoreList) do
        UnignoreCharacter(characterName)
    end
end

local titleCase = function(phrase)
    local result = string.gsub(phrase, "(%a)([%w_']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end)
    return result
end

function IgnoreInInstance:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("IgnoreInInstanceDB", {
        profile = {
            ignoreList = {},
            groupCheck = false,
            instanceTypes = {
                party = true,
                raid = true,
                pvp = true,
                arena = true
            }
        }
    }, true)
    self:RegisterEvent("PLAYER_ENTERING_WORLD", self.OnPlayerEnteringWorld)
    self:RegisterEvent("PLAYER_LEAVING_WORLD", self.OnZoneChanged)

    AceConfig:RegisterOptionsTable(addonName, {
        name = "Ignore In Instance",
        type = "group",
        args = {
            ignoreList = {
                name = "Ignored Characters",
                desc = "Characters that are ignored while in an instance.\n\n" ..
                    "Each character name should be on a separate line.",
                type = "input",
                multiline = true,
                width = "full",
                get = function(info)
                    return table.concat(IgnoreInInstance.db.profile.ignoreList,
                                        "\n")
                end,
                set = function(info, value)
                    local ignoreList = {}
                    for characterName in value:gmatch("[^\r\n]+") do
                        characterName = strtrim(characterName)
                        characterName = string.gsub(characterName, "%s", "")
                        characterName = titleCase(characterName)
                        if characterName ~= "" then
                            table.insert(ignoreList, characterName)
                        end
                    end
                    IgnoreInInstance.db.profile.ignoreList = ignoreList
                end
            },
            groupCheck = {
                name = "Ignore only if in your group",
                desc = "Only ignore characters if they're in your group.",
                type = "toggle",
                width = "full",
                get = function(info)
                    return IgnoreInInstance.db.profile.groupCheck
                end,
                set = function(info, value)
                    IgnoreInInstance.db.profile.groupCheck = value
                end
            },
            instanceTypes = {
                name = "Instance Types",
                desc = "Select which instance types to ignore in.",
                type = "multiselect",
                values = {
                    party = "Dungeon",
                    raid = "Raid",
                    pvp = "Battleground",
                    arena = "Arena"
                },
                get = function(info, key)
                    return IgnoreInInstance.db.profile.instanceTypes[key]
                end,
                set = function(info, key, value)
                    IgnoreInInstance.db.profile.instanceTypes[key] = value
                end
            }
        }
    })

    AceConfigDialog:AddToBlizOptions(addonName, "Ignore In Instance")
end

-- Helper function to check if a value is in an array, like in Python.
local function isInArray(value, array)
    for _, v in ipairs(array) do if v == value then return true end end
    return false
end

function IgnoreInInstance:OnPlayerEnteringWorld()
    local configInstanceTypes = IgnoreInInstance.db.profile.instanceTypes
    local enabledInstanceTypes = {}
    for instanceType, enabled in pairs(configInstanceTypes) do
        if enabled then table.insert(enabledInstanceTypes, instanceType) end
    end
    local isInInstance, instanceType = IsInInstance()
    if isInInstance and isInArray(instanceType, enabledInstanceTypes) then
        OnEnterInstance()
    end
end

function IgnoreInInstance:OnZoneChanged()
    local configInstanceTypes = IgnoreInInstance.db.profile.instanceTypes
    local enabledInstanceTypes = {}
    for instanceType, enabled in pairs(configInstanceTypes) do
        if enabled then table.insert(enabledInstanceTypes, instanceType) end
    end
    local isInInstance, instanceType = IsInInstance()
    if isInInstance and isInArray(instanceType, enabledInstanceTypes) then
        OnEnterInstance()
    else
        OnLeaveInstance()
    end
end
