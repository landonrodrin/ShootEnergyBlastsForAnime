local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local ByteNet = require(ReplicatedStorage.Shared:WaitForChild("ByteNet"))

local NAMESPACE_NAME = "gameplay"

if RunService:IsClient() then
	local ByteNetStorage = ReplicatedStorage:WaitForChild("BytenetStorage", 10)
	assert(ByteNetStorage, "Missing ReplicatedStorage.BytenetStorage; make sure the server requires ReplicatedStorage.Network.Packets before clients.")

	local NamespaceValue = ByteNetStorage:WaitForChild(NAMESPACE_NAME, 10)
	assert(NamespaceValue, string.format("Missing ReplicatedStorage.BytenetStorage.%s; make sure the server defines the ByteNet namespace before clients.", NAMESPACE_NAME))
end

local Packets = ByteNet.defineNamespace(NAMESPACE_NAME, function()
	local color = ByteNet.struct({
		R = ByteNet.uint8,
		G = ByteNet.uint8,
		B = ByteNet.uint8,
	})

	local inventoryItem = ByteNet.struct({
		Id = ByteNet.string,
		Name = ByteNet.string,
		Mutation = ByteNet.string,
		Level = ByteNet.uint16,
		Sell = ByteNet.float64,
	})

	local inventorySnapshot = ByteNet.struct({
		Items = ByteNet.array(inventoryItem),
		EquippedId = ByteNet.optional(ByteNet.string),
		HotbarOrder = ByteNet.map(ByteNet.uint8, ByteNet.string),
		MaxHotbarSlots = ByteNet.uint8,
	})

	local shootResult = ByteNet.struct({
		Hit = ByteNet.bool,
		Reason = ByteNet.optional(ByteNet.string),
		WallName = ByteNet.optional(ByteNet.string),
		Hp = ByteNet.optional(ByteNet.float64),
		MaxHP = ByteNet.optional(ByteNet.float64),
		Destroyed = ByteNet.optional(ByteNet.bool),
	})

	local wallDebris = ByteNet.struct({
		Id = ByteNet.string,
		DisplayName = ByteNet.string,
		WallCFrame = ByteNet.cframe,
		WallSize = ByteNet.vec3,
		Wall = ByteNet.inst,
		HitPosition = ByteNet.vec3,
		Color = color,
		Material = ByteNet.string,
		Count = ByteNet.uint16,
	})

	return {
		money = ByteNet.definePacket({value = ByteNet.float64}),
		speed = ByteNet.definePacket({value = ByteNet.float64}),
		carry = ByteNet.definePacket({value = ByteNet.uint16}),
		rebirth = ByteNet.definePacket({
			value = ByteNet.struct({
				Rebirths = ByteNet.uint16,
				Speed = ByteNet.float64,
			}),
		}),
		toggleSpeed = ByteNet.definePacket({value = ByteNet.optional(ByteNet.bool)}),
		incrementSpeed = ByteNet.definePacket({value = ByteNet.float64}),
		incrementCarry = ByteNet.definePacket({value = ByteNet.uint16}),
		rebirthRequest = ByteNet.definePacket({value = ByteNet.nothing}),
		announcement = ByteNet.definePacket({
			value = ByteNet.struct({
				Text = ByteNet.string,
				Colour = ByteNet.optional(color),
			}),
		}),
		inventorySync = ByteNet.definePacket({value = inventorySnapshot}),
		sellInventory = ByteNet.definePacket({
			value = ByteNet.struct({
				Mode = ByteNet.string,
				Id = ByteNet.optional(ByteNet.string),
			}),
		}),
		equipInventory = ByteNet.definePacket({
			value = ByteNet.struct({
				Id = ByteNet.string,
			}),
		}),
		updateHotbarSlot = ByteNet.definePacket({
			value = ByteNet.struct({
				Slot = ByteNet.uint8,
				Id = ByteNet.optional(ByteNet.string),
			}),
		}),
		indexRequest = ByteNet.definePacket({
			value = ByteNet.struct({
				Mutation = ByteNet.string,
			}),
		}),
		indexSync = ByteNet.definePacket({
			value = ByteNet.struct({
				Index = ByteNet.map(ByteNet.string, ByteNet.map(ByteNet.string, ByteNet.bool)),
				Mutation = ByteNet.optional(ByteNet.string),
			}),
		}),
		animeUnlocked = ByteNet.definePacket({
			value = ByteNet.struct({
				Name = ByteNet.string,
				Mutation = ByteNet.string,
			}),
		}),
		levelBind = ByteNet.definePacket({
			value = ByteNet.struct({
				Gui = ByteNet.inst,
				Identifier = ByteNet.optional(ByteNet.string),
			}),
		}),
		levelPurchased = ByteNet.definePacket({
			value = ByteNet.struct({
				Identifier = ByteNet.string,
			}),
		}),
		levelRequest = ByteNet.definePacket({
			value = ByteNet.struct({
				Identifier = ByteNet.string,
			}),
		}),
		setPropertiesApply = ByteNet.definePacket({
			value = ByteNet.struct({
				Identifier = ByteNet.string,
				Object = ByteNet.inst,
				Properties = ByteNet.unknown,
			}),
		}),
		setPropertiesConfirm = ByteNet.definePacket({
			value = ByteNet.struct({
				Identifier = ByteNet.string,
			}),
		}),
		dropRequest = ByteNet.definePacket({value = ByteNet.nothing}),
		dropState = ByteNet.definePacket({
			value = ByteNet.struct({
				CanDrop = ByteNet.bool,
			}),
		}),
		shootRequest = ByteNet.definePacket({
			value = ByteNet.struct({
				TargetPoint = ByteNet.vec3,
			}),
		}),
		shootResult = ByteNet.definePacket({value = shootResult}),
		wallDebris = ByteNet.definePacket({value = wallDebris}),
		clientReady = ByteNet.definePacket({value = ByteNet.nothing}),
	}
end)

