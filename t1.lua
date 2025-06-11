-- emergency_station.lua
-- Remote Emergency Alert Station
-- This represents a field station that can send alerts to the central system

local STATION_NAME = "Emergency Station Alpha" -- Each station should have a unique name
local CENTRAL_SYSTEM_ID = 1 -- The computer ID of our central alert system
local STATION_VERSION = "1.0"

-- Think of these priority levels like the severity ratings doctors use in emergency rooms
-- CRITICAL means "drop everything and respond now"
-- HIGH means "this needs immediate attention" 
-- MEDIUM means "handle this soon"
-- LOW means "handle when you can"
-- INFO means "just so you know"
local PRIORITY_LEVELS = {
    "CRITICAL",  -- Life-threatening emergencies
    "HIGH",      -- Serious situations requiring quick response
    "MEDIUM",    -- Important but not immediately dangerous
    "LOW",       -- Minor issues that should be addressed
    "INFO"       -- General information updates
}

-- This function initializes our station, similar to how a radio operator
-- would check their equipment before starting their shift
local function initializeStation()
    print("🚨 " .. STATION_NAME .. " v" .. STATION_VERSION)
    print("🔄 Initializing emergency station...")
    
    -- Check if we have a modem to communicate with the central system
    local modem = peripheral.find("modem")
    if not modem then
        error("❌ No modem found! This station cannot communicate with central command.", 0)
    end
    
    -- Open our communication channel
    rednet.open(peripheral.getName(modem))
    print("📡 Communication link established")
    
    -- Test connection to central system
    print("🔍 Testing connection to central command...")
    rednet.send(CENTRAL_SYSTEM_ID, {
        type = "status_request",
        station = STATION_NAME
    }, "city_alert")
    
    -- Wait for response (like calling dispatch to check if they can hear you)
    local sender, response = rednet.receive("city_alert_response", 5)
    
    if response and response.type == "status_response" then
        print("✅ Connection to central command confirmed")
        print("📊 Central system status: " .. response.system_status)
        print("🚨 Active alerts at central: " .. response.active_alerts)
    else
        print("⚠️ No response from central command - alerts will be queued")
    end
    
    print("🎯 Station ready for emergency operations")
end

-- This function handles the user interface for sending alerts
-- Think of it like the interface a 911 operator would use
local function displayStationInterface()
    term.clear()
    term.setCursorPos(1, 1)
    
    -- Create a header that looks professional and urgent
    term.setBackgroundColor(colors.red)
    term.setTextColor(colors.white)
    term.clearLine()
    term.write(" 🚨 EMERGENCY ALERT STATION 🚨 ")
    
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.setCursorPos(1, 2)
    term.write("Station: " .. STATION_NAME)
    
    term.setCursorPos(1, 4)
    term.write("📋 PRIORITY LEVELS:")
    
    -- Display priority levels with color coding to help users understand urgency
    local colors_for_priority = {
        [1] = colors.red,     -- CRITICAL
        [2] = colors.orange,  -- HIGH  
        [3] = colors.yellow,  -- MEDIUM
        [4] = colors.lime,    -- LOW
        [5] = colors.lightBlue -- INFO
    }
    
    for i, priority in ipairs(PRIORITY_LEVELS) do
        term.setCursorPos(3, 4 + i)
        term.setTextColor(colors_for_priority[i])
        term.write(i .. ". " .. priority)
        
        -- Add descriptions to help users choose the right priority
        term.setTextColor(colors.lightGray)
        local descriptions = {
            " - Life threatening emergency",
            " - Serious situation, quick response needed", 
            " - Important issue, handle soon",
            " - Minor issue, handle when possible",
            " - General information update"
        }
        term.write(descriptions[i])
    end
    
    term.setTextColor(colors.white)
    term.setCursorPos(1, 11)
    term.write("📝 QUICK ALERTS:")
    term.setCursorPos(3, 12)
    term.write("F1 - Fire Emergency")
    term.setCursorPos(3, 13) 
    term.write("F2 - Medical Emergency")
    term.setCursorPos(3, 14)
    term.write("F3 - Security Alert")
    term.setCursorPos(3, 15)
    term.write("F4 - Infrastructure Problem")
    
    term.setCursorPos(1, 17)
    term.write("💬 Type 'custom' for custom message")
    term.setCursorPos(1, 18)
    term.write("🔧 Type 'test' to send test alert")
    term.setCursorPos(1, 19)
    term.write("📊 Type 'status' to check central system")
