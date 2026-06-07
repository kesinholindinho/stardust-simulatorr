-- Cria os RemoteEvents/RemoteFunctions principais quando o projeto roda via Rojo.
-- Esses objetos podem existir no .rbxlx original, mas nao aparecem quando extraimos apenas scripts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local function ensureRemoteEvent(name, parent)
	parent = parent or ReplicatedStorage

	local existing = parent:FindFirstChild(name)
	if existing then
		if existing:IsA("RemoteEvent") then
			return existing
		end

		warn("[CoreRemotes] Objeto com nome '" .. name .. "' existe, mas nao e RemoteEvent: " .. existing.ClassName)
		return existing
	end

	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = parent
	return remote
end

local function ensureRemoteFunction(parent, name)
	local existing = parent:FindFirstChild(name)
	if existing then
		if existing:IsA("RemoteFunction") then
			return existing
		end

		warn("[CoreRemotes] Objeto com nome '" .. name .. "' existe, mas nao e RemoteFunction: " .. existing.ClassName)
		return existing
	end

	local remote = Instance.new("RemoteFunction")
	remote.Name = name
	remote.Parent = parent
	return remote
end

local function ensureFolder(name)
	local existing = ReplicatedStorage:FindFirstChild(name)
	if existing then
		if existing:IsA("Folder") then
			return existing
		end

		warn("[CoreRemotes] Objeto com nome '" .. name .. "' existe, mas nao e Folder: " .. existing.ClassName)
		return existing
	end

	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = ReplicatedStorage
	return folder
end

local function ensureServerFolder(name)
	local existing = ServerStorage:FindFirstChild(name)
	if existing then
		if existing:IsA("Folder") then
			return existing
		end

		warn("[CoreRemotes] Objeto com nome '" .. name .. "' existe em ServerStorage, mas nao e Folder: " .. existing.ClassName)
		return existing
	end

	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = ServerStorage
	return folder
end

local function ensureBindableEvent(parent, name)
	local existing = parent:FindFirstChild(name)
	if existing then
		if existing:IsA("BindableEvent") then
			return existing
		end

		warn("[CoreRemotes] Objeto com nome '" .. name .. "' existe, mas nao e BindableEvent: " .. existing.ClassName)
		return existing
	end

	local event = Instance.new("BindableEvent")
	event.Name = name
	event.Parent = parent
	return event
end

ensureRemoteEvent("GameAction")
ensureRemoteEvent("StardustSync")
ensureRemoteEvent("TutorialSync")
ensureRemoteEvent("InventoryAction")
ensureRemoteEvent("SettingsSync")
ensureRemoteEvent("TradeAction")
ensureRemoteEvent("TradeSync")
ensureBindableEvent(ReplicatedStorage, "ItemStardustEvent")

local questRemotes = ensureFolder("QuestRemotes")
if questRemotes:IsA("Folder") then
	ensureRemoteFunction(questRemotes, "GetQuestData")
	ensureRemoteEvent("QuestProgressUpdated", questRemotes)
	ensureRemoteEvent("QuestClaimed", questRemotes)
	ensureRemoteEvent("ClaimQuest", questRemotes)
end

local questEvents = ensureServerFolder("QuestEvents")
if questEvents:IsA("Folder") then
	ensureBindableEvent(questEvents, "OnClick")
	ensureBindableEvent(questEvents, "OnStardustEarned")
	ensureBindableEvent(questEvents, "OnStardustSpent")
	ensureBindableEvent(questEvents, "OnItemUsed")
	ensureBindableEvent(questEvents, "OnItemBought")
	ensureBindableEvent(questEvents, "OnLevelUp")
end

print("[CoreRemotes] RemoteEvents principais verificados.")
