import { Modding } from "@flamework/core";
import { Trash } from "@rbxts/trash";
import Destroyable from "@rbxts/destroyable";
import { MiddlewareProvider } from "../middleware";
import type { SerializedPacket, ClientMessageCallback, ServerMessageCallback, BaseMessage, MessageEmitterMetadata } from "../structs";
import { ServerEmitter } from "./server-emitter";
import { ClientEmitter } from "./client-emitter";
import { Relayer } from "../relayer";
import { Serdes } from "../serdes";
import { SerializerMetadata } from "@rbxts/serio";
export interface MessageEmitterOptions<MessageData> {
    readonly batchRemotes: boolean;
    readonly batchRate: number;
    readonly doNotBatch: Set<keyof MessageData>;
    readonly testMode: boolean;
    readonly testPlayer?: Player;
}
export declare class MessageEmitter<MessageData> extends Destroyable {
    readonly options: MessageEmitterOptions<MessageData>;
    readonly server: ServerEmitter<MessageData>;
    readonly client: ClientEmitter<MessageData>;
    readonly middleware: MiddlewareProvider<MessageData>;
    /** @hidden */ readonly trash: Trash;
    /** @hidden */ readonly relayer: Relayer<MessageData>;
    /** @hidden */ readonly serdes: Serdes<MessageData>;
    /** @hidden */ clientCallbacks: Map<keyof MessageData, Set<ClientMessageCallback>>;
    /** @hidden */ clientFunctions: Map<keyof MessageData, Set<(data: unknown) => void>>;
    /** @hidden */ serverCallbacks: Map<keyof MessageData, Set<ServerMessageCallback>>;
    /** @hidden */ serverFunctions: Map<keyof MessageData, Set<(data: unknown) => void>>;
    /** The mock player used in test mode. Reassign per-test without recreating the emitter. */
    testPlayer: Player | undefined;
    private readonly guards;
    /** @metadata macro */
    static create<MessageData>(options?: Partial<MessageEmitterOptions<MessageData>>, meta?: Modding.Many<MessageEmitterMetadata<MessageData>>): MessageEmitter<MessageData>;
    private constructor();
    /** @hidden */
    runClientSendMiddlewares<Kind extends keyof MessageData>(message: Kind & BaseMessage, data?: MessageData[Kind], player?: Player | Player[]): [boolean, MessageData[Kind]];
    /** @hidden */
    runServerSendMiddlewares<Kind extends keyof MessageData>(message: Kind & BaseMessage, data?: MessageData[Kind]): [boolean, MessageData[Kind]];
    /** @hidden */
    deliverLocally<Kind extends keyof MessageData>(isServer: boolean, message: Kind & BaseMessage, data?: MessageData[Kind], player?: Player): void;
    /** @hidden */
    onRemoteFire(isServer: boolean, serializedPackets: SerializedPacket[], player?: Player): void;
    /**
     * Note: Will only work for literal message types, where `MessageData[Kind]` can be exactly inferred
     * @metadata macro
     */
    getSchema<Kind extends keyof MessageData>(message: Kind & BaseMessage, meta?: Modding.Many<SerializerMetadata<MessageData[Kind]>>): SerializerMetadata<MessageData[Kind]>;
    private runServerReceiveMiddlewares;
    private runClientReceiveMiddlewares;
    private validateData;
    private executeFunctions;
    private executeEventCallbacks;
    private executeServerCallback;
    private executeClientCallback;
}
