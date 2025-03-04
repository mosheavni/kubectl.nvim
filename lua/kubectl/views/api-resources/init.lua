local ResourceBuilder = require("kubectl.resourcebuilder")
local cache = require("kubectl.cache")
local definition = require("kubectl.views.api-resources.definition")
local state = require("kubectl.state")
local tables = require("kubectl.utils.tables")

local M = {}

function M.View(cancellationToken)
  local self = state.instance[definition.resource]
  if not self or not self.resource or self.resource ~= definition.resource then
    self = ResourceBuilder:new(definition.resource)
  end

  self:display(definition.ft, definition.resource, cancellationToken)

  state.instance[definition.resource] = self
  local cached_resources = cache.cached_api_resources
  self.data = cached_resources and cached_resources.values or {}

  vim.schedule(function()
    M.Draw(cancellationToken)
  end)
end

function M.Draw(cancellationToken)
  if #state.instance[definition.resource].data == 0 then
    local cached_resources = cache.cached_api_resources
    if #vim.tbl_keys(cached_resources.values) > 0 then
      state.instance[definition.resource].data = cached_resources.values
    end
  end
  state.instance[definition.resource]:draw(definition, cancellationToken)
end

--- Get current seletion for view
---@return string|nil
function M.getCurrentSelection()
  return tables.getCurrentSelection(1)
end

return M
