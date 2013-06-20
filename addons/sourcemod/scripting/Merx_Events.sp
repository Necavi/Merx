#include <sourcemod>
#include <sdktools>
#include "include/Merx"

public Plugin:myinfo = 
{
	name = "Merx Events System",
	author = "necavi",
	description = "Rewards players with points for certain events",
	version = MERX_BUILD,
	url = "http://necavi.org"
}

new Handle:g_hEvents = INVALID_HANDLE;

public OnPluginStart()
{
	PrintToServer("Loading plugin Merx Events");
}
public OnMapStart()
{
	new String:path[PLATFORM_MAX_PATH];
	new String:szGameDir[64];
	GetGameFolderName(szGameDir, sizeof(szGameDir));
	Format(path, sizeof(path), "merx.%s.events.txt", szGameDir); 
	if(FileExists(path))
	{
		LoadTranslations(path);
	}
	LoadEvents();	
}
LoadEvents()
{
	new String:path[PLATFORM_MAX_PATH];
	if(g_hEvents != INVALID_HANDLE)
	{
		CloseHandle(g_hEvents);
	}
	g_hEvents = CreateKeyValues("events");
	new String:szGameDir[64];
	GetGameFolderName(szGameDir, sizeof(szGameDir));
	BuildPath(Path_SM, path, sizeof(path), "configs/merx/%s.events.txt", szGameDir);
	FileToKeyValues(g_hEvents, path);
	HookEvents(g_hEvents);
}
HookEvents(Handle:events)
{
	KvRewind(events);
	if(KvGotoFirstSubKey(events))
	{
		new String:name[64];
		do
		{
			KvGetSectionName(events, name, sizeof(name));
			HookEvent(name, Event_Callback);
		} while(KvGotoNextKey(events));
	}
}
public Event_Callback(Handle:event, const String:name[], bool:dontBroadcast)
{
	new any:args[16];
	new Handle:kv = g_hEvents;
	KvRewind(kv);
	KvJumpToKey(kv, name);
	new String:szFormat[1024];
	KvGetString(kv, "format", szFormat, sizeof(szFormat));
	new String:szKey[64];
	KvGetString(kv, "rewardtarget", szKey, sizeof(szKey), "userid");
	new String:szNotEquals[64];
	KvGetString(kv, "rewardifnotequals", szNotEquals, sizeof(szNotEquals));
	if(GetEventInt(event, szKey) == GetEventInt(event, szNotEquals))
	{
		return;
	}
	new reward = KvGetNum(kv, "reward");
	if(KvGetNum(kv, "rewardteam"))
	{
		new team;
		if(StrEqual(szKey, "team"))
		{
			team = GetEventInt(event, "team");
		}
		else if(StrEqual(szKey, "winner"))
		{
			team = GetEventInt(event, "winner");
		}
		else
		{
			team = GetClientTeam(GetClientOfUserId(GetEventInt(event, szKey)));
		}
		if(team >= 2)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsValidPlayer(i) && GetClientTeam(i) == team)
				{
					GivePlayerPoints(i, reward);
				}
			}
		}
		else
		{
			return;
		}
	}
	else
	{
		new client = GetClientOfUserId(GetEventInt(event, szKey));
		GivePlayerPoints(client, reward);
	}
	if(KvGetNum(kv, "notifyall"))
	{
		Call_StartFunction(INVALID_HANDLE, WrappedPrintToChatAll);
	}
	else
	{
		Call_StartFunction(INVALID_HANDLE, WrappedPrintToChat);
		Call_PushCell(GetClientOfUserId(GetEventInt(event, szKey)));
	}
	Call_PushString(szFormat);
	if(KvGetNum(kv, "translated"))
	{
		Call_PushCell(0);
	}
	if(KvJumpToKey(kv, "formatkeys") && KvGotoFirstSubKey(kv, false))
	{
		new String:szType[64];
		new Handle:keys = CreateArray(ByteCountToCells(64));
		do
		{
			KvGetSectionName(kv, szKey, sizeof(szKey));
			PushArrayString(keys, szKey);
		} while(KvGotoNextKey(kv, false));
		KvGoBack(kv);
		for(new i = 0; i < GetArraySize(keys); i++)
		{
			GetArrayString(keys, i, szKey, sizeof(szKey));
			KvGetString(kv, szKey, szType, sizeof(szType));
			if(StrEqual(szType, "short") || StrEqual(szType, "byte") || StrEqual(szType, "long"))
			{
				args[i] = GetEventInt(event, szKey);
				Call_PushCellRef(args[i]);
			}
			else if(StrEqual(szType, "client"))
			{
				args[i] = GetClientOfUserId(GetEventInt(event, szKey));
				Call_PushCellRef(args[i]);
			}
			else if(StrEqual(szType, "float"))
			{
				args[i] = GetEventFloat(event, szKey);
				Call_PushCellRef(args[i]);
			}
			else if(StrEqual(szType, "bool"))
			{
				args[i] = GetEventBool(event, szKey);
				Call_PushCellRef(args[i]);
			}
			else if(StrEqual(szType, "team"))
			{
				new String:szBuffer[32];
				GetTeamName(GetEventInt(event, szKey), szBuffer, sizeof(szBuffer));
				Call_PushString(szBuffer);
			}
			else if(StrEqual(szType, "string"))
			{
				new String:szBuffer[256];
				GetEventString(event, szKey, szBuffer, sizeof(szBuffer));
				Call_PushString(szBuffer);
			}
		}
	}
	Call_Finish();
}

public WrappedPrintToChatAll(const String:format[], any:...)
{
	new String:szBuffer[1024];
	VFormat(szBuffer, sizeof(szBuffer), format, 2);
	CPrintToChatAll("%s%s", MERX_TAG, szBuffer);
}
public WrappedPrintToChat(client, const String:format[], any:...)
{
	new String:szBuffer[1024];
	VFormat(szBuffer, sizeof(szBuffer), format, 3);
	CPrintToChat(client, "%s%s", MERX_TAG, szBuffer);
}







