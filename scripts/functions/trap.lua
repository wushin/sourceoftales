-- [[
-- Logic of traps
--
-- To create a trap place a trap object on the map and require this file in your
-- atinit function.
--
-- The mapobject has to have the following properties:
--  TYPE             -> "TRAP"
--  damage           -> value of damage
--  damage_delta     -> delta of damage. default: 0
--  chance_to_hit    -> chance to hit. default: 999
--  damage_type      -> damage tpye. default: DAMAGE_PHYSICAL
--  reuse_delay      -> time until the trap can get triggered again after use. default: 0
--  trigger_radius   -> radius around the trap in which a trigger is placed. default: 0
--  trigger_delay    -> time in seconds until trap deals damage. default: 0
--  effect_id        -> effect that will be spawned in the center of the trap. default: none
--
-- As soon someone steps on the trigger surrounding the trap the trigger_delay
-- is scheduled. If the timer is up damage will be dealt to all beings in the
-- focus of the trap (boundaries of the object in tiled)
--
-- Authors:
-- - Ablu
-- ]]

module("trap", package.seeall)

local traps = {}

local objects = map_get_objects("TRAP")

--- Assigns a callback to the trap trigger. If the callback returns true no
-- damage is dealt
-- @param name The name of the trap (the name property of the object in tiled)
-- @param func The function that will be called with the being as parameter
function assign_callback(name, func)
    for _, trap in ipairs(traps) do
        if trap.name == name then
            trap.callback = func
            break
        end
    end
end

local function deal_damage(trap)
    local beings = get_beings_in_rectangle(trap.x, trap.y, trap.w, trap.h)
    for _, being in ipairs(beings) do
        being_damage(being, trap.damage, trap.damage_delta, trap.chance_to_hit,
                     trap.damage_type, trap.element)
    end
    trap.usable = false
    schedule_in(trap.reuse_delay, function() trap.usable = true end)
end

local function triggered(trap, being)
    if not trap.usable then
        return
    end

    if trap.callback and trap.callback(being) then
        return
    end

    if trap.effect_id ~= -1 then
        effect_create(trap.effect_id, trap.x + trap.w / 2, trap.y + trap.h / 2)
    end
    
    schedule_in(trap.trigger_delay, function() deal_damage(trap) end)
end

for _, object in ipairs(objects) do
    local trap = {}
    trap.name = object:name()
    trap.damage = tonumber(object:property("damage"))
    trap.damage_delta = tonumber(object:property("damage_delta") or 0)
    trap.chance_to_hit = tonumber(object:property("chance_to_hit") or 999)
    trap.damage_type = tonumber(object:property("damage_type") or DAMAGE_PHYSICAL)
    trap.element = tonumber(object:property("element") or ELEMENT_NEUTRAL)
    trap.effect_id = tonumber(object:property("effect_id") or -1)
    trap.reuse_delay = tonumber(object:property("reuse_delay") or 0)
    trap.trigger_delay = tonumber(object:property("trigger_delay") or 0)
    trap.usable = true
    local trigger_radius = tonumber(object:property("trigger_radius") or 0)
    trap.x, trap.y, trap.w, trap.h = object:bounds()
    local new_id = #traps + 1
    trigger_create(trap.x - trigger_radius, trap.y - trigger_radius,
                   2 * trigger_radius + trap.w, 2 * trigger_radius + trap.h,
                   function(being, id) triggered(trap, being) end, 0, true)

    traps[new_id] = trap
end