local MAX_QUEUED_PACKETS_PER_PLAYER = 128
local ServerToClientPacketNames = {
	"money",
	"speed",
	"carry",
	"rebirth",
	"toggleSpeed",
	"announcement",
	"inventorySync",
	"indexSync",
	"animeUnlocked",
	"levelBind",
	"levelPurchased",
	"setPropertiesApply",
	"dropState",
	"shootResult",
	"wallDebris",
}

if RunService:IsServer() then
	local ReadyPlayers = {}
	local QueuedByPlayer = {}

	local function flushPlayer(Player)
		local Queue = QueuedByPlayer[Player]
		QueuedByPlayer[Player] = nil

		if not Queue then return end
		if not ReadyPlayers[Player] then return end
		if not Player.Parent then return end

		for _, Entry in ipairs(Queue) do
			Entry.SendTo(Entry.Data, Player)
		end
	end

	local function queuePacket(Player, SendTo, Data)
		if not Player or not Player.Parent then return end

		local Queue = QueuedByPlayer[Player]
		if not Queue then
			Queue = {}
			QueuedByPlayer[Player] = Queue
		end

		table.insert(Queue, {
			SendTo = SendTo,
			Data = Data,
		})

		while #Queue > MAX_QUEUED_PACKETS_PER_PLAYER do
			table.remove(Queue, 1)
		end
	end

	for _, PacketName in ipairs(ServerToClientPacketNames) do
		local Packet = Packets[PacketName]
		if Packet and Packet.sendTo then
			local SendTo = Packet.sendTo

			Packet.sendTo = function(Data, Player)
				if ReadyPlayers[Player] then
					SendTo(Data, Player)
				else
					queuePacket(Player, SendTo, Data)
				end
			end
		end

		if Packet and Packet.sendToAll then
			Packet.sendToAll = function(Data)
				for _, Player in ipairs(Players:GetPlayers()) do
					Packet.sendTo(Data, Player)
				end
			end
		end
	end

	Packets.clientReady.listen(function(_, Player)
		if not Player then return end

		ReadyPlayers[Player] = true
		flushPlayer(Player)
	end)

	Players.PlayerRemoving:Connect(function(Player)
		ReadyPlayers[Player] = nil
		QueuedByPlayer[Player] = nil
	end)
else
	task.defer(function()
		Packets.clientReady.send(nil)
	end)
end

function Packets.Listen(Packet, Callback, OwnerTrove)
	Packet.listen(Callback)

	local function Disconnect()
		if not Packet.getListeners then return end

		local Listeners = Packet.getListeners()
		for Index = #Listeners, 1, -1 do
			if Listeners[Index] ~= Callback then continue end

			table.remove(Listeners, Index)
			break
		end
	end

	if OwnerTrove then
		OwnerTrove:Add(Disconnect)
	end

	return Disconnect
end

function Packets.EncodeColour(Colour)
	if typeof(Colour) ~= "Color3" then
		return nil
	end

	return {
		R = math.clamp(math.round(Colour.R * 255), 0, 255),
		G = math.clamp(math.round(Colour.G * 255), 0, 255),
		B = math.clamp(math.round(Colour.B * 255), 0, 255),
	}
end

function Packets.DecodeColour(Colour)
	if typeof(Colour) ~= "table" then
		return nil
	end

	return Color3.fromRGB(Colour.R or 255, Colour.G or 255, Colour.B or 255)
end

function Packets.EncodeInventorySnapshot(Snapshot)
	Snapshot = Snapshot or {}

	local Items = {}
	for _, Item in ipairs(Snapshot.Items or {}) do
		table.insert(Items, {
			Id = tostring(Item.Id or ""),
			Name = tostring(Item.Name or ""),
			Mutation = tostring(Item.Mutation or "Default"),
			Level = math.clamp(tonumber(Item.Level) or 1, 0, 65535),
			Sell = tonumber(Item.Sell) or 0,
		})
	end

	local HotbarOrder = {}
	for Slot, Id in pairs(Snapshot.HotbarOrder or {}) do
		if typeof(Slot) == "number" and typeof(Id) == "string" then
			HotbarOrder[math.clamp(math.floor(Slot), 0, 255)] = Id
		end
	end

	return {
		Items = Items,
		EquippedId = typeof(Snapshot.EquippedId) == "string" and Snapshot.EquippedId or nil,
		HotbarOrder = HotbarOrder,
		MaxHotbarSlots = math.clamp(tonumber(Snapshot.MaxHotbarSlots) or 0, 0, 255),
	}
end

function Packets.DecodeInventorySnapshot(Snapshot)
	Snapshot = Snapshot or {}
	Snapshot.HotbarOrder = Snapshot.HotbarOrder or {}
	Snapshot.Items = Snapshot.Items or {}

	return Snapshot
end

function Packets.EncodeMaterial(Material)
	if typeof(Material) ~= "EnumItem" then
		return "Plastic"
	end

	return Material.Name
end

function Packets.DecodeMaterial(Material)
	if typeof(Material) ~= "string" then
		return Enum.Material.Plastic
	end

	for _, MaterialItem in ipairs(Enum.Material:GetEnumItems()) do
		if MaterialItem.Name == Material then
			return MaterialItem
		end
	end

	return Enum.Material.Plastic
end

return Packets
