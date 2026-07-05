import { ContextualEmitter } from "./contextual-emitter";
import type { BaseMessage, ServerMessageCallback, ServerFunctionMessageCallback } from "../structs";
export declare class ServerEmitter<MessageData> extends ContextualEmitter<MessageData> {
    readonly context = "server";
    readonly on: <K extends keyof MessageData>(this: ServerEmitter<MessageData>, message: K & BaseMessage, callback: ServerMessageCallback<MessageData[K]>) => () => void;
    readonly once: <K extends keyof MessageData>(this: ServerEmitter<MessageData>, message: K & BaseMessage, callback: ServerMessageCallback<MessageData[K]>) => () => void;
    /**
     * Emits a message to the server
     *
     * @param message The message kind to be sent
     * @param data The data associated with the message
     * @param unreliable Whether the message should be sent unreliably
     */
    emit<K extends keyof MessageData>(message: K & BaseMessage, data?: MessageData[K], unreliable?: boolean): void;
    /**
     * Sets a callback for a simulated remote function
     *
     * @returns A destructor function that disconnects the callback from the message
     */
    setCallback<K extends keyof MessageData, R extends keyof MessageData>(message: K & BaseMessage, returnMessage: R & BaseMessage, callback: ServerFunctionMessageCallback<MessageData[K], MessageData[R]>): () => void;
    /**
     * Simulates a remote function invocation
     *
     * @param message The message kind to be sent
     * @param returnMessage The message kind to be returned
     * @param data The data associated with the message
     * @param unreliable Whether the message should be sent unreliably
     */
    invoke<K extends keyof MessageData, R extends keyof MessageData>(message: K & BaseMessage, returnMessage: R & BaseMessage, data?: MessageData[K], unreliable?: boolean): Promise<MessageData[R]>;
}
