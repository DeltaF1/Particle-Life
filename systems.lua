local s = require "lib.ECS.system".makeSystemClass
local Vector = require "lib.vector"

PhysicsSystem = s{"physics", "transform"}

function PhysicsSystem:onUpdate(entity, eventArgs)
  local dt = eventArgs.dt
  local physics, transform = entity.physics, entity.transform
  
  physics.vel = physics.vel + physics.accel * dt
  transform.pos = transform.pos + physics.vel * dt
end

FrictionSystem = s{"physics"}

function FrictionSystem:onUpdate(entity, eventArgs)
  local dt = eventArgs.dt
  local physics = entity.physics
  
  physics.vel = physics.vel - (physics.vel * 1 * dt)
  
end

DrawSystem = s{"dot", "colour", "transform"}

function DrawSystem:onDraw(entity)
  local pos = entity.transform.pos
  local dot = entity.dot
  
  love.graphics.setColor(entity.colour)
  love.graphics.circle("fill", pos.x, pos.y, dot.radius)
end

ColliderMover = s{"transform", "influence"}

function ColliderMover:onUpdate(entity, eventArgs)
  entity.influence:moveTo(entity.transform.pos:unpack())
end

ForceSystem = s{"forces", "physics", "transform", "dot"}
function ForceSystem:onUpdate(entity, eventArgs)
  entity.physics.accel = Vector()
  for other, _ in pairs(HC.collisions(entity.influence)) do
    other = other.entity
    local delta = other.transform.pos - entity.transform.pos
    
    local tooClose = (entity.dot.radius + other.dot.radius) * 0.8
    
    local f
    if delta:len() < tooClose then
      if delta:len() == 0 then
        delta = Vector.randomDirection()
      end
      f = delta:normalized() * -600/delta:len()
    else
      f = entity.forces[other.type]
      
      f = (f * delta:normalized())
      
      --f = f * math.max(1, math.pow(delta:len(), 2))
    end
    -- a = f / m
    entity.physics.accel = entity.physics.accel + (f / (entity.dot.radius/3)) -- approximation of mass
  end
end

return {ColliderMover, ForceSystem, FrictionSystem, PhysicsSystem, LoopSystem, DrawSystem}