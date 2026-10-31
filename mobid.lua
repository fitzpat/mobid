--[[
* mobid - Ashita v4 addon
*
* Watches for the "defeats" message packet (0x0029, MessageNum 6) and prints
* a self-contained line into the chat log with the defeated mob's server id,
* so external tools tailing chatlogs/*.log can associate kills with a mob id.
*
* Output example (lands just before the matching "X defeats Y." line):
*   [mobid] Playername defeats Buffalo | id: 17694721 | hex: 0x010DE981 | idx: 193
*
* Requires the Ashita logs addon for chatlogs/*.log capture. Mob id lines are
* hidden from the in-game chat window by default, but remain in the log file.
* The show_in_chat setting is saved using Ashita's per-character settings.
*
* Commands:
*   /mobid help   - Shows commands and defaults.
*   /mobid        - Toggles logging on/off. (On by default.)
*   /mobid test   - Emits a sample line to verify chatlog capture.
*   /mobid chat [on|off] - Toggles or sets in-game mob id display. (Off by default.)
--]]

addon.name      = 'mobid';
addon.author    = 'morrowindislong';
addon.version   = '1.2';
addon.desc      = 'Logs defeated mob server ids to the chat log.';

require 'common';

local chat = require 'chat';
local settings = require 'settings';

local default_settings = T{
    show_in_chat = false,
};

local mobid = T{
    enabled = true,
    settings = settings.load(default_settings),
};

settings.register('settings', 'settings_update', function (s)
    if (s ~= nil) then
        mobid.settings = s;
    end
end);

-- 0x0029 MessageNum values treated as a mob defeat..
--   6 = MsgBasic::DefeatsTarget ("<player> defeats <target>.")
local defeat_messages = T{ 6, };

-- Prints help separately from mob id lines so it remains visible in chat.
local function print_help()
    local lines = {
        'Commands:',
        '/mobid help - Shows this help.',
        '/mobid - Toggles mob id logging. Default: on.',
        '/mobid test - Emits a sample mob id line using the current chat visibility setting.',
        '/mobid chat [on|off] - Sets chat visibility; omit on/off to toggle. Default: off.',
        'Chat visibility is saved per character. Hidden mob id lines are still logged.',
        'Load the Ashita logs addon to capture mob id lines in chatlogs/*.log.',
    };
    for _, line in ipairs(lines) do
        print(chat.header(addon.name):append(chat.message(line)));
    end
end

--[[
* Returns the name of the entity at the given array index, or nil if the slot
* does not hold the expected entity anymore.
*
* @param {number} index      - The entity array index (targid).
* @param {number} server_id  - Optional server id to validate against.
* @return {string|nil}
--]]
local function entity_name(index, server_id)
    local ent = GetEntity(index);
    if (ent ~= nil and ent.Name ~= nil
        and (server_id == nil or ent.ServerId == server_id)) then
        return ent.Name;
    end
    return nil;
end

--[[
* event: packet_in
* desc : Event called when the addon is processing incoming packets.
--]]
ashita.events.register('packet_in', 'packet_in_cb', function (e)
    if (e.id ~= 0x0029 or not mobid.enabled) then
        return;
    end

    -- GP_SERV_COMMAND_BATTLE_MESSAGE layout (XiPackets):
    --   0x04  uint32  UniqueNoCas  - killer server id
    --   0x08  uint32  UniqueNoTar  - defeated server id
    --   0x0C  uint32  Data         - param
    --   0x10  uint32  Data2        - value
    --   0x14  uint16  ActIndexCas  - killer targid
    --   0x16  uint16  ActIndexTar  - defeated targid
    --   0x18  uint16  MessageNum   - message id
    local msg = struct.unpack('H', e.data, 0x18 + 1);
    if (not defeat_messages:contains(msg)) then
        return;
    end

    local target_id  = struct.unpack('L', e.data, 0x08 + 1);
    local target_idx = struct.unpack('H', e.data, 0x16 + 1);
    local actor_idx  = struct.unpack('H', e.data, 0x14 + 1);
    local actor_id   = struct.unpack('L', e.data, 0x04 + 1);

    local mob_name   = entity_name(target_idx, target_id) or 'Unknown';
    local actor_name = entity_name(actor_idx, actor_id) or 'Someone';

    -- Plain text (no color codes) so log parsers get a clean line..
    print(('[mobid] %s defeats %s | id: %d | hex: 0x%08X | idx: %d')
        :fmt(actor_name, mob_name, target_id, target_id, target_idx));
end);

--[[
* event: text_in
* desc : Hides injected mob id lines without removing their text from logs.
--]]
ashita.events.register('text_in', 'text_in_cb', function (e)
    if (not mobid.settings.show_in_chat and e.injected
        and e.message:match('^%[mobid%] .- defeats .- | id: %d+ | hex: 0x%x+ | idx: %d+$')) then
        -- The logs addon reads message_modified even when the event is blocked.
        -- Match the original message so timestamp/color addons do not interfere.
        e.blocked = true;
    end
end);

--[[
* event: command
* desc : Event called when the addon is processing a command.
--]]
ashita.events.register('command', 'command_cb', function (e)
    local args = e.command:args();
    if (#args == 0 or not args[1]:any('/mobid')) then
        return;
    end

    e.blocked = true;

    if (#args >= 2 and args[2]:any('help', '?')) then
        print_help();
        return;
    end

    if (#args >= 2 and args[2]:any('chat')) then
        if (#args == 2) then
            mobid.settings.show_in_chat = not mobid.settings.show_in_chat;
        elseif (#args == 3 and args[3]:any('on', 'off')) then
            mobid.settings.show_in_chat = args[3]:any('on');
        else
            print(chat.header(addon.name):append(chat.message('Usage: /mobid chat [on|off]')));
            return;
        end
        settings.save();
        print(chat.header(addon.name)
            :append(chat.message(('In-game mob id display %s.'):fmt(mobid.settings.show_in_chat and 'enabled' or 'disabled'))));
        return;
    end

    if (#args >= 2 and args[2]:any('test')) then
        print('[mobid] TestPlayer defeats TestMob | id: 12345678 | hex: 0x00BC614E | idx: 123');
        return;
    end

    if (#args > 1) then
        print_help();
        return;
    end

    mobid.enabled = not mobid.enabled;
    print(chat.header(addon.name)
        :append(chat.message(('Logging %s.'):fmt(mobid.enabled and 'enabled' or 'disabled'))));
end);
