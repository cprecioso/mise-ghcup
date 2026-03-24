--- Lists available versions for a tool in this backend
--- Documentation: https://mise.jdx.dev/backend-plugin-development.html#backendlistversions
--- @param ctx BackendListVersionsCtx
--- @return BackendListVersionsResult
function PLUGIN:BackendListVersions(ctx)
    local tool = ctx.tool
    if not tool or tool == "" then
        error("Tool name cannot be empty")
    end

    local cmd = require("cmd")
    local strings = require("strings")
    local semver = require("semver")
    local ghcup = require("ghcup")

    local ghcup_bin, ghcup_env = ghcup.find_ghcup()

    -- List available versions
    local output = cmd.exec(
        ghcup_bin .. " list -t " .. tool .. " -r",
        { env = ghcup_env }
    )

    local versions = {}
    for _, line in ipairs(strings.split(output, "\n")) do
        line = strings.trim_space(line)
        if line ~= "" then
            -- ghcup list output has version as the 2nd whitespace-delimited field
            local version = line:match("^%S+%s+(%S+)")
            if version then
                table.insert(versions, version)
            end
        end
    end

    if #versions == 0 then
        error("No versions found for " .. tool)
    end

    versions = semver.sort(versions)

    return { versions = versions }
end
