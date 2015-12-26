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
    pos = pos + 1
    if char == '-' then
      -- Stop processing by demand of user
      return nil
    end

    local i, j = string.find(options, char..':*')
    if not i then
      return '?', char
    elseif j - i == 0 then
      -- No option argument.
      return char
    elseif j - i == 1 then
      -- Required option arguments MAY be bundled with the flags (e.g. -ofoo),
      -- OR separated by a space (e.g. -o foo). Arguments that start with a
      -- dash are okay (e.g. negative numbers: -n-5 and -n -5 both return "n", "-5").
      local arg = (pos <= #current) and current:sub(pos) or table.remove(args, 1)
      current = nil

      if not arg then
        return ':', char
      else
        return char, arg
      end
    elseif j - i == 2 then
      -- Optional option arguments MUST be bundled with the flag (e.g. -ofoo, -f" test").
      -- An argument separated by a space (e.g. -n -5) is instead treated as another
      -- option (-n and -5 are options; to pass -5 as the argument, you must use -n-5).
      local arg = (pos <= #current) and current:sub(pos) or nil
      current = nil

      return char, arg
    end
  end
end

return getopt
