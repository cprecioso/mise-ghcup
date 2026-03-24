--- Sets up environment variables for a tool
--- Documentation: https://mise.jdx.dev/backend-plugin-development.html#backendexecenv
--- @param ctx BackendExecEnvCtx
--- @return BackendExecEnvResult
function PLUGIN:BackendExecEnv(ctx)
    local install_path = ctx.install_path
    local file = require("file")

    local bin_path
    if
        ctx.tool == "cabal"
        or ctx.tool == "stack"
        or (ctx.tool == "hls" and RUNTIME.osType == "windows")
    then
        bin_path = install_path
    else
        bin_path = file.join_path(install_path, "bin")
    end

    return {
        env_vars = {
            { key = "PATH", value = bin_path },
        },
    }
end
