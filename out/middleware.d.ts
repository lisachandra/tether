import type { BaseMessage, SerializedPacket } from "./structs";
type DropRequestSymbol = symbol & {
    _drop_req?: undefined;
};
export declare const DropRequest: DropRequestSymbol;
export type ClientMiddleware<Data = unknown> = {
    _client?: void;
} & ((player: Player | Player[], ctx: MiddlewareContext<Data>) => DropRequestSymbol | void);
export type ServerMiddleware<Data = unknown> = {
    _server?: void;
} & SharedMiddleware<Data>;
export type SharedMiddleware<Data = unknown> = (ctx: MiddlewareContext<Data>) => DropRequestSymbol | void;
export type Middleware<Data = unknown> = ServerMiddleware<Data> & ClientMiddleware<Data> & SharedMiddleware<Data>;
export interface MiddlewareContext<Data = unknown, Message extends BaseMessage = BaseMessage> {
    readonly message: Message;
    data: Data;
    getRawData: () => SerializedPacket;
}
type RequestDropCallback = (message: BaseMessage, reason?: string) => void;
export declare class MiddlewareProvider<MessageData> {
    private readonly clientGlobalMiddlewares;
    private readonly serverGlobalMiddlewares;
    private readonly clientSendMiddlewares;
    private readonly serverSendMiddlewares;
    private readonly serverReceiveMiddlewares;
    private readonly clientReceiveMiddlewares;
    private readonly requestDroppedCallbacks;
    /**
     * Registers a callback to be called whenever a message is dropped.
     * The callback will receive the message that was dropped and an optional reason string.
     *
     * @returns A function that can be called to unregister the callback.
     */
    onRequestDropped(callback: RequestDropCallback): () => void;
    /** @hidden */
    notifyRequestDropped(message: BaseMessage, reason?: string): void;
    /** @hidden */
    getClient<Kind extends keyof MessageData>(message: Kind & BaseMessage): ClientMiddleware<MessageData[Kind]>[];
    /** @hidden */
    getServer<Kind extends keyof MessageData>(message: Kind & BaseMessage): ServerMiddleware<MessageData[Kind]>[];
    /** @hidden */
    getClientGlobal<Data>(): ClientMiddleware<Data>[];
    /** @hidden */
    getServerGlobal<Data>(): ServerMiddleware<Data>[];
    /** @hidden */
    getClientReceive<Kind extends keyof MessageData>(message: Kind & BaseMessage): ServerMiddleware<MessageData[Kind]>[];
    /** @hidden */
    getServerReceive<Kind extends keyof MessageData>(message: Kind & BaseMessage): ClientMiddleware<MessageData[Kind]>[];
    useClient<Kind extends keyof MessageData>(message: Kind & BaseMessage, middlewares: ClientMiddleware<MessageData[Kind]> | readonly ClientMiddleware<MessageData[Kind]>[] | ClientMiddleware | readonly ClientMiddleware[], order?: number): this;
    useServer<Kind extends keyof MessageData>(message: Kind & BaseMessage, middlewares: ServerMiddleware<MessageData[Kind]> | readonly ServerMiddleware<MessageData[Kind]>[] | ServerMiddleware | readonly ServerMiddleware[], order?: number): this;
    useShared<Kind extends keyof MessageData>(message: Kind & BaseMessage, middlewares: SharedMiddleware<MessageData[Kind]> | readonly SharedMiddleware<MessageData[Kind]>[] | SharedMiddleware | readonly SharedMiddleware[], order?: number): this;
    useClientReceive<Kind extends keyof MessageData>(message: Kind & BaseMessage, middlewares: ServerMiddleware<MessageData[Kind]> | readonly ServerMiddleware<MessageData[Kind]>[] | ServerMiddleware | readonly ServerMiddleware[], order?: number): this;
    useServerReceive<Kind extends keyof MessageData>(message: Kind & BaseMessage, middlewares: ClientMiddleware<MessageData[Kind]> | readonly ClientMiddleware<MessageData[Kind]>[] | ClientMiddleware | readonly ClientMiddleware[], order?: number): this;
    useSharedReceive<Kind extends keyof MessageData>(message: Kind & BaseMessage, middlewares: SharedMiddleware<MessageData[Kind]> | readonly SharedMiddleware<MessageData[Kind]>[] | SharedMiddleware | readonly SharedMiddleware[], order?: number): this;
    useClientGlobal(middlewares: ClientMiddleware | readonly ClientMiddleware[], order?: number): this;
    useServerGlobal(middlewares: ServerMiddleware | readonly ServerMiddleware[], order?: number): this;
    useSharedGlobal(middlewares: SharedMiddleware | readonly SharedMiddleware[], order?: number): this;
    deleteSharedGlobal<Kind extends keyof MessageData>(middlewares: SharedMiddleware<MessageData[Kind]> | readonly SharedMiddleware<MessageData[Kind]>[] | SharedMiddleware | readonly SharedMiddleware[]): void;
    deleteClientGlobal<Kind extends keyof MessageData>(middlewares: ClientMiddleware<MessageData[Kind]> | readonly ClientMiddleware<MessageData[Kind]>[] | ClientMiddleware | readonly ClientMiddleware[]): void;
    deleteServerGlobal<Kind extends keyof MessageData>(middlewares: ServerMiddleware<MessageData[Kind]> | readonly ServerMiddleware<MessageData[Kind]>[] | ServerMiddleware | readonly ServerMiddleware[]): void;
    deleteShared<Kind extends keyof MessageData>(message: Kind & BaseMessage, middlewares: SharedMiddleware<MessageData[Kind]> | readonly SharedMiddleware<MessageData[Kind]>[] | SharedMiddleware | readonly SharedMiddleware[]): void;
    deleteClient<Kind extends keyof MessageData>(message: Kind & BaseMessage, middlewares: ClientMiddleware<MessageData[Kind]> | readonly ClientMiddleware<MessageData[Kind]>[] | ClientMiddleware | readonly ClientMiddleware[]): void;
    deleteServer<Kind extends keyof MessageData>(message: Kind & BaseMessage, middlewares: ServerMiddleware<MessageData[Kind]> | readonly ServerMiddleware<MessageData[Kind]>[] | ServerMiddleware | readonly ServerMiddleware[]): void;
}
export {};
