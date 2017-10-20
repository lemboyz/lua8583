local M = {}

--local cjson = require("cjson")
local time = require("time")

local function echoColor(num, str)
    -- 30 black
    -- 31 red
    -- 32 green
    -- 33 yellow
    -- 34 blue
    -- 35 purple
    -- 36 light blue
    -- other: white 
    io.write('\27[' .. num .. 'm' .. str .. '\27[m')
end

local function echoRed(str)
    echoColor(31, str)
end

local function echoGreen(str)
    echoColor(32, str)
end

function M.decodeURI(s)
    s = string.gsub(s, '%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)
    return s
end

function M.encodeURI(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end

function M.popenRun(cmd)
    local t = io.popen(cmd)
    local ret = t:read("*all");
    t:close()
    return ret;
end

function M.trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

--[[
local function removeWhitespace(str)
        if not str then
                return str
        end

        local ret = "";
        for i=1,#str do
                if string.sub(str, i, i) ~= " " then
                        ret = ret .. string.sub(str, i, i)
                end
        end

        return ret
end
--]]

function M.curl(ipport, uri, postdata, timeout)
        timeout = timeout or 5
        local url = string.format("http://%s/%s",ipport, uri)
        local cmd = string.format("curl -m %d -s -d '%s' '%s'", timeout, postdata, url)
        print(cmd)
        local ret = M.popenRun(cmd)
        ret = M.decodeURI(ret)
        --ret = removeWhitespace(ret)
        print(ret)
        return ret
end

function M.curl_https(ipport, uri, postdata, timeout)
        timeout = timeout or 5
        local url = string.format("https://%s/%s", ipport, uri)
        local cmd = string.format("curl -k -m %d -s -d '%s' '%s'", timeout, postdata, url)
        print(cmd)
        local ret = M.popenRun(cmd)
        ret = M.decodeURI(ret)
        print(ret)
        return ret
end

function M.EXPECT_TRUE(value)
        if value == true then
                echoGreen("[ TEST OK   ]")
        else
                echoRed  ("[ TEST FAIL ]")
        end
end

function M.TEST(func, funcname)
        local tv1 = time.gettimeofday()

        func()
        local tv2 = time.gettimeofday()

        local interval = (tv2.sec - tv1.sec) + (tv2.usec - tv1.usec)/1000000

        print(string.format(" %s() ( %0.3fs )\n", tostring(funcname), interval))
end

-- run all test_xxx function 
function M.run()
        for k,v in pairs(M) do
                if type(v) == "function" and tostring(k):sub(1,5)=="test_" then
                        --print(k, " - ", v)
                        M.TEST(v, tostring(k))
                end
        end
end

return M
