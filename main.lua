local World = require "lib.ECS.world"
local Vector = require "lib.vector"
HC = require "lib.HC"
local c = require "lib.ECS.component".makeComponentClass

function clone(value, seen)
  local seen = seen or {}
  if type(value) ~= "table" then
    return value
  end
  
  if seen[value] then
    return seen[value]
  end
  
  local t = {}
  seen[value] = t
  for k,v in pairs(value) do
    t[k] = clone(v, seen)
  end
  
  return setmetatable(t, getmetatable(value))
end

Transform = c("transform", {pos = Vector()})
Physics = c("physics", {accel=Vector(), vel=Vector()})

function makeParticle()
  local particle = {
    transform={pos=Vector(love.math.random(-WORLD_WIDTH, WORLD_WIDTH),love.math.random(-WORLD_HEIGHT, WORLD_HEIGHT))},
    physics = Physics(),
    influence = HC.circle(0,0,10),
  }
  
  particle.influence.entity = particle
  
  local typ = love.math.random(#particleTypes)
  particle.type = typ
  return setmetatable(particle, particleTypes[typ])
end    

function love.load()
  world = World()
  
  local systems = require "systems"
  
  for i = 1, #systems do
    world:addSystem(systems[i])
  end
  
  NUM_TYPES = 8
  
  particleTypes = {}
  
  FORCE_MAX=90
  
  for i = 1, NUM_TYPES do
    local typ = {
      colour = {love.math.random(), love.math.random(), love.math.random()},
      dot = {radius = love.math.random(3,5)},
    }
    
    -- use as metatable
    typ.__index = typ
    
    local forces = {}
    for j = 1, NUM_TYPES do
      forces[j] = (love.math.random() * FORCE_MAX - (FORCE_MAX/2))
    end
    
    typ.forces = forces
    
    particleTypes[i] = typ
  end
  
  WORLD_WIDTH, WORLD_HEIGHT = 1000, 1000
  
  NUM_PARTICLES = 2000
  
  for i = 1, NUM_PARTICLES do
    world:addEntity(makeParticle())
  end
  
  zoom = 1
  cameraPos = Vector()
  SPEED = 100
  ZOOMSPEED = 5
end

elapsed = 0
function love.update(dt)
  elapsed = elapsed + dt
  
  if elapsed >= 5 then
    elapsed = 0
    world:addEntity(makeParticle())
  end
  
  if love.keyboard.isDown("left") then
    cameraPos.x = cameraPos.x - SPEED * dt
  end
  if love.keyboard.isDown("right") then
    cameraPos.x = cameraPos.x + SPEED * dt
  end
  if love.keyboard.isDown("up") then
    cameraPos.y = cameraPos.y - SPEED * dt
  end
  if love.keyboard.isDown("down") then
    cameraPos.y = cameraPos.y + SPEED * dt
  end
  
  if love.keyboard.isDown("-") then
    zoom = zoom - ZOOMSPEED * dt
  elseif love.keyboard.isDown("=") then
    zoom = zoom + ZOOMSPEED * dt
  end
  
  world:addEvent(nil, "update", {dt=0.01})
  world:process()
end

function love.draw()
  world:addEvent(nil, "draw")
  
  love.graphics.push()
  love.graphics.translate(love.graphics.getWidth()/2, love.graphics.getHeight()/2)
  love.graphics.scale(zoom)
  love.graphics.translate(-cameraPos.x, -cameraPos.y)
  world:process()
  love.graphics.pop()
end