end

-- This function sends an alert to the central system
-- It's like pressing the emergency button and speaking into the radio
local function sendAlert(message, priority, duration)
    priority = priority or "INFO"
    duration = duration or 300 -- Default 5 minutes
    
    print("📡 Sending alert to central command...")
    
    -- Package our alert with all necessary information
    local alert_package = {
        type = "alert",
        source = STATION_NAME,
        message = message,
        priority = priority,
        duration = duration,
        timestamp = os.time(),
        station_id = os.getComputerID()
    }
    
    -- Send to central system
    rednet.send(CENTRAL_SYSTEM_ID, alert_package, "city_alert")
    
    -- Wait for confirmation (like waiting for dispatch to acknowledge your radio call)
    local sender, confirmation = rednet.receive("city_alert_response", 10)
    
    if confirmation and confirmation.type == "confirmation" then
        print("✅ Alert sent successfully!")
        print("📅 Acknowledged at: " .. confirmation.timestamp)
        
        -- Visual feedback - flash the screen to show success
        term.setBackgroundColor(colors.green)
        term.clear()
        term.setCursorPos(1, 1)
        term.setTextColor(colors.white)
        term.write("✅ ALERT SENT SUCCESSFULLY!")
        sleep(1)
        
    else
        print("⚠️ No confirmation received from central command")
        print("📝 Alert may have been queued for retry")
        
        -- Visual feedback for potential failure
        term.setBackgroundColor(colors.orange)
        term.clear()
        term.setCursorPos(1, 1)
        term.setTextColor(colors.black)
        term.write("⚠️ ALERT STATUS UNCERTAIN")
        sleep(1)
    end
end

-- Pre-defined emergency messages for quick deployment
-- These are like having pre-written scripts for common emergencies
local QUICK_ALERTS = {
    F1 = {
        message = "🔥 FIRE EMERGENCY - Immediate evacuation may be required",
        priority = "CRITICAL",
        duration = 1800 -- 30 minutes
    },
    F2 = {
        message = "🏥 MEDICAL EMERGENCY - Medical assistance required",
        priority = "CRITICAL", 
        duration = 900 -- 15 minutes
    },
    F3 = {
        message = "🔒 SECURITY ALERT - Potential threat detected",
        priority = "HIGH",
        duration = 600 -- 10 minutes
    },
    F4 = {
        message = "⚡ INFRASTRUCTURE PROBLEM - City services may be affected",
        priority = "MEDIUM",
        duration = 1200 -- 20 minutes
    }
}

