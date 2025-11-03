--// LocalScript placed in StarterPlayerScripts

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Create ScreenGUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ChatLogger"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 420, 0, 320)
mainFrame.Position = UDim2.new(0.5, -210, 0.5, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -100, 0, 30)
title.Position = UDim2.new(0, 10, 0, 6)
title.BackgroundTransparency = 1
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(240,240,240)
title.Text = "Chat Log"
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = mainFrame

-- Close Button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 80, 0, 28)
closeButton.Position = UDim2.new(1, -90, 0, 6)
closeButton.BackgroundColor3 = Color3.fromRGB(255, 75, 75)
closeButton.Text = "Close"
closeButton.TextColor3 = Color3.new(1,1,1)
closeButton.Font = Enum.Font.SourceSansBold
closeButton.TextSize = 16
closeButton.Parent = mainFrame

-- ScrollFrame for messages
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "Messages"
scrollFrame.Size = UDim2.new(1, -20, 1, -70)
scrollFrame.Position = UDim2.new(0, 10, 0, 40)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.ScrollBarThickness = 8
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.Parent = mainFrame

-- UIListLayout for messages
local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 6)
layout.Parent = scrollFrame

-- Resizer (bottom-right)
local resizer = Instance.new("Frame")
resizer.Name = "Resizer"
resizer.Size = UDim2.new(0, 18, 0, 18)
resizer.Position = UDim2.new(1, -18, 1, -18)
resizer.AnchorPoint = Vector2.new(0, 0)
resizer.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
resizer.BorderSizePixel = 0
resizer.Parent = mainFrame

-- Styling helper (message)
local function createMessageLabel(text)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -10, 0, 22)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.SourceSans
	label.TextSize = 18
	label.TextColor3 = Color3.fromRGB(230,230,230)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = text
	label.TextWrapped = true
	label.Parent = scrollFrame
	return label
end

-- Add message to the scroll frame
local function addMessage(sender, message)
	-- protect against nil
	sender = tostring(sender or "System")
	message = tostring(message or "")

	local text = string.format("[%s]: %s", sender, message)
	local lbl = createMessageLabel(text)

	-- Small delay to let layout update before computing canvas size
	task.defer(function()
		local newY = layout.AbsoluteContentSize.Y + 8
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, newY)
		-- Scroll to bottom
		scrollFrame.CanvasPosition = Vector2.new(0, math.max(0, newY - scrollFrame.AbsoluteSize.Y))
	end)
end

-- Close button logic
closeButton.MouseButton1Click:Connect(function()
	screenGui.Enabled = false
end)

-- Resizing logic
local resizing = false
local startMousePos = Vector2.new(0,0)
local startSize = Vector2.new(0,0)

resizer.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		resizing = true
		startMousePos = input.Position
		startSize = Vector2.new(mainFrame.AbsoluteSize.X, mainFrame.AbsoluteSize.Y)
		-- Capture the mouse so we still get InputChanged
		input.Changed:Connect(function()
			-- nothing necessary here
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - startMousePos
		local newX = math.max(240, math.floor(startSize.X + delta.X))
		local newY = math.max(160, math.floor(startSize.Y + delta.Y))
		mainFrame.Size = UDim2.new(0, newX, 0, newY)
		-- adjust canvas when resized
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		resizing = false
	end
end)

-- --- Chat listeners ---

-- 1) Preferred: listen to the DefaultChatSystemChatEvents.OnMessageDoneFiltering (filtered, includes all players' chat)
local success, chatEvents = pcall(function()
	return ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents", 2)
end)

if success and chatEvents and chatEvents:FindFirstChild("OnMessageDoneFiltering") then
	chatEvents.OnMessageDoneFiltering.OnClientEvent:Connect(function(data)
		-- data is typically a table that contains FromSpeaker and Message
		-- Example: {SpeakerUserId = 123, FromSpeaker = "PlayerName", Message = "Hello", ...}
		local from = data.FromSpeaker or data.SpeakerName or "System"
		local msg = data.Message or (type(data) == "string" and data) or ""
		addMessage(from, msg)
	end)
else
	-- Fallback: connect Player.Chatted for each player (works in many cases)
	-- Note: Player.Chatted may not be guaranteed filtered in the same way; OnMessageDoneFiltering is preferred.
	warn("[ChatLogger] DefaultChatSystemChatEvents not found; using Player.Chatted fallback.")

	-- Connect existing players
	for _, p in ipairs(Players:GetPlayers()) do
		p.Chatted:Connect(function(msg)
			addMessage(p.Name, msg)
		end)
	end
	-- Connect future players
	Players.PlayerAdded:Connect(function(newP)
		newP.Chatted:Connect(function(msg)
			addMessage(newP.Name, msg)
		end)
	end)
end

-- Also capture local player's Chatted as a safe extra measure (won't duplicate if OnMessageDoneFiltering already fires)
if player then
	player.Chatted:Connect(function(msg)
		-- This will only fire for the local player's outgoing text.
		-- OnMessageDoneFiltering normally also relays this; duplication is unlikely but acceptable for fallback cases.
		addMessage(player.Name, msg)
	end)
end

print("✅ Chat Logger GUI initialized.")
