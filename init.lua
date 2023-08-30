local q = xplr.util.shell_quote

local function fzf(args, paths)
  local cmd = q(args.bin) .. " -m " .. args.args
  if paths ~= nil then
    cmd = cmd .. " <<< " .. q(paths)
  end

  local p = io.popen(cmd, "r")
  local output = p:read("*a")
  p:close()

  local lines = {}
  for line in output:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end

  local count = #lines

  if count == 0 then
    return
  elseif count == 1 then
    local path = lines[1]
    local msgs = {
      { FocusPath = path },
    }

    if args.enter_dir then
      local isdir = xplr.util.shell_execute("test", { "-d", path }).returncode == 0
      if isdir then
        table.insert(msgs, "Enter")
      end
    end

    return msgs
  else
    local msgs = {}
    for i, line in ipairs(lines) do
      table.insert(msgs, { SelectPath = line })
      if i == count then
        table.insert(msgs, { FocusPath = line })
      end
    end
    return msgs
  end
end

local function setup()
  local xplr = xplr

  args = {}
  args.mode = "default"
  args.bin = "fzf"
  args.args = ""

  if args.enter_dir == nil then
    args.enter_dir = false
  end

  xplr.config.modes.builtin[args.mode].key_bindings.on_key["alt-c"] = {
    help = "fzf search (non-recursively)",
    messages = {
      "PopMode",
      { CallLua = "custom.fzf.search" },
    },
  }

  xplr.config.modes.builtin[args.mode].key_bindings.on_key["ctrl-t"] = {
    help = "fzf search recursively",
    messages = {
      "PopMode",
      { CallLua = "custom.fzf.search_recursively" },
    },
  }

  xplr.config.modes.builtin[args.mode].key_bindings.on_key["alt-j"] = {
    help = "fzf autojump",
    messages = {
      "PopMode",
      { CallLua = "custom.fzf.autojump" },
    },
  }


  xplr.fn.custom.fzf = {}

  xplr.fn.custom.fzf.search = function(app)
    local paths = {}
    for _, n in ipairs(app.directory_buffer.nodes) do
      table.insert(paths, n.relative_path)
    end
    args.bin = "fzf"
    return fzf(args, table.concat(paths, "\n"))
  end

  xplr.fn.custom.fzf.search_recursively = function(app)
    args.bin = "fzf"
    return fzf(args)
  end

  xplr.fn.custom.fzf.autojump = function(app)
    args.bin = "autojump -s | sed -n '/^_______/!p; /^_______/q'  | tac | cut -d$'\\t' -f2; | fzf "
    return fzf(args)
  end
end

return { setup = setup }
