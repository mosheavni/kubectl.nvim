local ResourceBuilder = require("kubectl.resourcebuilder")
local buffers = require("kubectl.actions.buffers")
local commands = require("kubectl.actions.commands")
local definition = require("kubectl.views.deployments.definition")
local tables = require("kubectl.utils.tables")

local M = {}

function M.View(cancellationToken)
  ResourceBuilder:new("deployments")
    :setCmd({ "{{BASE}}/apis/apps/v1/{{NAMESPACE}}deployments?pretty=false" }, "curl")
    :fetchAsync(function(self)
      self:decodeJson():process(definition.processRow):sort():prettyPrint(definition.getHeaders)
      vim.schedule(function()
        self
          :addHints({
            { key = "<grr>", desc = "restart" },
            { key = "<gd>", desc = "desc" },
            { key = "<enter>", desc = "pods" },
          }, true, true, true)
          :display("k8s_deployments", "Deployments", cancellationToken)
      end)
    end)
end

function M.Desc(name, ns)
  ResourceBuilder:new("desc")
    :setCmd({ "describe", "deployment", name, "-n", ns })
    :fetchAsync(function(self)
      self:splitData()
      vim.schedule(function()
        self:displayFloat("k8s_deployment_desc", name, "yaml")
      end)
    end)
end

function M.Edit(name, ns)
  buffers.floating_buffer({}, {}, "k8s_deployment_edit", { title = name, syntax = "yaml" })
  commands.execute_terminal("kubectl", { "edit", "deployments/" .. name, "-n", ns })
end

--- Get current seletion for view
---@return string|nil
function M.getCurrentSelection()
  return tables.getCurrentSelection(2, 1)
end

return M
