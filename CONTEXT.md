# Tether — Domain Glossary

## Loopback mode
A `MessageEmitter` configuration where messages are dispatched in-process, bypassing the network layer (Relayer). Activated via `{ testMode: true }` in constructor options.

## Test player
A mock `Player` object used in loopback mode to satisfy server-side callbacks that expect `(player, data)`. Defaults to `{ Name: "TestPlayer" }` but can be overridden via the `testPlayer` option.

## Fire server
The act of simulating a client→server message delivery in loopback mode. Achieved by calling `server.emit()` on an emitter with `testMode: true`.

## Fire client
The act of simulating a server→client message delivery in loopback mode. Achieved by calling `client.emit()` or `client.emitAll()` on an emitter with `testMode: true`.

## Deliver locally
Internal method on `MessageEmitter` that directly invokes registered callbacks without going through the Relayer. Used exclusively in loopback mode.
