import type { Modding } from "@flamework/core";
import type { Serializer, SerializerMetadata } from "@rbxts/serio";
import type { BaseMessage, SerializedPacket } from "./structs";
export declare class Serdes<MessageData> {
    serializers: Partial<Record<keyof MessageData, Serializer<MessageData[keyof MessageData]>>>;
    /** @metadata macro */
    getSchema<Kind extends keyof MessageData>(message: Kind & BaseMessage, meta?: Modding.Many<SerializerMetadata<MessageData[Kind]>>): SerializerMetadata<MessageData[Kind]>;
    serializePacket<Kind extends keyof MessageData>(message: Kind & BaseMessage, data?: MessageData[Kind]): SerializedPacket;
    deserializePacket<K extends keyof MessageData>(message: K & BaseMessage, serializedPacket: SerializedPacket): MessageData[K] | undefined;
    /** @metadata macro */
    addSerializer<K extends keyof MessageData>(message: K & BaseMessage, meta?: Modding.Many<SerializerMetadata<MessageData[K]>>): void;
    /** @metadata macro */
    createMessageSerializer<Kind extends keyof MessageData>(meta?: Modding.Many<SerializerMetadata<MessageData[Kind]>>): Serializer<MessageData[Kind]>;
    getSerializer<Kind extends keyof MessageData>(message: Kind & BaseMessage): Serializer<MessageData[Kind]> | undefined;
}
