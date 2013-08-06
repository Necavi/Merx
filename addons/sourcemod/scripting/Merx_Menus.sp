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

new Handle:g_hCvarConfirmationMenu = INVALID_HANDLE;

new Handle:g_hEventMenuItemDrawn = INVALID_HANDLE;

new bool:g_bConfirmationMenu = true;

new g_iLastPurchasePrice[MAXPLAYERS + 2];

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("RefundLastPurchase", Native_RefundLastPurchase);
	return APLRes_Success;
}
public OnPluginStart()
{
	LoadTranslations("merx.core");
	RegConsoleCmd("sm_merxmenu", ConCmd_MerxMenu, "Displays the points menu.");
	g_hCvarConfirmationMenu = CreateConVar("merx_confirmationmenu", "1", "Enables or disables the confirmation menu when buying items.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(g_hCvarConfirmationMenu, Convar_ConfirmationMenu);
	g_bConfirmationMenu = GetConVarBool(g_hCvarConfirmationMenu);
	g_hEventMenuItemDrawn = CreateGlobalForward("OnMerxItemDrawn", ET_Hook, Param_Cell, Param_String, Param_Cell, Param_String, Param_String);
}
public OnClientConnected(client)
{
	g_iLastPurchasePrice[client] = 0;
}
public OnMapStart()
{
	LoadMenus();	
}
public Native_RefundLastPurchase(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	GivePlayerPoints(client, g_iLastPurchasePrice[client]);
}
public Convar_ConfirmationMenu(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bConfirmationMenu = bool:StringToInt(newValue);
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
		MerxReplyToCommand(client, "%T", "unable_to_use_points", client);
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
				PurchaseItem(client);
			} 
			ShowPreviousMenu(client);
		}
	}
}
ShowMenu(client) 
{
	new Handle:kv = GetClientKv(client);
	new String:title[32];
	KvGetSectionName(kv, title, sizeof(title));
	new Handle:menu;
	if(KvGotoFirstSubKey(kv))
	{
		menu = CreateMenu(MenuHandler_Items);
		SetMenuExitBackButton(menu, true);
		SetMenuTitle(menu, "%T", "menu_title_shop_main", client, title, GetPlayerPoints(client));
		new String:name[32];
		new String:display[64];
		do
		{
			KvGetSectionName(kv, name, sizeof(name));
			name[0] = CharToUpper(name[0]);
			if(IsKeyCategory(kv)) 
			{
				AddMenuItem(menu, name, name);
			} 
			else if(KvGetNum(kv, "enabled", 1))
			{
				Format(display, sizeof(display), "%s ($%d)", name, KvGetNum(kv, "price", 100));
				new String:commandArgs[256];
				new String:command[1][64];
				new Action:result;
				Call_StartForward(g_hEventMenuItemDrawn);
				Call_PushCell(client);
				Call_PushStringEx(display, sizeof(display), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
				Call_PushCell(sizeof(display));
				KvGetString(kv, "command", commandArgs, sizeof(commandArgs));
				ExplodeString(commandArgs, " ", command, sizeof(command), sizeof(command[]));
				Call_PushString(command[0]);
				Call_PushString(commandArgs);
				Call_Finish(result);
				if(result == Plugin_Continue || result == Plugin_Changed)
				{
					AddMenuItem(menu, name, display, (GetPlayerPoints(client) >= KvGetNum(kv, "price", 100)) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
				}
			}
		} while(KvGotoNextKey(kv));
		KvGoBack(kv);
		if(GetMenuItemCount(menu) == 0)
		{
			GetMenuTitle(menu, display, sizeof(display));
			SetMenuTitle(menu, "%T", "menu_title_no_items_found", client, display);
		}
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	} 
	else 
	{
		if(g_bConfirmationMenu)
		{
			menu = CreateMenu(MenuHandler_Confirm);
			SetMenuTitle(menu, "%T", "menu_title_confirm_buy", client, GetPlayerPoints(client), title, KvGetNum(kv, "price", 100), (KvGetNum(kv, "price", 100) != 1) ? "points" : "point");
			new String:item[16];
			Format(item, sizeof(item), "%T", "yes", client);
			AddMenuItem(menu, "yes", item);
			Format(item, sizeof(item), "%T", "no", client);
			AddMenuItem(menu, "no", item);
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
		}
		else
		{
			PurchaseItem(client);
			ShowPreviousMenu(client);
		}
	}
}
PurchaseItem(client)
{
	new Handle:kv = GetClientKv(client);
	new bool:enabled = bool:KvGetNum(kv, "enabled", 1);
	if(enabled)
	{
		new price = KvGetNum(kv, "price", 100);
		if(price <= GetPlayerPoints(client))
		{
			g_iLastPurchasePrice[client] = price;
			new String:type[16];
			new String:command[256];
			new String:szBuffer[16];
			KvGetString(kv, "command", command, sizeof(command));
			KvGetString(kv, "type", type, sizeof(type), "server");
			new flags = RemoveCommandCheatFlag(command);
			IntToString(GetClientUserId(client), szBuffer, sizeof(szBuffer));
			ReplaceString(command, sizeof(command), "{userid}", szBuffer);
			IntToString(client, szBuffer, sizeof(szBuffer));
			ReplaceString(command, sizeof(command), "{client}", szBuffer);
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
			for(new client = 1; client <= MaxClients; client++)
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
	new String:buffer[1][64];
	ExplodeString(command, " ", buffer, sizeof(buffer), sizeof(buffer[]));
	new flags = GetCommandFlags(buffer[0]);
	SetCommandFlags(buffer[0], flags & ~FCVAR_CHEAT);
	return flags;
}	

RestoreCommandFlags(const String:command[], flags = 0)
{
	new String:buffer[1][64];
	ExplodeString(command, " ", buffer, sizeof(buffer), sizeof(buffer[]));
	SetCommandFlags(buffer[0], flags);
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




