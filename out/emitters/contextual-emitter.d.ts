import type { MessageEmitter } from "./message-emitter";
import type { BaseMessage, MessageCallback, FunctionMessageCallback } from "../structs";
type Cleanup = () => void;
export declare abstract class ContextualEmitter<MessageData> {
    protected readonly master: MessageEmitter<MessageData>;
    abstract readonly context: "client" | "server";
    /**
     * Constructs a new ContextualEmitter.
     * @param master The master emitter to which messages are delegated.
     */
    constructor(master: MessageEmitter<MessageData>);
    abstract emit<K extends keyof MessageData>(player: (K & BaseMessage) | (Player | Player[]), message?: MessageData[K] | (K & BaseMessage), data?: MessageData[K] | boolean, unreliable?: boolean): void;
    abstract setCallback<K extends keyof MessageData, R extends keyof MessageData>(message: K & BaseMessage, returnMessage: R & BaseMessage, callback: FunctionMessageCallback<MessageData[K], MessageData[R]>): Cleanup;
    abstract invoke<K extends keyof MessageData, R extends keyof MessageData>(message: K & BaseMessage, returnMessage: R & BaseMessage, player?: Player | MessageData[K], data?: MessageData[K] | boolean, unreliable?: boolean): Promise<MessageData[R]>;
    /**
     * @returns A destructor function that disconnects the callback from the message
     */
    on<K extends keyof MessageData>(message: K & BaseMessage, callback: MessageCallback<MessageData[K]>): Cleanup;
    /**
     * Disconnects the callback as soon as it is called for the first time
     *
     * @returns A destructor function that disconnects the callback from the message
     */
    once<K extends keyof MessageData>(message: K & BaseMessage, callback: MessageCallback<MessageData[K]>): Cleanup;
}
export {};
