-- LocalScript (StarterPlayerScripts)
-- Robust Chat Logger: filtered chat (all players), whispers, and local commands.
-- Avoids duplicates by short-term dedupe. V3 SHOULD WORK.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- GUI setup (same layout as before)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ChatLogger"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 420, 0, 320)
mainFrame.Position = UDim2.new(0.5, -210, 0.5, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

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

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 80, 0, 28)
closeButton.Position = UDim2.new(1, -90, 0, 6)
closeButton.BackgroundColor3 = Color3.fromRGB(255,75,75)
closeButton.Text = "Close"
closeButton.TextColor3 = Color3.new(1,1,1)
closeButton.Font = Enum.Font.SourceSansBold
closeButton.TextSize = 16
closeButton.Parent = mainFrame

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "Messages"
scrollFrame.Size = UDim2.new(1, -20, 1, -70)
scrollFrame.Position = UDim2.new(0, 10, 0, 40)
scrollFrame.CanvasSize = UDim2.new(0,0,0,0)
scrollFrame.ScrollBarThickness = 8
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.Parent = mainFrame

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 6)
layout.Parent = scrollFrame

local resizer = Instance.new("Frame")
resizer.Name = "Resizer"
resizer.Size = UDim2.new(0, 18, 0, 18)
resizer.Position = UDim2.new(1, -18, 1, -18)
resizer.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
resizer.BorderSizePixel = 0
resizer.Parent = mainFrame

-- Add message function with colouring by type
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
		label.TextColor3 = Color3.fromRGB(150,200,255)
	elseif msgType == "Command" then
		label.TextColor3 = Color3.fromRGB(200,150,255)
	elseif msgType == "System" then
		label.TextColor3 = Color3.fromRGB(255,180,120)
	end

	label.Text = string.format("[%s]: %s", tostring(sender or "System"), tostring(message or ""))
	label.Parent = scrollFrame

	-- update canvas size and scroll to bottom
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

-- Resizer logic
local resizing = false
local startMousePos = Vector2.new()
local startSize = Vector2.new()

resizer.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		resizing = true
		startMousePos = input.Position
		startSize = Vector2.new(mainFrame.AbsoluteSize.X, mainFrame.AbsoluteSize.Y)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - startMousePos
		local newX = math.max(240, math.floor(startSize.X + delta.X))
		local newY = math.max(160, math.floor(startSize.Y + delta.Y))
		mainFrame.Size = UDim2.new(0, newX, 0, newY)
		-- update canvas (in case layout changed)
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		resizing = false
	end
end)

-- ---------- Chat listeners (robust) ----------

-- Dedupe cache: keys are sender..":"..message -> timestamp when seen
local dedupe = {}
local DEDUPE_WINDOW = 1.0 -- seconds; ignore identical messages within this window

local function seenRecently(key)
	local now = tick()
	local t = dedupe[key]
	if t and now - t < DEDUPE_WINDOW then
		return true
	end
	dedupe[key] = now
	-- purge old entries occasionally
	for k,v in pairs(dedupe) do
		if now - v > (DEDUPE_WINDOW * 5) then
			dedupe[k] = nil
		end
	end
	return false
end

-- Primary: OnMessageDoneFiltering (filtered messages for all players)
local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
if chatEvents then
	local onFiltered = chatEvents:FindFirstChild("OnMessageDoneFiltering")
	if onFiltered and onFiltered:IsA("RemoteEvent") then
		onFiltered.OnClientEvent:Connect(function(data)
			-- typical data table contains: FromSpeaker, Message, MessageType, OriginalChannel, SpeakerUserId, etc.
			local from = data.FromSpeaker or data.SpeakerName or "System"
			local msg = data.Message or (type(data) == "string" and data) or ""
			-- determine message type
			local msgType = nil
			if data.MessageType then
				msgType = tostring(data.MessageType)
			elseif data.OriginalChannel then
				msgType = tostring(data.OriginalChannel)
			end

			-- Normalize some whisper types
			if msgType then
				local lower = string.lower(tostring(msgType))
				if string.find(lower, "whisper") or string.find(lower, "private") then
					msgType = "Whisper"
				elseif string.find(lower, "system") then
					msgType = "System"
				end
			end

			local key = tostring(from) .. ":" .. tostring(msg)
			if not seenRecently(key) then
				addMessage(from, msg, msgType)
			end
		end)
	else
		warn("[ChatLogger] OnMessageDoneFiltering not found or not a RemoteEvent.")
	end
else
	warn("[ChatLogger] DefaultChatSystemChatEvents not found in ReplicatedStorage.")
end

-- Fallback: Player.Chatted for servers or old chat systems (and to capture local outgoing messages)
-- We'll use it for local player's own chat (to detect commands) and for other players if OnMessageDoneFiltering wasn't available.
-- If OnMessageDoneFiltering is present, these may duplicate, so dedupe protects us.
-- Connect existing players' Chatted (works in classic chat)
for _, p in ipairs(Players:GetPlayers()) do
	p.Chatted:Connect(function(msg)
		local key = tostring(p.Name) .. ":" .. tostring(msg)
		-- classify local player's commands (start with '/')
		local mtype = nil
		if p == player and type(msg) == "string" and string.sub(msg,1,1) == "/" then
			mtype = "Command"
		end
		if not seenRecently(key) then
			addMessage(p.Name, msg, mtype)
		end
	end)
end

-- Connect future players
Players.PlayerAdded:Connect(function(newP)
	newP.Chatted:Connect(function(msg)
		local key = tostring(newP.Name) .. ":" .. tostring(msg)
		if not seenRecently(key) then
			addMessage(newP.Name, msg, nil)
		end
	end)
end)

-- Also explicitly capture the local player's outgoing chat so we can display commands starting with '/'
-- (OnMessageDoneFiltering will usually also deliver the local player's message; dedupe prevents duplication)
if player then
	player.Chatted:Connect(function(msg)
		local key = tostring(player.Name) .. ":" .. tostring(msg)
		local mtype = nil
		if type(msg) == "string" and string.sub(msg,1,1) == "/" then
			mtype = "Command"
		end
		if not seenRecently(key) then
			addMessage(player.Name, msg, mtype)
		end
	end)
end

print("✅ Chat Logger initialized (filtered + whisper + local command capture).")
