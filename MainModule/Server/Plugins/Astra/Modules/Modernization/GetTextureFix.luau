-- EasternBloxxer 2024

return function(Vargs)
	local server, service = Vargs.Server, Vargs.Service
	local Functions = server.Functions;
	local Remote = server.Remote;
	local HTTP = server.HTTP;

	local HttpService = service.HttpService;

	Functions.GetTexture = function(ID)
		
		if Functions.IsValidTexture(ID) then
			return ID;
		end; --// Check if the user is using a texture id and return it. 
			--// Some functions dont seem to do this check so we will do it here.
		
		if not HTTP.CheckHttp then
			return ID;
		end;

		local Success, Result = pcall(HttpService.RequestAsync, HttpService, {
			Url = `http://f3xteam.com/bt/getDecalImageID/{ID}`, --TODO: Make it use our own api(?)
			Method = "GET",										--The code for that is mostly done in /capeid
		});

		if not Success then
			return ID, warn(`Something went wrong while getting a texture id: {Result.Body or Result}`);
		end;
		
		if tonumber(Result.Body) then ID = Result.Body end;

		if Functions.IsValidTexture(ID) then
			return ID;
		end;

		return ID;
	end;
	
	Remote.Commands.GetTextureId = function(p, args)
		return Functions.GetTexture(args[1]);
	end;
	
end