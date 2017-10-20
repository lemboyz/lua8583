local _M = {}

local function bcdunzip(str)
    return ({str:gsub(".", function(c) return string.format("%02X", c:byte(1)) end)})[1]
end

local function bcdzip(str)
    return ({str:gsub("..", function(x) return string.char(tonumber(x, 16)) end)})[1]
end

local MSG_TYPE = 0
local BITMAP = 1

local TYPE   = 1
local LEN    = 2
local ALIGN  = 3
local PADDING= 4
local ZIP    = 5

local _fields = {
 --  idx: 索引
 --  type: 字段类型
 --  len: 长度
 --  align: 对齐方式
 --  padding: 填充字符
 --  zip: 是否bcd压缩

 --  idx      type     len align padding zip
    [0  ] = {"fix"   ,   4, 'R', '0', 'Z'},   -- Message Type           n      4
    [1  ] = {"fix"   ,   1, 'L', 'D', 'U'},   -- BIT MAP EXTENDED       b      1
    [2  ] = {"llvar" ,  19, 'L', 'F', 'Z'},   -- PRIMARY ACC. NUM       n     19 llvar
    [3  ] = {"fix"   ,   6, 'R', '0', 'Z'},   -- PROCESSING CODE        n      6
    [4  ] = {"fix"   ,  12, 'R', '0', 'Z'},   -- AMOUNT, TRANS.         n     12
    [5  ] = {"fix"   ,  12, 'R', '0', 'Z'},   -- AMOUNT, SETTLEMENT     n     12
    [6  ] = {"fix"   ,  12, 'R', '0', 'Z'},   -- AMOUNT,CardHolder bill n     12
    [7  ] = {"fix"   ,  10, 'R', '0', 'Z'},   -- TRANSMISSION D & T     n     10 mmddhhmmss
    [8  ] = {"fix"   ,   8, 'R', '0', 'Z'},   -- AMN., CH BILLING FEE   n      8
    [9  ] = {"fix"   ,   8, 'R', '0', 'Z'},   -- CONV RATE,SET'T        n      8
    [10 ] = {"fix"   ,   8, 'R', '0', 'Z'},   -- CONV RATE, CH billing  n      8
    [11 ] = {"fix"   ,   6, 'R', '0', 'Z'},   -- SYSTEM TRACE #         n      6
    [12 ] = {"fix"   ,   6, 'R', '0', 'Z'},   -- TIME, LOCAL TRAN       n      6 hhmmss
    [13 ] = {"fix"   ,   4, 'R', '0', 'Z'},   -- DATE, LOCAL TRAN       n      4 mmdd
    [14 ] = {"fix"   ,   4, 'R', '0', 'Z'},   -- DATE, EXPIRATION       n      4 yymm
    [15 ] = {"fix"   ,   4, 'R', '0', 'Z'},   -- DATE, SETTLEMENT       n      4 mmdd
    [16 ] = {"fix"   ,   4, 'R', '0', 'Z'},   -- DATE, CONVERSION       n      4 mmdd
    [17 ] = {"fix"   ,   4, 'R', '0', 'Z'},   -- DATE, CAPTURE          n      4 mmdd
    [18 ] = {"fix"   ,   4, 'R', '0', 'Z'},   -- MERCHANT'S TYPE        n      4
    [19 ] = {"fix"   ,   3, 'R', '0', 'Z'},   -- AI COUNTRY CODE        n      3
    [20 ] = {"fix"   ,   3, 'L', 'F', 'Z'},   -- PAN EXT.,CO'Y CODE     n      3
    [21 ] = {"fix"   ,   3, 'R', '0', 'Z'},   -- FI COUNTRY CODE        n      3
    [22 ] = {"fix"   ,   3, 'L', 'D', 'Z'},   -- POS ENTRY MODE         n      3
--  [23 ] = {"fix"   ,   3, 'L', 'F', 'Z'},   -- CARD SEQUECE NUM.      n      3
    [23 ] = {"fix"   ,   3, 'R', '0', 'Z'},   -- CARD SEQUECE NUM.      n      3
    [24 ] = {"fix"   ,   3, 'L', 'D', 'Z'},   -- NETWORK INT'L ID       n      3
    [25 ] = {"fix"   ,   2, 'R', 'D', 'Z'},   -- POS COND. CODE         n      2
    [26 ] = {"fix"   ,   2, 'L', 'D', 'Z'},   -- POS PIN CAP. CODE      n      2
    [27 ] = {"fix"   ,   1, 'R', '0', 'Z'},   -- AUTH ID RES. LEN       n      1
    [28 ] = {"fix"   ,   8, 'R', '0', 'Z'},   -- AMT. TRANS FEE         n      8
    [29 ] = {"fix"   ,   8, 'R', '0', 'Z'},   -- AMT. SETT.  FEE        n      8
    [30 ] = {"fix"   ,   8, 'R', '0', 'Z'},   -- AMT. TRAN PROC FEE     n      8
    [31 ] = {"fix"   ,   8, 'R', '0', 'Z'},   -- AMT. SET PROC FEE      n      8
    [32 ] = {"llvar" ,  11, 'L', '0', 'Z'},   -- ACOUIR. INST. ID       n     11 llvar
    [33 ] = {"llvar" ,  11, 'L', 'F', 'Z'},   -- FI ID                  n     11 llvar
    [34 ] = {"llvar" ,  11, 'L', 'F', 'Z'},   -- PAN EXTENDED           n     28 llvar
    [35 ] = {"llvar" ,  37, 'L', 'F', 'Z'},   -- TRACK 2 DATA           z     37 llvar
    [36 ] = {"lllvar", 104, 'L', 'F', 'Z'},   -- TRACK 3 DATA           z    104 lllvar
    [37 ] = {"fix"   ,  12, 'L', 'D', 'U'},   -- RETR. REF. NUM         an    12
    [38 ] = {"fix"   ,   6, 'R', 'D', 'U'},   -- AUTH. ID. RESP         an     6
    [39 ] = {"fix"   ,   2, 'R', 'D', 'U'},   -- RESPONSE CODE          an     2
    [40 ] = {"fix"   ,   3, 'L', 'D', 'U'},   -- SERV. REST'N CODE      an     3
    [41 ] = {"fix"   ,   8, 'R', 'D', 'U'},   -- TERMINAL ID            ans    8
    [42 ] = {"fix"   ,  15, 'L', 'F', 'U'},   -- CARD ACC. ID           ans   15
    [43 ] = {"fix"   ,  40, 'L', ' ', 'U'},   -- CARD ACC. NAME         ans   40
    [44 ] = {"llvar" ,  25, 'R', '0', 'U'},   -- ADD. RESP DATA         an    25 llvar
    [45 ] = {"llvar" ,  76, 'L', 'F', 'U'},   -- TRACK 1 DATA           an    76 llvar
    [46 ] = {"lllvar", 999, 'L', 'F', 'U'},   -- ADD. DATA - ISO        an   999 lllvar
    [47 ] = {"lllvar", 999, 'L', 'F', 'U'},   -- ADD. DATA - NATI.      an   999 lllvar
--  [48 ] = {"lllvar", 999, 'L', 'F', 'U'},   -- ADD. DATA - PRI.       an   999 lllvar
    [48 ] = {"lllvar", 999, 'L', 'F', 'Z'},   -- ADD. DATA - PRI.       an   999 lllvar
    [49 ] = {"fix"   ,   3, 'L', ' ', 'U'},   -- CC, TRANSACTION        a      3
    [50 ] = {"fix"   ,   3, 'L', '0', 'U'},   -- CC, SETTLEMENT         an     3
    [51 ] = {"fix"   ,   3, 'L', '0', 'U'},   -- CC, CH. BILLING        a      3
    [52 ] = {"fix"   ,   8, 'R', 'D', 'U'},   -- PIN DATA               b      8
    [53 ] = {"fix"   ,  16, 'L', '0', 'Z'},   -- SECU. CONT. INFO.      n     16
    [54 ] = {"lllvar", 120, 'R', 'F', 'U'},   -- ADDITIONAL AMTS        an   120 LLLVAR
    [55 ] = {"lllvar", 999, 'L', 'F', 'U'},   -- REVERVED ISO           ans  999 lllvar
    [56 ] = {"lllvar", 999, 'L', 'F', 'U'},   -- REVERVED ISO           ans  999 lllvar
    [57 ] = {"lllvar", 999, 'L', 'F', 'U'},   -- REVERVED NATIONAL      ans  999 lllvar
    [58 ] = {"lllvar", 999, 'L', 'F', 'U'},   -- REVERVED NATIONAL      ans  999 lllvar
    [59 ] = {"lllvar", 999, 'L', 'F', 'U'},   -- REVERVED NATIONAL      ans  999 lllvar
    [60 ] = {"lllvar", 999, 'L', 'F', 'Z'},   -- RESERVED - PRIV1       ans  999 lllvar
--  [61 ] = {"lllvar", 999, 'L', 'F', 'U'},   -- RESERVED - PRIV2       ans  999 lllvar
    [61 ] = {"lllvar", 999, 'L', 'F', 'Z'},   -- RESERVED - PRIV2       ans  999 lllvar
    [62 ] = {"lllvar", 999, 'L', 'F', 'U'},   -- RESERVED - PRIV3       ans  999 lllvar
    [63 ] = {"lllvar", 999, 'L', 'F', 'U'},   -- RESERVED - PRIV4       ans  999 lllvar
    [64 ] = {"fix"   ,   8, 'L', 'D', 'U'},   -- MSG. AUTH. CODE        b      8

    [65 ] = {"fix"   ,   8, 'L', 'D', 'U'},   -- BIT MAP, EXTENDED      b      8
    [66 ] = {"fix"   ,   1, 'L', 'D', 'U'},   -- SETTLEMENT CODE        n      1
    [67 ] = {"fix"   ,   2, 'L', 'D', 'U'},   -- EXT. PAYMENT CODE      n      2
    [68 ] = {"fix"   ,   3, 'L', 'D', 'U'},   -- RECE. INST. CN.        n      3
    [69 ] = {"fix"   ,   3, 'L', 'D', 'U'},   -- SETTLEMENT ICN.        n      3
    [70 ] = {"fix"   ,   3, 'L', 'D', 'U'},   -- NET MAN IC             n      3
    [71 ] = {"fix"   ,   4, 'L', 'D', 'U'},   -- MESSAGE NUMBER         n      4
    [72 ] = {"fix"   ,   4, 'L', 'D', 'U'},   -- MESSAGE NUM. LAST      n      4
    [73 ] = {"fix"   ,   6, 'L', 'D', 'U'},   -- DATE, ACTION           n      6 yymmdd
    [74 ] = {"fix"   ,  10, 'L', 'D', 'U'},   -- CREDIT NUMBER          n     10
    [75 ] = {"fix"   ,  10, 'L', 'D', 'U'},   -- CRED REVERSAL NUM      n     10
    [76 ] = {"fix"   ,  10, 'L', 'D', 'U'},   -- DEBITS NUMBER          n     10
    [77 ] = {"fix"   ,  10, 'L', 'D', 'U'},   -- DEBT REVERSAL NUM      n     10
    [78 ] = {"fix"   ,  10, 'L', 'D', 'U'},   -- TRANSFER NUMBER        n     10
    [79 ] = {"fix"   ,  10, 'L', 'D', 'U'},   -- TRANS REVERSAL NUM     n     10
    [80 ] = {"fix"   ,  10, 'L', 'D', 'U'},   -- INQUERIES NUMBER       n     10
    [81 ] = {"fix"   ,  10, 'L', 'D', 'U'},   -- AUTHORIZE NUMBER       n     10
    [82 ] = {"fix"   ,  12, 'L', 'D', 'U'},   -- CRED.PROC.FEE.AMT      n     12
    [83 ] = {"fix"   ,  12, 'L', 'D', 'U'},   -- CRED.TRANS.FEE.AMT     n     12
    [84 ] = {"fix"   ,  12, 'L', 'D', 'U'},   -- DEBT.PROC.FEE.AMT      n     12
    [85 ] = {"fix"   ,  12, 'L', 'D', 'U'},   -- DEBT.TRANS.FEE.AMT     n     12
    [86 ] = {"fix"   ,  15, 'L', 'D', 'U'},   -- CRED AMT               n     16
    [87 ] = {"fix"   ,  15, 'L', 'D', 'U'},   -- CRED REVERSAL AMT      n     16
    [88 ] = {"fix"   ,  15, 'L', 'D', 'U'},   -- DEBIT AMT              n     16
    [89 ] = {"fix"   ,  15, 'L', 'D', 'U'},   -- DEBIT REVERSAL AMT     n     16
    [90 ] = {"fix"   ,  42, 'L', '0', 'U'},   -- ORIGIN DATA ELEMNT     n     42
    [91 ] = {"fix"   ,   1, 'L', 'D', 'U'},   -- FILE UPDATE CODE       an     1
    [92 ] = {"fix"   ,   2, 'L', 'D', 'U'},   -- FILE SECURITY CODE     n      2
    [93 ] = {"fix"   ,   5, 'L', 'D', 'U'},   -- RESPONSE INDICATOR     n      5
    [94 ] = {"fix"   ,   7, 'L', 'D', 'U'},   -- SERVICE INDICATOR      an     7
    [95 ] = {"fix"   ,  42, 'L', 'D', 'U'},   -- REPLACEMENT AMOUNT     an    42
    [96 ] = {"fix"   ,   8, 'L', 'D', 'U'},   -- MESSAGE SECUR CODE     an     8
    [97 ] = {"fix"   ,  16, 'L', 'D', 'U'},   -- AMT.NET SETTLEMENT     n     16
    [98 ] = {"fix"   ,  25, 'L', 'D', 'U'},   -- PAYEE                  ans   25
    [99 ] = {"llvar" ,  11, 'L', 'D', 'U'},   -- SETTLE.INST.IC         n     11 llvar
    [100] = {"llvar" ,  11, 'L', 'D', 'U'},   -- RECE.INST.IC           n     11 llvar
    [101] = {"fix"   ,  17, 'L', 'D', 'U'},   -- FILE NAME              ans   17
    [102] = {"llvar" ,  28, 'L', 'D', 'U'},   -- ACCOUNT ID 1           ans   28 llvar
    [103] = {"llvar" ,  28, 'L', 'D', 'U'},   -- ACCOUNT ID 2           ans   28 llvar
    [104] = {"lllvar", 100, 'L', 'D', 'U'},   -- TRANS.DESCRIPTION      ans  100 lllvar
    [105] = {"lllvar", 999, 'L', 'D', 'U'},   -- RESERVED FOR ISO       ans  999 lllvar
    [106] = {"lllvar", 999, 'L', 'D', 'U'},   -- RESERVED FOR ISO       ans  999 lllvar
    [107] = {"lllvar", 999, 'L', 'D', 'U'},   -- RESERVED FOR ISO       ans  999 lllvar
    [108] = {"lllvar", 999, 'L', 'D', 'U'},   -- RESERVED FOR ISO       ans  999 lllvar
    [109] = {"lllvar", 999, 'L', 'D', 'U'},   -- RESERVED FOR ISO       ans  999 lllvar
    [110] = {"lllvar", 999, 'L', 'D', 'U'},   -- RESERVED FOR ISO       ans  999 lllvar
    [111] = {"lllvar", 999, 'L', 'D', 'U'},   -- RESERVED FOR ISO       ans  999 lllvar
    [112] = {"lllvar", 999, 'L', 'D', 'U'},   -- RESERVED FOR NATIO     ans  999 lllvar
    [113] = {"lllvar", 999, 'L', 'D', 'U'},   -- RESERVED FOR NATIO     ans  999 lllvar
    [114] = {"lllvar", 999, 'L', 'D', 'U'},   -- RESERVED FOR NATIO     ans  999 lllvar
    [115] = {"lllvar", 999, 'L', 'D', 'U'},   -- RESERVED FOR NATIO     ans  999 lllvar
    [116] = {"lllvar", 999, 'L', 'D', 'U'},   -- RESERVED FOR NATIO     ans  999 lllvar
    [117] = {"lllvar", 999, 'L', 'D', 'U'},   -- RESERVED FOR NATIO     ans  999 lllvar
    [118] = {"lllvar", 999, 'L', 'D', 'U'},   -- RESERVED FOR NATIO     ans  999 lllvar
    [119] = {"lllvar", 999, 'L', 'D', 'U'},   -- RESERVED FOR NATIO     ans  999 lllvar
    [120] = {"lllvar", 999, 'L', 'D', 'U'},   -- RESERVED FOR PRIVA     ans  999 lllvar
    [121] = {"lllvar", 999, 'L', 'D', 'U'},   -- RESERVED FOR PRIVA     ans  999 lllvar
    [122] = {"lllvar", 999, 'L', 'D', 'U'},   -- RESERVED FOR PRIVA     ans  999 lllvar
    [123] = {"lllvar", 999, 'L', 'D', 'U'},   -- RESERVED FOR PRIVA     ans  999 lllvar
    [124] = {"lllvar", 999, 'L', 'D', 'U'},   -- RESERVED FOR PRIVA     ans  999 lllvar
    [125] = {"lllvar", 999, 'L', 'D', 'U'},   -- RESERVED FOR PRIVA     ans  999 lllvar
    [126] = {"lllvar", 999, 'L', 'D', 'U'},   -- RESERVED FOR PRIVA     ans  999 lllvar
    [127] = {"lllvar", 999, 'L', 'D', 'U'},   -- RESERVED FOR PRIVA     ans  999 lllvar
    [128] = {"fix"   ,   8, 'L', 'D', 'U'},   -- MESS AUTHEN.CODE       b      8
}

