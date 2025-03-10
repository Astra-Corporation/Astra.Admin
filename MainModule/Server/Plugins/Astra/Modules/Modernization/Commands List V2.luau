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
	local HTTP = server.HTTP;
	local Anti = server.Anti;
	local version = server.Version

	server.Commands.oldViewCommands = {
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

	server.Commands.ViewCommands = { -- Someone remind me to rewrite this.....
		Prefix = Settings.Prefix;
		Commands = {"cmds","commands","cmdlist"};
		Args = {};
		Description = "Shows you a list of commands";
		AdminLevel = "Players";
		Function = function(plr,args)
			local commands = Admin.SearchCommands(plr,"all")
			local ret = {
				["All"] = {}; --all commands
				["Fun"] = {};
				["Aliases"] = {};
				["Special"] = {};
				["PBCS"] = {};
				--the rest are created
			}
			local taborder = {"All","Fun","Players","Aliases","Donors","PBCS","Special","PIA","Assistant","Moderators","Admins","HeadAdmins","Creators"};
			local num = 0
			for i,v in commands do
				if not v.Hidden and not v.Disabled then
					local temp = ""
					local lvl = v.AdminLevel
					if v.Alias then
						table.insert(ret["Aliases"],{
							Text = Admin.FormatCommand(v);
							Desc = "[".."Players".."+] "..v.Description
						})
					end
					if type(lvl) == "number" then

						local list, name, data = Admin.LevelToList(lvl);
						--print(tostring(list), tostring(name), tostring(data))
						if not ret[(name or "Players")] then ret[(name or "Players")] = {} end

						if v.CommandsTab and type(v.CommandsTab)=="string" then
							if not ret[v.CommandsTab] then ret[v.CommandsTab] = {} table.insert(taborder,1,v.CommandsTab) end
							table.insert(ret[v.CommandsTab],{
								Text = Admin.FormatCommand(v);
								Desc = "["..(name or "Players").."+] "..v.Description
							})
						else	
							if v.Fun then
								table.insert(ret["Fun"],{
									Text = Admin.FormatCommand(v);
									Desc = "["..(name or "Players").."+] "..v.Description
								})
							end
							if v.Special then
								table.insert(ret["Special"],{
									Text = Admin.FormatCommand(v);
									Desc = "["..(name or "Players").."+] "..v.Description
								})
							end
							
							if v.PBCS then
								table.insert(ret["PBCS"],{
									Text = Admin.FormatCommand(v);
									Desc = "["..(name or "Players").."+] "..v.Description
								})
							end
							
							if v.Alias then
								print(v)
								table.insert(ret["Aliases"],{
									Text = Admin.FormatCommand(v);
									Desc = "["..(name or "Players").."+] "..v.Description
								})
							end
							table.insert(ret[(name or "Players")],{
								Text = Admin.FormatCommand(v);
								Desc = "["..(name or "Players").."+] "..v.Description
							})
						end

						table.insert(ret["All"],{
							Text = Admin.FormatCommand(v);
							Desc = "["..(name or "Players").."+] "..v.Description
						})
					elseif type(lvl) == "string" then
						if not ret[lvl] then ret[lvl] = {} end
						if v.CommandsTab and type(v.CommandsTab)=="string" then
							if not ret[v.CommandsTab] then ret[v.CommandsTab] = {} table.insert(taborder,1,v.CommandsTab) end
							table.insert(ret[v.CommandsTab],{
								Text = Admin.FormatCommand(v);
								Desc = "["..lvl.."+] "..v.Description
							})
						else
							table.insert(ret[lvl],{
								Text = Admin.FormatCommand(v);
								Desc = "["..lvl.."+] "..v.Description
							})
							if v.Fun then
								table.insert(ret["Fun"],{
									Text = Admin.FormatCommand(v);
									Desc = "["..lvl.."+] "..v.Description
								})
							end
						end
						
						table.insert(ret["All"],{
							Text = Admin.FormatCommand(v);
							Desc = "["..lvl.."+] "..v.Description
						})

					end


				end
				num += 1
			end
			Remote.MakeGui(plr,"TabList",{
				Title = `Commands - {num}`;
				Lists = ret;
				Order = taborder;
				StartingTab = "Players"
			})
		end
	};


end;
