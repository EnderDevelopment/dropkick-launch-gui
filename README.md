# Roblox Dropkick and Flight Script

Dropkick Launch GUI is a Roblox script system that provides a player targeting GUI, a server validated dropkick ability, and a client side flight controller. It is a Roblox script package for a dropkick system, fling script, control GUI, and flying script.

## Install

1. Open your Roblox experience in Roblox Studio.
2. In `ServerScriptService`, create a new `Script`.
3. Copy the contents of `src/DropkickServer.server.lua` into the server Script.
4. In `StarterPlayer > StarterPlayerScripts`, create a new `LocalScript`.
5. Copy the contents of `src/DropkickClient.client.lua` into the LocalScript.
6. Do not manually create the remote folder or RemoteEvent. The server script creates `ReplicatedStorage > DropkickRemotes > RequestDropkick` automatically when the server starts.

## Use

1. Start the experience with at least two players for dropkick testing.
2. Click a nearby player to select them.
3. Press `E` or click `DROP KICK` to launch the selected player.
4. The target must be another live player within 18 studs and visible without an obstruction.
5. Press `F` or click the flight button to enable or disable flight.
6. While flying, use the normal movement controls to move horizontally.
7. Press `Space` to rise and `LeftControl` to descend.
8. The dropkick has a 2.5 second cooldown. The server checks the target, distance, line of sight, player state, and cooldown before applying the fling.

---

More Roblox script projects by EnderDevelopment: https://github.com/EnderDevelopment

Project page: https://dash.enderdevelopment.com/community/b52a449f-426b-467c-b98e-127fd2c625ae?utm_source=github&utm_medium=readme&utm_campaign=auto_publish&utm_content=b52a449f-426b-467c-b98e-127fd2c625ae
