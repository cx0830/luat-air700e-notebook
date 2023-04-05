-- LuaTools需要PROJECT和VERSION这两个信息
PROJECT = "uart_gps"
VERSION = "1.0.0"

log.info("main", PROJECT, VERSION)

-- 引入必要的库文件(lua编写), 内部库不需要require
sys = require("sys")

if wdt then
    --添加硬狗防止程序卡死，在支持的设备上启用这个功能
    wdt.init(9000)--初始化watchdog设置为9s
    sys.timerLoopStart(wdt.feed, 3000)--3s喂一次狗
end

log.info("main", "uart demo")

local uartid = 2 -- 根据实际设备选取不同的uartid

--初始化
local result = uart.setup(
    uartid,--串口id
    9600,--波特率
    8,--数据位
    1--停止位
)

-- 收取数据会触发回调, 这里的"receive" 是固定值
uart.on(uartid, "receive", function(id, len)
    local s = ""
    repeat
        -- 如果是air302, len不可信, 传1024
        -- s = uart.read(id, 1024)
        s = uart.read(id, len)
        if #s > 0 then -- #s 是取字符串的长度
            -- log.info("uart", "receive", id, #s, s)
            local utc_time, lat, lat_ns, lon, lon_ew = string.match(s, "%$GNGGA,(%d+%.%d+),(%d+%.%d+),(%a),(%d+%.%d+),(%a),")
            if utc_time and lat and lat_ns and lon and lon_ew then
                log.info("uart", "UTC Time", utc_time)
                local hour = tonumber(utc_time:sub(1,2))
                local minute = tonumber(utc_time:sub(3,4))
                local second = tonumber(utc_time:sub(5,6))
                hour = hour +8
                if hour >=24 then
                    hour = hour -24
                end
                local time_str = string.format("%02d:%02d:%02d", hour, minute, second) -- 转换为时分秒格式
                log.info("uart", "Beijing Time", time_str)

                -- 转换经纬度为GPS坐标格式
                local lat_deg = math.floor(tonumber(lat) / 100)
                local lat_min = tonumber(lat) % 100
                local lat_google = lat_deg + lat_min / 60
                if lat_ns == "S" then
                    lat_google = -lat_google
                end
                log.info("uart", "Latitude", lat_google)
                local lon_deg = math.floor(tonumber(lon) / 100)
                local lon_min = tonumber(lon) % 100
                local lon_google = lon_deg + lon_min / 60
                if lon_ew == "W" then
                    lon_google = -lon_google
                end
                log.info("uart", "Longitude", lon_google)
            end
        end
        if #s == len then
            break
        end
    until s == ""
end)

-- 用户代码已结束---------------------------------------------
-- 结尾总是这一句
sys.run()
-- sys.run()之后后面不要加任何语句!!!!!
