-- RADAR PRO - CLIENT
-- Coloca este LocalScript en StarterPlayer > StarterPlayerScripts.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local event = ReplicatedStorage:WaitForChild("RadarEvent")

local gui = Instance.new("ScreenGui")
gui.Name = "RadarProGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0, 270, 0, 330)
panel.Position = UDim2.new(0, 12, 0.5, -165)
panel.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
panel.BorderSizePixel = 0
panel.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -16, 0, 34)
title.Position = UDim2.new(0, 8, 0, 6)
title.BackgroundTransparency = 1
title.Text = "RADAR PRO"
title.TextColor3 = Color3.fromRGB(90, 230, 145)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.Parent = panel

local counts = Instance.new("TextLabel")
counts.Size = UDim2.new(1, -16, 0, 24)
counts.Position = UDim2.new(0, 8, 0, 40)
counts.BackgroundTransparency = 1
counts.TextColor3 = Color3.fromRGB(235, 235, 235)
counts.Font = Enum.Font.Gotham
counts.TextSize = 13
counts.TextXAlignment = Enum.TextXAlignment.Left
counts.Parent = panel

local notice = Instance.new("TextLabel")
notice.Size = UDim2.new(1, -16, 0, 32)
notice.Position = UDim2.new(0, 8, 0, 66)
notice.BackgroundColor3 = Color3.fromRGB(35, 75, 55)
notice.TextColor3 = Color3.fromRGB(220, 255, 230)
notice.Font = Enum.Font.Gotham
notice.TextSize = 12
notice.Text = "Esperando datos del servidor..."
notice.TextWrapped = true
notice.Parent = panel

local list = Instance.new("ScrollingFrame")
list.Name = "Lista"
list.Size = UDim2.new(1, -16, 1, -112)
list.Position = UDim2.new(0, 8, 0, 104)
list.BackgroundColor3 = Color3.fromRGB(29, 34, 44)
list.BorderSizePixel = 0
list.ScrollBarThickness = 5
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.Parent = panel

local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 8)
listCorner.Parent = list

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 3)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local function addLine(text, color)
    local row = Instance.new("TextLabel")
    row.Size = UDim2.new(1, -8, 0, 24)
    row.BackgroundTransparency = 1
    row.Text = text
    row.TextColor3 = color
    row.Font = Enum.Font.Gotham
    row.TextSize = 12
    row.TextXAlignment = Enum.TextXAlignment.Left
    row.Parent = list
end

local function render(data)
    for _, child in ipairs(list:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    local bots = data.Bots or {}
    local players = data.Players or {}
    counts.Text = string.format("Bots: %d/50   |   Jugadores: %d", #bots, #players)

    addLine("-- NPC REGISTRADOS --", Color3.fromRGB(100, 230, 150))
    for _, bot in ipairs(bots) do
        addLine("● " .. bot.Name, Color3.fromRGB(170, 220, 185))
    end

    addLine("-- JUGADORES REALES --", Color3.fromRGB(110, 190, 255))
    if #players == 0 then
        addLine("No hay otros jugadores conectados", Color3.fromRGB(220, 220, 220))
    else
        for _, p in ipairs(players) do
            addLine("● " .. p.Name, Color3.fromRGB(220, 235, 255))
        end
    end

    task.defer(function()
        list.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
    end)
end

event.OnClientEvent:Connect(function(kind, payload)
    if kind == "Update" then
        render(payload)
    elseif kind == "Notification" then
        notice.Text = payload
    end
end)

-- Pide la lista cuando la interfaz ya está lista.
event:FireServer("RequestUpdate")
