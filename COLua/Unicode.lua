local COLua = require "COLua"
local String = require "COLua.String"
local unicode = require "unicode"

COLua.Unicode = COLua{"Unicode", String;
  __len = function(self)
    return unicode.len(self.str)
  end,
  _char = function(self, code, ...)
    return COLua.Unicode(unicode.char(code, ...))
  end,
  len = function(self)
    return unicode.len(self.str)
  end,
  lower = function(self)
    return COLua.Unicode(unicode.lower(self.str))
  end,
  reverse = function(self)
    return COLua.Unicode(unicode.reverse(self.str))
  end,
  sub = function(self, i, j)
    return COLua.Unicode(unicode.sub(self.str, i, j))
  end,
  upper = function(self)
    return COLua.Unicode(unicode.upper(self.str))
  end}

return COLua.Unicode

