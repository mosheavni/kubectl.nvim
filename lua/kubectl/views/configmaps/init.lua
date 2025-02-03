local ResourceBuilder = require("kubectl.resourcebuilder")
local definition = require("kubectl.views.configmaps.definition")
local state = require("kubectl.state")
local tables = require("kubectl.utils.tables")

local M = {}

function M.View(cancellationToken)
  ResourceBuilder:view(definition, cancellationToken)
end

function M.Draw(cancellationToken)
  state.instance:draw(definition, cancellationToken)
end

--- Describe a configmap
---@param name string
---@param ns string
function M.Desc(name, ns, reload)
  ResourceBuilder:view_float({
    resource = "configmaps | " .. name .. " | " .. ns,
    ft = "k8s_desc",
    url = { "describe", "configmaps", name, "-n", ns },
    syntax = "yaml",
  }, { cmd = "kubectl", reload = reload })
end

--- Get current seletion for view
---@return string|nil
function M.getCurrentSelection()
  return tables.getCurrentSelection(2, 1)
end

return M
