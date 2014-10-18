local component = require "component"
local computer = require "computer"
local event = require "event"
local fs = require "filesystem"

local devices = {}
local dev = {}
local handles = {}

local label = "defvs"
local files = {}

local function getPathComponents(path)
  local components = {}
  for component in path:gmatch("[^/^\\]+") do
    table.insert(components, component)
  end 
  return components
end 

local function getNode(path)
  local comps = getPathComponents(path)
  local curDir = dir
  for i in 1, #comps do
    local tmp = dir[comps[i]]
    if tmp then
      if i == #comps then
        return tmp
      elseif tmp.__type == "directory" then
        curDir = tmp
      else
        return nil, "No such file: "..path
      end
    else
        return nil, "No such file: "..path
    end
  end
end

local function getLabel()
  return label
end

local function setLabel(name)
  label = name
  return label
end

local function isReadOnly()
  return false
end

local function spaceTotal()
  return computer.freeMemory()
end

local function spaceUsed()
  return computer.usedMemory()
end

local function isDirectory(path)
  local dir = getNode(path)
  return dir and dir.__type == "directory"
end

local function exists(path)
  return getNode(path) and true or false
end

local function size(path)
  return #(list(path))
end

local function lastModified(path)
  return os.time()
end

-- returns an table of entries inside the path, and table.n = #table
local function list(path)
  if isDirectory(path) then
    local lst = {}
    for k, _ in pairs(getNode(path)) do
      if k:sub(1,2) ~= "__" then
        table.insert(lst, k)
      end
    end
    return lst
  else
    return nil, "No such directory: " .. path
  end
end

local function dirMakeDirectory(dir, path)
  local base, rest = getBase(path)
  if rest then
    return dirMakeDirectory(dir[base], rest)
  else
    dir[base] = {isDirectory = true}
    return true
  end
end

local function makeDirectory(path)
  return dirMakeDirectory(dev, path)
end

local function dirRemove(dir, path)
  local base, rest = getBase(path)
  if rest then
    return dirRemove(dir[base], rest)
  else
    dir[base]= nil
    return true
  end
end

local function remove(path)
  return dirRemove(dev, path)
end

local function dirRename(dir, source, dest)
  local base, rest = getBase(source)
  if rest then
    return dirRename(dir[base], rest, dest)
  else
    local destBase, destRest, destDir = nil, nil, dev
    repeat
      destBase, destRest = getBase(dest)
      if not destDir[destBase] then
        destDir[destBase] = {}
      end
      destDir = destDir[destBase]
      dest = destRest
    until not destRest
    destDir[destBase] = dir[base]
    dir[base] = nil
    return true
  end
end

local function rename(source, dest)
  return dirRename(dev, source, dest)
end

local function open(path, mode)
  print(tostring(path), tostring(mode))
  mode = mode or 'r'
  local nextHandle = #handles + 1
  if exists(path) then
    local base, rest, dir = nil, path, dev
    repeat
      base, rest = getBase(rest)
      if rest then
        dir = dir[base]
      end
    until not rest
    local file = dir[base]
    local hand = {type = file.name}
    if file.type == "component" then
      hand.data = component.proxy(file.address)
    elseif file.type == "singleton" then
      hand.data = nil
    end
    (devices[hand.type]).open(hand.data, path, mode)
    handles[nextHandle] = hand
  else
    error "No such file!"
  end
  return nextHandle
end

local function close(handle)
  local hand = handles[handle]
  handles[handle] = nil
  return (devices[hand.type]).close(hand.data)
end

local function read(handle, bytes)
  local hand = handles[handle]
  return (devices[hand.type]).read(hand.data, bytes)
end

local function seek(handle, whence, offset)
  local hand = handles[handle]
  return (devices[hand.type]).seek(hand.data, whence, offset)
end

local function write(handle, data)
  local hand = handles[handle]
  return (devices[hand.type]).write(hand.data, data)
end

--- Functions for (un)registering new devices
local function registerComponent(name, open, read, seek, write, close)
  checkArg(1, name, "string")
  checkArg(2, open, "function")
  checkArg(3, read, "function")
  checkArg(4, seek, "function")
  checkArg(5, write, "function")
  checkArg(6, close, "function")
  devices[name] = {open = open, read = read, seek = seek, write = write, 
                    close = close}
  local i = 1
  for address, componentType in component.list(name) do
    if componentType == name then
      dev[name..i] = {name = name, address = address, type = "component"}
      i = i + 1
    end
  end
  return true
end

local function registerSingleton(name, open, read, seek, write, close)
  checkArg(1, name, "string")
  checkArg(2, open, "function")
  checkArg(3, read, "function")
  checkArg(4, seek, "function")
  checkArg(5, write, "function")
  checkArg(6, close, "function")
  devices[name] = {open = open, read = read, seek = seek, write = write, 
                    close = close}
  dev[name] = {name = name, type = "singleton"}
  return true
end


local function unregister(name)
  local pattern = name.."%d*"
  devices[name] = nil
  local rmTab = {}
  for path in list() do
    if path:find(pattern) then
      table.insert(rmTab, path)
    end
  end
  for i=1, #rmTab do
    remove(rmTab[i])
  end
  return true
end

return {registerComponent = registerComponent, unregister = unregister,
  registerSingleton = registerSingleton;
  getLabel = getLabel, setLabel = setLabel, isReadOnly = isReadOnly,
  spaceTotal = spaceTotal, spaceUsed = spaceUsed, exists = exists,
  size = size, isDirectory = isDirectory, lastModified = lastModified,
  list = list, makeDirectory = makeDirectory, remove = remove, 
  rename = rename, close = close, open = open, read = read, write = write,
  seek = seek}
