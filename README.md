# mobid

An Ashita v4 addon by **morrowindislong** that records defeated mobs' server IDs
for tools that read your chat logs. Mob ID lines are hidden from the in-game
chat window by default and still captured by Ashita's `logs` addon.

## Installation

1. Download `mobid.zip` from the [latest release](https://github.com/fitzpat/mobid/releases/latest).
2. Extract it into your Ashita `addons` directory so the file is at `addons/mobid/mobid.lua`.
3. Load both addons in-game:

   ```text
   /addon load logs
   /addon load mobid
   ```

If mobid is already loaded, use `/addon reload mobid` after updating it.
Add the load commands to your Ashita startup script to load them automatically.

## Commands

| Command | Behavior |
| --- | --- |
| `/mobid help` or `/mobid ?` | Show help and defaults. |
| `/mobid` | Toggle mob ID logging; enabled by default when loaded. |
| `/mobid test` | Emit a sample line using the current visibility setting. |
| `/mobid chat` | Toggle mob ID lines in the in-game chat window. |
| `/mobid chat on` | Show mob ID lines in the in-game chat window. |
| `/mobid chat off` | Hide mob ID lines from the in-game chat window (default). |

Chat visibility is saved per character through Ashita's settings library.
Command responses and help remain visible when mob ID lines are hidden.

## Log output

With Ashita's `logs` addon loaded, mob ID lines are captured in
`chatlogs/<character>_YYYY.MM.DD.log` alongside normal chat:

```text
[mobid] Playername defeats Buffalo | id: 17694721 | hex: 0x010E0001 | idx: 193
```

Run `/mobid test` and check the log file to verify capture.

## Releases

The release workflow packages `mobid.lua` as `mobid/mobid.lua` inside `mobid.zip`.
Updating the version in `addon.version` and pushing to `main` publishes a new
tagged release. The workflow can also be started manually in GitHub Actions.
