import { ContextualEmitter } from "./contextual-emitter";
import type { BaseMessage, ClientMessageCallback, ClientFunctionMessageCallback } from "../structs";
export declare class ClientEmitter<MessageData> extends ContextualEmitter<MessageData> {
    readonly context = "client";
    readonly on: <K extends keyof MessageData>(this: ClientEmitter<MessageData>, message: K & BaseMessage, callback: ClientMessageCallback<MessageData[K]>) => () => void;
    readonly once: <K extends keyof MessageData>(this: ClientEmitter<MessageData>, message: K & BaseMessage, callback: ClientMessageCallback<MessageData[K]>) => () => void;
    /**
     * Emits a message to a specific client or multiple clients
     *
     * @param player The player(s) to whom the message is sent
     * @param message The message kind to be sent
     * @param data The data associated with the message
     * @param unreliable Whether the message should be sent unreliably
     */
    emit<K extends keyof MessageData>(player: Player | Player[], message: K & BaseMessage, data?: MessageData[K], unreliable?: boolean): void;
    /**
     * Emits a message to all clients except the specified client(s)
     *
     * @param player The player(s) to whom the message is not sent
     * @param message The message kind to be sent
     * @param data The data associated with the message
     * @param unreliable Whether the message should be sent unreliably
     */
    emitExcept<K extends keyof MessageData>(player: Player | Player[], message: K & BaseMessage, data?: MessageData[K], unreliable?: boolean): void;
    /**
   * Emits a message to all connected clients
   *
   * @param message The message kind to be sent
   * @param data The data associated with the message
   * @param unreliable Whether the message should be sent unreliably
   */
    emitAll<K extends keyof MessageData>(message: K & BaseMessage, data?: MessageData[K], unreliable?: boolean): void;
    /**
     * Sets a callback for a simulated remote function
     *
     * @returns A destructor function that disconnects the callback from the message
     */
    setCallback<K extends keyof MessageData, R extends keyof MessageData>(message: K & BaseMessage, returnMessage: R & BaseMessage, callback: ClientFunctionMessageCallback<MessageData[K], MessageData[R]>): () => void;
    /**
     * Simulates a remote function invocation
     *
     * @param message The message kind to be sent
     * @param returnMessage The message kind to be returned
     * @param player The player to whom the function is sent
     * @param data The data associated with the message
     * @param unreliable Whether the message should be sent unreliably
     */
    invoke<K extends keyof MessageData, R extends keyof MessageData>(message: K & BaseMessage, returnMessage: R & BaseMessage, player: Player, data?: MessageData[K], unreliable?: boolean): Promise<MessageData[R]>;
}
