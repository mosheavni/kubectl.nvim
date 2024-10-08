local time = require("kubectl.utils.time")
local M = {
  resource = "sa",
  display_name = "sa",
  ft = "k8s_sa",
  url = { "{{BASE}}/api/v1/{{NAMESPACE}}serviceaccounts?pretty=false" },
}

function M.processRow(rows)
  local data = {}

  if not rows or not rows.items then
    return data
  end

  for _, row in ipairs(rows.items) do
    local pod = {
      namespace = row.metadata.namespace,
      name = row.metadata.name,
      secret = row.secrets and #row.secrets or 0,
      age = time.since(row.metadata.creationTimestamp),
    }

    table.insert(data, pod)
  end
  return data
end

function M.getHeaders()
  local headers = {
    "NAMESPACE",
    "NAME",
    "SECRET",
    "AGE",
  }

  return headers
end

return M
