local component = require "component"
local computer = require "computer"
local event = require "event"
local fs = require "filesystem"

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

local dev = {}

local label = "defvs"
local files = {}

local function getBase(path)
  checkArg(1, path, "string")
  return path:match("([^/])/?(.*)")
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

local function dirExists(dir, path)
  checkArg(1, path, "string")
  local base, rest = getBase(path)
  if rest then
    if isDirectory(dir[base]) then
      return dirExists(dir[base], rest)
    else
      return false
    end
  else
    return (dir[base] and true) or false
  end
end

local function exists(path)
  return dirExists(dev, path)
end

local function dirSize(dir, path)
  local base, rest = getBase(path)
  if rest then
    if isDirectory(dir[base]) then
      return dirSize(dir[base], rest)
    else
      return 0
    end
  else
    return #(dir[path])
  end
end

local function size(path)
  return dirSize(dev, path)
end

local function dirIsDirectory(dir, path)
  local base, rest = getBase(path)
  if rest then
    return dirIsDirectory(dir[base], rest)
  else
    return base.isDirectory or false
  end
end

local function isDirectory(path)
  return dirIsDirectory(dev, path)
end

local function lastModified(path)
  return os.time()
end

local function list(path)
  local last = nil
  local dir = fs.getName(path)
  return function()
    local new = next(dir, last)
    if isDirectory(new) then
      new = new..'/'
    end
    return new
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
