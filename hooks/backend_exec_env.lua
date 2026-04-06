--- Sets up environment variables for a tool
--- Documentation: https://mise.jdx.dev/backend-plugin-development.html#backendexecenv
--- @param ctx BackendExecEnvCtx
--- @return BackendExecEnvResult
function PLUGIN:BackendExecEnv(ctx)
    local install_path = ctx.install_path
    local file = require("file")
    local tools = require("tools")

    local tool_data = tools.assert_valid_tool(ctx.tool)

    local bin_search_paths = {
        file.join_path(install_path, "bin"),
        install_path
    }

    local binary_name = tool_data.binary_name
    local bin_path
    for _, path in ipairs(bin_search_paths) do
        if
            file.exists(file.join_path(path, binary_name))
            or file.exists(file.join_path(path, binary_name .. ".exe"))
        then
            bin_path = path
            break
        end
    end

    return {
        env_vars = {
            { key = "PATH", value = bin_path },
        },
    }
end
