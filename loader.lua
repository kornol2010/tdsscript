-- ==================== LOADER Z DIAGNOSTYKĄ BŁĘDU ====================
local API_BASE_URL = "https://tds-key-backend.onrender.com"
local LICENSE_KEY = "TDS-A5730BFB-6168"   -- Twój klucz
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

if not verifyKey(LICENSE_KEY) then
    error("Invalid key")
end

writefile(KEY_FILE, HttpService:JSONEncode({key = LICENSE_KEY}))

local scriptContent = fetchScript(LICENSE_KEY)

-- Diagnostyka: próba załadowania z pcall i wypisanie błędu
local chunk, err = loadstring(scriptContent)
if not chunk then
    error("Błąd składni w tds.lua: " .. err)
end

-- Opakowujemy wykonanie w pcall, aby przechwycić błąd runtime
local success, result = pcall(chunk)
if not success then
    local errorMsg = tostring(result)
    -- Próba wyciągnięcia numeru linii z komunikatu błędu
    local line = errorMsg:match(":(%d+):")
    print("❌ BŁĄD WYKONANIA tds.lua:")
    print(errorMsg)
    if line then
        print("➡ Linia: " .. line)
        -- Pobierz tę linię z kodu dla kontekstu
        local lines = {}
        for s in scriptContent:gmatch("([^\n]*)\n?") do
            table.insert(lines, s)
        end
        local ctxStart = math.max(1, tonumber(line) - 2)
        local ctxEnd = math.min(#lines, tonumber(line) + 2)
        print("📄 Kontekst:")
        for i = ctxStart, ctxEnd do
            local prefix = (i == tonumber(line)) and ">>> " or "    "
            print(prefix .. i .. ": " .. lines[i])
        end
    end
else
    print("✅ Skrypt uruchomiony pomyślnie!")
end
