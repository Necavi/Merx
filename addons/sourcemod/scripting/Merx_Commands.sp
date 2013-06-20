#include <sourcemod>
#include <sdktools>
#include "include/Merx"

public Plugin:myinfo = 
{
	name = "Merx Commands",
	author = "necavi",
	description = "Adds useful commands for Merx",
	version = MERX_BUILD,
	url = "http://necavi.org/>"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_points", ConCmd_Points, "Displays your current points to chat.");
	RegConsoleCmd("sm_merxmenu", ConCmd_MerxMenu);
	RegConsoleCmd("giveitem", ConCmd_GiveItem, "Give item to player.", FCVAR_CHEAT);
}

public Action:ConCmd_Points(client, args)
{
	if(client > 0)
	{
		CReplyToCommand(client, "%sYou have {olive}%d{default} points.", MERX_TAG, GetPlayerPoints(client));
	}
	else
	{
		CReplyToCommand(client, "%sThe server is unable to use points.", MERX_TAG);
	}
	return Plugin_Handled;
}
public Action:ConCmd_MerxMenu(client, args) 
{
	ShowPlayerMenu(client);
	return Plugin_Handled;
}
public Action:ConCmd_GiveItem(client, args) 
{
	new String:item[64];
	GetCmdArg(1, item, sizeof(item));
	PrintToServer("GiveItem: %s", item);
	GivePlayerItem(client, item);
	return Plugin_Handled;
}


