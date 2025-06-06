-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Trello API Documentation: 																							     --
--																																							     --
-- App Key Link: 			 	/app-key																						    			 --
--																																				  				 --
-- Token Link:   			 	/1/connect?name=Trello_API_Module&response_type=token&expires=never&scope=read,write&key=YOUR_APP_KEY_HERE     --
-- Replace "YOUR_APP_KEY_HERE" with the App Key from /app-key																					 --
-- Trello API Remade by imskyyc for Kronos and Adonis - original by Sceleratis / Davey_Bones for Adonis.																	 --
-- It is requested that existing credits remain here.																											 --
-------------------------------------------------------------------------------------------------------------------------------------------------------------------

local print = function(...) for i,v in {...} do warn(`[Astra TrelloAPI]: INFO: {v}`) end end
local error = function(...) for i,v in {...} do warn(`[Astra TrelloAPI]: ERROR: {v}`) end end
local warn = function(...) for i,v in {...} do warn(`[Astra TrelloAPI]: WARN: {v}`) end end

local HttpService = game:GetService("HttpService")
local Weeks = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"}
local Months = {"January"; "February"; "March"; "April"; "May"; "June"; "July"; "August"; "September"; "October"; "November"; "December"}
local Queue = {}
local Requests = 0
local MaxRequests = 5
local WaitTime = 10

local RateLimit = function()
	if Requests >= MaxRequests then
		warn("Trello RateLimit Reached! Waiting 10 seconds...")
		task.wait(WaitTime)
		Requests = 0
	end
	Requests += 1
	task.delay(WaitTime/2, function()
		if next(Queue) == nil then
			Requests = 0
		end
	end)
end

local HttpFunctions; HttpFunctions = {
	--// Same as the GetRandom() function
	GenerateRequestID = function()
		local format = string.format
		local random = math.random

		local Len = random(5,10)

		local Res = {};
		for Idx = 1, Len do
			Res[Idx] = format('%02x', random(126));
		end;
		return table.concat(Res)
	end;

	Decode = function(str)
		local success, tab = pcall(function()
			return HttpService:JSONDecode(str)
		end)

		if success then
			return tab
		else
			return {}
		end
	end;

	Encode = function(tab)
		local success, str = pcall(function()
			return HttpService:JSONEncode(tab)
		end)

		if success then
			return str
		else
			return "{}"
		end
	end;

	UrlEncode = function(str)
		return HttpService:UrlEncode(str)
	end;

	Request = function(Url, Method, Headers, Body)
		local RequestID = HttpFunctions.GenerateRequestID()
		local ran, response = pcall(function()
			local Request = {
				Url = Url;
				Method = Method;
				Headers = {
					["Content-Type"] = "application/json"
				};
				Body = HttpService:JSONEncode(Body);
			}

			Queue[RequestID] = Request

			for ind, header in Headers do
				Request.Headers[ind] = header
			end

			RateLimit()
			return HttpService:RequestAsync(Request)
		end)

		Queue[RequestID] = nil
		if ran then
			return response
		else
			warn(`RequestAsync failed: {response}`)
			return false
		end
	end;

	Get = function(Url)
		local RequestID = HttpFunctions.GenerateRequestID()
		Queue[RequestID] = Url
		RateLimit()

		local ran, response = pcall(function()
			return HttpService:GetAsync(Url, true)
		end)

		Queue[RequestID] = nil
		if ran then
			return response
		else
			warn(`GetAsync failed: {response}`)
			return false
		end
	end;

	Post = function(Url, Data, Type)
		local RequestID = HttpFunctions.GenerateRequestID()
		Queue[RequestID] = Url
		RateLimit()

		local ran, response = pcall(function()
			return HttpService:PostAsync(Url, Data, Type)
		end)

		Queue[RequestID] = nil
		if ran then
			return response
		else
			warn(`PostAsync failed: {response}`)
			return false
		end
	end;

	Trim = function(str)
		return string.match(str, "^%s*(.-)%s*$")
	end;

	GetListObject = function(Lists, Name)
		if not Name then error("Missing search term") end
		for _, List in Lists do
			if type(Name)=="table" then
				for _, Name in Name do
					if string.lower(HttpFunctions.Trim(List.name)) == string.lower( HttpFunctions.Trim(Name)) then
						return List
					end
				end
			elseif type(Name)=="string" then
				if string.lower(HttpFunctions.Trim(List.name)) == string.lower(HttpFunctions.Trim(Name)) then
					return List
				end
			end
		end
	end;
}

