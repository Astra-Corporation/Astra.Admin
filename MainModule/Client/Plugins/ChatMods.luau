return function(Vargs,GetEnv)
	local client, service = Vargs.Client, Vargs.Service
	local Functions = client.Functions
	local Variables = client.Variables
	local BuildInfo = Variables.BuildInfo
	local shark = [=[
  	 Running Astra Admin Compiled %s %s@%s
  	]=]
	print(string.format(shark,BuildInfo.BUILD_DATE,BuildInfo.COMMIT,BuildInfo.BRANCH))
end
