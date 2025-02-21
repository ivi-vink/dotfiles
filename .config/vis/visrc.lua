-- load standard vis module, providing parts of the Lua API
require('vis')
require('vis-editorconfig')
require('vis-cursors')
require('vis-compile-win')
local quickfix = require('vis-quickfix')
local format = require('vis-format')
local m = vis.modes

quickfix.grepprg = "grep -Hn "

vis.ftdetect.filetypes.terraform = {
  ext = { "%.tf$" },
}
for k, _ in pairs(format.formatters) do
	format.formatters[k] = nil
end
format.formatters.python = format.stdio_formatter("ruff format -", {on_save=true})
format.formatters.terraform = format.stdio_formatter("terraform fmt -", {on_save=true})

vis.events.subscribe(vis.events.INIT, function()
  vis:command"set shell '/usr/bin/bash'"
  vis:command"set edconfhooks on"
  -- vis:command"set change256colors off"
  vis:command"set theme gruber-darker"

  vis:map(m.NORMAL,      '<C-[>', ':cp<Enter>')
  vis:map(m.NORMAL,      '<C-]>', ':cn<Enter>')
  vis:map(m.INSERT,      '<C-r>"', '<C-r>+')

  vis:map(m.NORMAL,      'y', '<vis-register>+<vis-operator-yank>')
  vis:map(m.VISUAL,      'y', '<vis-register>+<vis-operator-yank>')
  vis:map(m.VISUAL_LINE, 'y', '<vis-register>+<vis-operator-yank>')
  vis:map(m.NORMAL,      'd', '<vis-register>+<vis-operator-delete>')
  vis:map(m.VISUAL,      'd', '<vis-register>+<vis-operator-delete>')
  vis:map(m.VISUAL_LINE, 'd', '<vis-register>+<vis-operator-delete>')
  vis:map(m.NORMAL,      'p', '<vis-register>+<vis-put-after>')
  vis:map(m.VISUAL,      'p', '<vis-register>+<vis-put-after>')
  vis:map(m.VISUAL_LINE, 'p', '<vis-register>+<vis-put-after>')
  vis:map(m.NORMAL,      'P', '<vis-register>+<vis-put-before>')
  vis:map(m.VISUAL,      'P', '<vis-register>+<vis-put-before>')
  vis:map(m.VISUAL_LINE, 'P', '<vis-register>+<vis-put-before>')
end)

local files = {}
vis.events.subscribe(vis.events.WIN_OPEN, function(win)
  vis:command"set cul on"
  vis:command"set number"
  vis:command"set relativenumber"
  vis:command"set change256colors off"
  local radix = files[vis.win.file.path]
  for p, i in pairs(files) do
    if (radix == nil) or (radix >= i) then
      files[p] = i + 1
    end
  end
  if vis.win.file.path then
    files[vis.win.file.path] = 0
  end
end)

vis:map(m.NORMAL, "<C-x>b", function()
  local keys = {}
  for k in pairs(files) do if k ~= vis.win.file.path then table.insert(keys, k) end end
  if next(keys) == nil then
    return true
  end
  table.sort(keys, function(a, b) return files[a] < files[b] end)
  local code, result, err = vis:pipe(table.concat(keys, "\n"), "vis-menu -l 3")
  if result then
    vis:command("e " .. result)
  end
  return true;
end)

local parent = function(filename)
  if filename ~= nil then
    return filename:match("(.+)/[^/]+$")
  end
  return nil
end

-- Only works on linux for now.
local pcwd = function()
  local stat = io.open("/proc/self/stat"):read("*a")
  local fields = {}
  for k in stat:gmatch("[^%s]+") do table.insert(fields, k) end
  if not fields[4] then
    return "."
  end
  local parent_cwd = "/proc/" .. fields[4] .. "/cwd"
  vis:info(parent_cwd)
  return parent_cwd
end

vis:map(m.NORMAL, "<C-x>~", function()
  vis:command("cd " .. pcwd())
  return true;
end)
vis:map(m.NORMAL, "<C-x>_", function()
  local code, result, err = vis:pipe("vis-open .")
  if result then
    vis:command("e " .. result)
  end
  return true;
end)
vis:map(m.NORMAL, "<C-x>g", ":!tig<Enter>")
vis:map(m.NORMAL, "<C-x><C-f>", function()
  local code, result, err = vis:pipe("vis-open " .. (parent(vis.win.file.path) or "."))
  if result then
    vis:command("e " .. result)
  end
  return true;
end)
