# grm-discord
Discord integrations for Fivem

# How to install
- Download the script and drop in the resources folder
- Open your server.cfg and add this: ```lua ensure grm-discord ```
- Go to: https://discord.com/developers/applications
- Create a new bot and invite in your server
- Open the script and go to "init.lua"
- Paste your bot token & guild id in the script

# How to import 
go to fxmanifest.lua of your resource and add this in the "shared_scripts"
```lua
shared_scripts {
  'grm-discord/init.lua'
}
now you have the global "Discord" in your script.
```

# Functions
```lua
Discord.SetNickname(user, name)
    -- user: player source
    -- name: new nickname
end

Discord.AddRole(user, role)
    -- user: player source
    -- role: role id
end

Discord.RemoveRole(user, role)
    -- user: player source
    -- role: role id
end

-- get guild info
Discord.GetGuild()
    return = {
        name
        id
        online -- online users
    }
end

-- get role info
Discord.GetRole(role)
    -- role: role id
    return = {
        id
        name
        permissions
        position
        color
        hoist
        managed
        mentionable
    }
end

Discord.GetUser(user)
    -- user: player source
    return = {
        avatar
        id
        username
        nickname
        muted
        roles
    }
end
```
