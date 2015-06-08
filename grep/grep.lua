--- POSIX grep for OpenComputers, only difference is that this version uses Lua regex, not POSIX regex.
--
-- Depends on getopt by Wobbo. 

local args = {...} -- Catch the arguments
local getopt = require "getopt" -- Load getopt

-- Specify the variables for the options
local plain = false
local count = nil
local ignoreCase = false
local writeNamesOnce = false
local linNumber = nil
local quiet = false
local fileError = true
local invert = false
local metchWhole = false
local printNames = false

-- Table with patterns to check for
local patternList = {}

-- Table with files to look in
local patternFiles = {}

local function printUsage()
  local process = require("process")
  print('Usage: '..process.running()..' [-c|-l|-q][-Finsvx] [-e pattern] [-f patternFile] [pattern] [file...]')
end

-- Resolve the location of a file, without searching the path
local function resolve(file)
  if file:sub(1,1) == '/' then
    return fs.canonical(file)
  else
    if file:sub(1,1) == '.' then
      file = file:sub(3, -1)
    end
    return fs.canonical(fs.concat(shell.getWorkingDirectory(), file))
  end
end

-- Checks if it should error, and errors if that is required
local function fileError(file)
  if fileError then
    print(shell.running()..': '..file..': No such file or directory')
  end
end

--- Builds a case insensitive pattern, code from stackOverflow (questions/11401890/case-insensitive-lua-pattern-matching)
local function caseInsensitivePattern(pattern)
  -- find an optional '%' (group 1) followed by any character (group 2)
  local p = pattern:gsub("(%%?)(.)", function(percent, letter)
    if percent ~= "" or not letter:match("%a") then
      -- if the '%' matched, or `letter` is not a letter, return "as is"
      return percent .. letter
    else
      -- else, return a case-insensitive character class of the matched letter
      return string.format("[%s%s]", letter:lower(), letter:upper())
    end
  end)
  return p
end

-- Process the command line arguments
if #args < 1 then
  printUsage()
  return 2
end

for opt, arg in getopt(args, "Fce:f:ilnqsvx") do
  if opt == 'F' then
    plain = true
  elseif opt == 'c' then
    if writeNamesOnce or quiet then printUsage() return end
    counter = 0
  elseif opt == 'e' then
    table.insert(patternList, arg)
  elseif opt == 'f' then
    table.insert(patternFiles, arg)
  elseif opt == 'i' then
    ignoreCase = true
  elseif opt == 'l' then
    if counter or quiet then printUsage() return end
    writeNamesOnce = true
  elseif opt == 'n' then
    lineNumber = 1
  elseif opt == 'q' then
    if writeNamesOnce or counter then printUsage() return end
    quiet = true
  elseif opt == 's' then
    fileError = false
  elseif opt == 'v' then
    invert = true
  elseif opt == 'x' then
    matchWhole = true
  elseif opt == 'E' then
  elseif opt == '?' then
    printUsage()
    return 2
  elseif opt == ':' then
    print(opt..' Needs an argument!')
    printUsage()
    return 2
  end
end

-- Read the pattern files and add the patterns to the patternList
for i = 1, #patternFiles do
  file = resolve(patternFiles[i])
  if fs.exists(file) then
    handle = io.open(file, 'r')
    for pat in handle:lines() do
      table.insert(patternList, pat)
    end
    handle:close()
  else
    fileError(file)
  end
end

-- Check if there are patterns, if not, get args[1] and add it to the list
if #patternList == 0 then
  if #args < 1 then
    printUsage()
    return 2
  else
    table.insert(patternList, table.remove(args, 1))
  end
end

-- Prepare an iterator for reading files
local readLines
if #args >= 1 then
  readLines = function()
    local files = args
    local curHand = nil
    local curFile = nil
    return function()
      if not curFile and #files > 0 then
        file = resolve(table.remove(files, 1))
        if fs.exists(file) then
          curFile = file
          curHand = io.open(curFile, 'r')
          if lineNumber then lineNumber = 1 end
        else
          fileError(file)
          return false, "file not found"
        end
      end
      local line = curHand:read("*l")
      if not line then
        curFile = nil
        curHand:close()
        if #files < 1 then
          return nil
        else
          return false, "end of file"
        end
      else
        return line, curFile
      end
    end
  end
else
  readLines = io.lines
end

-- Main
if #args > 1 then printNames = true end -- Print the names of the files we read

local matchFile = nil
for line, file in readLines() do
  if not line then
    if file ~= "end of file" then return 2 end
  else
    file = file or '(standard input)'
    if line then
      local match = false
      for _, pattern in pairs(patternList) do
        if ignoreCase then pattern = caseInsensitivePattern(pattern) end
        local i, j = line:find(pattern, 1, plain)
        if not matchWhole then
          match = i and true or match
        else
          if j == #line and i == 1 then match = true end
        end
      end
      if match ~= invert then
        if quiet then return 0 end
        if not count then
          if writeNamesOnce then
            if matchFile ~= file then print(file) end
          else
            if printNames then
              io.write(file..': ')
            end
            if lineNumber then io.write(lineNumber..': ') end
            print(line)
          end
        elseif matchFile ~= file then
          if printNames then io.write(matchFile': ') end
          print(count)
          count = 1
        else
          count = count + 1
        end
        matchFile = file
      end
      if lineNumber then lineNumber = lineNumber + 1 end
    end
  end
end

return (matchFile and 0 or 1)
