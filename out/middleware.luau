-- Compiled with roblox-ts v3.0.0
local DropRequest = newproxy()
-- TODO: middlewares upon received message
local MiddlewareProvider
do
	MiddlewareProvider = setmetatable({}, {
		__tostring = function()
			return "MiddlewareProvider"
		end,
	})
	MiddlewareProvider.__index = MiddlewareProvider
	function MiddlewareProvider.new(...)
		local self = setmetatable({}, MiddlewareProvider)
		return self:constructor(...) or self
	end
	function MiddlewareProvider:constructor()
		self.clientGlobalMiddlewares = {}
		self.serverGlobalMiddlewares = {}
		self.clientSendMiddlewares = {}
		self.serverSendMiddlewares = {}
		self.serverReceiveMiddlewares = {}
		self.clientReceiveMiddlewares = {}
		self.requestDroppedCallbacks = {}
	end
	function MiddlewareProvider:onRequestDropped(callback)
		local _requestDroppedCallbacks = self.requestDroppedCallbacks
		local _callback = callback
		_requestDroppedCallbacks[_callback] = true
		return function()
			local _requestDroppedCallbacks_1 = self.requestDroppedCallbacks
			local _callback_1 = callback
			-- ▼ Set.delete ▼
			local _valueExisted = _requestDroppedCallbacks_1[_callback_1] ~= nil
			_requestDroppedCallbacks_1[_callback_1] = nil
			-- ▲ Set.delete ▲
			return _valueExisted
		end
	end
	function MiddlewareProvider:notifyRequestDropped(message, reason)
		for callback in self.requestDroppedCallbacks do
			callback(message, reason)
		end
	end
	function MiddlewareProvider:getClient(message)
		local _exp = self.clientSendMiddlewares
		if _exp[message] == nil then
			_exp[message] = {}
		end
		return _exp[message]
	end
	function MiddlewareProvider:getServer(message)
		local _exp = self.serverSendMiddlewares
		if _exp[message] == nil then
			_exp[message] = {}
		end
		return _exp[message]
	end
	function MiddlewareProvider:getClientGlobal()
		return self.clientGlobalMiddlewares
	end
	function MiddlewareProvider:getServerGlobal()
		return self.serverGlobalMiddlewares
	end
	function MiddlewareProvider:getClientReceive(message)
		local _exp = self.clientReceiveMiddlewares
		if _exp[message] == nil then
			_exp[message] = {}
		end
		return _exp[message]
	end
	function MiddlewareProvider:getServerReceive(message)
		local _exp = self.serverReceiveMiddlewares
		if _exp[message] == nil then
			_exp[message] = {}
		end
		return _exp[message]
	end
	function MiddlewareProvider:useClient(message, middlewares, order)
		local messageMiddleware = self:getClient(message)
		local _middlewares = middlewares
		if type(_middlewares) == "function" then
			local _condition = order
			if _condition == nil then
				_condition = math.max(#messageMiddleware - 1, 0)
			end
			local _middlewares_1 = middlewares
			table.insert(messageMiddleware, _condition + 1, _middlewares_1)
		else
			for _, middleware in middlewares do
				self:useClient(message, middleware, order)
			end
		end
		return self
	end
	function MiddlewareProvider:useServer(message, middlewares, order)
		local messageMiddleware = self:getServer(message)
		local _middlewares = middlewares
		if type(_middlewares) == "function" then
			local _condition = order
			if _condition == nil then
				_condition = math.max(#messageMiddleware - 1, 0)
			end
			local _middlewares_1 = middlewares
			table.insert(messageMiddleware, _condition + 1, _middlewares_1)
		else
			for _, middleware in middlewares do
				self:useServer(message, middleware, order)
			end
		end
		return self
	end
	function MiddlewareProvider:useShared(message, middlewares, order)
		local server = middlewares
		local _middlewares = middlewares
		local _exp = (if type(_middlewares) == "function" then { middlewares } else middlewares)
		-- ▼ ReadonlyArray.map ▼
		local _newValue = table.create(#_exp)
		local _callback = function(middleware)
			return function(_, ctx)
				return middleware(ctx)
			end
		end
		for _k, _v in _exp do
			_newValue[_k] = _callback(_v, _k - 1, _exp)
		end
		-- ▲ ReadonlyArray.map ▲
		local client = _newValue
		self:useServer(message, server, order)
		return self:useClient(message, client, order)
	end
	function MiddlewareProvider:useClientReceive(message, middlewares, order)
		local messageMiddleware = self:getClientReceive(message)
		local _middlewares = middlewares
		if type(_middlewares) == "function" then
			local _condition = order
			if _condition == nil then
				_condition = math.max(#messageMiddleware - 1, 0)
			end
			local _middlewares_1 = middlewares
			table.insert(messageMiddleware, _condition + 1, _middlewares_1)
		else
			for _, middleware in middlewares do
				self:useClientReceive(message, middleware, order)
			end
		end
		return self
	end
	function MiddlewareProvider:useServerReceive(message, middlewares, order)
		local messageMiddleware = self:getServerReceive(message)
		local _middlewares = middlewares
		if type(_middlewares) == "function" then
			local _condition = order
			if _condition == nil then
				_condition = math.max(#messageMiddleware - 1, 0)
			end
			local _middlewares_1 = middlewares
			table.insert(messageMiddleware, _condition + 1, _middlewares_1)
		else
			for _, middleware in middlewares do
				self:useServerReceive(message, middleware, order)
			end
		end
		return self
	end
	function MiddlewareProvider:useSharedReceive(message, middlewares, order)
		local client = middlewares
		local _middlewares = middlewares
		local _exp = (if type(_middlewares) == "function" then { middlewares } else middlewares)
		-- ▼ ReadonlyArray.map ▼
		local _newValue = table.create(#_exp)
		local _callback = function(middleware)
			return function(_, ctx)
				return middleware(ctx)
			end
		end
		for _k, _v in _exp do
			_newValue[_k] = _callback(_v, _k - 1, _exp)
		end
		-- ▲ ReadonlyArray.map ▲
		local server = _newValue
		self:useServerReceive(message, server, order)
		return self:useClientReceive(message, client, order)
	end
	function MiddlewareProvider:useClientGlobal(middlewares, order)
		local globalMiddleware = self:getClientGlobal()
		local _middlewares = middlewares
		if type(_middlewares) == "function" then
			local _condition = order
			if _condition == nil then
				_condition = math.max(#globalMiddleware - 1, 0)
			end
			local _middlewares_1 = middlewares
			table.insert(globalMiddleware, _condition + 1, _middlewares_1)
		else
			for _, middleware in middlewares do
				self:useClientGlobal(middleware, order)
			end
		end
		return self
	end
	function MiddlewareProvider:useServerGlobal(middlewares, order)
		local globalMiddleware = self:getServerGlobal()
		local _middlewares = middlewares
		if type(_middlewares) == "function" then
			local _condition = order
			if _condition == nil then
				_condition = math.max(#globalMiddleware - 1, 0)
			end
			local _middlewares_1 = middlewares
			table.insert(globalMiddleware, _condition + 1, _middlewares_1)
		else
			for _, middleware in middlewares do
				self:useServerGlobal(middleware, order)
			end
		end
		return self
	end
	function MiddlewareProvider:useSharedGlobal(middlewares, order)
		local _middlewares = middlewares
		local _exp = (if type(_middlewares) == "function" then { middlewares } else middlewares)
		-- ▼ ReadonlyArray.map ▼
		local _newValue = table.create(#_exp)
		local _callback = function(middleware)
			return function(_, ctx)
				return middleware(ctx)
			end
		end
		for _k, _v in _exp do
			_newValue[_k] = _callback(_v, _k - 1, _exp)
		end
		-- ▲ ReadonlyArray.map ▲
		local client = _newValue
		self:useClientGlobal(client, order)
		return self:useServerGlobal(middlewares, order)
	end
	function MiddlewareProvider:deleteSharedGlobal(middlewares)
		local server = middlewares
		local _middlewares = middlewares
		local _exp = (if type(_middlewares) == "function" then { middlewares } else middlewares)
		-- ▼ ReadonlyArray.map ▼
		local _newValue = table.create(#_exp)
		local _callback = function(middleware)
			return function(_, ctx)
				return middleware(ctx)
			end
		end
		for _k, _v in _exp do
			_newValue[_k] = _callback(_v, _k - 1, _exp)
		end
		-- ▲ ReadonlyArray.map ▲
		local client = _newValue
		self:deleteClientGlobal(client)
		self:deleteServerGlobal(server)
	end
	function MiddlewareProvider:deleteClientGlobal(middlewares)
		local clientMiddlewares = self:getClientGlobal()
		local _middlewares = middlewares
		if type(_middlewares) == "function" then
			local _middlewares_1 = middlewares
			local _arg0 = (table.find(clientMiddlewares, _middlewares_1) or 0) - 1
			table.remove(clientMiddlewares, _arg0 + 1)
		else
			for _, middleware in middlewares do
				self:deleteClientGlobal(middleware)
			end
		end
	end
	function MiddlewareProvider:deleteServerGlobal(middlewares)
		local serverMiddlewares = self:getServerGlobal()
		local _middlewares = middlewares
		if type(_middlewares) == "function" then
			local _middlewares_1 = middlewares
			local _arg0 = (table.find(serverMiddlewares, _middlewares_1) or 0) - 1
			table.remove(serverMiddlewares, _arg0 + 1)
		else
			for _, middleware in middlewares do
				self:deleteServerGlobal(middleware)
			end
		end
	end
	function MiddlewareProvider:deleteShared(message, middlewares)
		local server = middlewares
		local _middlewares = middlewares
		local _exp = (if type(_middlewares) == "function" then { middlewares } else middlewares)
		-- ▼ ReadonlyArray.map ▼
		local _newValue = table.create(#_exp)
		local _callback = function(middleware)
			return function(_, ctx)
				return middleware(ctx)
			end
		end
		for _k, _v in _exp do
			_newValue[_k] = _callback(_v, _k - 1, _exp)
		end
		-- ▲ ReadonlyArray.map ▲
		local client = _newValue
		self:deleteClient(message, client)
		self:deleteServer(message, server)
	end
	function MiddlewareProvider:deleteClient(message, middlewares)
		local clientMiddlewares = self:getClient(message)
		local _middlewares = middlewares
		if type(_middlewares) == "function" then
			local _middlewares_1 = middlewares
			local _arg0 = (table.find(clientMiddlewares, _middlewares_1) or 0) - 1
			table.remove(clientMiddlewares, _arg0 + 1)
		else
			for _, middleware in middlewares do
				self:deleteClient(message, middleware)
			end
		end
	end
	function MiddlewareProvider:deleteServer(message, middlewares)
		local serverMiddlewares = self:getServer(message)
		local _middlewares = middlewares
		if type(_middlewares) == "function" then
			local _middlewares_1 = middlewares
			local _arg0 = (table.find(serverMiddlewares, _middlewares_1) or 0) - 1
			table.remove(serverMiddlewares, _arg0 + 1)
		else
			for _, middleware in middlewares do
				self:deleteServer(message, middleware)
			end
		end
	end
end
return {
	DropRequest = DropRequest,
	MiddlewareProvider = MiddlewareProvider,
}
