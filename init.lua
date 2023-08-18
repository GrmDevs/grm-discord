if IsDuplicityVersion() then
    Discord = {
        Token = ('Bot %s'):format('Your bot token here'),
        Guild = --[[ your guild here ]],
        Require = function(method, endpoint, jsondata, reason)
            local result, message = nil, ''
            PerformHttpRequest(('https://discordapp.com/api/%s'):format(endpoint), function(_, __, ___)
                if _ == 200 then 
                    result = __
                    message = ___
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
        end,
        GetIdentifier = function(source)
            for k, v in pairs(GetPlayerIdentifiers(source)) do
                if string.sub(v, 1, string.len("discord:")) == "discord:" then
                    return v:gsub('discord:', '')
                end
            end
        end,
        SetNickname = function(user, name)
            local id = Discord.GetIdentifier(user)
            if not id then return false end
            local endpoint = ('guilds/%s/members/%s'):format(Discord.Guild, id)
            local result, message = Discord.Require('PATCH', endpoint, json.encode({nick = tostring(name)}), 'Set nickname')
            return true
        end,
        AddRole = function(user, role)
            local id = Discord.GetIdentifier(user)
            if not id then return false end
            local roles = Discord.GetUser(user).roles
            local endpoint = ('guilds/%s/members/%s'):format(Discord.Guild, id)
            table.insert(roles, role)
            local member = Discord.Require("PATCH", endpoint, json.encode({roles = roles}), 'AddRole')
            return true
        end,
        RemoveRole = function(user, role)
            local id = Discord.GetIdentifier(user)
            if not id then return false end
            local roles = Discord.GetUser(user).roles
            
            if roles[role] then
                local endpoint = ('guilds/%s/members/%s'):format(Discord.Guild, id)
                roles[role] = nil
                local result, message = Discord.Require('PATCH', endpoint, json.encode({roles = roles}), 'RemoveRole')
                return true
            end

            return false
        end,
        GetGuild = function()
            local endpoint = ('guilds/%s?with_counts=true'):format(Discord.Guild)
            local result, message = Discord.Require('GET', endpoint, {})
            local guild = json.decode(result)
            
            return {
                name = guild.name,
                id = guild.id,
                online = guild.approximate_presence_count
            }
        end,
        GetRole = function(role)
            local endpoint = ('guilds/%s/roles'):format(Discord.Guild)
            local result, message = Discord.Require('GET', endpoint, {})
            if not result then return false end
            
            local roles = json.decode(result)
            for i = 1, #roles do
                if string.match(roles[i].id, role) then
                    return roles[i]
                end
            end
        end,
        GetUser = function(user)
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
    }
    
    return Discord
end
