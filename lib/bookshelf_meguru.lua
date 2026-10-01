-- lib/bookshelf_meguru.lua
-- Bridge to the optional meguru.koplugin (OPDS-PSE page streaming). Everything
-- here degrades to "no Meguru": a missing plugin, a disabled one, or one too old
-- to export Open.openStream all answer nil, and callers simply do not offer the
-- feature. Never require() Meguru at module top level -- pluginloader only adds
-- a plugin's directory to package.path once that plugin has loaded, so a
-- top-level require can fail on a build that has it installed.

local M = {}

-- The Open.STREAM_API revision this file was written against. A newer Meguru
-- may change openStream's argument table; refuse it rather than misuse it.
M.WANTED_API = 1

-- api() -> Meguru's `meguru/ui/open` module, or nil.
function M.api()
    local ok, Open = pcall(require, "meguru/ui/open")
    if not ok or type(Open) ~= "table" then return nil end
    if type(Open.openStream) ~= "function" then return nil end
    if Open.STREAM_API ~= M.WANTED_API then return nil end
    return Open
end

-- canStream(book) -> true when this record advertises a page stream AND Meguru
-- can open it. The stream fields come from bookshelf_opds_feed.mapEntries.
function M.canStream(book)
    local opds = book and book.opds
    if type(opds) ~= "table" or type(opds.stream_href) ~= "string"
            or opds.stream_href == "" then
        return false
    end
    return M.api() ~= nil
end

-- open(args) -> true | nil, reason. Straight pass-through to Meguru, pcall'd so
-- a fault inside it can never take the shelf down with it.
function M.open(args)
    local Open = M.api()
    if not Open then return nil, "meguru unavailable" end
    local ok, started, why = pcall(Open.openStream, args)
    if not ok then return nil, tostring(started) end
    return started, why
end

return M
