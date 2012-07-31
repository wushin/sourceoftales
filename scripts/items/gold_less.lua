local money = get_item_class("Few Gold Coins")

local amount_min = 3
local amount_max = 7

money:on("pickup", function(user)
    local count = chr_inv_count(user, true, false, money)
    local amount = count * math.random(amount_min, amount_max)
    chr_inv_change(user, money, -count)
    chr_money_change(user, amount)
end)
