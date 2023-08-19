Discord = {
    Token = ('Bot %s'):format('Token Here'),
    Guild = --[[ Guild here ]],
    Errors = {
        [400] = 'The request was improperly formatted, or the server couldn\'t understand it..!',
        [403] = 'Your Discord Token is probably wrong or does not have correct permissions!',
        [404] = 'Enpoint inexistent!',
        [429] = 'Too many requests!'
    }
}

if not IsDuplicityVersion() then
    return
end

Discord.Require = function(method, endpoint, jsondata, reason)
    local result, message = nil, ''
    PerformHttpRequest(('https://discordapp.com/api/%s'):format(endpoint), function(_, __, ___)
        print(endpoint, _)
        if (_ == 200) or (_ == 204) then 
            result = __
            message = ___
        else 
            print(('^1Error: %s'):format(Discord.Errors[_])) 
            return 
        end
    end, method, #jsondata > 0 and jsondata or "", {
        ["Content-Type"] = "application/json", 
        ["Authorization"] = Discord.Token, 
        ['X-Audit-Log-Reason'] = reason
    })
    
    while result == nil do
        Citizen.Wait(0)
    end    

    return result, message
end

Discord.GetIdentifier = function(source)
    for k, v in pairs(GetPlayerIdentifiers(source)) do
        if string.sub(v, 1, string.len("discord:")) == "discord:" then
            return v:gsub('discord:', '')
        end
    end
end

Discord.SetNickname = function(user, name)
    local id = Discord.GetIdentifier(user)
    if not id then return false end
    local endpoint = ('guilds/%s/members/%s'):format(Discord.Guild, id)
    Discord.Require('PATCH', endpoint, json.encode({nick = tostring(name)}), 'GRM-Discord AddRole')
    return true
end

Discord.HaveRole = function(user, role)
    local roles = Discord.GetUser(user).roles
    local bool = false

    for i = 1, #roles do
        if string.match(roles[i], role) then
            bool = true
            break
        end
    end

    return bool, roles
end

Discord.AddRole = function(user, role)
    local id = Discord.GetIdentifier(user)
    if not id then return false end
    local bool, roles = Discord.HaveRole(user, role)
    if bool then return false end
    table.insert(roles, role)
    local endpoint = ('guilds/%s/members/%s'):format(Discord.Guild, id)
    Discord.Require('PATCH', endpoint, json.encode({roles = roles}), 'GRM-Discord AddRole')
    return true
end

Discord.RemoveRole = function(user, role)
    local id = Discord.GetIdentifier(user)
    if not id then return false end
    local bool, roles = Discord.HaveRole(user, role)
    if not bool then return false end
    local endpoint = ('guilds/%s/members/%s'):format(Discord.Guild, id)
    roles[role] = nil
    Discord.Require('PATCH', endpoint, json.encode({roles = roles}), 'GRM-Discord RemoveRole')
    return true
end

Discord.GetGuild = function()
    local endpoint = ('guilds/%s?with_counts=true'):format(Discord.Guild)
    local result, message = Discord.Require('GET', endpoint, {})
    local guild = json.decode(result)
    
    return {
        name = guild.name,
        id = guild.id,
        online = guild.approximate_presence_count
    }
end

Discord.GetRole = function(role)
    local endpoint = ('guilds/%s/roles'):format(Discord.Guild)
    local result, message = Discord.Require('GET', endpoint, {})
    if not result then return false end
    
    local roles = json.decode(result)
    for i = 1, #roles do
        if string.match(roles[i].id, role) then
            return roles[i]
        end
    end
end

Discord.GetUser = function(user)
    local id = Discord.GetIdentifier(user)
    if not id then return false end
    local endpoint = ('guilds/%s/members/%s'):format(Discord.Guild, id)
    local result, message = Discord.Require('GET', endpoint, {})
    if not result or not message then return false end

    local member = json.decode(result)
    if member.user.avatar ~= nil then
        local gif = member.user.avatar:sub(1, 1) and member.user.avatar:sub(2, 2)
        member.user.avatar = ('https://cdn.discordapp.com/avatars/%s/%s.%s'):format(id, member.user.avatar, gif and 'gif' or 'png')
    end
    
    return {
        avatar = member.user.avatar,
        id = member.user.id,
        username = member.user.username,
        nickname = member.nick,
        muted = member.mute,
        roles = member.roles
    }
end
 
return Discord
