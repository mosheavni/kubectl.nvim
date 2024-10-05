local M = {
  resource = "lineage",
  display_name = "Lineage",
  ft = "k8s_lineage",
}

-- Function to collect all resources from the data sample
function M.collect_all_resources(data_sample)
  local resources = {}
  for kind_key, resource_group in pairs(data_sample) do
    if resource_group.data then
      -- Extract resource instances from the 'data' field
      for _, resource in ipairs(resource_group.data) do
        resource.kind = resource.kind and resource.kind:lower()
          or resource_group.kind and resource_group.kind:lower()
          or kind_key:lower()
        table.insert(resources, resource)
      end
    else
      -- No 'data' field; skip or handle as needed
    end
  end
  return resources
end

-- Function to create a unique key for resources
function M.get_resource_key(resource)
  local ns_part = resource.ns or "cluster"
  local kind = resource.kind and resource.kind:lower() or "unknownkind"
  return kind .. "/" .. ns_part .. "/" .. resource.name
end

-- Function to build a graph of resources
function M.build_graph(resources)
  local graph = {}

  -- First pass: map keys to resources and initialize graph nodes
  for _, resource in ipairs(resources) do
    if resource.name then
      resource.kind = resource.kind and resource.kind:lower() or "unknownkind"
      local resource_key = M.get_resource_key(resource)
      graph[resource_key] = { resource = resource, neighbors = {} }
      -- Debug: print added resource
      -- print("Added resource to graph:", resource_key, resource.kind, resource.name)
    end
  end

  -- Second pass: build ownership edges
  for _, resource in ipairs(resources) do
    if resource.name then
      local resource_key = M.get_resource_key(resource)
      local node = graph[resource_key]
      if resource.owners then
        for _, owner in ipairs(resource.owners) do
          owner.kind = owner.kind and owner.kind:lower() or "unknownkind"
          owner.ns = owner.ns or resource.ns -- Assume same namespace if not specified
          local owner_key = M.get_resource_key(owner)
          if not graph[owner_key] then
            graph[owner_key] = { resource = owner, neighbors = {} }
            -- Debug: print added owner
            -- print("Added owner to graph:", owner_key, owner.kind, owner.name)
          end
          -- Add bidirectional edge
          table.insert(node.neighbors, graph[owner_key])
          table.insert(graph[owner_key].neighbors, node)
          -- Debug: print linking
          -- print("Linking", resource_key, "to owner", owner_key)
        end
      end
    end
  end

  return graph
end

-- Function to find associated resources using BFS traversal
function M.find_associated_resources(graph, start_key)
  local visited = {}
  local queue = {}
  local associated_resources = {}

  if not graph[start_key] then
    print("Selected resource not found in the graph.")
    return associated_resources
  end

  table.insert(queue, start_key)
  visited[start_key] = true
  -- Debug: print starting traversal
  -- print("Starting traversal from key:", start_key)

  while #queue > 0 do
    local current_key = table.remove(queue, 1)
    local node = graph[current_key]
    if node then
      table.insert(associated_resources, node.resource)
      -- Debug: print visited node
      -- print("Visited:", current_key, node.resource.kind, node.resource.name)
      for _, neighbor in ipairs(node.neighbors) do
        local neighbor_key = M.get_resource_key(neighbor.resource)
        if not visited[neighbor_key] then
          visited[neighbor_key] = true
          table.insert(queue, neighbor_key)
        end
      end
    end
  end

  return associated_resources
end

return M
