local commands = require("kubectl.actions.commands")
local manager = require("kubectl.resource_manager")
local state = require("kubectl.state")

local M = { handles = nil, loading = false, timestamp = nil, cached_api_resources = { values = {}, shortNames = {} } }

local ttl = require("kubectl.config").options.api_resources_cache_ttl
local data = vim.fn.stdpath("data") .. "/kubectl"
local current_time = os.time()

M.LoadFallbackData = function(force)
  if M.loading then
    print("is loading")
    return
  end
  if force then
    print("force loading")
    M.cached_api_resources = { values = {}, shortNames = {} }
    M.load_cache(M.cached_api_resources)
    return
  end

  local ctx = state.context["current-context"]
  local path = string.format("%s/%s.json", data .. "/api_resources", ctx)

  local stat = vim.uv.fs_stat(path)
  local is_stale = not stat or (current_time - stat.mtime.sec >= ttl)
  local cached = commands.read_file("api_resources/" .. ctx .. ".json")
  if not cached then
    print("no cached data found")
    M.load_cache(M.cached_api_resources)
    return
  end
  M.cached_api_resources = cached

  if is_stale then
    print("cached data is stale, reloading")
    M.load_cache(M.cached_api_resources)
    return
  end

  M.timestamp = stat and stat.mtime.sec
end

local function process_apis(resource, cached_api_resources)
  local name = string.lower(resource.crd_name)
  local value = {
    name = name,
    gvk = {
      g = resource.gvk.group,
      v = resource.gvk.version,
      k = resource.gvk.kind,
    },
    plural = resource.plural,
    crd_name = name,
    namespaced = resource.namespaced,
    api_version = resource.api_version,
  }

  cached_api_resources.values[name] = value

  if resource.short_names then
    for _, shortName in ipairs(resource.short_names) do
      cached_api_resources.shortNames[shortName] = value
    end
  end
  state.sortby[name] = { mark = {}, current_word = "", order = "asc" }
end

function M.load_cache(cached_api_resources)
  M.loading = true

  local builder = manager.get_or_create("api_resources")
  commands.run_async("get_api_resources_async", {}, function(result, err)
    if err then
      vim.print("error: failed loading api_resources", err)
      return
    end
    builder.data = result
    builder.decodeJson()

    for _, resource in ipairs(builder.data) do
      if resource.gvk then
        process_apis(resource, cached_api_resources)
      end
    end

    M.loading = false
    M.timestamp = os.time()
    vim.schedule(function()
      vim.cmd("doautocmd User KubectlCacheLoaded")
      local ctx = state.context["current-context"]
      local ok, msg = commands.save_file("api_resources/" .. ctx .. ".json", cached_api_resources)
      if not ok then
        vim.notify("Failed to save api_resources: " .. msg, vim.log.levels.ERROR)
      end
    end)
  end)
end

return M
