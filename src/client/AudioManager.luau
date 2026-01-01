-- AudioManager.luau
-- Handles all audio playback for the game including music and sound effects

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local player = Players.LocalPlayer

local AudioManager = {}
local currentMusic = nil
local soundPool = {} -- Pool of reusable sound instances

-- =============================================================================
-- MUSIC SYSTEM
-- =============================================================================

-- Play background music
local function playMusic(trackName)
	if not Config.Audio or not Config.Audio.Enable or not Config.Audio.Music or not Config.Audio.Music.Enable then 
		return 
	end
	
	if not Config.Audio.Music.Tracks then
		warn("[AudioManager] Config.Audio.Music.Tracks not found")
		return
	end
	
	local trackId = Config.Audio.Music.Tracks[trackName]
	if not trackId then
		warn("[AudioManager] Music track not found:", trackName)
		return
	end
	
	-- Fade out current music if playing
	if currentMusic then
		local fadeTween = TweenService:Create(
			currentMusic,
			TweenInfo.new(Config.Audio.Music.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Volume = 0}
		)
		fadeTween:Play()
		fadeTween.Completed:Connect(function()
			currentMusic:Stop()
			currentMusic:Destroy()
		end)
	end
	
	-- Create new music instance
	local music = Instance.new("Sound")
	music.Name = "BackgroundMusic_" .. trackName
	music.SoundId = trackId
	music.Volume = 0
	music.Looped = Config.Audio.Music.Looped
	music.Parent = SoundService
	
	-- Play and fade in
	music:Play()
	local fadeInTween = TweenService:Create(
		music,
		TweenInfo.new(Config.Audio.Music.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Volume = Config.Audio.Music.Volume}
	)
	fadeInTween:Play()
	
	currentMusic = music
	-- print("[AudioManager] Playing music:", trackName)
end

-- Stop all music
local function stopMusic()
	if currentMusic then
		local fadeTween = TweenService:Create(
			currentMusic,
			TweenInfo.new(Config.Audio.Music.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Volume = 0}
		)
		fadeTween:Play()
		fadeTween.Completed:Connect(function()
			currentMusic:Stop()
			currentMusic:Destroy()
			currentMusic = nil
		end)
	end
end

-- =============================================================================
-- SOUND EFFECTS SYSTEM
-- =============================================================================

-- Get or create a sound from the pool
local function getSoundFromPool(soundId)
	if not Config.Audio.Playback.EnablePooling then
		-- Create new sound without pooling
		local sound = Instance.new("Sound")
		sound.SoundId = soundId
		sound.Volume = Config.Audio.SFX.Volume
		return sound, false
	end
	
	-- Try to get from pool
	if soundPool[soundId] then
		for i, sound in ipairs(soundPool[soundId]) do
			if not sound.IsPlaying then
				return sound, true
			end
		end
	else
		soundPool[soundId] = {}
	end
	
	-- Create new sound and add to pool if space available
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = Config.Audio.SFX.Volume
	
	if #soundPool[soundId] < Config.Audio.Playback.MaxPoolSize then
		table.insert(soundPool[soundId], sound)
	end
	
	return sound, false
end

-- Play a sound effect
local function playSFX(soundName, position)
	if not Config.Audio or not Config.Audio.Enable or not Config.Audio.SFX or not Config.Audio.SFX.Enable then 
		return 
	end
	
	local soundId = Config.Audio.SFX[soundName]
	if not soundId then
		return
	end
	
	-- Always create new sound (pooling disabled for now to avoid parent lock issues)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = Config.Audio.SFX.Volume
	
	-- Configure sound
	if position and Config.Audio.Playback and Config.Audio.Playback.Use3DSound then
		-- Create attachment for 3D positional audio
		local attachment = Instance.new("Attachment")
		attachment.WorldPosition = position
		attachment.Parent = workspace.Terrain
		sound.Parent = attachment
		
		-- 3D sound properties
		sound.RollOffMinDistance = Config.Audio.Playback.RollOffMinDistance or 10
		sound.RollOffMaxDistance = Config.Audio.Playback.RollOffMaxDistance or 50
		sound.EmitterSize = 5
		
		-- Cleanup attachment after sound ends
		sound.Ended:Connect(function()
			task.wait(0.1)
			attachment:Destroy()
		end)
	else
		-- 2D sound (UI sounds, etc.)
		sound.Parent = SoundService
	end
	
	-- Play sound
	sound:Play()
	
	-- Cleanup after sound ends
	sound.Ended:Connect(function()
		task.wait(0.1)
		sound:Destroy()
	end)
end

-- =============================================================================
-- PUBLIC API
-- =============================================================================

-- Play background music by track name
function AudioManager.PlayMusic(trackName)
	playMusic(trackName)
end

-- Stop background music
function AudioManager.StopMusic()
	stopMusic()
end

-- Play a sound effect by name
-- @param soundName: string - The name from Config.Audio.SFX
-- @param position: Vector3 (optional) - World position for 3D sound
function AudioManager.PlaySFX(soundName, position)
	playSFX(soundName, position)
end

-- Set music volume
function AudioManager.SetMusicVolume(volume)
	if currentMusic then
		currentMusic.Volume = math.clamp(volume, 0, 1)
	end
end

-- Set SFX volume
function AudioManager.SetSFXVolume(volume)
	Config.Audio.SFX.Volume = math.clamp(volume, 0, 1)
end

-- Enable/disable music
function AudioManager.SetMusicEnabled(enabled)
	Config.Audio.Music.Enable = enabled
	if not enabled then
		stopMusic()
	end
end

-- Enable/disable SFX
function AudioManager.SetSFXEnabled(enabled)
	Config.Audio.SFX.Enable = enabled
end

-- =============================================================================
-- INITIALIZE
-- =============================================================================
function AudioManager.Initialize()
	-- print("[AudioManager] Initializing...")
	
	-- Safety check for Config.Audio
	if not Config.Audio then
		warn("[AudioManager] Config.Audio not found - audio disabled")
		return
	end
	
	-- Start ambient music
	if Config.Audio.Enable and Config.Audio.Music and Config.Audio.Music.Enable then
		local trackName = Config.Audio.Music.CurrentTrack or "Ambient"
		playMusic(trackName)
	end
	
	-- Listen for weather changes to change music/ambient
	local success, weatherChangedEvent = pcall(function()
		return ReplicatedStorage:WaitForChild(Constants.EVENTS.WEATHER_CHANGED, 5)
	end)
	
	if success and weatherChangedEvent then
		weatherChangedEvent.OnClientEvent:Connect(function(weather)
			-- Play weather sound effects
			if weather == Constants.WEATHER_TYPES.RAINY then
				AudioManager.PlaySFX("RainStart")
			elseif weather == Constants.WEATHER_TYPES.STORMY then
				AudioManager.PlaySFX("StormStart")
			elseif weather == Constants.WEATHER_TYPES.SUNNY then
				AudioManager.PlaySFX("SunnyStart")
			end
		end)
	end
	
	-- print("[AudioManager] ✅ Initialized successfully!")
end

return AudioManager
