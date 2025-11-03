--// LocalScript placed in StarterPlayerScripts

-- Services
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Create ScreenGUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ChatLogger"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 400, 0, 300)
mainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- Resizer
local resizer = Instance.new("Frame")
resizer.Name = "Resizer"
resizer.Size = UDim2.new(0, 20, 0, 20)
resizer.Position = UDim2.new(1, -20, 1, -20)
resizer.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
resizer.Active = true
resizer.Draggable = false
resizer.Parent = mainFrame

-- Close Button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 80, 0, 25)
closeButton.Position = UDim2.new(1, -90, 0, 10)
closeButton.BackgroundColor3 = Color3.fromRGB(255, 75, 75)
closeButton.Text = "Close"
closeButton.TextColor3 = Color3.new(1,1,1)
closeButton.Font = Enum.Font.SourceSansBold
closeButton.TextSize = 18
closeButton.Parent = mainFrame

-- ScrollFrame
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -20, 1, -50)
scrollFrame.Position = UDim2.new(0, 10, 0, 40)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.ScrollBarThickness = 8
scrollFrame.BackgroundTransparency = 0.2
scrollFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
scrollFrame.BorderSizePixel = 0
scrollFrame.Parent = mainFrame

-- UIListLayout for messages
local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 4)
layout.Parent = scrollFrame

-- Handle resizing
local UserInputService = game:GetService("UserInputService")
local resizing = false
local startPos, startSize

resizer.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		resizing = true
		startPos = input.Position
		startSize = mainFrame.Size
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - startPos
		mainFrame.Size = UDim2.new(0, math.max(200, startSize.X.Offset + delta.X), 0, math.max(150, startSize.Y.Offset + delta.Y))
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		resizing = false
	end
end)

-- Close button logic
closeButton.MouseButton1Click:Connect(function()
	screenGui.Enabled = false
end)

-- Chat message listener
local function addMessage(sender, message)
	local msgLabel = Instance.new("TextLabel")
	msgLabel.Size = UDim2.new(1, -10, 0, 20)
	msgLabel.BackgroundTransparency = 1
	msgLabel.Font = Enum.Font.SourceSans
	msgLabel.TextSize = 18
	msgLabel.TextColor3 = Color3.new(1, 1, 1)
	msgLabel.TextXAlignment = Enum.TextXAlignment.Left
	msgLabel.Text = string.format("[%s]: %s", sender, message)
	msgLabel.Parent = scrollFrame

	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
end

-- Listen for player chat messages
Players.PlayerChatted:Connect(function(player, message)
	addMessage(player.Name, message)
end)

-- Also catch system chat events (modern chat system)
local ChatService = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
if ChatService and ChatService:FindFirstChild("OnMessageDoneFiltering") then
	ChatService.OnMessageDoneFiltering.OnClientEvent:Connect(function(data)
		addMessage(data.FromSpeaker or "System", data.Message or "")
	end)
end
