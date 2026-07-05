import { ReplicatedStorage, RunService } from "@rbxts/services";

import { getAllPacketsWhich, isReliable, isUnreliable, shouldBatch } from "\./utility";
import type { BaseMessage, MessageEvent, PacketInfo, SerializedPacket } from "./structs";
import type { MessageEmitter } from "./emitters/message-emitter";

export type ServerQueuedMessageData<MessageData> = [keyof MessageData & BaseMessage, MessageData[keyof MessageData], boolean];
export type ClientQueuedMessageData<MessageData> = [Player | Player[], ...ServerQueuedMessageData<MessageData>];
export type QueuedMessageData<MessageData> = ClientQueuedMessageData<MessageData> | ServerQueuedMessageData<MessageData>;

declare let setLuneContext: (ctx: "server" | "client" | "both") => void;
setLuneContext ??= () => { };

let nextEmitterId = 0;

function createRemotePair(id: number): {
  send: RemoteEvent<MessageEvent>;
  sendUnreliable: UnreliableRemoteEvent<MessageEvent>;
} {
  const sendName = `tether_send_${id}`;
  const sendUnreliableName = `tether_sendUnreliable_${id}`;

  const existingSend = ReplicatedStorage.FindFirstChild(sendName);
  const send = (existingSend ?? new Instance("RemoteEvent", ReplicatedStorage)) as RemoteEvent<MessageEvent>;
  if (existingSend === undefined)
    send.Name = sendName;

  const existingUnreliable = ReplicatedStorage.FindFirstChild(sendUnreliableName);
  const sendUnreliable = (existingUnreliable ?? new Instance("UnreliableRemoteEvent", ReplicatedStorage)) as UnreliableRemoteEvent<MessageEvent>;
  if (existingUnreliable === undefined)
    sendUnreliable.Name = sendUnreliableName;

  return { send, sendUnreliable };
}

export class Relayer<MessageData> {
  private serverQueue: ServerQueuedMessageData<MessageData>[] = [];
  private clientBroadcastQueue: ServerQueuedMessageData<MessageData>[] = [];
  private clientQueue: ClientQueuedMessageData<MessageData>[] = [];
  private isRelaying = false;

  private readonly sendMessage: RemoteEvent<MessageEvent>;
  private readonly sendUnreliableMessage: UnreliableRemoteEvent<MessageEvent>;
  private readonly emitterId: number;

  public constructor(
    private readonly emitter: MessageEmitter<MessageData>
  ) {
    this.emitterId = nextEmitterId++;
    const remotes = createRemotePair(this.emitterId);
    this.sendMessage = remotes.send;
    this.sendUnreliableMessage = remotes.sendUnreliable;

    setLuneContext("client");
    if (RunService.IsClient()) {
      this.emitter.trash.add(this.sendMessage.OnClientEvent.Connect(
        (...serializedPacket) => this.emitter.onRemoteFire(false, serializedPacket))
      );
      this.emitter.trash.add(this.sendUnreliableMessage.OnClientEvent.Connect(
        (...serializedPacket) => this.emitter.onRemoteFire(false, serializedPacket))
      );
    }

    setLuneContext("server");
    if (RunService.IsServer()) {
      this.emitter.trash.add(this.sendMessage.OnServerEvent.Connect(
        (player, ...serializedPacket) => this.emitter.onRemoteFire(true, serializedPacket as never, player))
      );
      this.emitter.trash.add(this.sendUnreliableMessage.OnServerEvent.Connect(
        (player, ...serializedPacket) => this.emitter.onRemoteFire(true, serializedPacket as never, player))
      );
    }

    // Clean up remotes when emitter is destroyed
    this.emitter.trash.add(() => {
      this.sendMessage.Destroy();
      this.sendUnreliableMessage.Destroy();
    });

    let elapsed = 0;
    const { batchRemotes, batchRate } = this.emitter.options;
    if (!batchRemotes)
      return this;

    this.emitter.trash.add(RunService.Heartbeat.Connect(dt => {
      elapsed += dt;
      if (elapsed < batchRate) return;

      elapsed -= batchRate;
      this.relayAll();
    }));
  }

