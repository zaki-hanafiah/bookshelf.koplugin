-- tests/_test_meguru_bridge.lua
-- lib/bookshelf_meguru: the optional-dependency gate for "Read in Meguru".
-- Usage (from plugin root): luajit tests/_test_meguru_bridge.lua

package.path = "./?.lua;./?/init.lua;" .. package.path

local helpers = dofile("tests/_helpers.lua")
local t       = helpers.runner()
local eq      = helpers.eq

local Bridge = dofile("lib/bookshelf_meguru.lua")
local STREAM_BOOK = { opds = { stream_href = "http://h/p/{pageNumber}" } }

local function withMeguru(mod, fn)
    local prev = package.loaded["meguru/ui/open"]
    package.loaded["meguru/ui/open"] = mod
    local ok, err = pcall(fn)
    package.loaded["meguru/ui/open"] = prev
    if not ok then error(err, 0) end
end

t.test("no Meguru installed: nothing is offered", function()
    package.loaded["meguru/ui/open"] = nil
    eq(Bridge.api(), nil)
    eq(Bridge.canStream(STREAM_BOOK), false)
    local started, why = Bridge.open({})
    eq(started, nil); eq(why, "meguru unavailable")
end)

t.test("a Meguru without openStream (upstream) is treated as absent", function()
    withMeguru({ STREAM_API = nil }, function()
        eq(Bridge.canStream(STREAM_BOOK), false)
    end)
end)

t.test("a Meguru speaking a different API revision is refused", function()
    withMeguru({ openStream = function() return true end, STREAM_API = 2 }, function()
        eq(Bridge.canStream(STREAM_BOOK), false)
    end)
end)

t.test("matching Meguru + stream record: offered", function()
    withMeguru({ openStream = function() return true end, STREAM_API = 1 }, function()
        eq(Bridge.canStream(STREAM_BOOK), true)
    end)
end)

t.test("matching Meguru but a plain download record: not offered", function()
    withMeguru({ openStream = function() return true end, STREAM_API = 1 }, function()
        eq(Bridge.canStream({ opds = {} }), false)
        eq(Bridge.canStream({}), false)
        eq(Bridge.canStream(nil), false)
    end)
end)

t.test("open passes the args through and returns Meguru's answer", function()
    local seen
    withMeguru({ STREAM_API = 1, openStream = function(a) seen = a; return true end }, function()
        eq(Bridge.open({ server_name = "S" }), true)
        eq(seen.server_name, "S")
    end)
end)

t.test("open contains a throw inside Meguru", function()
    withMeguru({ STREAM_API = 1, openStream = function() error("boom") end }, function()
        local started, why = Bridge.open({})
        eq(started, nil)
        eq(why:find("boom", 1, true) ~= nil, true)
    end)
end)

-- ── default-tap opt-in ─────────────────────────────────────────────────────
local function withSetting(on, fn)
    local prev = package.loaded["lib/bookshelf_settings_store"]
    package.loaded["lib/bookshelf_settings_store"] = {
        isTrue = function(k) return on and k == "meguru_default_tap" end,
    }
    local ok, err = pcall(fn)
    package.loaded["lib/bookshelf_settings_store"] = prev
    if not ok then error(err, 0) end
end
local FULL = { STREAM_API = 1, openStream = function() return true end }

t.test("default tap is off unless the user turned it on", function()
    withMeguru(FULL, function()
        withSetting(false, function()
            eq(Bridge.opensRemoteDirectly(STREAM_BOOK), false)
            eq(Bridge.providerFor("/b/x.cbz"), nil)
        end)
    end)
end)

t.test("default tap on: streamable record opens directly, plain one does not", function()
    withMeguru(FULL, function()
        withSetting(true, function()
            eq(Bridge.opensRemoteDirectly(STREAM_BOOK), true)
            eq(Bridge.opensRemoteDirectly({ opds = {} }), false)
        end)
    end)
end)

t.test("default tap on but Meguru gone: nothing is redirected", function()
    package.loaded["meguru/ui/open"] = nil
    withSetting(true, function()
        eq(Bridge.opensRemoteDirectly(STREAM_BOOK), false)
        eq(Bridge.providerFor("/b/x.cbz"), nil)
    end)
end)

t.test("providerFor forces Meguru's provider for .cbz only", function()
    local prov = { name = "meguru-provider" }
    local prevA = package.loaded["meguru/association"]
    package.loaded["meguru/association"] = { provider = function() return prov end }
    withMeguru(FULL, function()
        withSetting(true, function()
            eq(Bridge.providerFor("/b/Vol 1.CBZ"), prov)
            eq(Bridge.providerFor("/b/book.epub"), nil)
            eq(Bridge.providerFor("/b/x.cbz.txt"), nil)
            eq(Bridge.providerFor(nil), nil)
        end)
    end)
    package.loaded["meguru/association"] = prevA
end)

t.done()
