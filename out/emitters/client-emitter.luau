-- Compiled with roblox-ts v3.0.0
local TS = _G[script]
local _services = TS.import(script, TS.getModule(script, "@rbxts", "services"))
local Players = _services.Players
local RunService = _services.RunService
local ContextualEmitter = TS.import(script, script.Parent, "contextual-emitter").ContextualEmitter
local getTestMode = TS.import(script, script.Parent.Parent, "test-mode").getTestMode
if setLuneContext == nil then
	setLuneContext = function() end
end
local ClientEmitter
do
	local super = ContextualEmitter
	ClientEmitter = setmetatable({}, {
		__tostring = function()
			return "ClientEmitter"
		end,
		__index = super,
	})
	ClientEmitter.__index = ClientEmitter
	function ClientEmitter.new(...)
		local self = setmetatable({}, ClientEmitter)
		return self:constructor(...) or self
	end
	function ClientEmitter:constructor(...)
		super.constructor(self, ...)
		self.context = "client"
	end
	function ClientEmitter:emit(player, message, data, unreliable)
		if unreliable == nil then
			unreliable = false
		end
		if getTestMode() then
			local _binding = self.master:runClientSendMiddlewares(message, data, player)
			local dropRequest = _binding[1]
			local newData = _binding[2]
			if dropRequest then
				return nil
			end
			self.master:deliverLocally(false, message, newData)
			return nil
		end
		if RunService:IsClient() then
			error("[tether::error] Cannot emit message from client to client")
		end
		task.spawn(function()
			local _binding = self.master:runClientSendMiddlewares(message, data, player)
			local dropRequest = _binding[1]
			local newData = _binding[2]
			if dropRequest then
				return nil
			end
			self.master.relayer:queueMessage(self.context, message, { player, message, newData, unreliable })
		end)
	end
	function ClientEmitter:emitExcept(player, message, data, unreliable)
		if unreliable == nil then
			unreliable = false
		end
		local shouldSendTo = function(p)
			local _player = player
			local _result
			if typeof(_player) == "Instance" then
				_result = p ~= player
			else
				local _player_1 = player
				local _p = p
				_result = not (table.find(_player_1, _p) ~= nil)
			end
			return _result
		end
		local _self = self
		local _exp = Players:GetPlayers()
		-- ▼ ReadonlyArray.filter ▼
		local _newValue = {}
		local _length = 0
		for _k, _v in _exp do
			if shouldSendTo(_v, _k - 1, _exp) == true then
				_length += 1
				_newValue[_length] = _v
			end
		end
		-- ▲ ReadonlyArray.filter ▲
		_self:emit(_newValue, message, data, unreliable)
	end
	function ClientEmitter:emitAll(message, data, unreliable)
		if unreliable == nil then
			unreliable = false
		end
		if getTestMode() then
			local _binding = self.master:runClientSendMiddlewares(message, data)
			local dropRequest = _binding[1]
			local newData = _binding[2]
			if dropRequest then
				return nil
			end
			self.master:deliverLocally(false, message, newData)
			return nil
		end
		if RunService:IsClient() then
			error("[tether::error] Cannot emit message from client to all clients")
		end
		task.spawn(function()
			local _binding = self.master:runClientSendMiddlewares(message, data)
			local dropRequest = _binding[1]
			local newData = _binding[2]
			if dropRequest then
				return nil
			end
			self.master.relayer:queueMessage(true, message, { message, newData, unreliable })
		end)
	end
	function ClientEmitter:setCallback(message, returnMessage, callback)
		if not getTestMode() and RunService:IsServer() then
			error("[tether::error] Cannot listen to server message from client")
		end
		return self:on(message, function(data)
			local returnValue = callback(data)
			-- Defer the response emission to end of frame and swap context to avoid context check issues
			-- task.defer guarantees response is sent by end of current frame, ensuring predictable timing in production
			task.defer(function()
				setLuneContext("client")
				self.master.server:emit(returnMessage, returnValue)
				setLuneContext("both")
			end)
		end)
	end
	function ClientEmitter:invoke(message, returnMessage, player, data, unreliable)
		if unreliable == nil then
			unreliable = false
		end
		if not getTestMode() and RunService:IsClient() then
			error("[tether::error] Cannot invoke function from client to client")
		end
		local _binding = self.master
		local serverFunctions = _binding.serverFunctions
		local _returnMessage = returnMessage
		if not (serverFunctions[_returnMessage] ~= nil) then
			local _returnMessage_1 = returnMessage
			serverFunctions[_returnMessage_1] = {}
		end
		local _returnMessage_1 = returnMessage
		local functions = serverFunctions[_returnMessage_1]
		local returnValue
		local responseCallback = function(data)
			returnValue = data
			return returnValue
		end
		functions[responseCallback] = true
		self:emit(player, message, data, unreliable)
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
				return reject("[tether::error] Client function timed out (no response)")
			end
			-- clean up the callback after receiving the response
			functions[responseCallback] = nil
			resolve(returnValue)
		end)
	end
end
return {
	ClientEmitter = ClientEmitter,
}