-- This function handles user input and processes different types of alerts
local function handleUserInput()
    while true do
        displayStationInterface()
        
        term.setCursorPos(1, 21)
        term.setTextColor(colors.white)
        term.write("Command: ")
        
        local input = read()
        
        -- Handle quick alert keys (F1-F4)
        if QUICK_ALERTS[input] then
            local alert = QUICK_ALERTS[input]
            
            term.clear()
            term.setCursorPos(1, 1)
            term.setTextColor(colors.red)
            term.write("⚠️ SENDING EMERGENCY ALERT ⚠️")
            term.setCursorPos(1, 3)
            term.setTextColor(colors.white)
            term.write("Message: " .. alert.message)
            term.setCursorPos(1, 4)
            term.write("Priority: " .. alert.priority)
            term.setCursorPos(1, 6)
            term.write("Confirm send? (y/n): ")
            
            local confirm = read()
            if confirm:lower() == "y" or confirm:lower() == "yes" then
                sendAlert(alert.message, alert.priority, alert.duration)
            else
                print("❌ Alert cancelled")
            end
            
            sleep(2)
            
        elseif input == "custom" then
            -- Allow users to create custom alerts
            term.clear()
            term.setCursorPos(1, 1)
            term.write("📝 CUSTOM ALERT CREATOR")
            
            term.setCursorPos(1, 3)
            term.write("Enter your message: ")
            local custom_message = read()
            
            if custom_message and custom_message ~= "" then
                term.setCursorPos(1, 5)
                term.write("Select priority (1-5): ")
                local priority_num = tonumber(read())
                
                if priority_num and priority_num >= 1 and priority_num <= 5 then
                    local selected_priority = PRIORITY_LEVELS[priority_num]
                    
                    term.setCursorPos(1, 7)
                    term.write("Duration in minutes (default 5): ")
                    local duration_input = read()
                    local duration = tonumber(duration_input) or 5
                    duration = duration * 60 -- Convert to seconds
                    
                    term.setCursorPos(1, 9)
                    term.write("Preview:")
                    term.setCursorPos(1, 10)
                    term.setTextColor(colors.yellow)
                    term.write(custom_message)
                    term.setTextColor(colors.white)
                    term.setCursorPos(1, 11)
                    term.write("Priority: " .. selected_priority)
                    term.setCursorPos(1, 12)
                    term.write("Duration: " .. (duration/60) .. " minutes")
                    
                    term.setCursorPos(1, 14)
                    term.write("Send this alert? (y/n): ")
                    local confirm = read()
                    
                    if confirm:lower() == "y" or confirm:lower() == "yes" then
                        sendAlert(custom_message, selected_priority, duration)
                    else
                        print("❌ Custom alert cancelled")
                    end
                else
                    print("❌ Invalid priority level")
                end
            else
                print("❌ No message entered")
            end
            
            sleep(2)
            
        elseif input == "test" then
            -- Send a test alert to verify the system is working
            local test_message = "🔧 TEST ALERT from " .. STATION_NAME .. " - System operational"
            sendAlert(test_message, "INFO", 60)
            sleep(2)
            
        elseif input == "status" then
            -- Check the status of the central system
            term.clear()
            term.setCursorPos(1, 1)
            term.write("📊 CHECKING CENTRAL SYSTEM STATUS...")
            
            rednet.send(CENTRAL_SYSTEM_ID, {
                type = "status_request",
                station = STATION_NAME
            }, "city_alert")
            
            local sender, response = rednet.receive("city_alert_response", 5)
            
            if response and response.type == "status_response" then
                term.setCursorPos(1, 3)
                term.setTextColor(colors.green)
                term.write("✅ Central Command Online")
                term.setTextColor(colors.white)
                term.setCursorPos(1, 4)
                term.write("System Status: " .. response.system_status)
                term.setCursorPos(1, 5)
                term.write("Active Alerts: " .. response.active_alerts)
                term.setCursorPos(1, 6)
                term.write("Uptime: " .. math.floor(response.uptime/60) .. " minutes")
            else
                term.setCursorPos(1, 3)
                term.setTextColor(colors.red)
                term.write("❌ Central Command Not Responding")
                term.setTextColor(colors.white)
                term.setCursorPos(1, 4)
                term.write("Check network connection")
            end
            
            term.setCursorPos(1, 8)
            term.write("Press any key to continue...")
            read()
            
        elseif input == "exit" or input == "quit" then
            print("👋 Shutting down emergency station...")
            break
            
        else
            term.setCursorPos(1, 22)
            term.setTextColor(colors.red)
            term.write("❌ Unknown command: " .. input)
            sleep(1)
        end
    end
end

-- Main function that brings everything together
local function main()
    initializeStation()
    
    print("\n🎯 Emergency Station Ready!")
    print("📡 Central System ID: " .. CENTRAL_SYSTEM_ID)
    print("🆔 This Station ID: " .. os.getComputerID())
    print("⚡ Press any key to start operations...")
    
    read() -- Wait for user to be ready
    
    handleUserInput()
end

-- Start the station
main()