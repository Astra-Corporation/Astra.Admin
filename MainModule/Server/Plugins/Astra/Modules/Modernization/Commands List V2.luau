return function(Vargs)
	local server = Vargs.Server
	local Admin = server.Admin;
	local Settings = server.Settings;
	local Commands = server.Commands;
	local Remote = server.Remote;
	
	type CommandEntry = {
		Text: string,
		Desc: string
	}

	type Command = {
		Hidden: boolean,
		Disabled: boolean,
		AdminLevel: number | string,
		Description: string,
		Commands: {string},
		CommandsTab: string?,
		Fun: boolean?,
		Special: boolean?,
		PBSF: boolean?,
		Alias: boolean?
	}

	local function createCommandEntry(command: Command, levelName: string): CommandEntry
		return {
			Text = Admin.FormatCommand(command),
			Desc = `[{levelName}] {if #command.Commands >= 1 then `\nAliases: {table.concat(command.Commands, ", ")}` else ""} \n\n{command.Description or "(No description provided)"}`,
		}
	end

	Commands.ViewCommands = {
		Prefix = Settings.Prefix;
		Commands = {"cmds","commands","cmdlist"};
		Args = {};
		Description = "Shows you a list of commands";
		AdminLevel = "Players";
		Function = function(plr: Player, args: {[string]: any})
			local commands: {Command} = Admin.SearchCommands(plr, "all")

			local ret: {[string]: {CommandEntry}} = {
				["All"] = {},
				["Fun"] = {},
				["Aliases"] = {},
				["Special"] = {},
				["PBSF"] = {}
			}

			local taborder = {"All", "Fun", "Players", "Aliases", "Donors", "PBSF", "Special", "PIA", "Assistant", "Moderators", "Admins", "HeadAdmins", "Creators"}
			local num = 0

			for _, command in pairs(commands) do
				if command.Hidden or command.Disabled then continue end

				num += 1

				local levelName: string?
				if typeof(command.AdminLevel) == "number" then
					local _, name = Admin.LevelToList(command.AdminLevel)
					levelName = name or "Players"
				elseif typeof(command.AdminLevel) == "string" then
					levelName = command.AdminLevel
				end

				if not levelName then continue end
				
				if not ret[levelName] then
					ret[levelName] = {}
				end

				local primaryCategory = levelName
				if command.CommandsTab and typeof(command.CommandsTab) == "string" then
					primaryCategory = command.CommandsTab
				
					if not ret[primaryCategory] then
						ret[primaryCategory] = {}
						table.insert(taborder, 1, primaryCategory)
					end
				end

				local entry = createCommandEntry(command, levelName)

				table.insert(ret.All, entry)
				table.insert(ret[primaryCategory], entry)

				-- legacy/misc categories
				if command.Fun then table.insert(ret.Fun, entry) end
				if command.Special then table.insert(ret.Special, entry) end
				if command.PBSF then table.insert(ret.PBSF, entry) end
				if command.Alias then table.insert(ret.Aliases, entry) end
			end
			
			Remote.MakeGui(plr, "TabList", {
				Title = string.format("Commands - %d", num),
				Lists = ret,
				Order = taborder,
				StartingTab = "All"
			})
		end
	};
	
	Commands.oldViewCommands = {
		Prefix = Settings.Prefix;
		Commands = {"oldcmds","oldcommands"};
		Args = {};
		Description = "Old version of ViewCommands, use this if you run into problems using the new version";
		AdminLevel = "Players";
		Function = function(plr,args)
			local commands = Admin.SearchCommands(plr,"all")
			local tab = {}
			local cStr = ""

			local cmdCount = 0

			for i, v in commands do
				if not v.Hidden and not v.Disabled then
					local lvl = v.AdminLevel;
					local gotLevels = {};

					if type(lvl) == "table" then
						for i,v in lvl do
							table.insert(gotLevels, v);
						end
					elseif type(lvl) == "string" or type(lvl) == "number" then
						table.insert(gotLevels, lvl);
					end

					for i,lvl in next,gotLevels do
						local tempStr = "";

						if type(lvl) == "number" then
							local list, name, data = Admin.LevelToList(lvl);
							--print(tostring(list), tostring(name), tostring(data))
							tempStr = (name or "Players") .."+"
						elseif type(lvl) == "string" then
							local numLvl = Admin.StringToComLevel(lvl);
							tempStr = lvl .. "+"
						end

						if i > 1 then
							tempStr = cStr.. ", ".. tempStr;
						end

						cStr = tempStr;
					end

					table.insert(tab, {
						Text = Admin.FormatCommand(v),
						Desc = "["..cStr.."] "..v.Description,
						Filter = cStr
					})
					cmdCount = cmdCount + 1
				end
			end

			Remote.MakeGui(plr,"List",
				{
					Title = "Commands ("..cmdCount..")";
					Table = tab;
				}
			)
		end
	};
end;