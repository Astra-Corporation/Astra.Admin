# Get the current Git branch
$branch = git rev-parse --abbrev-ref HEAD

# Get the latest Git commit hash
$commit = git rev-parse --short HEAD

# Read BuildInfo.lua, replace placeholders, and save it
(Get-Content MainModule\Client\Core\Variables.luau) -replace 'COMMIT = "";', "COMMIT = `"$commit`";" -replace 'BRANCH = "";', "BRANCH = `"$branch`";" | Set-Content MainModule\Client\Core\Variables.luau
