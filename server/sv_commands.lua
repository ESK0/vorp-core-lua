-------------------------------------------------------------------------------------------------
--------------------------------------- VORP ADMIN COMMANDS -------------------------------------
-------------------------------------------------------------------------------------------------

local VORPInv = exports.vorp_inventory:vorp_inventoryApi()

local CheckUser = function(target)
    return VorpCore.getUser(tonumber(target)) and true
end

local CheckArgs = function(args, requiered)
    return #args == requiered
end

local function CheckAce(ace, source)
    -- if nil allow commands that don't need permissions
    if not ace then
        return true
    end

    local all = 'vorpcore.showAllCommands'
    local aceAllowed = IsPlayerAceAllowed(source, all)
    if aceAllowed then
        return true
    end

    return IsPlayerAceAllowed(source, ace)
end

local function LogMessage(source)
    local Identifier = GetPlayerIdentifier(source) -- steam id
    local getDiscord = GetPlayerIdentifierByType(source, 'discord')
    local discordId = string.sub(getDiscord, 9)
    local ip = GetPlayerEndpoint(source)    -- ip
    local steamName = GetPlayerName(source) -- steam name
    local message = Translation[Lang].Commands.webHookMessage

    return (message):format(steamName, Identifier, discordId, ip)
end

local function CheckGroupAllowed(table, group)
    if not table or not next(table) then
        return true
    end

    for _, value in pairs(table) do
        if value == group then
            return true
        end
    end

    return false -- allow use command if array is empty
end
--future implementation
local function CheckJobAllowed(table, job)
    if not table or not next(table) then -- ? we check for nil or if its empty
        return true                      -- if empty allows passing
    end

    for _, value in pairs(table) do
        if value == job then
            return true
        end
    end

    return false -- allow use command if array is empty
end
--========================================== THREAD =====================================================--

