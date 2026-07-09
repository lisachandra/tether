-- Compiled with roblox-ts v3.0.0
local _testMode = false
local function getTestMode()
	return _testMode
end
local function setTestMode(value)
	_testMode = value
end
return {
	getTestMode = getTestMode,
	setTestMode = setTestMode,
}
