return function(Vargs)
	local server = Vargs.Server
	local service = Vargs.Service
	local Core = server.Core;
	local Admin = server.Admin;
	local Process = server.Process;
	local Settings = server.Settings;
	local Functions = server.Functions;
	local Commands = server.Commands;
	local Remote = server.Remote;
	local Logs = server.Logs;
	local Variables = server.Variables;
	local Permission = server.Permission;
	local HTTP = server.HTTP;
	local Anti = server.Anti;
    
    
    --server.Commands.AdminList = {
    --    Prefix = server.Settings.Prefix;
    --    Commands = {"admins";"adminlist";"owners";"Moderators";};
    --    Args = {};
    --    Hidden = false;
    --    Description = "Shows you the list of admins, also shows admins that are currently in the server";
    --    Fun = false;
    --    AdminLevel = "Moderators";
    --    Function = function(plr,args)
    --        local data = {
    --            InGame = {}
    --        }

    --        for name, _ in pairs(Settings.Ranks) do
    --            data[name] = {} -- Inserting an empty table for each rank
    --        end

    --        for rank, _ in pairs(data) do
    --            if Settings.Ranks[rank] and Settings.Ranks[rank].Users then
    --                data[rank].Users = Settings.Ranks[rank].Users
    --            end
    --        end

    --        --for i,v in pairs(server.HTTP.Trello.Creators) do 
    --        --    table.insert(data.Creators,v .. " [Trello]") 
    --        --end 

    --        --for i,v in pairs(server.HTTP.Trello.Moderators) do 
    --        --    table.insert(data.Moderators,v .. " [Trello]") 
    --        --end 

    --        --for i,v in pairs(server.HTTP.Trello.Admins) do 
    --        --    table.insert(data.Admins,v .. " [Trello]") 
    --        --end 

    --        --for i,v in pairs(server.HTTP.Trello.Owners) do 
    --        --    table.insert(data.Owners,v .. " [Trello]") 
    --        --end

    --        --service.Iterate(server.Settings.CustomRanks,function(rank,tab)
    --        --    service.Iterate(tab,function(ind,admin)
    --        --        table.insert(data.InGame,admin.." - "..rank) 
    --        --    end)
    --        --end)

    --        for i,v in pairs(service.GetPlayers()) do 
    --            local level = server.Admin.GetLevel(v)
    --            if level>=4 then
    --                table.insert(data.InGame,v.Name..' [Creator]')
    --            elseif level>=3 then 
    --                table.insert(data.InGame,v.Name..' [Owner]')
    --            elseif level>=2 then
    --                table.insert(data.InGame,v.Name..' [Admin]')
    --            elseif level>=1 then
    --                table.insert(data.InGame,v.Name..' [Mod]')
    --            end
    --        end
    --        --    warn(data)
    --        server.Remote.MakeGui(plr,"AdminLists",data)
    --    end
    --};

    server.Commands.ShowSBL = {
        Prefix = server.Settings.Prefix;
        Commands = {"sbl";"syncedbanlist";"globalbanlist";"trellobans";"trellobanlist";};
        Args = {};
        Hidden = false;
        Description = "Shows Trello bans";
        Fun = false;
        AdminLevel = "Moderators";
        Function = function(plr,args)
            local bans = {}
            for _,v in ipairs(server.HTTP.Trello.Bans) do
                table.insert(bans, v.ID)
            end
            local blist = {}
            --for _,v in ipairs(server.HTTP.Trello.Blacklist) do
            --    table.insert(v, blist)
            --end
            for _,v in ipairs(server.HTTP.Trello.Mutes) do
                table.insert(v, blist)
            end
            server.Remote.MakeGui(plr,"TrelloLists",{
                Banlist = bans,
            --    PBSTList = server.HTTP.Trello.PBSTBlacklist,
            --    WeaponList = server.HTTP.Trello.WeaponsBlacklist,
                Blacklist = blist,
                Mutes = blist,
                --Exemptions = server.HTTP.Trello.Exemptions
            })
        end
    }

end;