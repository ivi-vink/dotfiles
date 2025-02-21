require('vis')
local process_name = "vis-compile-win"

local buf

local M = {}

local function append_to_win(win, buffer)
  local file = win.file
  local pos = win.selection.pos
  local result = file:insert(file.size, buffer)
  file.modified = false
  win.selection.pos = pos
end

function M:compile(cmd, callback)
  vis:command"new"
  self.callback = callback
  self.win = vis.win
  self.buf = [[Compilation started at ]]..os.date("%a %b %d %X")..[[


]]..cmd..[[

]]
  append_to_win(self.win, self.buf)
	self.fd = vis:communicate(process_name, cmd)
	return true
end

function M:recv_data(buffer)
  local data = buffer or ""
  self.buf = self.buf..data
  append_to_win(self.win, data)
  return true
end

function M:finish_compilation(event, code, buffer)
  local footer = [[

Compilation finished at ]]..os.date("%a %b %d %X")
  self.buf = self.buf..footer
  append_to_win(self.win, footer)
  return self:callback()
end

vis:command_register("Compile", function(argv, force, win, selection, range)
	return M:compile(table.concat(argv, " "))
end)

vis.events.subscribe(vis.events.PROCESS_RESPONSE, function(name, event, code, buffer)
	if name ~= process_name then end

  if event == 'EXIT' or event == 'SIGNAL' then
    M:finish_compilation(event, code, buffer)
    return
  end

	M:recv_data(buffer)
end)

return M
