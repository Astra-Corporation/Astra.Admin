return [=[
	local Chat = game:GetService("Chat")
	local ClientChatModules = Chat:WaitForChild('ClientChatModules')
	local ChatSettings = require(ClientChatModules:WaitForChild("ChatSettings"), false,true)
	
	ChatSettings.PlayerDisplayNamesEnabled = false

	ChatSettings.ShowChannelsBar = %s
	print'Astra chat setup done!'
	
	script:Destroy()
]=]