local gears   = require("gears")

local function match(sequence, pattern)
  local capture      = string.match(sequence, '^' .. pattern[1])
  local sub_sequence = string.gsub(sequence, '^' .. pattern[1], '')

  if capture then
    table.remove(pattern, 1)
    if #sub_sequence == 0 and #pattern == 0 then
      return {capture}, true, true
    elseif #sub_sequence == 0 and #pattern > 0 then
      return {capture}, true, false
    elseif #sub_sequence > 0 and #pattern > 0 then
      local captures, valid, finished = match(sub_sequence, pattern)
      return gears.table.merge({capture}, captures), valid, finished
    end
  end
  return {}, false, false
end

local function parse(sequence, commands)
  local should_break = true
  for _, command in ipairs(commands) do
    local captures, valid, finished = match(sequence, gears.table.clone(command.pattern))

    if finished then
      command:handler(table.unpack(captures))
      return true
    elseif valid then
      should_break = false
    end
  end

  if should_break then
    return true
  end

  return false
end


return {parse = parse}
