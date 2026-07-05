-- Compiled with roblox-ts v3.0.0
local TS = _G[script]
local RunService = TS.import(script, TS.getModule(script, "@rbxts", "services")).RunService
local repr = TS.import(script, TS.getModule(script, "@rbxts", "repr").out).default
local DropRequest = TS.import(script, script.Parent, "middleware").DropRequest
local bufferToString = TS.import(script, script.Parent, "utility").bufferToString
local BLOB_SIZE = 5
local BuiltinMiddlewares = {}
do
	local _container = BuiltinMiddlewares
	--[[
		*
		     * Creates a shared middleware that will simulate a ping of the given amount when a message is sent
		     *
		     * @param pingInMs The amount of time in milliseconds that the middleware should wait
		     * @returns A shared middleware that will simulate a ping
		     
	]]
	local function simulatePing(pingInMs)
		return function()
			task.wait(pingInMs / 1000)
			return nil
		end
	end
	_container.simulatePing = simulatePing
	--[[
		*
		     * Creates a shared middleware that will check if a message packet exceeds the given maximum size in bytes
		     *
		     * @param maxBytes The maximum size of the packet in bytes
		     * @param throwError Whether the middleware should throw an error if the packet exceeds the maximum size, or simply drop the request
		     * @returns A shared middleware that will check if a message packet exceeds the given maximum size
		     
	]]
	local function maxPacketSize(maxBytes, throwError)
		if throwError == nil then
			throwError = true
		end
		return function(ctx)
			local _binding = ctx.getRawData()
			local buf = _binding.buf
			local blobs = _binding.blobs
			local bufferSize = if buf == nil then 0 else buffer.len(buf)
			local blobsSize = if blobs == nil then 0 else #blobs * BLOB_SIZE
			local totalSize = bufferSize + blobsSize
			if totalSize > maxBytes then
				return if throwError then error(`[@rbxts/tether]: Message '{ctx.message}' exceeded maximum packet size of {maxBytes} bytes`) else DropRequest
			end
		end
	end
	_container.maxPacketSize = maxPacketSize
	--[[
		*
		     * Creates a shared middleware that will drop any message that occurs within the given interval of the previous message
		     *
		     * @param interval The interval in seconds that the middleware should wait before allowing a new request
		     * @returns A middleware that will drop any message that occurs within the given interval
		     
	]]
	local function rateLimit(interval)
		local lastRequest = 0
		return function()
			if os.clock() - lastRequest < interval then
				return DropRequest
			end
			lastRequest = os.clock()
		end
	end
	_container.rateLimit = rateLimit
	local horizontalLine = string.rep("-", 36)
	--[[
		*
		     * Creates a shared middleware that will log a message whenever a message is sent, containing the following information:
		     * - The message kind
		     * - The data associated with the message
		     * - The raw data (buffer and blobs) associated with the message
		     * - The size of the packet (in bytes)
		     * - The size of the buffer (in bytes)
		     * - The size of the blobs (in bytes)
		     * - The schema string associated with the message (if it can be deduced)
		     *
		     * @returns A shared middleware that will log a message whenever a message is sent.
		     * @metadata macro
		     
	]]
	local function debug(schema)
		return function(_param)
			local message = _param.message
			local data = _param.data
			local getRawData = _param.getRawData
			local _binding = getRawData()
			local messageBuf = _binding.messageBuf
			local buf = _binding.buf
			local blobs = _binding.blobs
			local bufferSize = if buf == nil then 0 else buffer.len(buf)
			local blobsSize = if blobs == nil then 0 else #blobs * BLOB_SIZE
			local schemaString = if schema ~= nil then " " .. table.concat(string.split(repr(schema[1], {
				pretty = true,
			}), "\n"), "\n ") else "unknown"
			local text = { "\n", horizontalLine, "\n", "Packet sent to ", (if RunService:IsServer() then "client" else "server"), "!\n", " - Message: ", tostring(message), "\n", " - Data: ", repr(data, {
				pretty = true,
			}), "\n", " - Raw data:\n", "   - Message Buffer: ", bufferToString(messageBuf), "\n", "   - Buffer: ", bufferToString(buf), "\n", "   - Blobs: ", repr(blobs, {
				pretty = false,
				robloxClassName = true,
			}), "\n", " - Packet size: ", tostring(bufferSize + blobsSize), " bytes\n", "   - Buffer: ", tostring(bufferSize), " bytes\n", "   - Blobs: ", tostring(blobsSize), " bytes\n", " - Schema: ", schemaString, "\n", horizontalLine, "\n" }
			print(table.concat(text, ""))
		end
	end
	_container.debug = debug
end
return {
	BuiltinMiddlewares = BuiltinMiddlewares,
}
