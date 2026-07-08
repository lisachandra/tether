-- Compiled with roblox-ts v3.0.0
local TS = _G[script]
local _services = TS.import(script, TS.getModule(script, "@rbxts", "services"))
local ReplicatedStorage = _services.ReplicatedStorage
local RunService = _services.RunService
local _utility = TS.import(script, script.Parent, "utility")
local getAllPacketsWhich = _utility.getAllPacketsWhich
local isReliable = _utility.isReliable
local isUnreliable = _utility.isUnreliable
local shouldBatch = _utility.shouldBatch
local getTestMode = TS.import(script, script.Parent, "test-mode").getTestMode
if setLuneContext == nil then
	setLuneContext = function() end
end
local nextEmitterId = 0
local function createRemotePair(id)
	local sendName = `tether_send_{id}`
	local sendUnreliableName = `tether_sendUnreliable_{id}`
	local existingSend = ReplicatedStorage:FindFirstChild(sendName)
	local send = (existingSend or Instance.new("RemoteEvent", ReplicatedStorage))
	if existingSend == nil then
		send.Name = sendName
	end
	local existingUnreliable = ReplicatedStorage:FindFirstChild(sendUnreliableName)
	local sendUnreliable = (existingUnreliable or Instance.new("UnreliableRemoteEvent", ReplicatedStorage))
	if existingUnreliable == nil then
		sendUnreliable.Name = sendUnreliableName
	end
	return {
		send = send,
		sendUnreliable = sendUnreliable,
	}
