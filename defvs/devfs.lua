local component = require "component"
local event = require "event"
local proxy = require "devfs.proxy"

local devices = {}

local function register(name, read, seek, write, close)
  checkArg(1, name, "string")
  checkArg(2, read, "function")
  checkArg(3, seek, "function")
  checkArg(4, write, "function")
  checkArg(5, close, "function")
  devices[name] = {read = read, seek = seek, write = write, close = close}
  local i = 1
  for address, componentType in omponent.list(name) do
    if componentType == name then
      proxy.dev[name..i] = address
      i = i + 1
    end
  end
  return true
end

local function unregister(name)
  local pattern = name.."%d*"
  local rmTab = {}
  for path in proxy.list() do
    if path:find(pattern) then
      table.insert(rmTab, path)
    end
  end
  for i=1, #rmTab do
    proxy.remove(rmTab[i])
  end
  return true
end



