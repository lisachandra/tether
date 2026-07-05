-- Compiled with roblox-ts v3.0.0
local COEFF = 0xFA
local function bufferToString(buf)
	local s = { "{ " }
	if buf ~= nil then
		do
			local i = 0
			local _shouldIncrement = false
			while true do
				if _shouldIncrement then
					i += 1
				else
					_shouldIncrement = true
				end
				if not (i < buffer.len(buf)) then
					break
				end
				local byte = buffer.readu8(buf, i)
				local _arg0 = tostring(byte)
				table.insert(s, _arg0)
				local _arg0_1 = if i < buffer.len(buf) - 1 then ", " else ""
				table.insert(s, _arg0_1)
			end
		end
	end
	table.insert(s, " }")
	return table.concat(s, "")
end
local function encodeMessage(message)
	message = bit32.band((bit32.bxor(message, COEFF)), 0xFF)
	return bit32.bor((bit32.lshift(message, 3)), (bit32.arshift(message, 5)))
end
local function decodeMessage(encoded)
	encoded = bit32.bor((bit32.arshift(encoded, 3)), (bit32.lshift(encoded, 5)))
	return bit32.band((bit32.bxor(encoded, COEFF)), 0xFF)
end
local function writeMessage(buf, message)
	local _arg0 = buffer.len(buf) == 1
	assert(_arg0)
	buffer.writeu8(buf, 0, encodeMessage(message))
end
local function readMessage(packet)
	local _packet = packet
	local buf = if type(_packet) == "buffer" then packet else packet.messageBuf
	return decodeMessage(buffer.readu8(buf, 0))
end
local function createMessageBuffer(message)
	local messageBuf = buffer.create(1)
	writeMessage(messageBuf, message)
	return messageBuf
end
local getPacket
local function getAllPacketsWhich(infos, predicate)
	local _infos = infos
	local _predicate = predicate
	-- ▼ ReadonlyArray.filter ▼
	local _newValue = {}
	local _length = 0
	for _k, _v in _infos do
		if _predicate(_v, _k - 1, _infos) == true then
			_length += 1
			_newValue[_length] = _v
		end
	end
	-- ▲ ReadonlyArray.filter ▲
	-- ▼ ReadonlyArray.map ▼
	local _newValue_1 = table.create(#_newValue)
	for _k, _v in _newValue do
		_newValue_1[_k] = getPacket(_v, _k - 1, _newValue)
	end
	-- ▲ ReadonlyArray.map ▲
	return _newValue_1
end
local function isUnreliable(info)
	return info.unreliable
end
local function isReliable(info)
	return not info.unreliable
end
function getPacket(info)
	return info.packet
end
local function shouldBatch(message, options)
	local _condition = options.batchRemotes
	if _condition then
		local _doNotBatch = options.doNotBatch
		local _message = message
		_condition = not (_doNotBatch[_message] ~= nil)
	end
	return _condition
end
return {
	bufferToString = bufferToString,
	encodeMessage = encodeMessage,
	decodeMessage = decodeMessage,
	writeMessage = writeMessage,
	readMessage = readMessage,
	createMessageBuffer = createMessageBuffer,
	getAllPacketsWhich = getAllPacketsWhich,
	isUnreliable = isUnreliable,
	isReliable = isReliable,
	getPacket = getPacket,
	shouldBatch = shouldBatch,
}
