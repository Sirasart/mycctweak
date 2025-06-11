-- message_sender.lua
-- Client Message Sending System
-- This computer sends messages and receives responses

local CLIENT_VERSION = "1.0"
local CLIENT_NAME = "Field Communication Unit"
local SERVER_ID = 1 -- Change this to match your server computer ID
local PROTOCOL_NAME = "city_comm"
local RESPONSE_PROTOCOL = "city_response"

-- Message templates for different types of communications
local MESSAGE_TEMPLATES = {
    EMERGENCY = {
        type = "EMERGENCY",
        priority = "HIGH",
        example = "Fire detected in sector 7"
    },
    STATUS_REQUEST = {
        type = "STATUS_REQUEST", 
        priority = "LOW",
        example = "Requesting system status check"
    },
    DATA_QUERY = {
        type = "DATA_QUERY",
        priority = "MEDIUM", 
        example = "Need current operational statistics"
    },
    GENERAL = {
        type = "GENERAL",
        priority = "LOW",
        example = "Routine status update"
    }
}

-- Track sent messages and received responses
local sent_messages = {}
local received_responses = {}
local message_id_counter = 0

-- Initialize the client system
local function initializeClient()
    print(" " .. CLIENT_NAME .. " v" .. CLIENT_VERSION)
    print(" Starting communication client...")
    
    -- Find and configure modem
    local modem = peripheral.find("modem")
    if not modem then
        error(" No modem found! Client cannot communicate without network.", 0)
    end
    
    rednet.open(peripheral.getName(modem))
    print(" Network connection established")
    
    -- Test connection to server
    print(" Testing connection to server ID:" .. SERVER_ID)
    local test_message = {
        type = "STATUS_REQUEST",
        content = "Connection test from client " .. os.getComputerID(),
        client_info = CLIENT_NAME
    }
    
    rednet.send(SERVER_ID, test_message, PROTOCOL_NAME)
    
    -- Wait for response to confirm connection
    local response_sender, response_data = rednet.receive(RESPONSE_PROTOCOL, 5)
    
    if response_sender == SERVER_ID and response_data then
        print(" Server connection confirmed")
        print(" Server status: " .. (response_data.status or "Unknown"))
    else
        print(" No response from server - messages will be sent anyway")
    end
    
    print(" Client ready for operation")
    return true
end

-- Display the user interface for message options
local function displayClientInterface()
    term.clear()
    term.setCursorPos(1, 1)
    
    -- Header
    term.setBackgroundColor(colors.blue)
    term.setTextColor(colors.white)
    term.clearLine()
    term.write("  MESSAGE COMMUNICATION CLIENT 📱 ")
    
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.setCursorPos(1, 2)
    term.write("Client: " .. CLIENT_NAME)
    term.setCursorPos(1, 3)
    term.write("Server ID: " .. SERVER_ID)
    
    term.setCursorPos(1, 5)
    term.write(" MESSAGE TYPES:")
    
    -- Display message type options with colors
    local type_colors = {
        colors.red,    -- EMERGENCY
        colors.yellow, -- STATUS_REQUEST
        colors.cyan,   -- DATA_QUERY
        colors.green   -- GENERAL
    }
    
    local type_list = {"EMERGENCY", "STATUS_REQUEST", "DATA_QUERY", "GENERAL"}
    
    for i, msg_type in ipairs(type_list) do
        term.setCursorPos(3, 5 + i)
        term.setTextColor(type_colors[i])
        term.write(i .. ". " .. msg_type)
        
        term.setTextColor(colors.lightGray)
        local template = MESSAGE_TEMPLATES[msg_type]
        term.write(" (" .. template.priority .. " priority)")
    end
    
    term.setTextColor(colors.white)
    term.setCursorPos(1, 11)
    term.write(" QUICK ACTIONS:")
    term.setCursorPos(3, 12)
    term.write("T - Test connection to server")
    term.setCursorPos(3, 13)
    term.write("H - View response history") 
    term.setCursorPos(3, 14)
    term.write("S - Check server status")
    term.setCursorPos(3, 15)
    term.write("C - Send custom message")
    
    term.setCursorPos(1, 17)
    term.write(" Select option or type 'quit' to exit")
end

-- Send a message to the server and wait for response
local function sendMessageAndWaitForResponse(message_data, timeout)
    timeout = timeout or 10
    message_id_counter = message_id_counter + 1
    
    -- Add client metadata to message
    message_data.client_id = os.getComputerID()
    message_data.client_message_id = message_id_counter
    message_data.sent_at = os.date()
    
    -- Log the outgoing message
    local message_record = {
        id = message_id_counter,
        content = message_data,
        sent_at = os.time(),
        server_id = SERVER_ID
    }
    table.insert(sent_messages, message_record)
    
    print(" Sending message #" .. message_id_counter .. " to server...")
    print(" Type: " .. (message_data.type or "UNKNOWN"))
    
    -- Send the message
    rednet.send(SERVER_ID, message_data, PROTOCOL_NAME)
    
    -- Wait for response
    print(" Waiting for server response...")
    local response_sender, response_data = rednet.receive(RESPONSE_PROTOCOL, timeout)
    
    if response_sender == SERVER_ID and response_data then
        -- Log the response
        local response_record = {
            message_id = message_id_counter,
            response_data = response_data,
            received_at = os.time(),
            server_id = response_sender
        }
        table.insert(received_responses, response_record)
        
        print(" Response received from server!")
        print(" Server message: " .. (response_data.message or "No message"))
        
        -- Display additional response data if available
        if response_data.server_status then
            print(" Server uptime: " .. math.floor(response_data.server_status.uptime_seconds/60) .. " minutes")
            print(" Messages processed: " .. response_data.server_status.messages_processed)
        end
        
        return true, response_data
    else
        print(" No response received within " .. timeout .. " seconds")
        return false, nil
    end
