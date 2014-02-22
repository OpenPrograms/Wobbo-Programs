--- Module for getopt
-- @author Wobbo

--- Iterate over all the options the user provided. 
-- This function returns an iterator that can be used in the generic for that iterates over all the options the user specified when he called the program. It takes the arguments that were provided to the program, and a list of valid options as a string.
-- @tparam table args A table with the command line options provided
-- @tparam string options A string with all the valid options. Options are specifid with a : after the arguments, optional options are specified with a :: 
function getopt(args, options)
  checkArg(1, args, "table")
  checkArg(2, options, "string")
  local current = nil
  local pos = 1
  return function()
    if #args <= 0 then
      return nil -- No arguments left to process
    end
    if not current or #current < pos then
      if string.find(args[1], "^%-%w") then
        current = string.sub(args[1], 2, #args[1])
        pos = 1
        table.remove(args, 1)
      else
        return nil -- No options left to process, the rest is up to the program
      end
    end
    local char = current:sub(pos, pos)
    pos = pos +1
    if char == '-' then
      return nil -- Stop processing by demand of user
    end
    local i, j = string.find(options, char..':*')
    if not i then
      return '?', char
    elseif j-i == 0 then
      return char
    elseif j - i == 1 then
      if not args[1] or args[1]:sub(1,1) == '-' then
        return ':', char
      else
        return char, table.remove(args, 1)
      end
    elseif j - i == 2 then
      return char, (args[1] and args[1]:sub(1,1) ~= '-' and table.remove(args, 1)) or nil
    end
  end
end

return getopt
