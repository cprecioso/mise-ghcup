--- Lists available versions for a tool in this backend
--- Documentation: https://mise.jdx.dev/backend-plugin-development.html#backendlistversions
--- @param ctx BackendListVersionsCtx
--- @return BackendListVersionsResult
function PLUGIN:BackendListVersions(ctx)
    local ghcup = require("ghcup")
    local version = require("version")
    local strings = require("strings")
    local tools = require("tools")

    local tool = ctx.tool

    local tool_data = tools.assert_valid_tool(tool)
    ghcup.assert_installed(tool_data.ghcup_id)

    -- List available versions
    local output = ghcup.call(tool_data.ghcup_id, "list -t " .. tool_data.ghcup_id .. " -r")

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

    -- Sort ascending (oldest -> newest), as mise expects. We use our own
    -- version comparison because the built-in semver.sort assumes 3-component
    -- versions and mis-orders the 1-to-4-component (PVP) versions these tools use.
    versions = version.sort(versions)

    return { versions = versions }
end
