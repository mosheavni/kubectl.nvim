local actions = require("kubectl.actions")
local commands = require("kubectl.commands")
local find = require("kubectl.utils.find")
local services = require("kubectl.services")
local tables = require("kubectl.view.tables")

local M = {}

function M.Services()
  local results = commands.execute_shell_command("kubectl", { "get", "services", "-A", "-o=json" })
  local data = services.processRow(vim.json.decode(results))
  local pretty = tables.pretty_print(data, services.getHeaders())
  local hints = tables.generateHints({
    { key = "<d>", desc = "describe" },
  }, true, true)

  actions.new_buffer(
    find.filter_line(pretty, FILTER),
    "k8s_services",
    { is_float = false, hints = hints, title = "Services" }
  )
end

function M.ServiceDesc(namespace, name)
  local desc = commands.execute_shell_command("kubectl", { "describe", "svc", name, "-n", namespace })
  actions.new_buffer(vim.split(desc, "\n"), "k8s_svc_desc", { is_float = true, title = name, syntax = "yaml" })
end

return M