end

-- Handle user input and process different types of messages
local function handleUserInteraction()
    while true do
        displayClientInterface()
        
        term.setCursorPos(1, 19)
        term.write("Your choice: ")
        local input = read()
        
        term.clear()
        term.setCursorPos(1, 1)
        
        if input == "1" then
            -- Emergency message
            term.setTextColor(colors.red)
            term.write(" EMERGENCY MESSAGE COMPOSER ")
            term.setTextColor(colors.white)
            term.setCursorPos(1, 3)
            term.write("Enter emergency details: ")
            local emergency_details = read()
            
            if emergency_details and emergency_details ~= "" then
                local emergency_msg = {
                    type = "EMERGENCY",
                    content = emergency_details,
                    priority = "CRITICAL",
                    requires_immediate_response = true
                }
                
                sendMessageAndWaitForResponse(emergency_msg, 15)
            else
                print("❌ No emergency details provided")
            end
            
        elseif input == "2" then
            -- Status request
            print(" REQUESTING SERVER STATUS")
            local status_msg = {
                type = "STATUS_REQUEST",
                content = "Status check requested by " .. CLIENT_NAME
            }
            
            sendMessageAndWaitForResponse(status_msg, 5)
            
        elseif input == "3" then
            -- Data query
            print(" DATA QUERY REQUEST")
            term.write("What data do you need? ")
            local query_content = read()
            
            local data_msg = {
                type = "DATA_QUERY", 
                content = "Data request: " .. query_content,
                query_details = query_content
            }
            
            sendMessageAndWaitForResponse(data_msg, 8)
            
        elseif input == "4" then
            -- General message
            print(" GENERAL MESSAGE COMPOSER")
            term.write("Enter your message: ")
            local general_content = read()
            
            if general_content and general_content ~= "" then
                local general_msg = {
                    type = "GENERAL",
                    content = general_content
                }
                
                sendMessageAndWaitForResponse(general_msg, 5)
            else
                print(" No message content provided")
            end
            
        elseif string.upper(input) == "T" then
            -- Test connection
            print(" TESTING CONNECTION TO SERVER")
            local test_msg = {
                type = "STATUS_REQUEST",
                content = "Connection test from " .. CLIENT_NAME,
                test_mode = true
            }
            
            sendMessageAndWaitForResponse(test_msg, 5)
            
        elseif string.upper(input) == "H" then
            -- View response history
            print(" RESPONSE HISTORY")
            if #received_responses == 0 then
                print("No responses received yet")
            else
                print("Recent responses:")
                local start_index = math.max(1, #received_responses - 5)
                for i = start_index, #received_responses do
                    local resp = received_responses[i]
                    print("#" .. resp.message_id .. ": " .. (resp.response_data.message or "No message"))
                end
            end
            
        elseif string.upper(input) == "S" then
            -- Check server status
            print(" CHECKING SERVER STATUS")
            local status_msg = {
                type = "STATUS_REQUEST",
                content = "Detailed status check",
                request_full_status = true
            }
            
            sendMessageAndWaitForResponse(status_msg, 8)
            
        elseif string.upper(input) == "C" then
            -- Custom message
            print("✏ CUSTOM MESSAGE BUILDER")
            term.write("Message type (EMERGENCY/GENERAL/DATA_QUERY): ")
            local custom_type = string.upper(read())
            
            if MESSAGE_TEMPLATES[custom_type] then
                term.write("Message content: ")
                local custom_content = read()
                
                local custom_msg = {
                    type = custom_type,
                    content = custom_content,
                    custom_message = true
                }
                
                sendMessageAndWaitForResponse(custom_msg, 10)
            else
                print(" Invalid message type")
            end
            
        elseif string.lower(input) == "quit" or string.lower(input) == "exit" then
            print(" Closing communication client...")
            break
            
        else
            print(" Invalid option: " .. input)
        end
        
        print("\n⏸ Press Enter to continue...")
        read()
    end
end

-- Main client function
local function runClient()
    if initializeClient() then
        print("\n Client is ready for communication!")
        print(" Client ID: " .. os.getComputerID())
        print(" Connected to server ID: " .. SERVER_ID)
        print(" Press Enter to start...")
        
        read()
        handleUserInteraction()
    end
end

-- Start the client
runClient()
