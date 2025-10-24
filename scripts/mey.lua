-- Mey Companion Script (LocalScript)
-- Safe to use inside Roblox Studio (StarterPlayerScripts)
-- Creates a companion NPC that looks like UserId 7139360318 and behaves like a friendly follower.

-- =========================================================
-- CONFIGURATION VARIABLES
-- =========================================================
local CONFIG = {
	UserIdToClone = 7139360318,           -- Roblox userId whose appearance to clone
	NameDisplay = "Mey ♥",                -- Name text over NPC head
	SpawnOffset = Vector3.new(1.5, 0, 0), -- spawn offset from player
	FollowDistance = 5,                   -- stop moving if within this distance
	FollowStartDistance = 10,             -- start moving if farther than this
	TeleportDistance = 80,                -- teleport if farther than this
	PathRecomputeInterval = 0.5,          -- seconds between path recalculations
	SpeechMinDelay = 6,                   -- min seconds between phrases
	SpeechMaxDelay = 18,                  -- max seconds between phrases
	SpeechBubbleDuration = 4,             -- duration of each speech bubble
	LookAtDistance = 8,                   -- distance under which NPC sometimes looks at player
	LookChance = 0.35,                    -- chance each interval to look
	LookCheckInterval = 2.2,              -- seconds between look checks
	JumpDelay = 1.0,                      -- seconds after player jump
	CollisionGroupName = "CompanionNoPlayer", -- collision group name
	EnableEmoteSync = true,               -- sync emotes if possible
}

-- Cute random phrases
local PHRASES = {
	"¡Hola! 💕",
	"No te vayas muy lejos 😳",
	"Jeje, te sigo~ 🐾",
	"Estás haciendo un buen trabajo 😌",
	"Me gusta estar contigo 💖",
	"No corras tan rápido 😅",
	"Eres genial, ¿sabías? 💫",
	"Siempre contigo~ 🌸",
	"¿Jugamos? 😊",
	"Te cuido 😉",
}

-- =========================================================
-- SERVICES
-- =========================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local PhysicsService = game:GetService("PhysicsService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	warn("This script must be a LocalScript under StarterPlayerScripts.")
	return
end

-- =========================================================
-- HELPER FUNCTIONS
-- =========================================================
local function safeWaitForChild(parent, name)
	local child = parent:FindFirstChild(name)
	while not child do
		child = parent:WaitForChild(name)
	end
	return child
end

local function createSpeechBubble(text)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, 180, 0, 50)
	gui.StudsOffset = Vector3.new(0, 3.2, 0)
	gui.AlwaysOnTop = true

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundTransparency = 0.35
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.BorderSizePixel = 0
	frame.Parent = gui

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -8, 1, -8)
	label.Position = UDim2.new(0, 4, 0, 4)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(40, 40, 40)
	label.Font = Enum.Font.Gotham
	label.TextSize = 18
	label.TextWrapped = true
	label.Parent = frame

	return gui
end

local function createNameTag(nameText)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "NameTag"
	billboard.Size = UDim2.new(0, 120, 0, 25)
	billboard.StudsOffset = Vector3.new(0, 2.25, 0)
	billboard.AlwaysOnTop = false

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = nameText
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextSize = 16
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextStrokeTransparency = 0.7
	textLabel.Parent = billboard

	return billboard
end

-- =========================================================
-- CREATE NPC
-- =========================================================
local function createCompanion()
	local success, appearance = pcall(function()
		return Players:GetCharacterAppearanceAsync(CONFIG.UserIdToClone)
	end)
	if not success or not appearance then
		warn("Failed to get avatar appearance; using dummy rig.")
		appearance = Instance.new("Model")
		local hum = Instance.new("Humanoid")
		hum.Parent = appearance
	end

	appearance.Name = CONFIG.NameDisplay
	appearance.Parent = workspace

	local hum = appearance:FindFirstChildOfClass("Humanoid")
	local root = appearance:FindFirstChild("HumanoidRootPart")
	if not root then
		root = Instance.new("Part")
		root.Name = "HumanoidRootPart"
		root.Size = Vector3.new(2,2,1)
		root.Anchored = false
		root.Parent = appearance
		appearance.PrimaryPart = root
	end

	local playerChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local playerRoot = safeWaitForChild(playerChar, "HumanoidRootPart")
	root.CFrame = playerRoot.CFrame * CFrame.new(CONFIG.SpawnOffset)

	-- name tag
	local head = appearance:FindFirstChild("Head")
	if head then
		createNameTag(CONFIG.NameDisplay).Parent = head
	end

	-- collision group
	pcall(function()
		PhysicsService:CreateCollisionGroup(CONFIG.CollisionGroupName)
		PhysicsService:SetPartCollisionGroup(root, CONFIG.CollisionGroupName)
	end)

	return appearance, hum, root
end

-- =========================================================
-- MAIN LOGIC
-- =========================================================
local companion, humanoid, hrp = createCompanion()
local lastPathTime = 0
local nextSpeech = tick() + math.random(CONFIG.SpeechMinDelay, CONFIG.SpeechMaxDelay)
local nextLook = tick() + CONFIG.LookCheckInterval
local path = nil

RunService.Heartbeat:Connect(function(dt)
	local playerChar = LocalPlayer.Character
	if not playerChar then return end
	local playerHRP = playerChar:FindFirstChild("HumanoidRootPart")
	if not playerHRP or not hrp or not humanoid then return end

	-- Teleport if too far
	local dist = (playerHRP.Position - hrp.Position).Magnitude
	if dist >= CONFIG.TeleportDistance then
		hrp.CFrame = playerHRP.CFrame * CFrame.new(CONFIG.SpawnOffset)
		return
	end

	-- Pathfinding follow
	if dist > CONFIG.FollowStartDistance then
		if tick() - lastPathTime > CONFIG.PathRecomputeInterval then
			local pathNew = PathfindingService:CreatePath()
			pathNew:ComputeAsync(hrp.Position, playerHRP.Position)
			path = pathNew
			lastPathTime = tick()
		end
		if path and path.Status == Enum.PathStatus.Success then
			local waypoints = path:GetWaypoints()
			for _,way in ipairs(waypoints) do
				humanoid:MoveTo(way.Position)
				humanoid.MoveToFinished:Wait(CONFIG.MoveToTimeout)
			end
		end
	end

	-- Speech bubbles
	if tick() >= nextSpeech then
		nextSpeech = tick() + math.random(CONFIG.SpeechMinDelay, CONFIG.SpeechMaxDelay)
		local phrase = PHRASES[math.random(1, #PHRASES)]
		local bubble = createSpeechBubble(phrase)
		local head = companion:FindFirstChild("Head")
		if head then
			bubble.Parent = head
			game:GetService("Debris"):AddItem(bubble, CONFIG.SpeechBubbleDuration)
		end
	end

	-- Look at player occasionally
	if dist < CONFIG.LookAtDistance and tick() >= nextLook then
		nextLook = tick() + CONFIG.LookCheckInterval
		if math.random() < CONFIG.LookChance then
			hrp.CFrame = CFrame.new(hrp.Position, playerHRP.Position)
		end
	end
end)

print("Companion NPC 'Mey ♥' is active.")
