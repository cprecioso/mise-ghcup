--- Lists available versions for a tool in this backend
--- Documentation: https://mise.jdx.dev/backend-plugin-development.html#backendlistversions
--- @param ctx BackendListVersionsCtx
--- @return BackendListVersionsResult
function PLUGIN:BackendListVersions(ctx)
    local ghcup = require("ghcup")
    local semver = require("semver")
    local strings = require("strings")
    local tools = require("tools")

    local tool = ctx.tool

    local tool_data = tools.assert_valid_tool(tool)
    ghcup.assert_installed()

    -- List available versions
    local output = ghcup.call(
        "list -t " .. tool_data.ghcup_id .. " -r"
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
