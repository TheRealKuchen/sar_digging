RegisterNetEvent('dig:rewardItem', function()
    local src = source
    local items = Config.RewardItems
    local randomItem = items[math.random(#items)]

    if randomItem == "nothing" then
        TriggerClientEvent('dig:notifyItemFound', src, "nothing", nil)
        return
    end

    exports.ox_inventory:AddItem(src, randomItem, 1)

    local oxItems = exports.ox_inventory:Items()
    local itemLabel = oxItems[randomItem] and oxItems[randomItem].label or randomItem

    TriggerClientEvent('dig:notifyItemFound', src, randomItem, itemLabel)
end)
