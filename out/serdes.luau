-- Compiled with roblox-ts v3.0.0
local TS = _G[script]
local createSerializer = TS.import(script, TS.getModule(script, "@rbxts", "serio").out).default
local createMessageBuffer = TS.import(script, script.Parent, "utility").createMessageBuffer
local Serdes
do
	Serdes = setmetatable({}, {
		__tostring = function()
			return "Serdes"
		end,
	})
	Serdes.__index = Serdes
	function Serdes.new(...)
		local self = setmetatable({}, Serdes)
		return self:constructor(...) or self
	end
	function Serdes:constructor()
		self.serializers = {}
	end
	function Serdes:getSchema(message, meta)
		local serializer = self:getSerializer(message)
		if serializer == nil then
			error(`[@rbxts/tether]: Cannot get schema metadata for message '{message}', serializer not found`)
		end
		return serializer:getSchema(meta)
	end
	function Serdes:serializePacket(message, data)
		local serializer = self:getSerializer(message)
		local messageBuf = createMessageBuffer(message)
		if serializer == nil then
			return {
				messageBuf = messageBuf,
				buf = buffer.create(0),
				blobs = {},
			}
		end
		local _object = {
			messageBuf = messageBuf,
		}
		for _k, _v in serializer.serialize(data) do
			_object[_k] = _v
		end
		return _object
	end
	function Serdes:deserializePacket(message, serializedPacket)
		local serializer = self:getSerializer(message)
		local _result = serializer
		if _result ~= nil then
			_result = _result.deserialize(serializedPacket)
		end
		return _result
	end
	function Serdes:addSerializer(message, meta)
		self.serializers[message] = self:createMessageSerializer(meta)
	end
	function Serdes:createMessageSerializer(meta)
		return createSerializer(meta)
	end
	function Serdes:getSerializer(message)
		return self.serializers[message]
	end
end
return {
	Serdes = Serdes,
}
