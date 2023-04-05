PROJECT = "mqttdemo"
VERSION = "1.0.0"

_G.sys = require("sys")
_G.sysplus = require("sysplus")

local mqtt_host = "bemfa.com"
local mqtt_port = 9501
local mqtt_isssl = false
local client_id = "9bcee0de11d893a64c895387146f1929"
local pub_topic = "mqtt/set"
local sub_topic = "mqtt"

sys.taskInit(function()
    if rtos.bsp() == "AIR780E" then
        device_id = mobile.imei()
        sys.waitUntil("IP_READY", 30000)
        pub_topic = "mqtt"
        sub_topic = "mqtt"
    end

    log.info("mqtt", "pub", pub_topic)
    log.info("mqtt", "sub", sub_topic)

    local mqttc = mqtt.create(nil, mqtt_host, mqtt_port, mqtt_isssl, nil)

    mqttc:auth(client_id, nil, nil)
    mqttc:autoreconn(true, 3000)

    mqttc:on(function(mqtt_client, event, data, payload)
        if event == "conack" then
            sys.publish("mqtt_conack")
            mqtt_client:subscribe(sub_topic)
        elseif event == "recv" then
            log.info("mqtt", "received", "topic", data, "payload", payload)
        elseif event == "sent" then
            log.info("mqtt", "sent", "pkgid", data)
        end
    end)

    mqttc:connect()
    sys.waitUntil("mqtt_conack")

    while true do
        sys.wait(5000)
        local data = "OFF"
        if math.random(0, 1) == 1 then
            data = "ON"
        end
        local pkgid = mqttc:publish(pub_topic, data, 1)
        log.info("mqtt", "published", pkgid, pub_topic, data)
    end

    mqttc:disconnect()
    mqttc:close()
    mqttc = nil
end)

sys.run()