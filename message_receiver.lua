-- message_receiver.lua
-- Central Message Processing Server
-- This computer receives messages and sends appropriate responses

local SERVER_VERSION = "1.0"
local SERVER_NAME = "Central Command Server"
local PROTOCOL_NAME = "city_comm"
local RESPONSE_PROTOCOL = "city_response"

-- Configuration for different types of messages and their responses
local MESSAGE_TYPES = {
    EMERGENCY = {
        priority = 5,
        auto_response = "Emergency alert received. Response team has been notified.",
        log_level = "CRITICAL",
        requires_ack = true
    },
    STATUS_REQUEST = {
        priority = 2,
        auto_response = "System operational. All services running normally.",
        log_level = "INFO",
        requires_ack = false
    },
    DATA_QUERY = {
        priority = 3,
        auto_response = "Data query processed. Results attached.",
        log_level = "INFO", 
        requires_ack = false
    },
    GENERAL = {
        priority = 1,
        auto_response = "Message received and logged.",
        log_level = "INFO",
        requires_ack = false
    }
}

-- Global variables for system state
local received_messages = {}
local response_log = {}
local system_start_time = os.clock()
local message_counter = 0

-- Initialize the server system
local function initializeServer()
    print(" " .. SERVER_NAME .. " v" .. SERVER_VERSION)
    print(" Starting message processing server...")
    
    -- Find and configure modem for network communication
    local modem = peripheral.find("modem")
    if not modem then
        error(" No modem found! Server cannot operate without network connectivity.", 0)
    end
    
    -- Open communication channels
    rednet.open(peripheral.getName(modem))
    print(" Network channels opened on " .. peripheral.getName(modem))
    
    -- Display server information
    print(" Server ID: " .. os.getComputerID())
    print(" Protocol: " .. PROTOCOL_NAME)
    print(" Server initialization complete")
    print(" Listening for incoming messages...")
    
    return true
end

-- Process incoming messages and determine appropriate response
local function processMessage(sender_id, message_data)
    message_counter = message_counter + 1
    local current_time = os.time()
    
    -- Create message record for logging
    local message_record = {
        id = message_counter,
        sender = sender_id,
        timestamp = current_time,
        content = message_data,
        processed_at = os.date()
    }
    
    -- Determine message type and get appropriate configuration
    local msg_type = "GENERAL"
    if message_data.type then
        msg_type = string.upper(message_data.type)
    end
    
    local type_config = MESSAGE_TYPES[msg_type] or MESSAGE_TYPES.GENERAL
    
    -- Log the message with appropriate priority
    message_record.type = msg_type
    message_record.priority = type_config.priority
    message_record.log_level = type_config.log_level
    
    table.insert(received_messages, message_record)
    
    -- Display message information
    print(" Message #" .. message_counter .. " from ID:" .. sender_id)
    print(" Type: " .. msg_type .. " | Priority: " .. type_config.priority)
    if message_data.content then
        print(" Content: " .. tostring(message_data.content))
    end
    
    -- Generate appropriate response
    local response = {
        type = "RESPONSE",
        original_message_id = message_counter,
        server_id = os.getComputerID(),
        timestamp = current_time,
        status = "RECEIVED",
        message = type_config.auto_response
    }
    
    -- Add specific data based on message type
    if msg_type == "STATUS_REQUEST" then
        response.server_status = {
            uptime_seconds = os.clock() - system_start_time,
            messages_processed = message_counter,
            system_health = "GOOD"
        }
    elseif msg_type == "DATA_QUERY" then
        response.query_result = {
            total_messages = #received_messages,
            last_message_time = current_time,
            server_load = "NORMAL"
        }
    elseif msg_type == "EMERGENCY" then
        response.emergency_response = {
            alert_level = "HIGH",
            response_team_notified = true,
            estimated_response_time = "5-10 minutes"
        }
    end
    
    return response, type_config.requires_ack
end

-- Send response back to the sender
local function sendResponse(sender_id, response_data, requires_ack)
    local response_record = {
        recipient = sender_id,
        timestamp = os.time(),
        content = response_data,
        sent_at = os.date()
    }
    
    -- Send the response
    rednet.send(sender_id, response_data, RESPONSE_PROTOCOL)
    
    -- Log the response
    table.insert(response_log, response_record)
    
    print(" Response sent to ID:" .. sender_id)
    if requires_ack then
        print(" Response requires acknowledgment")
    end
    
    -- Visual separator for readability
    print(string.rep("-", 40))
end

-- Display current system status
local function displaySystemStatus()
    local uptime = os.clock() - system_start_time
    
    print("\n SYSTEM STATUS REPORT")
    print(" Uptime: " .. math.floor(uptime/60) .. " minutes")
    print(" Messages processed: " .. message_counter)
    print(" Responses sent: " .. #response_log)
    print(" Memory usage: " .. math.floor(collectgarbage("count")) .. " KB")
    print(string.rep("=", 40))
end

-- Main message handling loop
local function messageHandler()
    while true do
        -- Listen for incoming messages
        local sender_id, message_data = rednet.receive(PROTOCOL_NAME)
        
        if sender_id and message_data then
            -- Process the message and generate response
            local response, requires_ack = processMessage(sender_id, message_data)
            
            -- Send response back to sender
            sendResponse(sender_id, response, requires_ack)
            
            -- Display status every 10 messages
            if message_counter % 10 == 0 then
                displaySystemStatus()
            end
        end
    end
end

-- Handle user commands while server is running
local function commandHandler()
    while true do
        local command = read()
        
        if command == "status" then
            displaySystemStatus()
        elseif command == "messages" then
            print(" Recent messages:")
            local start_index = math.max(1, #received_messages - 5)
            for i = start_index, #received_messages do
                local msg = received_messages[i]
                print("#" .. msg.id .. " from " .. msg.sender .. ": " .. msg.type)
            end
        elseif command == "clear" then
            received_messages = {}
            response_log = {}
            message_counter = 0
            print(" Message logs cleared")
        elseif command == "shutdown" then
            print(" Shutting down server...")
            break
        else
            print("Available commands: status, messages, clear, shutdown")
        end
    end
end

-- Main server function
local function runServer()
    if initializeServer() then
        print("\n Server is now running!")
        print(" Available commands: status, messages, clear, shutdown")
        print(" Ready to receive messages on protocol: " .. PROTOCOL_NAME)
        
        -- Run message handler and command handler in parallel
        parallel.waitForAny(messageHandler, commandHandler)
    end
end

-- Start the server
runServer()
