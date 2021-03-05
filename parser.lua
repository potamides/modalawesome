local unpack = unpack or table.unpack -- luacheck: globals unpack (compatibility with Lua 5.1)

local function match(sequence, pattern)
  local captures, matches = {}

  for index = 1, #pattern do
    sequence, matches = string.gsub(sequence, '^' .. pattern[index],
      function(capture)
        table.insert(captures, capture)
        return ''
      end)

      if matches == 0 then
        return false
      elseif #sequence == 0 and index < #pattern then
        return true, false
      end
  end

  return true, true, captures
end

local function parse(sequence, commands)
  local sequence_processed = true
  for _, command in ipairs(commands) do
    local valid, finished, captures = match(sequence, command.pattern)

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

return {parse = parse}