-- 返回长度前缀
local function prefix(field_type, value)
    if not value or value=="" then
        return ""
    end

    local str = ""
    if field_type == "fix" then
        str = ""
    elseif field_type == "lllvar" then
        str = tostring(string.len(value))
        if #str < 3 then -- 不足三位数, 要在左边补0
            local padding = string.rep("0", 3 - #str)
            str = padding .. str
        end
    elseif field_type == "llvar" then
        str = tostring(#value)
        if #str < 2 then
            local padding = string.rep("0", 2 - #str)
            str = padding .. str
        end
    end

    return str
end

local function prefix64(field_type, value)
    if not value or value=="" then
        return ""
    end

    local str = ""
    if field_type == "fix" then
        str = ""
    elseif field_type == "lllvar" then
        str = tostring(string.len(value))
        if #str < 4 then
            local padding = string.rep("0", 4 - #str)
            str = padding .. str
        end
    elseif field_type == "llvar" then
        str = tostring(#value)
        if #str < 2 then
            local padding = string.rep("0", 2 - #str)
            str = padding .. str
        end
    end
    str = bcdzip(str)

    return str
end

function _M.set_field(idx, field_type, field_len, align_type, padding, zip_flag)
    _fields[idx] = {field_type, field_len, align_type, padding, zip_flag}
end

local function change_value_by_field(idx, value)
    if not value or #value==0 then
        return ""
    end
    local val = value
    local field_type = _fields[idx][TYPE]
    local len        = _fields[idx][LEN]
    local align      = _fields[idx][ALIGN]
    local padding    = _fields[idx][PADDING]
    --local zip        = _fields[idx][ZIP]

    if #val > len then
        val = string.sub(val, 1, len)
    end

    if field_type == "fix" then
        local padding_str = string.rep(padding, len - #val)
        if align == "L" then
            val = val .. padding_str
        else
            val = padding_str .. val
        end
    end

    --if idx == 35 or idx == 36 then -- f35:track2  f36:track3
    --    val = string.gsub(val, "D", "=")
    --end

    return val
end


-- len must be 64 or 128
local function create_bitmap(len)
    local bitmap = {}
    for i=1,len do
        table.insert(bitmap, 0)
    end
    return bitmap
end

local function pack_bitmap(tab_bitmap)
    -- tab_bitmap = {0,0,0,0,0,0,0,1, ...}
    local bitmap = ""
    local str_binary = table.concat(tab_bitmap, "")
    --print("str_binary: ["..str_binary.."]")
    local count = #str_binary / 8
    for i=1, count do
        local p = (i-1)*8 + 1
        local str8 = string.sub(str_binary, p, p+7)
        local ch = string.char(tonumber(str8, 2))
        bitmap = bitmap .. ch
    end
    return bitmap
end

local function show_bitmap(table_bitmap)
    local str = ""
    for i=1,#table_bitmap do
        str = str .. table_bitmap[i]
        if math.mod(i, 8) == 0 and i~=#table_bitmap then
            str = str .. " "
        end
    end
    io.write(str)
end

local hex_tab = {
    ["0"] = {0,0,0,0},
    ["1"] = {0,0,0,1},
    ["2"] = {0,0,1,0},
    ["3"] = {0,0,1,1},
    ["4"] = {0,1,0,0},
    ["5"] = {0,1,0,1},
    ["6"] = {0,1,1,0},
    ["7"] = {0,1,1,1},
    ["8"] = {1,0,0,0},
    ["9"] = {1,0,0,1},
    ["A"] = {1,0,1,0},
    ["B"] = {1,0,1,1},
    ["C"] = {1,1,0,0},
    ["D"] = {1,1,0,1},
    ["E"] = {1,1,1,0},
    ["F"] = {1,1,1,1},
}
local function hex_to_binary(ch)
    -- ch: a single char in 0123456789ABCDEF
    return hex_tab[ch]
end

local function unpack_bitmap(str_bitmap)
    local bitmap = {}
    local str = bcdunzip(str_bitmap)
    for i=1,#str do
        local ch = str:sub(i,i)
        local binary = hex_to_binary(ch)
        table.insert(bitmap, binary[1])
        table.insert(bitmap, binary[2])
        table.insert(bitmap, binary[3])
        table.insert(bitmap, binary[4])
    end
    return bitmap
end

function _M.show8583(tab8583)
    if tab8583[MSG_TYPE] then
        print("F0: ["..tab8583[0].."]")
    end
    local bitmap = tab8583[BITMAP]
    if bitmap then
        io.write("F1: ["); show_bitmap(bitmap); print("]")
    end

    for i=2, #bitmap do
        if bitmap[i] == 1 then
            if i == 52 then
                print("F52: [" .. bcdunzip(tab8583[i]) .. "] unzipped")
            else
                print("F"..i..": [" ..tostring(tab8583[i]).."]")
            end
        end
    end
end

-- 把table中所有值打包为8583包字符串
-- 128个域
-- tab8583 = {
-- [0] = "0200",
-- [2] = "6225881234567890",
-- [3] = "000000",
-- [4] = "000000346500",
-- [7] = "1013151952",
-- [11]= "365799",
-- [12]= "151952",
-- [13]= "1013",
-- [18]= "9498",
-- [22]= "021",
-- [25]= "00",
-- [26]= "12",
-- ...
-- }
function _M.pack128(tab8583)
    local bitmap = create_bitmap(128)
    bitmap[1] = 1

    local msg_type = tab8583[0] or ""
    local str8583 = ""
    for i=2, #bitmap do
        local value = tab8583[i]
        local field_type = _fields[i][TYPE]

        if value and value~="" then
            bitmap[i] = 1
            value = change_value_by_field(i, value)
            str8583 = str8583 .. prefix(field_type, value) .. value
        end
    end
    bitmap = pack_bitmap(bitmap)

    return msg_type .. bitmap .. str8583
end

-- 把8583包字符串解析为table
-- 128个域
function _M.unpack128(str8583)
    local tab8583 = {}
    local msg_type = str8583:sub(1,4)
    tab8583[MSG_TYPE] = msg_type

    local n = 1 -- 当前位置
    local bitmap1 = str8583:sub(5,5) -- 第一段bitmap的第一个字节
    n = n + 4
    local tab_bitmap = unpack_bitmap(bitmap1)
    local bitmap_len = 8
    if tab_bitmap[1] == 1 then
        bitmap_len = 16
    end
    n = n + bitmap_len
    local bitmap = str8583:sub(5, 5+bitmap_len-1) -- 字符串
    bitmap = unpack_bitmap(bitmap) -- {1,0,1,1,......}
    tab8583[1] = bitmap

    local nLen = 0 -- 某个域的长度
    for i=2,#bitmap do
        if bitmap[i] == 1 then
            local field_def = _fields[i] -- type len align padding zip
            local field_type = field_def[TYPE]
            local field_len  = field_def[LEN]
            if field_type == "fix" then
                nLen = field_len
            elseif field_type == "lllvar" then
                nLen = tonumber(str8583:sub(n,n+2))
                n = n + 3
            elseif field_type == "llvar" then
                nLen = tonumber(str8583:sub(n,n+1))
                n = n + 2
            end
            local value = str8583:sub(n, n+nLen-1)
            tab8583[i] = value
            n = n + nLen
        end
    end

    return tab8583
end

-- 把table中所有值打包为8583包字符串
-- 64个域
function _M.pack64(tab8583)
    local bitmap = create_bitmap(64)

    local msg_type = tab8583[MSG_TYPE] or ""
    if msg_type and #msg_type == 4 then
        msg_type = bcdzip(msg_type)
    end
    local str8583 = ""
    for i=2, #bitmap do
        local value = tab8583[i]

        if value and value~="" then
            bitmap[i] = 1
            value = change_value_by_field(i, value)
            --print("value: " .. value)
            local field_type = _fields[i][TYPE]
            local pf = prefix64(field_type, value)
            if _fields[i][ZIP] == "Z" then
                local padding = _fields[i][PADDING]
                local align   = _fields[i][ALIGN] -- R, L
                if align == "L" and math.mod(#value,2)~=0 then
                    value = value .. padding
                elseif align == "R" and math.mod(#value,2)~=0 then
                    value = padding .. value
                end
                value = bcdzip(value)
            end
            str8583 = str8583 .. pf .. value
        end
    end
    bitmap = pack_bitmap(bitmap)

    return msg_type .. bitmap .. str8583
end

-- 把8583包字符串解析为table
-- 64个域
function _M.unpack64(str8583)
    local tab8583 = {}
    local msg_type = string.sub(str8583, 1, 2)
    msg_type = bcdunzip(msg_type)
    tab8583[0] = msg_type
    --print("F0: Z[" .. tab8583[0] .. "]")

    local n = 1 -- 当前位置
    local bitmap1 = str8583:sub(3,3) -- 第一段bitmap的第一个字节
    n = n + 2
    local tab_bitmap = unpack_bitmap(bitmap1)
    local bitmap_len = 8
    if tab_bitmap[1] == 1 then
        bitmap_len = 16
    end
    n = n + bitmap_len
    local bitmap = str8583:sub(3, 3+bitmap_len-1) -- 字符串
    bitmap = unpack_bitmap(bitmap) -- {1,0,1,1,......}
    --io.write("F1: [");show_bitmap(bitmap); print("]")
    tab8583[1] = bitmap

    local nLen = 0 -- 某个域值的长度
    for i=2,#bitmap do
        if bitmap[i] == 1 then
            local field_def = _fields[i] -- type len align padding zip
            local field_type = field_def[TYPE]
            local field_len  = field_def[LEN]
            if field_type == "fix" then
                nLen = field_len
            elseif field_type == "lllvar" then
                nLen = tonumber(bcdunzip(str8583:sub(n,n+1)))
                n = n + 2
            elseif field_type == "llvar" then
                nLen = tonumber(bcdunzip(str8583:sub(n,n)))
                n = n + 1
            end

            local value
            local zip = field_def[ZIP]
            if zip == "Z" then
                local len = math.floor((nLen+1)/2)
                value = str8583:sub(n, n+len-1)
                value = bcdunzip(value)
                n = n + len
            --    print("F" .. i .. ": Z[" .. value.."]")
            else
                value = str8583:sub(n, n+nLen-1)
                n = n + nLen
            --    print("F" .. i .. ": ["..value.."]")
            end

            if #value > nLen then
                if field_def[ALIGN] == "L" then
                    value = value:sub(1, nLen)
                else
                    value = value:sub(-nLen)
                end
            end

            tab8583[i] = value or ""
        end
    end

    return tab8583
end

return _M
