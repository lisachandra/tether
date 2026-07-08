-- Compiled with roblox-ts v3.0.0
local TS = _G[script]
local RunService = TS.import(script, TS.getModule(script, "@rbxts", "services")).RunService
local getTestMode = TS.import(script, script.Parent.Parent, "test-mode").getTestMode
local ContextualEmitter
do
	ContextualEmitter = {}
	function ContextualEmitter:constructor(master)
		self.master = master
	end
	function ContextualEmitter:on(message, callback)
		local isClient = self.context == "client"
		if not getTestMode() then
			if RunService:IsClient() and not isClient then
				return error("[tether::error] Cannot listen to server message from client")
			elseif RunService:IsServer() and isClient then
				return error("[tether::error] Cannot listen to client message from server")
			end
		end
		local callbacksMap = if isClient then self.master.clientCallbacks else self.master.serverCallbacks
		local _message = message
		if not (callbacksMap[_message] ~= nil) then
			local _message_1 = message
			callbacksMap[_message_1] = {}
		end
		local _message_1 = message
		local callbacks = callbacksMap[_message_1]
		local _callback = callback
		callbacks[_callback] = true
		local _message_2 = message
		callbacksMap[_message_2] = callbacks
		return function()
			local _callback_1 = callback
			-- ▼ Set.delete ▼
			local _valueExisted = callbacks[_callback_1] ~= nil
			callbacks[_callback_1] = nil
			-- ▲ Set.delete ▲
			return _valueExisted
		end
	end
	function ContextualEmitter:once(message, callback)
		local destructor
		destructor = self:on(message, function(player, data)
			destructor()
			callback(player, data)
		end)
		return destructor
	end
end
return {
	ContextualEmitter = ContextualEmitter,
}
