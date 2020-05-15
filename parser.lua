local function match(sequence, pattern, index)
  index              = index or 1
  local capture      = string.match(sequence, '^' .. pattern[index])
  local sub_sequence = string.gsub(sequence, '^' .. pattern[index], '')

  if capture then
    if #sub_sequence == 0 and #pattern == index then
      return {capture}, true, true
    elseif #sub_sequence == 0 and #pattern > index then
      return {capture}, true, false
    elseif #sub_sequence > 0 and #pattern > index then
      local captures, valid, finished = match(sub_sequence, pattern, index + 1)
      table.insert(captures, 1, capture)
      return captures, valid, finished
    end
  end
  return {}, false, false
end

local function parse(sequence, commands)
  local should_break = true
  for _, command in ipairs(commands) do
    local captures, valid, finished = match(sequence, command.pattern)

    if finished then
      -- prevent the keygrabber from stopping when command fails
      xpcall(command.handler, function(err) awesome.emit_signal("debug::error", err) end,
        command, table.unpack(captures))
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
