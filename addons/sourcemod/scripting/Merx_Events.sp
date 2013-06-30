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

public APLRes:AskPluginLoad2(Handle:plugin, bool:late, String:error[], err_max) 
{
	CreateNative("CreateCustomEvent", Native_CreateCustomEvent);
	CreateNative("SetCustomEventString", Native_SetCustomEventString);
	CreateNative("SetCustomEventBool", Native_SetCustomEventNum);
	CreateNative("SetCustomEventInt", Native_SetCustomEventNum);
	CreateNative("SetCustomEventFloat", Native_SetCustomEventFloat);
	CreateNative("FireCustomEvent", Native_FireCustomEvent);
	return APLRes_Success;
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
HandleEvent(Handle:event, const String:name[], bool:isCustom)
{
	new Handle:kv = g_hEvents;
	KvRewind(kv);
	KvJumpToKey(kv, name);
	new String:szFormat[1024];
	KvGetString(kv, "format", szFormat, sizeof(szFormat));
	new String:szKey[64];
	KvGetString(kv, "rewardtarget", szKey, sizeof(szKey), "userid");
	new String:szNotEquals[64];
	KvGetString(kv, "rewardifnotequals", szNotEquals, sizeof(szNotEquals));
	if(isCustom)
	{
		if(KvGetNum(event, szKey) == KvGetNum(event, szNotEquals))
		{
			return;
		}
	}
	else
	{
		if(GetEventInt(event, szKey) == GetEventInt(event, szNotEquals))
		{
			return;
		}
	}
	new reward = KvGetNum(kv, "reward");
	if(KvGetNum(kv, "rewardteam"))
	{
		new team;
		if(StrEqual(szKey, "team"))
		{
			if(isCustom)
			{
				team = KvGetNum(event, "team");
			}
			else
			{
				team = GetEventInt(event, "team");
			}
		}
		else if(StrEqual(szKey, "winner"))
		{
			if(isCustom)
			{
				team = KvGetNum(event, "winner");
			}
			else
			{
				team = GetEventInt(event, "winner");
			}
		}
		else
		{
			if(isCustom)
			{
				team = GetClientTeam(GetClientOfUserId(KvGetNum(event, szKey)));
			}
			else
			{
				team = GetClientTeam(GetClientOfUserId(GetEventInt(event, szKey)));
			}
		}
		if(team >= 2)
		{
			new bool:notify = bool:!KvGetNum(kv, "notifyall");
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsValidPlayer(i) && GetClientTeam(i) == team)
				{
					GivePlayerPoints(i, reward);
					if(notify)
					{
						NotifyPlayers(i, szFormat, kv, event, isCustom);
					}
				}
			}
			if(!notify)
			{
				NotifyPlayers(0, szFormat, kv, event, isCustom);
			}
		}
		else
		{
			return;
		}
	}
	else
	{
		new client;
		if(isCustom)
		{
			client = GetClientOfUserId(KvGetNum(event, szKey));
		}
		else
		{
			client = GetClientOfUserId(GetEventInt(event, szKey));
		}
		GivePlayerPoints(client, reward);
		if(KvGetNum(kv, "notifyall"))
		{
			NotifyPlayers(0, szFormat, kv, event, isCustom);
		}
		else
		{
			NotifyPlayers(client, szFormat, kv, event, isCustom);
		}
	}	
}
public Event_Callback(Handle:event, const String:name[], bool:dontBroadcast)
{
	HandleEvent(event, name, false);
}
NotifyPlayers(client, const String:szFormat[], Handle:kv, Handle:event, bool:isCustom)
{
	new any:args[16];
	if(client == 0)
	{
		Call_StartFunction(INVALID_HANDLE, WrappedPrintToChatAll);
	}
	else
	{
		Call_StartFunction(INVALID_HANDLE, WrappedPrintToChat);
		Call_PushCell(client);
	}
	Call_PushString(szFormat);
	if(KvGetNum(kv, "translated"))
	{
		Call_PushCell(client);
	}
	if(KvJumpToKey(kv, "formatkeys") && KvGotoFirstSubKey(kv, false))
	{
		new String:szKey[64];
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
			if(StrEqual(szType, "short") || StrEqual(szType, "byte") || StrEqual(szType, "long") || StrEqual(szType, "int"))
			{
				if(isCustom)
				{
					args[i] = KvGetNum(event, szKey);
				}
				else
				{
					args[i] = GetEventInt(event, szKey);
				}
				Call_PushCellRef(args[i]);
			}
			else if(StrEqual(szType, "client"))
			{
				if(isCustom)
				{
					args[i] = GetClientOfUserId(KvGetNum(event, szKey));
				}
				else
				{
					args[i] = GetClientOfUserId(GetEventInt(event, szKey));
				}
				Call_PushCellRef(args[i]);
			}
			else if(StrEqual(szType, "float"))
			{
				if(isCustom)
				{
					args[i] = KvGetFloat(event, szKey);
				}
				else
				{
					args[i] = GetEventFloat(event, szKey);
				}
				Call_PushCellRef(args[i]);
			}
			else if(StrEqual(szType, "bool"))
			{
				if(isCustom)
				{
					args[i] = KvGetNum(event, szKey);
				}
				else
				{
					args[i] = GetEventBool(event, szKey);
				}
				Call_PushCellRef(args[i]);
			}
			else if(StrEqual(szType, "team"))
			{
				new String:szBuffer[32];
				if(isCustom)
				{
					GetTeamName(KvGetNum(event, szKey), szBuffer, sizeof(szBuffer));
				}
				else
				{
					GetTeamName(GetEventInt(event, szKey), szBuffer, sizeof(szBuffer));
				}
				Call_PushString(szBuffer);
			}
			else if(StrEqual(szType, "string"))
			{
				new String:szBuffer[256];
				if(isCustom)
				{
					KvGetString(event, szKey, szBuffer, sizeof(szBuffer));
				}
				else
				{
					GetEventString(event, szKey, szBuffer, sizeof(szBuffer));
				}
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
	MerxPrintToChatAll("%s", szBuffer);
}
public WrappedPrintToChat(client, const String:format[], any:...)
{
	new String:szBuffer[1024];
	VFormat(szBuffer, sizeof(szBuffer), format, 3);
	MerxPrintToChat(client, "%s", szBuffer);
}
public Native_CreateCustomEvent(Handle:plugin, numParams)
{
	new length;
	GetNativeStringLength(1, length);
	new String:name[length];
	return _:CreateKeyValues(name);
}
public Native_SetCustomEventString(Handle:plugin, numParams)
{
	new length;
	GetNativeStringLength(2, length);
	new String:key[length];
	GetNativeString(2, key, length);
	GetNativeStringLength(3, length);
	new String:value[length];
	GetNativeString(3, value, length);
	KvSetString(GetNativeCell(1), key, value);
}
public Native_SetCustomEventNum(Handle:plugin, numParams)
{
	new length;
	GetNativeStringLength(2, length);
	new String:key[length];
	GetNativeString(2, key, length);
	KvSetNum(GetNativeCell(1), key, GetNativeCell(3));
}
public Native_SetCustomEventFloat(Handle:plugin, numParams)
{
	new length;
	GetNativeStringLength(2, length);
	new String:key[length];
	GetNativeString(2, key, length);
	KvSetFloat(GetNativeCell(1), key, GetNativeCell(3));
}
public Native_FireCustomEvent(Handle:plugin, numParams)
{
	new String:name[256];
	KvGetSectionName(GetNativeCell(1), name, sizeof(name));
	HandleEvent(Handle:GetNativeCell(1), name, true);
}




