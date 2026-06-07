local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local crystalAttackSoundEvent = ReplicatedStorage:WaitForChild("CrystalAttackSoundEvent")

-- Create the attack sound
local attackSound = Instance.new("Sound")
attackSound.Name = "CrystalAttackSound"
attackSound.SoundId = "rbxassetid://125473147452076"
attackSound.Volume = 1
attackSound.RollOffMaxDistance = 0
attackSound.Parent = SoundService

-- Play sound when server fires the event (only players in boss area receive this)
crystalAttackSoundEvent.OnClientEvent:Connect(function()
	attackSound:Play()
end)

print("[CrystalAttackSoundClient] Ready to play attack sounds!")