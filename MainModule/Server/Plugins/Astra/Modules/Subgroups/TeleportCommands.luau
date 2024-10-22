--[==[
    EasternBloxxer
    Astra Defense Network
--]==]

local places = {
	PBOP = {
		PlaceId = 758601306;
	};
	PBOPDev = {
		PlaceId = 6645633469;
		Hidden = true;
	};
	PBCC = {
		PlaceId = 17541193
	};
	PBCSDev = {
		PlaceId=14858809740
	};
	PBCS = {PlaceId=15945185890};
	PBSTH = {PlaceId=2681874142};
	PBSSA = {PlaceId=17541196};
	megaminers = {PlaceId=17541179};
	pss = {PlaceId=17541177};
	laundromat = {PlaceId=17541212};
	pbhq = {PlaceId=7956592};
	pbsttfold = {PlaceId=298521066};
	pbrf = {PlaceId=7692456};
	tmsrs = {PlaceId=9231976996};
	pbsttf = {PlaceId=14036005954};
	pbstac = {PlaceId=1564828419};
	pbdsf = {PlaceId=1428153850};
}
return function(Vargs)
	local server = Vargs.Server
	local service = Vargs.Service
	local Functions = server.Functions;
	for name,place in pairs(places) do

		server.Commands[name] = {
			Prefix = server.Settings.PlayerPrefix;
			Commands = {string.lower(name)};
			Args = {};
			Description = "Teleports to a facility";
			Hidden = place.Hidden or false;
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				Functions.Message(`Teleport`, `You are teleporting to {name}`, {plr}, true)
				service.TeleportService:TeleportAsync(place.PlaceId, {plr})
			end
		}

	end
end