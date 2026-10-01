-- tests/_test_meguru_ext.lua
-- Meguru stream markers (.meguru) count as shelf books; sidecar files do not.
-- Usage (from plugin root): lua tests/_test_meguru_ext.lua

package.path = "./?.lua;./?/init.lua;" .. package.path

local helpers = dofile("tests/_helpers.lua")
local t       = helpers.runner()
local eq      = helpers.eq

package.loaded["logger"] = { dbg = function() end, info = function() end, warn = function() end, err = function() end }
package.loaded["readhistory"] = { hist = {} }
package.loaded["readcollection"] = { coll = { favorites = {} }, default_collection_name = "favorites" }
package.loaded["bookinfomanager"] = { getBookInfo = function() return nil end }

package.loaded["docsettings"] = { open = function() return {} end }
package.loaded["libs/libkoreader-lfs"] = { attributes = function() end }
package.loaded["ui/data/isolanguage"] = { getLocalizedLanguage = function(_, c) return c end }
package.loaded["lib/bookshelf_settings_store"] = {
    read = function(_, d) return d end, save = function() end, delete = function() end,
    flush = function() end, generation = function() return 1 end,
    isTrue = function() return false end, nilOrTrue = function() return true end,
}
_G.G_reader_settings = setmetatable({}, { __index = function() return nil end })

local Repo = dofile("lib/bookshelf_book_repository.lua")

t.test("a .meguru marker is a shelf book, case-insensitively", function()
    eq(Repo.isBookFile("Now That We Draw - Vol 1.meguru"), true)
    eq(Repo.isBookFile("Chapter 3.MEGURU"), true)
end)

t.test("Meguru's .cover.jpg sidecar is not a book", function()
    eq(Repo.isBookFile(".cover.jpg"), false)
end)

t.test("a bare name containing 'meguru' is not a book", function()
    eq(Repo.isBookFile("meguru"), false)
end)

t.done()
