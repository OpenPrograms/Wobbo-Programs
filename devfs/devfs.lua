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

local function makeDirectory(path)
  if exists(path) then
    return nil, path .. " already exists"
  end
  local dirPath = fs.getPath(path)
  if isDirectory(dirPath) then
    local dir  = getNode(dirPath)
    local name = fs.getName(path)
    dir[name] = {__type = "directory"}
    return true
  else
    return nil, dirPath .. " is not a directory"
  end
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

local function rename(source, dest)
  if not exists(source) then
    return nil, "No such file: " .. source
  end
  local sourcePath = fs.getPath(source)
  local destPath   = fs.getPath(dest)
  if not isDirectory(destPath) then
    return nil, destPath .. " is not a directory"
  end
  local src = getNode(source)
  local destDir = getNose(destPath)
  destDir[fs.getName(dest)] = src
  return true
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
local function register(path, typ, open, read, seek, write, close)
  checkArg(1, name,  "string")
  checkArg(2, typ ,  "string")
  checkArg(3, open,  "function")
  checkArg(4, read,  "function")
  checkArg(5, seek,  "function")
  checkArg(6, write, "function")
  checkArg(7, close, "function")
  local dirPath = fs.getPath(path)
  if not isDirectory(dirPath) then
    return nil, "No such directory: "..dir
  elseif exists(path) then
    return nil, "File "..path.." already exists"
  end
  local dir  = getNode(dirPath)
  local name = fs.getName(path)
  local file = {__type = typ , open  = open,  read  = read,
                seek   = seek, write = write, close = close}
  dir[name] = file
  return true
end

local function unregister(path)
  if not exists(path) then
    return nil, "No such file"
  end
  if isDirectory(path) then
    return nil, path .. " is a directory"
  end
  local dirPath = fs.getPath(path)
  local dir     = getNode(dirPath)
  local name    = fs.getName(path)
  dir[name] = nil
  return true
end

return {register      = register,   unregister = unregister, 
        getLabel      = getLabel,   setLabel   = setLabel,
        isReadOnly    = isReadOnly, spaceTotal = spaceTotal, 
        spaceUsed     = spaceUsed,  exists     = exists,
        size          = size,      isDirectory = isDirectory,
        lastModified  = lastModified, list     = list,
        makeDirectory = makeDirectory, remove  = remove,
        rename        = rename,     close      = close,
        open          = open,       read       = read,
        write         = write,      seek       = seek}
