local QBCore = exports['qb-core']:GetCoreObject()

-- Function to check for items when a player loads
RegisterNetEvent('QBCore:Server:PlayerLoaded')
AddEventHandler('QBCore:Server:PlayerLoaded', function()
    local src = source
    CheckPlayerItems(src)
end)

-- Function to check player items
function CheckPlayerItems(src)
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end

    -- Loop through the list of items to check
    for i = 1, #Config.ItemsToCheck do
        local itemName = Config.ItemsToCheck[i]
        local item = Player.Functions.GetItemByName(itemName)

        if item then
            -- Remove the specific item found
            Player.Functions.RemoveItem(itemName, item.amount)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], "remove")
            print("Removed " .. item.amount .. " of " .. itemName .. " from player " .. Player.PlayerData.citizenid)

            -- Send data to webhook for the specific item removed
            if Config.WebhookURL ~= "" then
                PerformHttpRequest(Config.WebhookURL, function(err, text, headers) end, 'POST', json.encode({
                    content = "",
                    embeds = {{ -- Embed for webhook
                        title = "Item Removed",
                        description = Player.PlayerData.name .. " (" .. Player.PlayerData.citizenid .. ") had " .. item.amount .. " of " .. itemName .. " and it was removed.",
                        color = 16711680, -- Red color
                        footer = {
                            text = os.date("%Y-%m-%d %H:%M:%S")
                        }
                    }}
                }), { ['Content-Type'] = 'application/json' })
            end
        end
    end
end

-- Main function to check and remove items
RegisterNetEvent('ic7-antyitem:checkAndRemoveItem')
AddEventHandler('ic7-antyitem:checkAndRemoveItem', function()
    local src = source
    CheckPlayerItems(src)
end)

-- Check all online players periodically
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.CheckInterval * 1000) -- Convert to milliseconds
        local players = QBCore.Functions.GetPlayers()
        for _, playerId in ipairs(players) do
            CheckPlayerItems(playerId)
        end
    end
end)

-- Check player inventory when they receive an item
RegisterNetEvent('QBCore:Server:AddItem')
AddEventHandler('QBCore:Server:AddItem', function(itemName, amount, slot, info)
    local src = source
    Citizen.Wait(100) -- Small delay to ensure item is added
    CheckPlayerItems(src)
end)

-- Command to manually check and remove items (for admins)
QBCore.Commands.Add('checkitems', 'Check and remove prohibited items', {}, false, function(source, args)
    local src = source
    CheckPlayerItems(src)
end, 'admin')