return function(AppKey, Token)
	AppKey = AppKey or ""
	Token = Token or ""

	local Arguments = `key={AppKey}&token={Token}`

	local GetUrl = function(str)
		local Token = Token
		if string.find(str, "?") then
			Token=`&{Arguments}`
		else
			Token=`?{Arguments}`
		end
		return `https://trello.com/1/{str}{Token}`
	end;
	
	local CheckHttp = function()
		local enabled, err = pcall(function()
			HttpService:GetAsync(GetUrl("members/trello?fields=id"))
		end)
		
		return enabled
	end;
	
	local HttpEnabled = pcall(HttpService.GetAsync, HttpService, "http://www.google.com/robots.txt");
	
	if not HttpEnabled then
		error("Unable to connect to trello, Http requests are not enabled. Enable them via game settings.")
		return
	end
	
	if not CheckHttp() then
		error("Could not connect to Trello! Please check if your app-key/token are valid.")
		return
	end;

	local API; API = {
		EpochToHuman = function(Epoch)
            local TimeTable = os.date("!*t", tonumber(Epoch))

            local Week = Weeks[TimeTable.wday]
            local Month = Months[TimeTable.month]
            local Day = TimeTable.day
            local Year = TimeTable.year

            local hour, am_pm

            if TimeTable.hour >= 12 then
                hour = TimeTable.hour - 12
                am_pm = "PM"
            else
                hour = TimeTable.hour
                am_pm = "AM"
            end

            if hour == 0 then
                hour = 12
            end

            local Hour = string.format("%02s", tostring(hour))
            local Minute = string.format("%02s", tostring(TimeTable.min))
            local Seconds = string.format("%02s", tostring(TimeTable.sec))

            local TimeString = `{Week} {Month} {Day} @ {Hour}:{Minute}:{Seconds} {am_pm} (UTC)`
            return TimeString
        end;

		Boards = {
			GetBoard = function(BoardID)
				return HttpFunctions.Decode(HttpFunctions.Get(GetUrl(`boards/{BoardID}`)))
			end;

			GetBoardField = function(BoardID, Field)
				return HttpFunctions.Decode(HttpFunctions.Get(GetUrl(`boards/{BoardID}/{Field}`)))
			end;

			GetLists = function(BoardID)
				local Response = HttpFunctions.Decode(HttpFunctions.Get(GetUrl(`boards/{BoardID}/lists`)))
				if type(Response)=="table" then
					return Response
				else
					return {}
				end
			end;
			
			GetListsAndCards = function(BoardID, ExcludeLabels)
				local CardFilter = `id,name,desc{ExcludeLabels and "" or ",labels"}`
				local Response = HttpFunctions.Decode(HttpFunctions.Get(GetUrl(`boards/{BoardID}/lists?filter=open&fields=id,name,cards&cards=open&card_fields={CardFilter}`)))
				if type(Response)=="table" then
					return Response
				else
					return {}
				end
			end;

			GetList = function(BoardID, Name)
				local Lists = API.Boards.GetLists(BoardID)
				return HttpFunctions.GetListObject(Lists, Name)
			end;

			MakeList = function(BoardID, Name, Extra)
				local Extra = Extra or ""
				return HttpFunctions.Decode(HttpFunctions.Post(GetUrl(`boards/{BoardID}/lists`),`&name={HttpFunctions.UrlEncode(Name)}{Extra}`,2))
			end;
		};

		Lists = {
			GetListField = function(ListID, Field)
				return HttpFunctions.Decode(HttpFunctions.Get(GetUrl(`lists/{ListID}/{Field}`)))
			end;

			GetCards = function(ListID)
				local Response = HttpFunctions.Decode(HttpFunctions.Get(GetUrl(`lists/{ListID}/cards`)))
				if type(Response)=="table" then
					return Response
				else
					return {}
				end
			end;

			GetCard = function(ListID, Name)
				local Cards = API.Lists.GetCards(ListID)
				return HttpFunctions.GetListObject(Cards, Name)
			end;

			ArchiveAllCards = function(ListID)
				return HttpFunctions.Decode(HttpFunctions.Post(GetUrl(`lists/{ListID}/archiveAllCards`)))
			end;

			ArchiveList = function(ListID, Archive)
				return HttpFunctions.Decode(HttpFunctions.Post(GetUrl(`lists/{ListID}{Archive or false}`)))
			end;

			GetListBoard = function(ListID)
				return HttpFunctions.Decode(HttpFunctions.Get(GetUrl(`lists/{ListID}/board`)))
			end;

			MakeCard = function(ListID, Name, Description, Extra)
				local Extra = Extra or ""
				return HttpFunctions.Decode(HttpFunctions.Post(GetUrl(`lists/{ListID}/cards`),`&name={HttpFunctions.UrlEncode(Name)}&desc={HttpFunctions.UrlEncode(Description)}{Extra}`,2))
			end;
		};

		Cards = {
			ArchiveCard = function(CardID, Archive)
				local Request = HttpFunctions.Request(GetUrl(`cards/{CardID}`),"PUT",{},{closed = Archive or false})
				return HttpFunctions.Decode(Request)
			end;

			DeleteCard = function(CardID)
				local Request = HttpFunctions.Request(GetUrl(`cards/{CardID}`),"DELETE",{},{})
				return HttpFunctions.Decode(Request)
			end;

			GetCardField = function(CardID, Field)
				return HttpFunctions.Decode(HttpFunctions.Get(GetUrl(`cards/{CardID}/{Field}`)))
			end;

			GetComments = function(CardID)
				return HttpFunctions.Decode(HttpFunctions.Get(GetUrl(`cards/{CardID}/actions?filter=commentCard`)))
			end;

			DeleteComment = function(CardID, CommentID)
				local Request = HttpFunctions.Request(GetUrl(`cards/{CardID}/actions/{CommentID}/comments`), "DELETE", {}, {})
				return HttpFunctions.Decode(Request)
			end;

			AddComment = function(CardID, Text)
				return HttpFunctions.Decode(HttpFunctions.Post(GetUrl(`cards/{CardID}/actions/comments`),`&text={HttpFunctions.UrlEncode(Text)}`,2))
			end;

			AddLabel = function(CardID, LabelID)
				return HttpFunctions.Decode(HttpFunctions.Post(GetUrl(`cards/{CardID}/idLabels`),`&value={HttpFunctions.UrlEncode(LabelID)}`,2))
			end;

			RemoveLabel = function(CardID, LabelID)
				local Request = HttpFunctions.Request(GetUrl(`cards/{CardID}/idLabels/{LabelID}`), "DELETE", {}, {})
				return HttpFunctions.Decode(Request)
			end;
		};

		Labels = {
			GetLabel = function(LabelID)
				return HttpFunctions.Decode(HttpFunctions.Get(GetUrl(`labels/{LabelID}`)))
			end;

			UpdateLabel = function(LabelID, Name, Color)
				local Data = {name = Name}
				if Color then Data.color = Color end
				local Request = HttpFunctions.Request(GetUrl(`labels/{LabelID}`),"PUT",{},Data)
				return HttpFunctions.Decode(Request)
			end;

			DeleteLabel = function(LabelID)
				local Request = HttpFunctions.Request(GetUrl(`labels/{LabelID}`),"DELETE",{},{})
				return HttpFunctions.Decode(Request)
			end;

			UpdateLabelField = function(LabelID, Field, Value)
				local Request = HttpFunctions.Request(GetUrl(`labels/{LabelID}/{Field}`),"PUT",{},{value = Value})
			end;

			CreateLabel = function(BoardID, Name, Color)
				Color = Color or "null"
				return HttpFunctions.Decode(HttpFunctions.Post(GetUrl("labels"),`&name={HttpFunctions.UrlEncode(Name)}&color={HttpFunctions.UrlEncode(Color)}&idBoard={HttpFunctions.UrlEncode(BoardID)}`,2))
			end;
		};
	}

	for ind, func in HttpFunctions do
		API[ind] = func
	end

	API.http = HttpService
	API.getListObj = API.GetListObject
	API.checkHttp = CheckHttp
	API.CheckHttp = CheckHttp
	API.urlEncode = API.UrlEncode
	API.encode = API.Encode
	API.decode = API.Decode
	API.httpGet = API.Get
	API.httpPost = API.Post
	API.trim = API.Trim
	API.epochToHuman = API.EpochToHuman
	API.getBoard = API.Boards.GetBoard
	API.getLists = API.Boards.GetLists
	API.getListsAndCards = API.Boards.GetListsAndCards
	API.getList = API.Boards.GetList
	API.getCards = API.Lists.GetCards
	API.getCard = API.Lists.GetCard
	API.getComments = API.Cards.GetComments
	API.delComment = API.Cards.DeleteComment
	API.makeComment = API.Cards.MakeComment
	API.getCardField = API.Cards.GetCardField
	API.getBoardField = API.Boards.GetBoardField
	API.getListField = API.Lists.GetListField
	API.getLabel = API.Labels.GetLabel
	API.makeCard = API.Lists.MakeCard
	API.doAction = function(method,subUrl,data)
		if string.lower(method)=="post" then
			return HttpFunctions.Decode(HttpFunctions.Post(GetUrl(subUrl),data,2))
		elseif string.lower(method)=="get" then
			return HttpFunctions.Decode(HttpFunctions.Get(GetUrl(subUrl)))
		end
	end;

	API.getUrl = GetUrl

	return API
end
