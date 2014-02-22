--- A deamon for managing the energy levels of a closed of system. Works for robots and computers connected to batteries.
local computer = require 'computer'
local event = require 'event'
local fs = require "filesystem"
local getopt = require 'getopt'
local shell = require 'shell'

-- Change this line if you want a different config file
local config = 'energyd.conf'
local borders = {}
local sleepTime = 1

local function levels(t)
  for k, v in ipairs(t) do
    if type(v) ~= "number" then
      error 'All levels must be numbers'
    end
  end
  borders = t
end

local function setSleep(val)
  time, reason = pcall(tonumber, val)
  if not time then
    error "The sleep time must be a number"
  end
  sleepTime = reason
end

--- Loads the configuration file for energyd
local function loadConfig(conf)
  local fEnv= {levels = levels, sleep = setSleep}
  local f, reason = loadfile(conf, 't',fEnv)
  if not f then
    print("Could not load "..conf..':')
    print(reason)
  else
    f()
  end
end

if fs.exists(config) then
  loadConfig(shell.resolve(config))
else
  print "No default configuration file"
end

for opt, arg in getopt({...}, 'c:s') do
  if opt == 'c' then
    loadConfig(shell.resolve(arg))
  elseif opt == 's' then
    setSleep(arg)
  end
end

if #borders <= 0 then
  print "No values are given for the event levels"
  print "Aborting"
  return
end

-- Start with creating the energy module
local energy = {}
energy.loading = false
energy.energyLevel = function()
  return computer.energy()/computer.maxEnergy()*100
end
-- Copy energy and maxEnergy, so the energy module becomes you one place to look for energy values
energy.energy = computer.energy
energy.maxEnergy = computer.maxEnergy

local lastLevel = energy.energyLevel()
-- Index of the next level
local idx
for i = 1, #borders do
  if borders[i] <= lastLevel and lastLevel <= (borders[i - 1] or 100) then
    idx = i
    break
  end
end

-- Create the daemon process
local function updateEnergy()
  local curLevel = energy.energyLevel()
  -- See if we have a larger percentage of energy now
  local loading = (curLevel >= lastLevel)
  if loading then
    if borders[idx-1] and curLevel >= borders[idx-1] then
      idx = idx - 1
      computer.pushSignal("energy_changed", loading, curLevel)
    end
  else
    if borders[idx] and curLevel <= borders[idx] then
      idx = idx +1
      computer.pushSignal("energy_changed", loading, curLevel)
    end
  end
  energy.loading = loading
  lastLevel = curLevel
end

local timer = event.timer(sleepTime, updateEnergy)
energy.running = true

function energy.stop()
  event.cancel(timer)
  energy.running = false
end

-- Load the energy module for real
package.loaded.energy = energy
