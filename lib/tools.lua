---@type table<string, {ghcup_id: string, binary_name: string}>
local tools = {
  cabal = { ghcup_id = "cabal", binary_name = "cabal" },
  ghc = { ghcup_id = "ghc", binary_name = "ghc" },
  hls = { ghcup_id = "hls", binary_name = "haskell-language-server-wrapper" },
  stack = { ghcup_id = "stack", binary_name = "stack" },
}

return tools
