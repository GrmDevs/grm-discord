Discord = {
    Token = ('Bot %s'):format(GetConvar('grm_discordBotToken', '')),
    Guild = GetConvar('grm_discordGuildId', ''),
    Errors = {
        [400] = 'The request was improperly formatted, or the server couldn\'t understand it..!',
        [403] = 'Your Discord Token is probably wrong or does not have correct permissions!',
        [404] = 'Enpoint inexistent!',
        [429] = 'Too many requests!'
    }
}

---Request to discord API
---@param method string
---@param endpoint string
---@param jsondata string
---@param reason string
---@return table
Discord.Require = function(method, endpoint, jsondata, reason)
    local data = nil

    PerformHttpRequest(('https://discord.com/api/%s'):format(endpoint), function(errorCode, resultData, resultHeaders)
        if (errorCode ~= 200) and (errorCode ~= 204) then
            print(('^1ERROR: %s^7'):format(Discord.Errors[errorCode]))
            return
        end

        data = {data = resultData, code = errorCode, headers = resultHeaders}
    end, method, #jsondata > 0 and jsondata or '', {
        ['Content-Type'] = 'application/json', 
        ['Authorization'] = Discord.Token, 
        ['X-Audit-Log-Reason'] = reason
    })
    
    while not data do Wait(0) end

    return data
end

---Get discord ID
---@param source number
---@return string
Discord.GetIdentifier = function(source)
    local discord = GetPlayerIdentifierByType(source, 'discord')

    return discord and discord:gsub('discord:', '')
end

---Set nickname on discord
---@param user number
---@param name string
---@return boolean
Discord.SetNickname = function(user, name)
    local id = Discord.GetIdentifier(user)

    if not id then return end

    local endpoint = ('guilds/%s/members/%s'):format(Discord.Guild, id)

    Discord.Require('PATCH', endpoint, json.encode({nick = tostring(name)}), 'GRM-Discord AddRole')

    return true
end

---Check if member has discord role
---@param user number
---@param role string
---@return boolean
Discord.HaveRole = function(user, role)
    local roles = Discord.GetUser(user).roles
    local found = false

    for i = 1, #roles do
        if string.match(roles[i], role) then
            found = true
            break
        end
    end

    return found, roles
end

---Add discord role to member
---@param user number
---@param role string
---@return boolean
Discord.AddRole = function(user, role)
    local id = Discord.GetIdentifier(user)

    if not id then return end

    local hasRole, roles = Discord.HaveRole(user, role)

    if hasRole then return end

    roles[#roles + 1] = role

    local endpoint = ('guilds/%s/members/%s'):format(Discord.Guild, id)

    Discord.Require('PATCH', endpoint, json.encode({roles = roles}), 'GRM-Discord AddRole')

    return true
end

---Remove discord role from member
---@param user number
---@param role string
---@return boolean
Discord.RemoveRole = function(user, role)
    local id = Discord.GetIdentifier(user)

    if not id then return end

    local hasRole, roles = Discord.HaveRole(user, role)

    if not hasRole then return end

    local endpoint = ('guilds/%s/members/%s'):format(Discord.Guild, id)

    roles[role] = nil

    Discord.Require('PATCH', endpoint, json.encode({roles = roles}), 'GRM-Discord RemoveRole')

    return true
end

---Get discord guild
---@return table
Discord.GetGuild = function()
    local endpoint = ('guilds/%s?with_counts=true'):format(Discord.Guild)
    local result = Discord.Require('GET', endpoint, {})

    if not result then return end

    local guild = json.decode(result.data)
    
    return {
        name = guild.name,
        id = guild.id,
        online = guild.approximate_presence_count
    }
end

---Get discord role
---@param role string
---@return table
Discord.GetRole = function(role)
    local endpoint = ('guilds/%s/roles'):format(Discord.Guild)
    local result = Discord.Require('GET', endpoint, {})

    if not result then return end
    
    local roles = json.decode(result.data)

    for i = 1, #roles do
        if string.match(roles[i].id, role) then
            return roles[i]
        end
    end
end

---Get discord user
---@param user number
---@return table
Discord.GetUser = function(user)
    local id = Discord.GetIdentifier(user)

    if not id then return end

    local endpoint = ('guilds/%s/members/%s'):format(Discord.Guild, id)
    local result = Discord.Require('GET', endpoint, {})

    if not result then return end

    local member = json.decode(result.data)

    if member and member.user.avatar then
        local gif = member.user.avatar:sub(1, 1) and (member.user.avatar:sub(2, 2) == '_')
        local fileType = gif and 'gif' or 'png'

        member.user.avatar = ('https://cdn.discordapp.com/avatars/%s/%s.%s'):format(id, member.user.avatar, fileType)
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
