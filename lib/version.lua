local M = {}

--- Split a version string into its numeric components.
--- The Haskell tools ghcup manages (GHC, cabal, HLS, stack) follow the PVP, so
--- a version is a dot-separated list of non-negative integers with anywhere
--- from 1 to 4 components, e.g. "9", "9.14", "9.14.1", "2.9.0.1".
--- @param version string
--- @return integer[]
local function parse(version)
    local parts = {}
    for component in tostring(version):gmatch("%d+") do
        parts[#parts + 1] = tonumber(component)
    end
    return parts
end

--- Compare two version strings, returning -1, 0, or 1 (a < b, a == b, a > b).
--- The built-in semver.compare assumes the 3-component MAJOR.MINOR.PATCH shape
--- and mis-sorts the 1-to-4-component versions these tools use, so we compare
--- component by component ourselves, treating any missing trailing component as
--- 0 (so "9.14" == "9.14.0").
--- @param a string
--- @param b string
--- @return integer
function M.compare(a, b)
    local pa = parse(a)
    local pb = parse(b)

    local n = math.max(#pa, #pb)
    for i = 1, n do
        local na = pa[i] or 0
        local nb = pb[i] or 0
        if na ~= nb then
            return na < nb and -1 or 1
        end
    end

    return 0
end

--- Sort version strings ascending (oldest -> newest), as mise expects.
--- Returns a new sorted list and leaves the input untouched.
--- @param versions string[]
--- @return string[]
function M.sort(versions)
    local sorted = {}
    for i, v in ipairs(versions) do
        sorted[i] = v
    end
    table.sort(sorted, function(a, b)
        return M.compare(a, b) < 0
    end)
    return sorted
end

return M
