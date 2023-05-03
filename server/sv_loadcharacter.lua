local characters = {}
VorpCore = {}

TriggerEvent("getCore", function(core)
    VorpCore = core
end)

function LoadCharacter(identifier, character)
    characters[identifier] = character
end

RegisterNetEvent('vorp:playerSpawn', function()
    local source = source
    local sid = GetSteamID(source)

    if not characters[sid] then
        characters[sid] = Character(source, sid, nil, 'user', 'unemployed', nil, nil, nil, '{}')
        TriggerClientEvent('vorpcharacter:createPlayer', source)

    else
        local pos = json.decode(characters[sid].Coords())
        if pos and pos.x then
            TriggerClientEvent("vorp:initPlayer", source, vector3(pos.x, pos.y, pos.z), pos.heading, characters[sid].IsDead())
        end

        characters[sid].source = source
        -- Send Nui Update UI all
        characters[sid].updateCharUi()
    end
end)

---@TODO potentional security risk, actually not in use
--[[RegisterNetEvent('vorp:UpdateCharacter', function(steamId, firstname, lastname)
    characters[steamId].Firstname(firstname)
    characters[steamId].Lastname(lastname)
end)]]--

--TX ADMIN HEAL EVENT
AddEventHandler('txAdmin:events:healedPlayer', function(eventData)
    if GetInvokingResource() ~= 'monitor' or type(eventData) ~= 'table' or type(eventData.id) ~= 'number' then
        return
    end

    local player = eventData.id
    if player == -1 then
        TriggerClientEvent('vorp:TipRight', -1, Translation[Lang].Notify.healall, 4000)
        TriggerClientEvent('vorp:resurrectPlayer', -1)
        TriggerClientEvent('vorp:heal', -1)

        return
    end

    local identifier = GetSteamID(player)
    local xCharacter = _users[identifier].GetUsedCharacter()
    if not xCharacter or not xCharacter.isdead then
        return
    end

    TriggerClientEvent('vorp:TipRight', player, Translation[Lang].Notify.healself, 4000)
    TriggerClientEvent('vorp:resurrectPlayer', player)
    TriggerClientEvent('vorp:heal', player)
end)

RegisterNetEvent('vorp:ImDead', function(isDead)
    local source = source
    local identifier = GetSteamID(source)

    if not _users[identifier] then
        return
    end

    _users[identifier].GetUsedCharacter().setDead(isDead)
end)

RegisterNetEvent('vorp:SaveDate', function()
    local _source = source
    local Character = VorpCore.getUser(_source).getUsedCharacter
    local charid = Character.charIdentifier
    
    db.updateLastLogin(charid)
end)