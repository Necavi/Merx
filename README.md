Overview:

    Tracks players points according to events.
    Completely configurable events and rewards.
    Completely configurable menus, able to use any client/server command.
    Supports both MySQL and SQLite

Cvars:

    This plugin doesn't have a terribly large number of Cvars, most configuration is done through the keyvalue configs. 

    merx_version - Either the current build number or CUSTOM for a hand-compile.
    merx_default_points - Sets the default number of points to give new players.
    merx_save_timer - Sets the duration between automatic saves.

Commands:

    sm_points - Displays your current points.
    sm_merxmenu - Displays the points menu.
    giveitem -(cheat) Give client an item.

Installation:

    Grab the latest build from: http://ci.0xf.org/job/Merx/lastBuild/
    Copy /addons/ in the zip to /addons/ on your server (if updating, beware of overwriting your existing configurations)
    (Optional) Navigate to the /configs/ directory
    (Optional) Add an entry for merx in the databases.cfg file
    (Optional) Navigate to the /merx/ directory
    (Optional) Modify the events for your game. Event files are in the format <gamedir>.events.txt
    (Optional) Modify the menus for your game. Menu files are in the format <gamedir>.<team>.menus.txt
    Start the server 

Configuration:

    Events:
		// Name of the event to hook
		"player_death"
			{
				// Message to be sent to the selected client(s)
				"format"            "You earned {olive}2{default} points for killing %N."
				// Event keys to use in the format
				"formatkeys"
				{
					// Key is the event key, value is the field type
					//     Use %d for short, byte or long
					//     Use %f for float
					//     Use %b for bool
					//     Use %s for string
					// Additional field types
					//     Any field that has a client (userid, attacker, victim, etc) can use the client fieldtype
					//    Use %N or %L for clients
					//    Any field that has a team number (winner) can use the team fieldtype
					//    Use %s for teams
					// Additional information can be found at: http://wiki.alliedmods.net/Format_Class_Functions_%28SourceMod_Scripting%29
					"userid"        "client"
				}
				// If this format string is a translation string, set this to 1
				"translated"        "0"
				// This is the target to be rewarded for completing this event
				"rewardtarget"        "attacker"
				// Do NOT reward the target if this field matches the target field
				"rewardifnotequals"    "userid"
				// Reward the player's entire team for completing this event
				"rewardteam"        "0"
				// The amount of points to reward the player
				"reward"            "5"
				// Whether to notify all players or just the players being rewarded
				"notifyall"            "0"
			}

Important Links:

    Github: http://github.com/necavi/merx/
    Jenkins: http://ci.0xf.org/job/merx/
    Latest Build: http://ci.0xf.org/job/Merx/lastBuild/
    Original Inspiration: https://forums.alliedmods.net/showthread.php?t=110229
    List of Source events: http://wiki.alliedmods.net/Game_Events_%28Source%29 