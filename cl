--// working with colored text

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ChatLogger"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 420, 0, 320)
mainFrame.Position = UDim2.new(0.5, -210, 0.5, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -100, 0, 30)
title.Position = UDim2.new(0, 10, 0, 6)
title.BackgroundTransparency = 1
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(240, 240, 240)
title.Text = "Chat Log"
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = mainFrame

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 80, 0, 28)
closeButton.Position = UDim2.new(1, -90, 0, 6)
closeButton.BackgroundColor3 = Color3.fromRGB(255, 75, 75)
closeButton.Text = "Close"
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.Font = Enum.Font.SourceSansBold
closeButton.TextSize = 16
closeButton.Parent = mainFrame

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -20, 1, -70)
scrollFrame.Position = UDim2.new(0, 10, 0, 40)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.ScrollBarThickness = 8
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.Parent = mainFrame

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 6)
layout.Parent = scrollFrame

local resizer = Instance.new("Frame")
resizer.Size = UDim2.new(0, 18, 0, 18)
resizer.Position = UDim2.new(1, -18, 1, -18)
resizer.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
resizer.BorderSizePixel = 0
resizer.Parent = mainFrame

-- Helper to add messages
local function addMessage(sender, message, msgType)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -10, 0, 22)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.SourceSans
	label.TextSize = 18
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.TextColor3 = Color3.fromRGB(230,230,230)

	if msgType == "Whisper" or msgType == "PrivateMessage" then
		label.TextColor3 = Color3.fromRGB(150, 200, 255)
	elseif msgType == "Command" then
		label.TextColor3 = Color3.fromRGB(200, 150, 255)
	elseif msgType == "System" then
		label.TextColor3 = Color3.fromRGB(255, 180, 120)
	end

	label.Text = string.format("[%s]: %s", sender, message)
	label.Parent = scrollFrame

	task.defer(function()
		local newY = layout.AbsoluteContentSize.Y + 8
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, newY)
		scrollFrame.CanvasPosition = Vector2.new(0, math.max(0, newY - scrollFrame.AbsoluteSize.Y))
	end)
end

-- Close button
closeButton.MouseButton1Click:Connect(function()
	screenGui.Enabled = false
end)

-- Resizing logic
local resizing = false
local startMousePos, startSize

resizer.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		resizing = true
		startMousePos = input.Position
		startSize = mainFrame.AbsoluteSize
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - startMousePos
		mainFrame.Size = UDim2.new(0, math.max(240, startSize.X + delta.X), 0, math.max(160, startSize.Y + delta.Y))
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		resizing = false
	end
end)

-- CHAT EVENT LISTENERS

local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")

if chatEvents then
	-- Regular, whisper, and system messages
	chatEvents.OnMessageDoneFiltering.OnClientEvent:Connect(function(data)
		local from = data.FromSpeaker or "System"
		local msg = data.Message or ""
		local msgType = data.MessageType or data.OriginalChannel or "Normal"
		addMessage(from, msg, msgType)
	end)

	-- Catch outgoing commands or whispers before filtering
	local sayEvent = chatEvents:FindFirstChild("SayMessageRequest")
	if sayEvent then
		sayEvent.OnClientEvent:Connect(function(message, channel)
			if string.sub(message, 1, 1) == "/" then
				addMessage(player.Name, message, "Command")
			elseif channel and string.find(string.lower(channel), "whisper") then
				addMessage(player.Name, message, "Whisper")
			end
		end)
	end
else
	warn("[ChatLogger] DefaultChatSystemChatEvents not found.")
end

-- Also show local player’s unfiltered chat (fallback)
player.Chatted:Connect(function(msg)
	addMessage(player.Name, msg, "Normal")
end)

print("✅ Chat Logger GUI with whisper & command capture initialized.")
