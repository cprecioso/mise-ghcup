local M = {}

--- @class ToolData
--- @field ghcup_id string The identifier for the tool used by ghcup (e.g "ghc", "cabal", etc)
--- @field binary_name string The name of the tool's main binary (e.g "ghc", "cabal", etc)

---@type table<string, ToolData>
local tools = {
    cabal = { ghcup_id = "cabal", binary_name = "cabal" },
    ghc = { ghcup_id = "ghc", binary_name = "ghc" },
    hls = { ghcup_id = "hls", binary_name = "haskell-language-server-wrapper" },
    stack = { ghcup_id = "stack", binary_name = "stack" },
}

--- Asserts that a tool is valid (exists in the tools table).
--- @param tool string
--- @return ToolData
M.assert_valid_tool = function(tool)
    local tool_data = tools[tool]
    if not tool_data then
        error("Tool '" .. tool .. "' not recognized")
    end
    return tool_data
end

return M
