-- Minimalny loader – zapisuje klucz i uruchamia tds.lua z API
local API_BASE_URL = "https://tds-key-backend.onrender.com"  -- Zmień na swój adres
local LICENSE_KEY = "TDS-A5730BFB-6168"                      -- <-- Twój klucz testowy
local KEY_FILE = "key.json"

local HttpService = game:GetService("HttpService")

local function getHWID()
    local s, r = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    if s and r and r ~= "" then return r end
    return tostring(math.floor(tonumber(tostring({}):match("0x(%x+)")) or 0))
end

local function verifyKey(key)
    local hwid = getHWID()
    local url = API_BASE_URL .. "/api/verify?key=" .. HttpService:UrlEncode(key) .. "&hwid=" .. HttpService:UrlEncode(hwid)
    local s, r = pcall(function() return game:HttpGet(url) end)
    if not s then return false end
    local data = HttpService:JSONDecode(r)
    return data.success == true
end

local function fetchScript(key)
    local hwid = getHWID()
    local url = API_BASE_URL .. "/api/get-script?key=" .. HttpService:UrlEncode(key)
                .. "&hwid=" .. HttpService:UrlEncode(hwid) .. "&script=tds.lua"
    local s, r = pcall(function() return game:HttpGet(url) end)
    if not s then error("Failed to fetch script") end
    if r:sub(1,1) == "{" then error("Server error: " .. r) end
    return r
end

-- Sprawdź klucz
if not verifyKey(LICENSE_KEY) then
    error("Invalid key")
end

-- Zapisz klucz do pliku (dla tds.lua)
writefile(KEY_FILE, HttpService:JSONEncode({key = LICENSE_KEY}))

-- Pobierz i uruchom główny skrypt
loadstring(fetchScript(LICENSE_KEY))()
