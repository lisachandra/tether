-- Compiled with roblox-ts v3.0.0
local TS = _G[script]
local Players = TS.import(script, TS.getModule(script, "@rbxts", "services")).Players
local Destroyable = TS.import(script, TS.getModule(script, "@rbxts", "destroyable").out)
local repr = TS.import(script, TS.getModule(script, "@rbxts", "repr").out).default
local _middleware = TS.import(script, script.Parent.Parent, "middleware")
local DropRequest = _middleware.DropRequest
local MiddlewareProvider = _middleware.MiddlewareProvider
local ServerEmitter = TS.import(script, script.Parent, "server-emitter").ServerEmitter
local ClientEmitter = TS.import(script, script.Parent, "client-emitter").ClientEmitter
local Relayer = TS.import(script, script.Parent.Parent, "relayer").Relayer
local Serdes = TS.import(script, script.Parent.Parent, "serdes").Serdes
local readMessage = TS.import(script, script.Parent.Parent, "utility").readMessage
if setLuneContext == nil then
	setLuneContext = function() end
end
setLuneContext("both")
local guardFailed = function(message, data)
	return `[tether::warning]: Type validation guard failed for message '{message}' - check your sent data\nSent data: {repr(data)}`
end
local defaultMesssageEmitterOptions = {
	batchRemotes = true,
	batchRate = 1 / 24,
	doNotBatch = {},
}
local MessageEmitter
do
	local super = Destroyable
	MessageEmitter = setmetatable({}, {
		__tostring = function()
			return "MessageEmitter"
		end,
		__index = super,
	})
	MessageEmitter.__index = MessageEmitter
	function MessageEmitter.new(...)
		local self = setmetatable({}, MessageEmitter)
		return self:constructor(...) or self
	end
	function MessageEmitter:constructor(options)
		if options == nil then
			options = defaultMesssageEmitterOptions
		end
		super.constructor(self)
		self.options = options
		self.server = ServerEmitter.new(self)
		self.client = ClientEmitter.new(self)
		self.middleware = MiddlewareProvider.new()
		self.relayer = Relayer.new(self)
		self.serdes = Serdes.new()
		self.clientCallbacks = {}
		self.clientFunctions = {}
		self.serverCallbacks = {}
		self.serverFunctions = {}
		self.guards = {}
		self.testPlayer = self.options.testPlayer
		self.trash:add(function()
			self.clientCallbacks = {}
			self.serverCallbacks = {}
			self.clientFunctions = {}
			self.clientCallbacks = {}
			self.serdes.serializers = {}
			self.relayer:relayAll()
			setmetatable(self, nil)
		end)
	end
	function MessageEmitter:create(options, meta)
		local _object = table.clone(defaultMesssageEmitterOptions)
		setmetatable(_object, nil)
		if options then
			for _k, _v in options do
				_object[_k] = _v
			end
		end
		local emitter = MessageEmitter.new(_object)
		if meta == nil then
			warn("[tether::warning] Failed to generate message metadata - make sure you have the Flamework transformer and are using Flamework macro-friendly types in your schemas")
			return emitter
		end
		-- lore
		-- https://discord.com/channels/476080952636997633/506983834877689856/1363938149486821577
		for kind, _binding in pairs(meta) do
			local guard = _binding.guard
			local serializerMetadata = _binding.serializerMetadata
			local numberKind = tonumber(kind)
			emitter.guards[numberKind] = guard
			if serializerMetadata == nil then
				continue
			end
			emitter.serdes:addSerializer(numberKind, serializerMetadata)
		end
		return emitter
	end
	function MessageEmitter:runClientSendMiddlewares(message, data, player)
		if not self:validateData(message, data) then
			return { true, data }
		end
		local players = player or Players:GetPlayers()
		local ctx = {
			message = message,
			data = data,
			getRawData = function()
				return self.serdes:serializePacket(message, data)
			end,
		}
		for _, globalMiddleware in self.middleware:getClientGlobal() do
			local result = globalMiddleware(players, ctx)
			if not self:validateData(message, ctx.data, "Invalid data after global client middleware") then
				return { true, ctx.data }
			end
			if result == DropRequest then
				self.middleware:notifyRequestDropped(message, "Global client middleware")
				return { true, ctx.data }
			end
		end
		for _, middleware in self.middleware:getClient(message) do
			local result = middleware(players, ctx)
			if not self:validateData(message, ctx.data, "Invalid data after client middleware") then
				return { true, ctx.data }
			end
			if result == DropRequest then
				self.middleware:notifyRequestDropped(message, "Client middleware")
				return { true, ctx.data }
			end
		end
		if not self:validateData(message, ctx.data) then
			return { true, ctx.data }
		end
		return { false, ctx.data }
	end
	function MessageEmitter:runServerSendMiddlewares(message, data)
		if not self:validateData(message, data) then
			return { true, data }
		end
		local ctx = {
			message = message,
			data = data,
			getRawData = function()
				return self.serdes:serializePacket(message, data)
			end,
		}
		for _, globalMiddleware in self.middleware:getServerGlobal() do
			if not self:validateData(message, ctx.data, "Invalid data after global server middleware") then
				return { true, ctx.data }
			end
			local result = globalMiddleware(ctx)
			if result == DropRequest then
				self.middleware:notifyRequestDropped(message, "Global server middleware")
				return { true, ctx.data }
			end
		end
		for _, middleware in self.middleware:getServer(message) do
			if not self:validateData(message, ctx.data, "Invalid data after server middleware") then
				return { true, ctx.data }
			end
			local result = middleware(ctx)
			if result == DropRequest then
				self.middleware:notifyRequestDropped(message, "Server middleware")
				return { true, ctx.data }
			end
		end
		if not self:validateData(message, ctx.data) then
			return { true, ctx.data }
		end
		return { false, ctx.data }
	end
	function MessageEmitter:deliverLocally(isServer, message, data, player)
		-- Deliver to event callbacks
		local callbacksMap = if isServer then self.serverCallbacks else self.clientCallbacks
		local _message = message
		local callbacks = callbacksMap[_message]
		if callbacks ~= nil then
			if isServer then
				local testPlayer = player or self.testPlayer or ({
					Name = "TestPlayer",
				})
				for callback in callbacks do
					self:executeServerCallback(callback, testPlayer, message, data)
				end
			else
				for callback in callbacks do
					self:executeClientCallback(callback, message, data)
				end
			end
		end
		-- Deliver to function callbacks (for invoke/setCallback patterns)
		local functionsMap = if isServer then self.serverFunctions else self.clientFunctions
		local _message_1 = message
		local functions = functionsMap[_message_1]
		if functions ~= nil then
			for callback in functions do
				self:executeClientCallback(callback, message, data)
			end
		end
	end
	function MessageEmitter:onRemoteFire(isServer, serializedPackets, player)
		for _, packet in serializedPackets do
			if buffer.len(packet.messageBuf) > 1 then
				return warn("[tether::warning] Rejected packet because message buffer was larger than one byte")
			end
			local message = readMessage(packet)
			self:executeEventCallbacks(isServer, message, packet, player)
			self:executeFunctions(isServer, message, packet)
		end
	end
	function MessageEmitter:getSchema(message, meta)
		return self.serdes:getSchema(message, meta)
	end
	function MessageEmitter:runServerReceiveMiddlewares(message, player, data)
		local ctx = {
			message = message,
			data = data,
			getRawData = function()
				return self.serdes:serializePacket(message, data)
			end,
		}
		for _, middleware in self.middleware:getServerReceive(message) do
			local result = middleware(player, ctx)
			if not self:validateData(message, ctx.data, "Invalid data after server receive middleware") then
				return { true, ctx.data }
			end
			if result == DropRequest then
				self.middleware:notifyRequestDropped(message, "Server receive middleware")
				return { true, ctx.data }
			end
		end
		if not self:validateData(message, ctx.data) then
			return { true, ctx.data }
		end
		return { false, ctx.data }
	end
	function MessageEmitter:runClientReceiveMiddlewares(message, data)
		local ctx = {
			message = message,
			data = data,
			getRawData = function()
				return self.serdes:serializePacket(message, data)
			end,
		}
		for _, middleware in self.middleware:getClientReceive(message) do
			local result = middleware(ctx)
			if not self:validateData(message, ctx.data, "Invalid data after client receive middleware") then
				return { true, ctx.data }
			end
			if result == DropRequest then
				self.middleware:notifyRequestDropped(message, "Client receive middleware")
				return { true, ctx.data }
			end
		end
		if not self:validateData(message, ctx.data) then
			return { true, ctx.data }
		end
		return { false, ctx.data }
	end
	function MessageEmitter:validateData(message, data, requestDropReason)
		if requestDropReason == nil then
			requestDropReason = "Invalid data"
		end
		local _guards = self.guards
		local _message = message
		local guard = _guards[_message]
		local guardPassed = guard(data)
		if not guardPassed then
			warn(guardFailed(message, data))
			self.middleware:notifyRequestDropped(message, requestDropReason)
		end
		return guardPassed
	end
	function MessageEmitter:executeFunctions(isServer, message, serializedPacket)
		local functionsMap = if isServer then self.serverFunctions else self.clientFunctions
		local _message = message
		local functions = functionsMap[_message]
		if functions == nil then
			return nil
		end
		local data = self.serdes:deserializePacket(message, serializedPacket)
		for callback in functions do
			self:executeClientCallback(callback, message, data)
		end
	end
	function MessageEmitter:executeEventCallbacks(isServer, message, serializedPacket, player)
		local callbacksMap = if isServer then self.serverCallbacks else self.clientCallbacks
		local _message = message
		local callbacks = callbacksMap[_message]
		if callbacks == nil then
			return nil
		end
		local data = self.serdes:deserializePacket(message, serializedPacket)
		for callback in callbacks do
			if isServer then
				local _arg0 = player ~= nil
				assert(_arg0)
				self:executeServerCallback(callback, player, message, data)
			else
				self:executeClientCallback(callback, message, data)
			end
		end
	end
	function MessageEmitter:executeServerCallback(callback, player, message, data)
		local _binding = self:runServerReceiveMiddlewares(message, player, data)
		local dropRequest = _binding[1]
		local newData = _binding[2]
		if dropRequest then
			return nil
		end
		callback(player, newData)
	end
	function MessageEmitter:executeClientCallback(callback, message, data)
		local _binding = self:runClientReceiveMiddlewares(message, data)
		local dropRequest = _binding[1]
		local newData = _binding[2]
		if dropRequest then
			return nil
		end
		callback(newData)
	end
end
return {
	MessageEmitter = MessageEmitter,
}
