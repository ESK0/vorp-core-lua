local function init_core()
    print("###############################################################################\n" ..
        "\n^1----- ^3#RedM ^1----------------------------------------------------------------------^0\n" ..
        " /##    /##  /######  /#######  /#######   /######   /######  /#######  /########\n" ..
        "| ##   | ## /##__  ##| ##__  ##| ##__  ## /##__  ## /##__  ##| ##__  ##| ##_____/\n" ..
        "| ##   | ##| ##  | ##| ##  | ##| ##  | ##| ##  |__/| ##  | ##| ##  | ##| ##      \n" ..
        "|  ## / ##/| ##  | ##| #######/| #######/| ##      | ##  | ##| #######/| #####   \n" ..
        " |  ## ##/ | ##  | ##| ##__  ##| ##____/ | ##      | ##  | ##| ##__  ##| ##__/   \n" ..
        "  |  ###/  | ##  | ##| ##  | ##| ##      | ##    ##| ##  | ##| ##  | ##| ##      \n" ..
        "   |  #/   |  ######/| ##  | ##| ##      |  ######/|  ######/| ##  | ##| ########\n" ..
        "    |_/     |______/ |__/  |__/|__/       |______/  |______/ |__/  |__/|________/\n" ..
        "^1----------------------------------------------------^3VORPcore Framework ^2Lua^0 ^1-----^0\n")
end

ScriptList = {}
Changelogs = 0

VorpInitialized = false

CreateThread(function()
    for i = 0, GetNumResources(), 1 do
        local resource = GetResourceByFindIndex(i)
        UpdateChecker(resource)
    end

    if next(ScriptList) then
        VorpInitialized = true
        init_core()
        Checker()
    end
end)

function UpdateChecker(resource)
    if not resource or GetResourceState(resource) ~= 'started' then
        return
    end

    if GetResourceMetadata(resource, 'vorp_checker', 0) ~= 'yes' then
        return
    end

    local Name = GetResourceMetadata(resource, 'vorp_name', 0)
    local Github = GetResourceMetadata(resource, 'vorp_github', 0)
    local Version = GetResourceMetadata(resource, 'vorp_version', 0)
    local Changelog, GithubL, NewestVersion

    Script = {}

    Script.Resource = resource
    if not Version then
        Version = GetResourceMetadata(resource, 'version', 0)
    end

    Script.Name = Name or ('^6%s'):format(resource:upper())

    if string.find(Github, "github") then
        if string.find(Github, "github.com") then
            Script.Github = Github
            Github = ('%s%s'):format(string.gsub(Github, 'github', 'raw.githubusercontent'), '/master/version')

        else
            GithubL = string.gsub(Github, 'raw.githubusercontent', 'github'):gsub('/master', '')
            Github = ('%s%s'):format(Github, '/version')
            Script.Github = GithubL
        end
        
    else
        Script.Github = ('%s%s'):format(Github, '/version')
    end

    PerformHttpRequest(Github, function(Error, V, Header)
        NewestVersion = V
    end)

    repeat
        Wait(10)
    until NewestVersion ~= nil

    StripVersion = NewestVersion:match('<%d?%d.%d?%d.?%d?%d?>')
    if not StripVersion then
        print(Name, 'Version is setup incorrectly!')
        return
    end

    CleanedVersion = StripVersion:gsub('[<>]', '')
    Version1 = CleanedVersion

    if not string.find(Version1, Version) then
        if Version1 < Version then
            Changelog = 'Your script version is newer than what was found in github'
            NewestVersion = Version

        else 
            local MinV = NewestVersion:gsub(('<%s>'):format(Version1), "")
            local StripedExtra
            local isMatch = MinV:match(('<%s>'):format(Version))
            if isMatch then
                StripedExtra = MinV:gsub(('<%s>.*'):format(Version), '')

            else
                StripedExtra = MinV:gsub('<%d?%d.%d?%d.?%d?%d?>.*', '')
            end

            local stripedVersions = StripedExtra:gsub('<%d?%d.%d?%d.?%d?%d?>', '')
            local Changelog = stripedVersions
            Changelog = string.gsub(Changelog, '\n', '')
            Changelog = string.gsub(Changelog, '-', ' \n-'):gsub('%b<>', ''):sub(1, -2)

            NewestVersion = Version1

            Script.CL = true
            Script.Changelog = Changelog
        end
    end

    Script.NewestVersion = Version1
    Script.Version = Version

    ScriptList[#ScriptList+1] = Script
end

function Checker()
    print('^3VORPcore Version check')
    print('^2Resources found\n')

    local outdated = {}
    local upToDate = {}

    local upIndex = 1
    local outIndex = 1
    for _, v in pairs(ScriptList) do
        if string.find(v.NewestVersion, v.Version) then
            upToDate[upIndex] = ('^4%s (%s) ^2✅ Up to date - Version %s\n'):format(v.Name, v.Resource, v.Version)
            upIndex += 1

        elseif v.Version > v.NewestVersion then
            outdated[outIndex] = ('^4%s (%s) ⚠️ Mismatch (v%s) ^5- Official Version: %s ^0(%s)\n'):format(v.Name, v.Resource, v.Version, v.NewestVersion, v.Github)
            outIndex += 1

        else
            outdated[outIndex] = ('^4%s (%s) ^1❌ Outdated (v%s) ^5- Update found: Version %s ^0(%s)\n'):format(v.Name, v.Resource, v.Version, v.NewestVersion, v.Github)
            outIndex += 1

        end

        if v.CL then
            Changelogs += 1
        end
    end

    -- print outdated first and up-to-date at the end
    for _, message in ipairs(outdated) do
        print(message)
    end

    if Changelogs > 0 then
        print('^1###############################')
        Changelog()

    else
        print('^0\n###############################################################################')
    end

    for _, message in ipairs(upToDate) do
        print(message)
    end
end


function Changelog()
    print('')
    for _, v in pairs(ScriptList) do
        local isNewVersion = v.Version ~= v.NewestVersion
        local hasChangelog = v.CL

        if isNewVersion and hasChangelog then
            print(('^3%s - Changelog:\n^0%s\n^1###############################^0\n'):format(v.Resource:upper(), v.Changelog))
        end

    end
    print('^0###############################################################################')
end
