ServerCallBacks = {}

RegisterServerEvent('vorp:addNewCallBack', function(name, ncb)
    ServerCallBacks[name] = ncb
end)

---comment
---@param name string
---@param requestId number
---@param args any
RegisterServerEvent('vorp:TriggerServerCallback', function(name, requestId, args)
    local source = source

    if not ServerCallBacks[name] then
        print(('Callback %s does not exist. make sure it matches client and server'):format(name))
        return
    end

    ServerCallBacks[name](source, function(data) -- index of table
        TriggerClientEvent('vorp:ServerCallback', source, requestId, data)
    end, args)
end)
