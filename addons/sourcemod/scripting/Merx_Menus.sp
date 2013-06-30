#include <sourcemod>
#include "include/Merx"
#include <sdktools>

public Plugin:myinfo = 
{
	name = "Merx Menu System",
	author = "necavi",
	description = "Creates menus and allows buying of items.",
	version = MERX_BUILD,
	url = "http://necavi.org/"
}

new Handle:g_hKvTeamMenus[MAXPLAYERS + 2][16];
public OnPluginStart()
{
	RegConsoleCmd("sm_merxmenu", ConCmd_MerxMenu, "Displays the points menu.");
}
public OnMapStart()
{
	LoadMenus();	
	//FindConCommand("giveitem");
}
public Action:ConCmd_MerxMenu(client, args) 
{
	if(client > 0)
	{
		KvRewind(GetClientKv(client));
		ShowMenu(client);
	}
	else
	{
		MerxReplyToCommand(client, "The server is unable to use points.");
	}
	return Plugin_Handled;
}
public MenuHandler_Items(Handle:menu, MenuAction:action, client, item) 
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if(item == MenuCancel_ExitBack) 
			{
				ShowPreviousMenu(client);
			}
		}
		case MenuAction_Select:
		{
			new String:name[32];
			GetMenuItem(menu, item, name, sizeof(name));
			KvJumpToKey(GetClientKv(client), name);
			ShowMenu(client);
		}
	}
}
public MenuHandler_Confirm(Handle:menu, MenuAction:action, client, item) 
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Select:
		{
			new String:choice[8];
			GetMenuItem(menu, item, choice, sizeof(choice));
			if(StrEqual(choice, "yes")) 
			{
				new Handle:kv = GetClientKv(client);
				new bool:enabled = bool:KvGetNum(kv, "enabled", 1);
				if(enabled)
				{
					new price = KvGetNum(kv, "price", 100);
					if(price <= GetPlayerPoints(client))
					{
						new String:type[16];
						new String:command[64];
						KvGetString(kv, "command", command, sizeof(command));
						KvGetString(kv, "type", type, sizeof(type), "client");
						new flags = RemoveCommandCheatFlag(command);
						if(StrEqual(type, "client", false)) 
						{
							FakeClientCommand(client, command);
						} 
						else 
						{
							ServerCommand(command);
						}
						RestoreCommandFlags(command, flags);
						TakePlayerPoints(client, price);
					}
				}
			} 
			else 
			{
				ShowPreviousMenu(client);
			}
		}
	}
}
ShowMenu(client) 
{
	new Handle:kv = GetClientKv(client);
	new String:title[32];
	KvGetSectionName(kv, title, sizeof(title));
	if(KvGotoFirstSubKey(kv))
	{
		new Handle:menu = CreateMenu(MenuHandler_Items);
		SetMenuExitBackButton(menu, true);
		SetMenuTitle(menu, "%s Menu\nYou have %d points", title, GetPlayerPoints(client));
		new String:name[32];
		new String:display[64];
		do
		{
			KvGetSectionName(kv, name, sizeof(name));
			if(IsKeyCategory(kv)) 
			{
				AddMenuItem(menu, name, name);
			} 
			else if(KvGetNum(kv, "enabled", 1))
			{
				Format(display, sizeof(display), "%s (%d)", name, KvGetNum(kv, "price", 100));
				AddMenuItem(menu, name, display, (GetPlayerPoints(client) >= KvGetNum(kv, "price", 100)) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
			}
		} while (KvGotoNextKey(kv));
		KvGoBack(kv);
		if(GetMenuItemCount(menu) == 0) 
		{
			GetMenuTitle(menu, display, sizeof(display));
			SetMenuTitle(menu, "%d\n\nNo items available",display);
		}
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	} 
	else 
	{
		new Handle:menu = CreateMenu(MenuHandler_Confirm);
		SetMenuTitle(menu, "Confirmation Menu\nYou have %d points\nAre you sure you would like to buy:\n %s for %d %s?", GetPlayerPoints(client), title, KvGetNum(kv, "price", 100),(KvGetNum(kv, "price", 100) != 1) ? "points" : "point");
		AddMenuItem(menu, "yes", "Yes");
		AddMenuItem(menu, "no", "No");
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}
ShowPreviousMenu(client) 
{
	new Handle:kv = GetClientKv(client);
	if(KvGoBack(kv)) 
	{
		ShowMenu(client);
	}
}
Handle:GetClientKv(client) 
{
	return g_hKvTeamMenus[client][GetClientTeam(client)];
}
bool:IsKeyCategory(Handle:kv) 
{
	new bool:value = KvGotoFirstSubKey(kv);
	if(value) 
	{
		KvGoBack(kv);
	}
	return value;
}
LoadMenus() 
{
	new max_teams_count = GetTeamCount();
	new String:team_name[64];
	new String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	String_ToLower(game_name, game_name, sizeof(game_name));
	new String:file[PLATFORM_MAX_PATH];
	new Handle:kv;
	for (new team_index = 0; (team_index < max_teams_count); team_index++)
	{
		GetTeamName(team_index, team_name, sizeof(team_name));
		String_ToLower(team_name, team_name, sizeof(team_name));
		BuildPath(Path_SM, file, sizeof(file), "configs/merx/%s.%s.menu.txt", game_name, team_name);
		kv = CreateKeyValues(team_name);
		if(FileExists(file))
		{
			FileToKeyValues(kv, file);
			CleanInvalidCommands(kv);
			KvRewind(kv);
			for(new client = 1; client < MaxClients; client++)
			{
				if(g_hKvTeamMenus[client][team_index] != INVALID_HANDLE)
				{
					CloseHandle(g_hKvTeamMenus[client][team_index]);
				}
				g_hKvTeamMenus[client][team_index] = CreateKeyValues(team_name);
				KvCopySubkeys(kv, g_hKvTeamMenus[client][team_index]);
			}
		}
		CloseHandle(kv);
	}
}
CleanInvalidCommands(Handle:kv)
{
	if(KvGotoFirstSubKey(kv))
	{
		new String:section[32];
		new String:command[256];
		new String:commandname[1][32];
		do
		{
			if(IsKeyCategory(kv)) 
			{
				CleanInvalidCommands(kv);
			} 
			else 
			{
				KvGetSectionName(kv, section, sizeof(section));
				KvGetString(kv, "command", command, sizeof(command));
				ExplodeString(command, " ", commandname, sizeof(commandname), sizeof(commandname[]));
				if(!FindConCommand(commandname[0]))
				{
					KvSetNum(kv, "enabled", 0);
				}
			}
		} while (KvGotoNextKey(kv));
		KvGoBack(kv);
	} 	
}
RemoveCommandCheatFlag(const String:command[])
{
	new String:buffer[1][32];
	ExplodeString(command, " ", buffer, sizeof(buffer), sizeof(buffer[]));
	new flags = GetCommandFlags(buffer[0]);
	SetCommandFlags(buffer[0], flags & ~FCVAR_CHEAT);
	return flags;
}	

RestoreCommandFlags(const String:command[], flags = 0)
{
	new String:buffer[1][32];
	ExplodeString(command, " ", buffer, sizeof(buffer), sizeof(buffer[]));
	SetCommandFlags(buffer[0], flags);
}	
// Taken from SMLib
stock String_ToLower(const String:input[], String:output[], size)
{
	size--;
	new x=0;
	while (input[x] != '\0' || x < size) 
	{
		if (IsCharUpper(input[x])) 
		{
			output[x] = CharToLower(input[x]);
		}
		else 
		{
			output[x] = input[x];
		}
		
		x++;
	}
	output[x] = '\0';
}
bool:FindConCommand(const String:command[])
{
	new String:buffer[256];
	new bool:isCommand;
	new Handle:iter = GetCommandIterator();
	if(iter != INVALID_HANDLE)
	{
		while(ReadCommandIterator(iter, buffer, sizeof(buffer)))
		{
			if(StrEqual(command, buffer, false))
			{
				CloseHandle(iter);
				return true;
			}
		}
		CloseHandle(iter);
	}
	iter = FindFirstConCommand(buffer, sizeof(buffer), isCommand);
	if(iter != INVALID_HANDLE)
	{
		do
		{
			if(StrEqual(command, buffer, false))
			{
				CloseHandle(iter);
				return true;
			}
		} while(FindNextConCommand(iter, buffer, sizeof(buffer), isCommand));
		CloseHandle(iter);
	}
	return false;
}




