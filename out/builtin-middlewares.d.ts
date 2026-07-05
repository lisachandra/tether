import { Modding } from "@flamework/core";
import type { SerializerMetadata } from "@rbxts/serio";
import type { Any } from "ts-toolbelt";
import { type SharedMiddleware } from "./middleware";
export declare namespace BuiltinMiddlewares {
    /**
     * Creates a shared middleware that will simulate a ping of the given amount when a message is sent
     *
     * @param pingInMs The amount of time in milliseconds that the middleware should wait
     * @returns A shared middleware that will simulate a ping
     */
    function simulatePing(pingInMs: number): SharedMiddleware;
    /**
     * Creates a shared middleware that will check if a message packet exceeds the given maximum size in bytes
     *
     * @param maxBytes The maximum size of the packet in bytes
     * @param throwError Whether the middleware should throw an error if the packet exceeds the maximum size, or simply drop the request
     * @returns A shared middleware that will check if a message packet exceeds the given maximum size
     */
    function maxPacketSize(maxBytes: number, throwError?: boolean): SharedMiddleware;
    /**
     * Creates a shared middleware that will drop any message that occurs within the given interval of the previous message
     *
     * @param interval The interval in seconds that the middleware should wait before allowing a new request
     * @returns A middleware that will drop any message that occurs within the given interval
     */
    function rateLimit(interval: number): SharedMiddleware;
    /**
     * Creates a shared middleware that will log a message whenever a message is sent, containing the following information:
     * - The message kind
     * - The data associated with the message
     * - The raw data (buffer and blobs) associated with the message
     * - The size of the packet (in bytes)
     * - The size of the buffer (in bytes)
     * - The size of the blobs (in bytes)
     * - The schema string associated with the message (if it can be deduced)
     *
     * @returns A shared middleware that will log a message whenever a message is sent.
     * @metadata macro
     */
    function debug<T>(schema?: Modding.Many<Any.Equals<T, unknown> extends 1 ? undefined : SerializerMetadata<T>>): SharedMiddleware<T>;
}