CreateThread(function()
    for _, value in pairs(Commands) do
        RegisterCommand(value.commandName, function(source, args, rawCommand)
            if source == 0 then
                return
            end

            local _source = source
            local group = VorpCore.getUser(_source).getGroup -- User DB table group

            if not CheckAce(value.aceAllowed, _source) and not CheckGroupAllowed(value.groupAllowed, group) then -- check ace first then group
                return VorpCore.NotifyObjective(_source, Config.Langs.NoPermissions, 4000)
            end

            if value.userCheck then            -- dont check for user existentence
                if not CheckUser(args[1]) then -- if target exists
                    return VorpCore.NotifyObjective(_source, Translation[Lang].Notify.userNonExistent, 4000)
                end
            end

            if not CheckJobAllowed(value.jobAllow, _source) then -- check ace first then group
                return VorpCore.NotifyObjective(_source, Config.Langs.NoPermissions, 4000)
            end

            if not CheckArgs(args, #value.suggestion) then -- if requiered argsuments are not met
                return VorpCore.NotifyObjective(_source, Translation[Lang].Notify.ReadSuggestion, 4000)
            end

            value.callFunction({ source = _source, args = args, rawCommand = rawCommand, config = value })
        end)
    end
end)

--====================================== FUNCTIONS =========================================================--

local function SendDiscordLogs(link, data, arg1, arg2, arg3)
    if not link then
        return
    end

    local message = LogMessage(data.source)
    local custom = data.config.custom
    local finaltext = message .. string.format(custom, arg1, arg2, arg3)
    local title = data.config.title
    VorpCore.AddWebhook(title, link, finaltext)
end

--ADDGROUPS
function SetGroup(data)
    local target = tonumber(data.args[1])
    local newgroup = tostring(data.args[2])
    local Character = VorpCore.getUser(target).getUsedCharacter
    local User = VorpCore.getUser(target)

    if Config.SetBothDBadmin then
        Character.setGroup(newgroup)
        User.setGroup(newgroup)

    else
        if Config.SetUserDBadmin then
            User.setGroup(newgroup)
        else
            Character.setGroup(newgroup)
        end
    end

    SendDiscordLogs(data.config.webhook, data, data.source, newgroup, '')
    VorpCore.NotifyRightTip(target, (Translation[Lang].Notify.SetGroup):format(target), 4000)
    VorpCore.NotifyRightTip(data.source, (Translation[Lang].Notify.SetGroup1):format(newgroup), 4000)
end

--ADDJOBS
function AddJob(data)
    local target = tonumber(data.args[1])
    local newjob = tostring(data.args[2])
    local jobgrade = tonumber(data.args[3])
    local Character = VorpCore.getUser(target).getUsedCharacter

    Character.setJob(newjob)
    Character.setJobGrade(jobgrade)
    SendDiscordLogs(data.config.webhook, data, data.source, newjob, jobgrade)

    VorpCore.NotifyRightTip(data.source, string.format(Translation[Lang].Notify.AddJob, newjob, target, jobgrade), 4000)
    VorpCore.NotifyRightTip(target, string.format(Translation[Lang].Notify.AddJob1, newjob, jobgrade), 4000)
end

--ADDMONEY
function AddMoney(data)
    if type(tonumber(data.args[2])) ~= 'number' then
        return VorpCore.NotifyObjective(data.source, Translation[Lang].Notify.error, 4000)
    end

    local target = tonumber(data.args[1])
    local montype = tonumber(data.args[2])
    local quantity = tonumber(data.args[3])
    local Character = VorpCore.getUser(target).getUsedCharacter

    Character.addCurrency(montype, quantity)

    SendDiscordLogs(data.config.webhook, data, data.source, montype, quantity)
    VorpCore.NotifyRightTip(data.source, (Translation[Lang].Notify.AddMoney):format(quantity, target), 4000)
    VorpCore.NotifyRightTip(target, (Translation[Lang].Notify.AddMoney1):format(quantity), 4000)
end


--ADDITEMS
function AddItems(data)
    local target = tonumber(data.args[1])
    local item = tostring(data.args[2])
    local count = tonumber(data.args[3])

    local itemCheck = VORPInv.getDBItem(target, item)
    if not itemCheck then
        return print(('%s < item dont exist in the database'):format(item))
    end

    local canCarry = VORPInv.canCarryItems(target, count)       --can carry inv space
    if not canCarry then
        return VorpCore.NotifyObjective(data.source, Translation[Lang].Notify.invfull, 4000)
    end

    local canCarry2 = VORPInv.canCarryItem(target, item, count) --cancarry item limit
    if not canCarry2 then
        return VorpCore.NotifyObjective(data.source, Translation[Lang].Notify.cantcarry, 4000)
    end

    VORPInv.addItem(target, item, count)
    SendDiscordLogs(data.config.webhook, data, data.source, item, count)
end

--ADDWEAPONS
function AddWeapons(data)
    local target = tonumber(data.args[1])
    local weaponHash = tostring(data.args[2])

    VORPInv.canCarryWeapons(target, 1, function(result) --can carry weapons
        if not result then
            return VorpCore.NotifyObjective(data.source, Config.Langs.cantCarry, 4000)
        end

        VORPInv.createWeapon(target, weaponHash)
        SendDiscordLogs(data.config.webhook, data, data.source, weaponHash, '')
    end)
end

--DELCURRENCY
function RemmoveCurrency(data)
    if type(tonumber(data.args[2])) ~= 'number' then
        return VorpCore.NotifyObjective(data.source, Translation[Lang].Notify.error, 4000)
    end

    local target = tonumber(data.args[1])
    local montype = tonumber(data.args[2])
    local quantity = tonumber(data.args[3])
    local Character = VorpCore.getUser(target).getUsedCharacter

    Character.removeCurrency(montype, quantity)
    SendDiscordLogs(data.config.webhook, data, data.source, montype, quantity)
    VorpCore.NotifyRightTip(data.source, (Translation[Lang].Notify.removedcurrency):format(quantity, target), 4000)
end

--REVIVEPLAYERS
function RevivePlayer(data)
    local target = tonumber(data.args[1])

    if #data.args == 0 or '' then
        TriggerClientEvent('vorp:resurrectPlayer', data.source) -- heal staff

    else
        if VorpCore.getUser(target) then
            TriggerClientEvent('vorp:resurrectPlayer', target) -- heal target

        else
            VorpCore.NotifyObjective(data.source, Translation[Lang].Notify.userNonExistent, 4000)
        end
    end

    SendDiscordLogs(data.config.webhook, data, target or data.source, '', '')
    VorpCore.NotifyRightTip(data.source, (Translation[Lang].Notify.revived):format(target), 4000)
end

--TELPORTPLAYER
function TeleporPlayer(data)
    TriggerClientEvent('vorp:teleportWayPoint', data.source)
    SendDiscordLogs(data.config.webhook, data, data.source, '', '')
end

--DELETEHORSES
function DeleteHorse(data)
    TriggerClientEvent('vorp:delHorse', data.source)
    SendDiscordLogs(data.config.webhook, data, data.source, '', '')
end

--DELETEWAGONS
function DeleteWagons(data)
    local radius = tonumber(data.args[1])
    if radius < 1 then
        return VorpCore.NotifyRightTip(data.source, Translation[Lang].Notify.radius, 4000)
    end

    TriggerClientEvent('vorp:deleteVehicle', data.source, radius)
    SendDiscordLogs(data.config.webhook, data, data.source, '', '')
end

--HEALPLAYERS
function HealPlayers(data)
    local target = tonumber(data.args[1])
    if #data.args == 0 then
        TriggerClientEvent('vorp:heal', data.source)

    else
        if VorpCore.getUser(target) then
            TriggerClientEvent('vorp:heal', target)

        else
            VorpCore.NotifyObjective(data.source, Translation[Lang].Notify.userNonExistent, 4000)
        end
    end

    SendDiscordLogs(data.config.webhook, data, data.source, '', '')
end

--BANPLAYERS
function BanPlayers(data)
    local target = tonumber(data.args[1])
    if data.source == target then -- check if the target is the same as the source
        return
    end

    local user = VorpCore.getUser(target)
    if not user then
        return
    end

    local banTime = tonumber(data.args[2]:match('%d+')) -- get unit from argument
    if not banTime then
        return
    end                      -- check if the ban time is valid

    local unit = tostring(data.args[2]:match('%a+'))    -- get character from argument
    if unit == 'd' then
        banTime = banTime * 24
    elseif unit == 'w' then
        banTime = banTime * 168
    elseif unit == 'm' then
        banTime = banTime * 720
    elseif unit == 'y' then
        banTime = banTime * 8760
    end

    local datetime = os.time() + banTime * 3600
    TriggerEvent('vorpbans:addtodb', true, target, banTime)

    local text = banTime == 0 and Translation[Lang].Notify.banned or ('%s %s %s'):format(Translation[Lang].Notify.banned2, os.date(Config.DateTimeFormat, datetime + Config.TimeZoneDifference * 3600), Config.TimeZone)
    SendDiscordLogs(data.config.webhook, data, data.source, text, '')
end

--UNBANPLAYERS
function UnBanPlayers(data)
    local target = tonumber(data.args[1])
    TriggerEvent('vorpbans:addtodb', false, target, 0)
    SendDiscordLogs(data.config.webhook, data, data.source, '', '')
end

--WHITELISTPLAYERS
function AddPlayerToWhitelist(data)
    local target = tonumber(data.args[1])
    TriggerEvent('vorp:whitelistPlayer', target)
    SendDiscordLogs(data.config.webhook, data, data.source, '', '')
end

--UNWHITELISTPLAYERS
function RemovePlayerFromWhitelist(data)
    local target = tonumber(data.args[1])
    TriggerEvent('vorp:unwhitelistPlayer', target)
    SendDiscordLogs(data.config.webhook, data, data.source, '', '')
end

--UNWARNPLAYERS
function UnWarnPlayer(data)
    local target = tonumber(data.args[1])
    TriggerEvent('vorpwarns:addtodb', false, target)
    SendDiscordLogs(data.config.webhook, data, data.source, '', '')
end

--WARN PLAYERS
function WarnPlayers(data)
    local target = tonumber(data.args[1])
    if data.source ~= target then -- dont warn yourself
        TriggerEvent('vorpwarns:addtodb', true, target)
        SendDiscordLogs(data.config.webhook, data, data.source, '', '')
    end
end

--ALLOW CHAR CREATION
function AddCharCanCreateMore(data)
    if not Config.UseCharPermission then
        return
    end
    local target = data.args[1]
    TriggerEvent('vorpchar:addtodb', true, target)
    SendDiscordLogs(data.config.webhook, data, data.source, '', '')
    VorpCore.NotifyRightTip(data.source, Config.Langs.AddChar .. target, 4000)
end

--REMOVE ALLOW CHAR CREATION
function RemoveCharCanCreateMore(data)
    if not Config.UseCharPermission then
        return
    end
    local target = data.args[1]
    TriggerEvent('vorpchar:addtodb', false, target)
    SendDiscordLogs(data.config.webhook, data, data.source, '', '')
    VorpCore.NotifyRightTip(data.source, Config.Langs.RemoveChar .. target, 4000)
end

--MODIFY CHARACTER NAME
function ModifyCharName(data)
    local target = tonumber(data.args[1])
    local firstname = tostring(data.args[2])
    local lastname = tostring(data.args[3])

    local Character = VorpCore.getUser(target).getUsedCharacter -- get old name
    Character.setFirstname(firstname)
    Character.setLastname(lastname)
    SendDiscordLogs(data.config.webhook, data, data.source, '', '')
    VorpCore.NotifyRightTip(target, (Translation[Lang].Notify.namechange):format(firstname, lastname), 4000)
end

--MYJOB
function MyJob(data)
    local source = data.source
    local Character = VorpCore.getUser(source).getUsedCharacter
    local job = Character.job
    local grade = Character.jobGrade
    VorpCore.NotifyRightTip(source, ('%s %s %s %s'):format(Config.Langs.myjob, job, Config.Langs.mygrade, grade), 4000)
end

--MYHOUR

local function isInteger(num)
    return math.floor(num) == num
end

function MyHours(data)
    local source = data.source
    local User = VorpCore.getUser(source).getUsedCharacter
    local hours = User.hours

    if isInteger(hours) then
        VorpCore.NotifyRightTip(source, (Config.Langs.charhours):format(hours), 4000)
        return
    end

    local newhour = math.floor(hours - 0.5)
    VorpCore.NotifyRightTip(source, (Config.Langs.playhours):format(newhour, 30), 4000)
end

--============================================ CHAT ADD SUGGESTION ========================================================--
RegisterServerEvent('vorp:chatSuggestion', function()
    local _source = source
    local group   = VorpCore.getUser(_source).getGroup

    for key, value in pairs(Commands) do
        if CheckAce(value.aceAllowed, _source) or CheckGroupAllowed(value.groupAllowed, group) then
            TriggerClientEvent('chat:addSuggestion', _source, '/' .. value.commandName, value.label, value.suggestion)                                                               -- add chat suggestions
        else
            TriggerClientEvent('chat:removeSuggestion', _source, '/' .. value.commandName) -- remove chat suggestions
        end
    end
    
    -- client commands
    TriggerClientEvent('chat:addSuggestion', _source, '/' .. Commands.myHours.commandName, Commands.myHours.label, {})
    TriggerClientEvent('chat:addSuggestion', _source, '/' .. Commands.myJob.commandName, Commands.myJob.label, {})
end)
--============================================================================================================================--
