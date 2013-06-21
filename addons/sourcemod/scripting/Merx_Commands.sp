#include <sourcemod>
#include <sdktools>
#include "include/Merx"

public Plugin:myinfo = 
{
	name = "Merx Commands",
	author = "necavi",
	description = "Adds useful commands for Merx",
	version = MERX_BUILD,
	url = "http://necavi.org/"
}
new Handle:g_hCvarCheats = INVALID_HANDLE;
public OnPluginStart()
{
	RegConsoleCmd("giveitem", ConCmd_GiveItem, "Give item to player.", FCVAR_CHEAT);
	g_hCvarCheats = FindConVar("sv_cheats");
}
public Action:ConCmd_GiveItem(client, args) 
{
	new String:item[64];
	GetCmdArg(1, item, sizeof(item));
	new String:command[64];
	GetCmdArg(0, command, sizeof(command));
	if(GetCommandFlags(command) & FCVAR_CHEAT && !GetConVarBool(g_hCvarCheats))
	{
		return Plugin_Continue;
	}
	GivePlayerItem(client, item);
	return Plugin_Handled;
}


