#include <sourcemod>
//#include "include/Merx"

public Plugin:myinfo = 
{
	name = "Merx Events System",
	author = "necavi",
	description = "Rewards players with points for certain events",
	version = "0.1",
	url = "http://necavi.org"
}

new Handle:g_hEvents = INVALID_HANDLE;
new Handle:g_hEventsCustom = INVALID_HANDLE;

public OnPluginStart()
{
	PrintToServer("Loading plugin Merx Events");
	//LoadTranslations("merx.events");
	new String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "translations/merx.events.translations.txt")
	if(FileExists(path))
	{
		LoadTranslations("merx.events.translations");
	}
	PrintToServer("Loading events for Merx Events");
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
	BuildPath(Path_SM, path, sizeof(path), "configs/merx.events.cfg");
	FileToKeyValues(g_hEvents, path);
	HookEvents(g_hEvents);
	if(g_hEventsCustom != INVALID_HANDLE)
	{
		CloseHandle(g_hEventsCustom);
	}
	g_hEventsCustom = CreateKeyValues("custom_events");
	FileToKeyValues(g_hEventsCustom, "configs/merx.events.custom.cfg");
	HookEvents(g_hEventsCustom);
}
HookEvents(Handle:events)
{
	KvRewind(events);
	if(KvGotoFirstSubKey(events))
	{
		PrintToServer("Hooking events");
		new String:name[64];
		do
		{
			KvGetSectionName(events, name, sizeof(name));
			HookEvent(name, Event_Callback);
			PrintToServer("Hooking event: %s", name);
		} while(KvGotoNextKey(events));
	}
}
public Event_Callback(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Handle:kv = GetEventKeyValue(name);
	new String:szFormat[1024];
	KvGetString(kv, "format", szFormat, sizeof(szFormat));
	Call_StartFunction(INVALID_HANDLE, WrappedPrintToChatAll);
	Call_PushString(szFormat);
	if(KvJumpToKey(kv, "formatkeys") && KvGotoFirstSubKey(kv, false))
	{
		new String:szKey[64]
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
			if(StrEqual(szType, "short") || StrEqual(szType, "byte"))
			{
				new userid = GetEventInt(event, szKey);
				PrintToServer("%d", userid);
				Call_PushCellRef(userid);
			}
			PrintToServer("Key: %s Value: %s", szKey, szType);
		}
	}
	Call_Finish();
}
Handle:GetEventKeyValue(const String:name[])
{
	KvRewind(g_hEvents);
	if(KvJumpToKey(g_hEvents, name))
	{
		return g_hEvents;
	}
	else
	{
		KvRewind(g_hEventsCustom);
		KvJumpToKey(g_hEventsCustom, name);
		return g_hEventsCustom;
	}
}

public WrappedPrintToChatAll(const String:format[], any:...)
{
	new String:szBuffer[1024];
	VFormat(szBuffer, sizeof(szBuffer), format, 2);
	PrintToChatAll("%s", szBuffer);
}







