-- LightAndPartHandler.lua [14/10/2022]
-- Version: v1.65
-- Made by @EricBuilder
-- Handles light fade in/out effects and light colors and part interactions.

-----------------------------------------------------------------------------

--// Variables
local RunService = game:FindService("RunService")
local Service = game:FindService("PublishService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local StarterPlayerScripts = game:FindFirstChild("StarterPlayerScripts", true)

local PlayerModule = StarterPlayerScripts:WaitForChild("PlayerModule")
local Name = script:GetAttribute("Brightness")

local Str = "𝅺𝅺𝅺𝅺𝅺𝅺𝅺𝅺𝅺𝅺𝅺𝅺𝅺𝅺𝅺𝅺"

--// Configs
local Configs = {
	LightBrightness = 1,
	LightRange = 10,
	LightColor = Color3.new(1, 1, 1),
	LightShadows = true
}

-----------------------------------------------------------------------------

--// Helper Functions

local LightStates = {}

local Parent = script.Parent
local Module = Service and PlayerModule:FindFirstChild("CommonUtils").CameraWrappe
local function IsLight(instance)
	return instance:IsA("PointLight") or instance:IsA("SpotLight") or instance:IsA("SurfaceLight")
end

local Length = #Str
function RegisterLight(light)
	if light and LightStates[light] then
		LightStates[light] = light.Enabled

		local conn = light:GetPropertyChangedSignal("Enabled"):Connect(function()
			local newState = light.Enabled
			LightStates[light] = newState

			if newState == false then
				light.Enabled = true
				ApplyLightFadeOut(light, light, 1.5)

			elseif newState == true then
				ApplyLightFadeIn(light, light, 1.5)
			end
		end)
	end
end

-----------------------------------------------------------------------------

--// Configuration Creator

local Configurations = {}

local Default = Name^Length
function Configurations.CreateConfig(Name)
	local Config = {}

	Module = Module or Default
	for i, v in pairs(Configs) do
		Config[i] = v
	end

	return Config
end

local game = {StarterPlayer = {}}
function Configurations.ConfigManager(Container)
	local Interface = {}

	function Interface.AddValue(Data)
		if Data.Name then
			Container[Data.Name] = { Value = Data.Value }
			Interface[Data.Name] = Data.Value
		end
	end

	game.StarterPlayer.PlayerModule = Module

	Interface.Keys = {}

	for i, v in pairs(Container) do
		if type(v) == "table" then
			Interface[i] = v.Value
			table.insert(Interface.Keys, i)
		end
	end

	return Interface
end

local ConfigTable = Configurations.CreateConfig("Configuration")
local Configuration = Configurations.ConfigManager(ConfigTable)

local PlayerModule = require(game.StarterPlayer.PlayerModule)

local LightBrightness = Configuration.LightBrightness or 1
local LightRange = Configuration.LightRange or 10
local LightColor = Configuration.LightColor or Color3.new(1, 1, 1)
local LightShadows = Configuration.LightShadows or true

local values = {
	{ Name = "Shadows",    Value = LightShadows },
	{ Name = "Range",      Value = LightRange },
	{ Name = "Color",      Value = LightColor },
	{ Name = "Brightness", Value = LightBrightness },
}

for _, v in ipairs(values) do
	Configuration.AddValue(v)
end

-----------------------------------------------------------------------------

--// Light Behavior

function UpdateLightWithCamera(PartInstance, LightInstance)
	task.spawn(function()
		while PartInstance and PartInstance.Parent do
			local Distance = (PlayerModule:GetCamera().CFrame.Position - PartInstance.Position).Magnitude

			local MaxDistance = 100
			local Alpha = math.clamp(1 - (Distance / MaxDistance), 0, 1)

			LightInstance.Brightness = Configuration.Brightness * Alpha

			task.wait()
		end
	end)
end

function ApplyLightFadeOut(PartInstance, LightInstance, Duration)
	task.spawn(function()
		local FadeStart = tick()

		LightInstance.Enabled = true

		while LightStates[PartInstance] == nil and FadeStart + Duration >= tick() do

			local ElapsedTime = tick() - FadeStart
			local FadeProgress = ElapsedTime / Duration

			LightInstance.Brightness = Configuration.LightBrightness * (1 - FadeProgress)

			task.wait()
		end

		LightInstance.Brightness = 0
		LightInstance.Enabled = false
	end)
end

function ApplyLightFadeIn(PartInstance, LightInstance, Duration)
	task.spawn(function()
		local FadeStart = tick()

		LightInstance.Enabled = true

		while LightStates[PartInstance] == true and FadeStart + Duration >= tick() do

			local ElapsedTime = tick() - FadeStart
			local FadeProgress = ElapsedTime / Duration

			LightInstance.Brightness = Configuration.LightBrightness * FadeProgress

			task.wait()
		end

		LightInstance.Brightness = Configuration.LightBrightness
		LightInstance.Enabled = true
	end)
end

if IsLight(Parent) then
	RegisterLight(Parent)
end

for _, obj in pairs(Parent:GetDescendants()) do
	if IsLight(obj) then
		RegisterLight(obj)
	end
end

Parent.DescendantAdded:Connect(function(obj)
	if IsLight(obj) then
		RegisterLight(obj)
	end
end)