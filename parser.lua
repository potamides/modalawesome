local hasitem = require("gears.table").hasitem
local unpack = unpack or table.unpack -- luacheck: globals unpack (compatibility with Lua 5.1)

local parser = {}

function parser.match(sequence, modifiers, pattern)
  local captures, matches, modifier_mismatch = {}

  for index, item in ipairs(pattern) do
    sequence, matches = string.gsub(sequence, '^' .. (item[#item] or item), function(capture)
      table.insert(captures, capture)
      return ''
    end)

    if type(item) == "table" then
      if #modifiers[index] == #item - 1 then
        for _, mod in pairs(modifiers[index]) do
          if not hasitem(item, mod) then
            modifier_mismatch = true
            break
          end
        end
      else
        modifier_mismatch = true
      end
    end

    if matches == 0 or modifier_mismatch then
      return false
    elseif #sequence == 0 and index < #pattern then
      return true, false
    end
  end

  return true, true, captures
end

function parser.evaluate(sequence, modifiers, commands)
  local sequence_processed = true
  for _, command in ipairs(commands) do
    local valid, finished, captures = parser.match(sequence, modifiers, command.pattern)

    if finished then
      -- make sure to return to caller gracefully, even under error conditions
      xpcall(function() command:handler(unpack(captures)) end,
        function(err) awesome.emit_signal("debug::error", err, true) end)
      return true
    elseif valid then
      sequence_processed = false
    end
  end

  return sequence_processed
end

return parser