  public queueMessage<K extends keyof MessageData>(
    context: "client" | "server" | true,
    message: K & BaseMessage,
    data: QueuedMessageData<MessageData>
  ): void {
    const queue = context === "client"
      ? this.clientQueue
      : context === true
        ? this.clientBroadcastQueue
        : this.serverQueue;

    queue.push(data as never);
    if (!shouldBatch(message, this.emitter.options))
      this.relayAll();
  }

  /** Send all queued data across the network simultaneously */
  public relayAll(): void {
    // Guard against re-entrancy: processing messages can trigger new emits
    if (this.isRelaying) return;
    this.isRelaying = true;

    if (RunService.IsClient()) {
      if (!this.serverQueue.isEmpty()) {
        const queue = this.serverQueue;
        this.serverQueue = [];
        this.relay(
          (...packets) => this.sendMessage.FireServer(...packets),
          (...packets) => this.sendUnreliableMessage.FireServer(...packets),
          queue
        );
      }
      this.isRelaying = false;
      return;
    }

    if (!this.clientBroadcastQueue.isEmpty()) {
      const queue = this.clientBroadcastQueue;
      this.clientBroadcastQueue = [];
      this.relay(
        (...packets) => this.sendMessage.FireAllClients(...packets),
        (...packets) => this.sendUnreliableMessage.FireAllClients(...packets),
        queue
      );
    }

    if (!this.clientQueue.isEmpty()) {
      const playerPacketInfos = new Map<Player, PacketInfo[]>;
      const addClientPacket = (player: Player, packetInfo: PacketInfo): void => {
        const packetInfos = playerPacketInfos.get(player) ?? [];
        packetInfos.push(packetInfo);
        playerPacketInfos.set(player, packetInfos);
      };

      const queue = this.clientQueue;
      this.clientQueue = [];
      for (const [player, message, data, unreliable] of queue) {
        const packet = this.emitter.serdes.serializePacket(message, data);
        const info = { packet, unreliable };
        if (typeIs(player, "Instance"))
          addClientPacket(player, info);
        else
          for (const p of player)
            addClientPacket(p, info);
      }

      for (const [player, packetInfos] of playerPacketInfos) {
        if (packetInfos.isEmpty()) continue;

        const unreliablePackets = getAllPacketsWhich(packetInfos, isUnreliable);
        const packets = getAllPacketsWhich(packetInfos, isReliable);
        if (!unreliablePackets.isEmpty())
          this.sendUnreliableMessage.FireClient(player, ...unreliablePackets);
        if (!packets.isEmpty())
          this.sendMessage.FireClient(player, ...packets);
      }
    }

    this.isRelaying = false;
  }

  private relay(send: MessageEvent, sendUnreliable: MessageEvent, queue: QueuedMessageData<MessageData>[]): void {
    if (queue.isEmpty()) return;

    const packetInfos = queue.map<PacketInfo>(messageData => {
      let message: keyof MessageData & BaseMessage,
        data: MessageData[keyof MessageData],
        unreliable: boolean;

      if (typeIs(messageData[0], "Instance"))
        [, message, data, unreliable] = messageData as ClientQueuedMessageData<MessageData>;
      else
        [message, data, unreliable] = messageData as ServerQueuedMessageData<MessageData>;

      const packet = this.emitter.serdes.serializePacket(message, data);
      return { packet, unreliable };
    });

    const unreliablePackets = getAllPacketsWhich(packetInfos, isUnreliable);
    const packets = getAllPacketsWhich(packetInfos, isReliable);
    if (!unreliablePackets.isEmpty())
      sendUnreliable(...unreliablePackets);
    if (!packets.isEmpty())
      send(...packets);
  }
}
