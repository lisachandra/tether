import type { BaseMessage } from "./structs";
import type { MessageEmitter } from "./emitters/message-emitter";
export type ServerQueuedMessageData<MessageData> = [keyof MessageData & BaseMessage, MessageData[keyof MessageData], boolean];
export type ClientQueuedMessageData<MessageData> = [Player | Player[], ...ServerQueuedMessageData<MessageData>];
export type QueuedMessageData<MessageData> = ClientQueuedMessageData<MessageData> | ServerQueuedMessageData<MessageData>;
export declare class Relayer<MessageData> {
    private readonly emitter;
    private serverQueue;
    private clientBroadcastQueue;
    private clientQueue;
    private isRelaying;
    private readonly sendMessage;
    private readonly sendUnreliableMessage;
    private readonly emitterId;
    constructor(emitter: MessageEmitter<MessageData>);
    queueMessage<K extends keyof MessageData>(context: "client" | "server" | true, message: K & BaseMessage, data: QueuedMessageData<MessageData>): void;
    /** Send all queued data across the network simultaneously */
    relayAll(): void;
    private relay;
}
