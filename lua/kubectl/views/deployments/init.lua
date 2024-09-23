local ResourceBuilder = require("kubectl.resourcebuilder")
local buffers = require("kubectl.actions.buffers")
local commands = require("kubectl.actions.commands")
local definition = require("kubectl.views.deployments.definition")
local state = require("kubectl.state")
local tables = require("kubectl.utils.tables")

local M = {}

function M.View(cancellationToken)
  ResourceBuilder:view(definition, cancellationToken)
end

function M.Draw(cancellationToken)
  state.instance:draw(definition, cancellationToken)
end

function M.Desc(name, ns, reload)
  ResourceBuilder:view_float({
    resource = "deployments_desc_" .. name .. "_" .. ns,
    ft = "k8s_desc",
    url = { "describe", "deployment", name, "-n", ns },
    syntax = "yaml",
  }, { cmd = "kubectl", reload = reload })
end

function M.Edit(name, ns)
  buffers.floating_buffer("k8s_deployment_edit", name, "yaml")
  commands.execute_terminal("kubectl", { "edit", "deployments/" .. name, "-n", ns })
end

--- Get current seletion for view
---@return string|nil
function M.getCurrentSelection()
  return tables.getCurrentSelection(2, 1)
end

return M
