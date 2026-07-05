export declare const enum Error {
    NoServerListen = "[tether::error] Cannot listen to server message from client",
    NoClientListen = "[tether::error] Cannot listen to client message from server",
    NoServerToServer = "[tether::error] Cannot emit message from server to server",
    NoClientToClient = "[tether::error] Cannot emit message from client to client",
    NoClientToAllClients = "[tether::error] Cannot emit message from client to all clients",
    NoServerToServerFunction = "[tether::error] Cannot invoke function from server to server",
    NoClientToClientFunction = "[tether::error] Cannot invoke function from client to client",
    ServerFunctionTimeout = "[tether::error] Server function timed out (no response)",
    ClientFunctionTimeout = "[tether::error] Client function timed out (no response)"
}
export declare const enum Warning {
    MessageBufferTooLong = "[tether::warning] Rejected packet because message buffer was larger than one byte",
    MetaGenerationFailed = "[tether::warning] Failed to generate message metadata - make sure you have the Flamework transformer and are using Flamework macro-friendly types in your schemas"
}
