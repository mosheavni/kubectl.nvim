local api = vim.api
local ResourceBuilder = require("kubectl.resourcebuilder")
local buffers = require("kubectl.actions.buffers")
local commands = require("kubectl.actions.commands")
local container_view = require("kubectl.views.containers")
local deployment_view = require("kubectl.views.deployments")
local hl = require("kubectl.actions.highlight")
local loop = require("kubectl.utils.loop")
local pod_view = require("kubectl.views.pods")
local root_definition = require("kubectl.views.definition")
local tables = require("kubectl.utils.tables")
local view = require("kubectl.views")

--- Set key mappings for the buffer
local function set_keymaps(bufnr)
  api.nvim_buf_set_keymap(bufnr, "n", "g?", "", {
    noremap = true,
    silent = true,
    desc = "Help",
    callback = function()
      view.Hints({
        { key = "<gd>", desc = "Describe selected pod" },
        { key = "<gk>", desc = "Kill pod" },
        { key = "<gl>", desc = "Shows logs for all containers in pod" },
        { key = "<gp>", desc = "Port forward" },
        { key = "<gP>", desc = "View active Port forwards" },
        { key = "<gu>", desc = "Show resources used" },
        { key = "<enter>", desc = "Opens container view" },
      })
    end,
  })

  api.nvim_buf_set_keymap(bufnr, "n", "gu", "", {
    noremap = true,
    silent = true,
    desc = "Resources used",
    callback = function()
      pod_view.Top()
    end,
  })

  api.nvim_buf_set_keymap(bufnr, "n", "<bs>", "", {
    noremap = true,
    silent = true,
    desc = "Go up",
    callback = function()
      deployment_view.View()
    end,
  })

  api.nvim_buf_set_keymap(bufnr, "n", "gl", "", {
    noremap = true,
    silent = true,
    desc = "View logs",
    callback = function()
      local name, ns = pod_view.getCurrentSelection()
      if name and ns then
        pod_view.selectPod(name, ns)
        pod_view.Logs()
      else
        api.nvim_err_writeln("Failed to extract pod name or namespace.")
      end
    end,
  })

  api.nvim_buf_set_keymap(bufnr, "n", "<CR>", "", {
    noremap = true,
    silent = true,
    desc = "Select",
    callback = function()
      local name, ns = pod_view.getCurrentSelection()
      if name and ns then
        pod_view.selectPod(name, ns)
        container_view.View(pod_view.selection.pod, pod_view.selection.ns)
      else
        api.nvim_err_writeln("Failed to select pod.")
      end
    end,
  })

  api.nvim_buf_set_keymap(bufnr, "n", "gk", "", {
    noremap = true,
    silent = true,
    desc = "Kill pod",
    callback = function()
      local name, ns = pod_view.getCurrentSelection()

      if name and ns then
        local port_forwards = {}
        root_definition.getPortForwards(port_forwards, false, "pods")
        for _, pf in ipairs(port_forwards) do
          if pf.resource == name then
            vim.notify("Killing port forward for " .. pf.resource)
            commands.shell_command_async("kill", { pf.pid })
          end
        end
        vim.notify("Deleting pod " .. name)
        commands.shell_command_async("kubectl", { "delete", "pod", name, "-n", ns })
        pod_view.View()
      else
        api.nvim_err_writeln("Failed to select pod.")
      end
    end,
  })

  api.nvim_buf_set_keymap(bufnr, "n", "gp", "", {
    noremap = true,
    silent = true,
    desc = "Port forward",
    callback = function()
      local name, ns = pod_view.getCurrentSelection()

      if not ns or not name then
        api.nvim_err_writeln("Failed to select pod for port forward")
        return
      end

      ResourceBuilder:new("pods_pf")
        :setCmd({
          "{{BASE}}/api/v1/namespaces/" .. ns .. "/pods/" .. name .. "?pretty=false",
        }, "curl")
        :fetchAsync(function(self)
          self:decodeJson()
          local data = {}
          for _, container in ipairs(self.data.spec.containers) do
            if container.ports then
              for _, port in ipairs(container.ports) do
                table.insert(data, {
                  name = { value = port.name, symbol = hl.symbols.pending },
                  port = { value = port.containerPort, symbol = hl.symbols.success },
                  protocol = port.protocol,
                })
              end
            end
          end

          vim.schedule(function()
            if next(data) == nil then
              api.nvim_err_writeln("No container ports exposed in pod")
              return
            end
            self.prettyData, self.extmarks = tables.pretty_print(data, { "NAME", "PORT", "PROTOCOL" })

            table.insert(self.prettyData, "")
            table.insert(
              self.prettyData,
              "Container port: " .. (data[1].name.value or "<unset>") .. "::" .. data[1].port.value
            )
            table.insert(self.prettyData, "Local port: " .. data[1].port.value)
            table.insert(self.prettyData, "")

            local max_width = 0
            for _, value in ipairs(self.prettyData) do
              if max_width < #value then
                max_width = #value
              end
            end
            local confirmation = "[y]es [n]o:"
            local padding = string.rep(" ", (max_width - #confirmation) / 2)
            table.insert(self.prettyData, padding .. confirmation)

            buffers.confirmation_buffer("Confirm port forward", "PortForward", function(confirm)
              if confirm then
                local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
                local container_port, local_port

                for _, line in ipairs(lines) do
                  if line:match("Container port:") then
                    container_port = line:match("::(%d+)$")
                  elseif line:match("Local port:") then
                    local_port = line:match("Local port: (.*)")
                  end
                end
                commands.shell_command_async(
                  "kubectl",
                  { "port-forward", "-n", ns, "pods/" .. name, local_port .. ":" .. container_port }
                )

                vim.schedule(function()
                  pod_view.View()
                end)
              end
            end, {
              content = self.prettyData,
              marks = self.extmarks,
              width = max_width,
            })
          end)
        end)
    end,
  })
end

--- Initialize the module
local function init()
  set_keymaps(0)
  if not loop.is_running() then
    loop.start_loop(pod_view.View)
  end
end

init()
