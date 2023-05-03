AddEventHandler('vorpbans:addtodb', function(status, id, datetime)
    local sid = _whitelist[id].GetEntry().getIdentifier() --IdsToIdentifiers[id]

    if status == true then
        for _, player in ipairs(GetPlayers()) do
            if sid == GetPlayerIdentifiers(player)[1] then
                if datetime == 0 then
                    DropPlayer(player, Translation[Lang].Notify.banned3)
                else
                    local bannedUntil = os.date(Config.DateTimeFormat, datetime + Config.TimeZoneDifference * 3600)
                    DropPlayer(player, Config.Langs.DropReasonBanned .. bannedUntil .. Config.TimeZone)
                end
                break
            end
        end
    end

    db.updateBan({status, datetime, sid})
end)

AddEventHandler('vorpwarns:addtodb', function(status, id)
    local sid = _whitelist[id].GetEntry().getIdentifier() --IdsToIdentifiers[id]
    local warnings = 0

    if _users[sid] then
        local user = _users[sid].GetUser()
        warnings = user.getPlayerwarnings()

        for _, target in ipairs(GetPlayers()) do
            if sid == GetPlayerIdentifiers(target)[1] then
                if status then
                    TriggerClientEvent('vorp:Tip', target, Config.Langs.Warned, 10000)
                    warnings += 1
                else
                    TriggerClientEvent('vorp:Tip', target, Config.Langs.Unwarned, 10000)
                    warnings -= 1
                end
                break
            end
        end

        user.setPlayerWarnings(warnings)

    else
        warnings = db.selectWarnings({sid})
        if status then
            warnings += 1
        else
            warnings -= 1
        end
    end

    db.updateWarnings({warnings, sid})
end)
