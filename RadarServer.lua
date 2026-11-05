-- RADAR PRO - SERVER
-- Coloca este Script en ServerScriptService.
-- Los 50 BOT son registros simulados del radar; no son cuentas reales ni NPCs físicos.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local event = ReplicatedStorage:FindFirstChild("RadarEvent")
if not event then
    event = Instance.new("RemoteEvent")
    event.Name = "RadarEvent"
    event.Parent = ReplicatedStorage
end

local bots = {}
for i = 1, 50 do
    bots[i] = {
        Name = string.format("BOT-%03d", i),
        DisplayName = string.format("BOT-%03d", i),
        Type = "NPC",
        Status = "Registrado"
    }
end

local function makeSnapshot()
    local playerList = {}

    for _, player in ipairs(Players:GetPlayers()) do
        table.insert(playerList, {
            Name = player.Name,
            DisplayName = player.DisplayName,
            UserId = player.UserId,
            Type = "Jugador"
        })
    end

    return {
        Bots = bots,
        Players = playerList
    }
end

local function updateRadar()
    event:FireAllClients("Update", makeSnapshot())
end

event.OnServerEvent:Connect(function(player, action)
    if action == "RequestUpdate" then
        event:FireClient(player, "Update", makeSnapshot())
    end
end)

Players.PlayerAdded:Connect(function(player)
    event:FireAllClients("Notification", player.Name .. " entró al servidor")
    updateRadar()
end)

Players.PlayerRemoving:Connect(function(player)
    event:FireAllClients("Notification", player.Name .. " salió del servidor")
    task.defer(updateRadar)
end)

-- Envía los datos actuales a los jugadores que ya están dentro.
task.defer(updateRadar)
