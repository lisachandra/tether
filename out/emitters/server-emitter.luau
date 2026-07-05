-- Compiled with roblox-ts v3.0.0
local TS = _G[script]
local RunService = TS.import(script, TS.getModule(script, "@rbxts", "services")).RunService
local ContextualEmitter = TS.import(script, script.Parent, "contextual-emitter").ContextualEmitter
if setLuneContext == nil then
	setLuneContext = function() end
end
local ServerEmitter
do
	local super = ContextualEmitter
	ServerEmitter = setmetatable({}, {
		__tostring = function()
			return "ServerEmitter"
		end,
		__index = super,
	})
	ServerEmitter.__index = ServerEmitter
	function ServerEmitter.new(...)
		local self = setmetatable({}, ServerEmitter)
		return self:constructor(...) or self
	end
	function ServerEmitter:constructor(...)
		super.constructor(self, ...)
		self.context = "server"
	end
	function ServerEmitter:emit(message, data, unreliable)
		if unreliable == nil then
			unreliable = false
		end
		if RunService:IsServer() then
			error("[tether::error] Cannot emit message from server to server")
		end
		task.spawn(function()
			local _binding = self.master:runServerSendMiddlewares(message, data)
			local dropRequest = _binding[1]
			local newData = _binding[2]
			if dropRequest then
				return nil
			end
			self.master.relayer:queueMessage(self.context, message, { message, newData, unreliable })
		end)
	end
	function ServerEmitter:setCallback(message, returnMessage, callback)
		if RunService:IsClient() then
			error("[tether::error] Cannot listen to client message from server")
		end
		return self:on(message, function(player, data)
			local returnValue = callback(player, data)
			-- Defer the response emission to end of frame and swap context to avoid context check issues
			-- task.defer guarantees response is sent by end of current frame, ensuring predictable timing in production
			task.defer(function()
				setLuneContext("server")
				self.master.client:emit(player, returnMessage, returnValue)
				setLuneContext("both")
			end)
		end)
	end
	function ServerEmitter:invoke(message, returnMessage, data, unreliable)
		if unreliable == nil then
			unreliable = false
		end
		if RunService:IsServer() then
			error("[tether::error] Cannot invoke function from server to server")
		end
		local _binding = self.master
		local clientFunctions = _binding.clientFunctions
		local _returnMessage = returnMessage
		if not (clientFunctions[_returnMessage] ~= nil) then
			local _returnMessage_1 = returnMessage
			clientFunctions[_returnMessage_1] = {}
		end
		local _returnMessage_1 = returnMessage
		local functions = clientFunctions[_returnMessage_1]
		local returnValue
		local responseCallback = function(data)
			returnValue = data
			return returnValue
		end
		functions[responseCallback] = true
		self:emit(message, data, unreliable)
		return TS.Promise.new(function(resolve, reject)
			-- awful
			local frames = 0
			while true do
				local _condition = returnValue == nil
				if _condition then
					local _original = frames
					frames += 1
					_condition = _original < 400
				end
				if not _condition then
					break
				end
				RunService.Heartbeat:Wait()
			end
			if frames == 400 then
				return reject("[tether::error] Server function timed out (no response)")
			end
			-- clean up the callback after receiving the response
			functions[responseCallback] = nil
			resolve(returnValue)
		end)
	end
end
return {
	ServerEmitter = ServerEmitter,
}