end
local Relayer
do
	Relayer = setmetatable({}, {
		__tostring = function()
			return "Relayer"
		end,
	})
	Relayer.__index = Relayer
	function Relayer.new(...)
		local self = setmetatable({}, Relayer)
		return self:constructor(...) or self
	end
	function Relayer:constructor(emitter)
		self.emitter = emitter
		self.serverQueue = {}
		self.clientBroadcastQueue = {}
		self.clientQueue = {}
		self.isRelaying = false
		local _original = nextEmitterId
		nextEmitterId += 1
		self.emitterId = _original
		if getTestMode() then
			self.sendMessage = nil
			self.sendUnreliableMessage = nil
			return self
		end
		local remotes = createRemotePair(self.emitterId)
		self.sendMessage = remotes.send
		self.sendUnreliableMessage = remotes.sendUnreliable
		setLuneContext("client")
		if RunService:IsClient() then
			self.emitter.trash:add(self.sendMessage.OnClientEvent:Connect(function(...)
				local serializedPacket = { ... }
				return self.emitter:onRemoteFire(false, serializedPacket)
			end))
			self.emitter.trash:add(self.sendUnreliableMessage.OnClientEvent:Connect(function(...)
				local serializedPacket = { ... }
				return self.emitter:onRemoteFire(false, serializedPacket)
			end))
		end
		setLuneContext("server")
		if RunService:IsServer() then
			self.emitter.trash:add(self.sendMessage.OnServerEvent:Connect(function(player, ...)
				local serializedPacket = { ... }
				return self.emitter:onRemoteFire(true, serializedPacket, player)
			end))
			self.emitter.trash:add(self.sendUnreliableMessage.OnServerEvent:Connect(function(player, ...)
				local serializedPacket = { ... }
				return self.emitter:onRemoteFire(true, serializedPacket, player)
			end))
		end
		-- Clean up remotes when emitter is destroyed
		self.emitter.trash:add(function()
			self.sendMessage:Destroy()
			self.sendUnreliableMessage:Destroy()
		end)
		local elapsed = 0
		local _binding = self.emitter.options
		local batchRemotes = _binding.batchRemotes
		local batchRate = _binding.batchRate
		if not batchRemotes then
			return self
		end
		self.emitter.trash:add(RunService.Heartbeat:Connect(function(dt)
			elapsed += dt
			if elapsed < batchRate then
				return nil
			end
			elapsed -= batchRate
			self:relayAll()
		end))
	end
	function Relayer:queueMessage(context, message, data)
		local queue = if context == "client" then self.clientQueue elseif context == true then self.clientBroadcastQueue else self.serverQueue
		local _data = data
		table.insert(queue, _data)
		if not shouldBatch(message, self.emitter.options) then
			self:relayAll()
		end
	end
	function Relayer:relayAll()
		-- Guard against re-entrancy: processing messages can trigger new emits
		if self.isRelaying then
			return nil
		end
		self.isRelaying = true
		if RunService:IsClient() then
			if not (#self.serverQueue == 0) then
				local queue = self.serverQueue
				self.serverQueue = {}
				self:relay(function(...)
					local packets = { ... }
					return self.sendMessage:FireServer(unpack(packets))
				end, function(...)
					local packets = { ... }
					return self.sendUnreliableMessage:FireServer(unpack(packets))
				end, queue)
			end
			self.isRelaying = false
			return nil
		end
		if not (#self.clientBroadcastQueue == 0) then
			local queue = self.clientBroadcastQueue
			self.clientBroadcastQueue = {}
			self:relay(function(...)
				local packets = { ... }
				return self.sendMessage:FireAllClients(unpack(packets))
			end, function(...)
				local packets = { ... }
				return self.sendUnreliableMessage:FireAllClients(unpack(packets))
			end, queue)
		end
		if not (#self.clientQueue == 0) then
			local playerPacketInfos = {}
			local addClientPacket = function(player, packetInfo)
				local _player = player
				local _condition = playerPacketInfos[_player]
				if _condition == nil then
					_condition = {}
				end
				local packetInfos = _condition
				local _packetInfo = packetInfo
				table.insert(packetInfos, _packetInfo)
				local _player_1 = player
				playerPacketInfos[_player_1] = packetInfos
			end
			local queue = self.clientQueue
			self.clientQueue = {}
			for _, _binding in queue do
				local player = _binding[1]
				local message = _binding[2]
				local data = _binding[3]
				local unreliable = _binding[4]
				local packet = self.emitter.serdes:serializePacket(message, data)
				local info = {
					packet = packet,
					unreliable = unreliable,
				}
				if typeof(player) == "Instance" then
					addClientPacket(player, info)
				else
					for _1, p in player do
						addClientPacket(p, info)
					end
				end
			end
			for player, packetInfos in playerPacketInfos do
				if #packetInfos == 0 then
					continue
				end
				local unreliablePackets = getAllPacketsWhich(packetInfos, isUnreliable)
				local packets = getAllPacketsWhich(packetInfos, isReliable)
				if not (#unreliablePackets == 0) then
					self.sendUnreliableMessage:FireClient(player, unpack(unreliablePackets))
				end
				if not (#packets == 0) then
					self.sendMessage:FireClient(player, unpack(packets))
				end
			end
		end
		self.isRelaying = false
	end
	function Relayer:relay(send, sendUnreliable, queue)
		if #queue == 0 then
			return nil
		end
		-- ▼ ReadonlyArray.map ▼
		local _newValue = table.create(#queue)
		local _callback = function(messageData)
			local message
			local data
			local unreliable
			local _arg0 = messageData[1]
			if typeof(_arg0) == "Instance" then
				local _binding = messageData
				message = _binding[2]
				data = _binding[3]
				unreliable = _binding[4]
			else
				local _binding = messageData
				message = _binding[1]
				data = _binding[2]
				unreliable = _binding[3]
			end
			local packet = self.emitter.serdes:serializePacket(message, data)
			return {
				packet = packet,
				unreliable = unreliable,
			}
		end
		for _k, _v in queue do
			_newValue[_k] = _callback(_v, _k - 1, queue)
		end
		-- ▲ ReadonlyArray.map ▲
		local packetInfos = _newValue
		local unreliablePackets = getAllPacketsWhich(packetInfos, isUnreliable)
		local packets = getAllPacketsWhich(packetInfos, isReliable)
		if not (#unreliablePackets == 0) then
			sendUnreliable(unpack(unreliablePackets))
		end
		if not (#packets == 0) then
			send(unpack(packets))
		end
	end
end
return {
	Relayer = Relayer,
}
