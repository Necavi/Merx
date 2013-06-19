#include <sourcemod>
#include "include/Merx"

public Plugin:myinfo = 
{
	name = "Merx Points System",
	author = "necavi",
	description = "Tracks player points",
	version = "0.1",
	url = "http://necavi.org"
}
new Handle:g_hEventOnPrePlayerPointChange = INVALID_HANDLE;
new Handle:g_hEventOnPlayerPointChange = INVALID_HANDLE;
new Handle:g_hEventOnPlayerPointChanged = INVALID_HANDLE;
new Handle:g_hEventOnDatabaseReady = INVALID_HANDLE;
new Handle:g_hCvarDefaultPoints = INVALID_HANDLE;
new Handle:g_hCvarSaveTimer = INVALID_HANDLE;
new Handle:g_hDatabase = INVALID_HANDLE;

new g_iPlayerPoints[MAXPLAYERS + 2];
new g_iPlayerID[MAXPLAYERS + 2];
new g_iDefaultPoints;

new DBType:g_DatabaseType;

public APLRes:AskPluginLoad2(Handle:plugin, bool:late, String:error[], err_max) 
{
	CreateNative("GivePlayerPoints", Native_GivePlayerPoints);
	CreateNative("TakePlayerPoints", Native_TakePlayerPoints);
	CreateNative("SetPlayerPoints", Native_SetPlayerPoints);
	CreateNative("GetPlayerPoints", Native_GetPlayerPoints);
	CreateNative("SavePlayerPoints", Native_SavePlayerPoints);
	CreateNative("ResetPlayerPoints", Native_ResetPlayerPoints);
	g_hEventOnPrePlayerPointChange = CreateGlobalForward("OnPrePlayerPointsChange", ET_Hook, Param_Cell, Param_Cell, Param_CellByRef);
	g_hEventOnPlayerPointChange = CreateGlobalForward("OnPlayerPointsChange", ET_Event, Param_Cell, Param_Cell, Param_Cell);
	g_hEventOnPlayerPointChanged = CreateGlobalForward("OnPlayerPointsChanged", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hEventOnDatabaseReady = CreateGlobalForward("OnDatabaseReady", ET_Ignore, Param_Cell, Param_Cell);
	return APLRes_Success;
}
public OnPluginStart()
{
	g_hCvarDefaultPoints = CreateConVar("merx_default_points", "10", "Sets the default number of points to give players.", FCVAR_PLUGIN, true, 0.0);
	g_iDefaultPoints = GetConVarInt(g_hCvarDefaultPoints);
	HookConVarChange(g_hCvarDefaultPoints, ConVar_DefaultPoints);
	g_hCvarSaveTimer = CreateConVar("merx_save_timer", "300", "Sets the duration between automatic saves.", FCVAR_PLUGIN);
	CreateTimer(GetConVarFloat(g_hCvarSaveTimer), Timer_SavePoints);
	if(SQL_CheckConfig("merx"))
	{
		SQL_TConnect(SQLCallback_DBConnect, "merx");
	}
	else
	{
		SQL_TConnect(SQLCallback_DBConnect);
	}
}
public OnClientConnected(client) 
{
	g_iPlayerPoints[client] = 0;
	g_iPlayerID[client] = -1;
}
public OnClientDisconnect(client)
{
	SaveClientPoints(client);
}
public OnClientAuthorized(client, const String:auth[]) 
{
	if(!IsFakeClient(client))
	{
		new String:query[256];
		Format(query, sizeof(query), "SELECT `player_id`, `player_points` FROM `merx_players` WHERE `player_steamid` = '%s';", auth);
		SQL_TQuery(g_hDatabase, SQLCallback_Connect, query, client);
	}
}
public SQLCallback_Connect(Handle:db, Handle:hndl, const String:error[], any:client) 
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Error selecting player. %s.", error);
	} 
	else 
	{
		if(SQL_GetRowCount(hndl)>0) 
		{
			PrintToServer("Retrieving old player %N", client);
			SQL_FetchRow(hndl);
			g_iPlayerID[client] = SQL_FetchInt(hndl, 0);
			g_iPlayerPoints[client] += SQL_FetchInt(hndl, 1);
		} 
		else 
		{
			PrintToServer("Adding new player %N", client);
			new String:query[128];
			Format(query, sizeof(query), "SELECT max(`player_id`) FROM `merx_players`;");
			SQL_TQuery(g_hDatabase, SQLCallback_NewPlayer, query, client);
		}
	}
}
public SQLCallback_NewPlayer(Handle:db, Handle:hndl, const String:error[], any:client) 
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Error inserting new player. %s.", error);
	} 
	else 
	{
		SQL_FetchRow(hndl);
		g_iPlayerID[client] = SQL_FetchInt(hndl, 0) + 1;
		PrintToServer("client: %N g_iPlayerID: %d max(`player_id`): %d", client, g_iPlayerID[client], SQL_FetchInt(hndl, 0));
		new String:query[512];
		new String:auth[32];
		GetClientAuthString(client, auth, sizeof(auth));
		g_iPlayerPoints[client] += g_iDefaultPoints;
		Format(query, sizeof(query), "INSERT INTO `merx_players` (`player_id`, `player_steamid`, `player_name`, `player_points`, `player_joindate`) VALUES ('%d', '%s', '%N', '%d', CURRENT_TIMESTAMP);", g_iPlayerID[client], auth, client, g_iPlayerPoints[client]);
		SQL_TQuery(g_hDatabase, SQLCallback_Void, query, client);
	}
}
public SQLCallback_Void(Handle:db, Handle:hndl, const String:error[], any:client) 
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("Error during SQL query. %s", error);
	}
}
public SQLCallback_DBConnect(Handle:db, Handle:hndl, const String:error[], any:data) 
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Error connecting to database. %s.", error);
	} 
	else 
	{
		g_hDatabase = hndl;
		new String:ident[32];
		SQL_GetDriverIdent(SQL_ReadDriver(g_hDatabase), ident, sizeof(ident));
		if(StrEqual("mysql", ident, false))
		{
			g_DatabaseType = DB_MySQL;
		}
		else if(StrEqual("sqlite", ident, false))
		{
			g_DatabaseType = DB_SQLite;
		}
		new String:query[512];
		Format(query, sizeof(query),"CREATE TABLE IF NOT EXISTS `merx_players` ( \
			`player_id` INTEGER UNSIGNED PRIMARY KEY, \
			`player_steamid` VARCHAR(32) NOT NULL, \
			`player_name` VARCHAR(32) NOT NULL, \
			`player_joindate` TIMESTAMP NULL, \
			`player_lastseen` TIMESTAMP NULL, \
			`player_points` INT NOT NULL \
			);");
		SQL_TQuery(g_hDatabase, SQLCallback_CreatePlayerTable, query);
	}
}
public SQLCallback_CreatePlayerTable(Handle:db, Handle:hndl, const String:error[], any:data) 
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Error creating player table. %s.", error);
	} 
	else
	{
		new String:query[512];
		Format(query, sizeof(query), "CREATE TRIGGER IF NOT EXISTS [UpdateLastTime] \
			AFTER UPDATE \
			ON `merx_players` \
			FOR EACH ROW \
			BEGIN \
			UPDATE `merx_players` SET `player_lastseen` = CURRENT_TIMESTAMP WHERE `player_id` = old.`player_id`; \
			END");
		SQL_TQuery(g_hDatabase, SQLCallback_CreateUpdateTrigger, query);
	}
}
public SQLCallback_CreateUpdateTrigger(Handle:db, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("Error creating update trigger. %s.", error);
	}
	else
	{
		
		Call_StartForward(g_hEventOnDatabaseReady);
		Call_PushCell(g_hDatabase);
		Call_PushCell(g_DatabaseType);
		Call_Finish();
	}
}
public Action:Timer_SavePoints(Handle:timer)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidPlayer(i))
		{
			SaveClientPoints(i);
		}
	}
	CreateTimer(GetConVarFloat(g_hCvarSaveTimer), Timer_SavePoints);
}
public ConVar_DefaultPoints(Handle:convar, String:oldValue[], String:newValue[]) 
{
	new value = StringToInt(newValue);
	if(value == 0) 
	{
		LogError("Invalid value for merx_default_points");
	} 
	else 
	{
		g_iDefaultPoints = value;
	}
}
public Native_SavePlayerPoints(Handle:plugin, args)
{
	new client = GetNativeCell(1);
	SaveClientPoints(client);
}
public Native_GivePlayerPoints(Handle:plugin, args) 
{
	new client = GetNativeCell(1);
	SetClientPoints(client, GetClientPoints(client) + GetNativeCell(2));
}
public Native_TakePlayerPoints(Handle:plugin, args) 
{
	new client = GetNativeCell(1);
	SetClientPoints(client, GetClientPoints(client) - GetNativeCell(2));
}
public Native_SetPlayerPoints(Handle:plugin, args) 
{
	SetClientPoints(GetNativeCell(1), GetNativeCell(2));	
}
public Native_GetPlayerPoints(Handle:plugin, args) 
{
	return GetClientPoints(GetNativeCell(1));
}
public Native_ResetPlayerPoints(Handle:plugin, args) 
{
	SetClientPoints(GetNativeCell(1), g_iDefaultPoints);
}
SaveClientPoints(client)
{
	PrintToServer("Saving player %N with id %d", client, g_iPlayerID[client]);
	if(g_iPlayerID[client] != -1)
	{
		new String:query[256];
		Format(query, sizeof(query), "UPDATE `merx_players` SET `player_points` = '%d', `player_name` = '%N' WHERE `player_id` = '%d';", g_iPlayerPoints[client], client, g_iPlayerID[client]);
		SQL_TQuery(g_hDatabase, SQLCallback_Void, query);
	}
}
SetClientPoints(client, points) 
{
	new Action:result;
	Call_StartForward(g_hEventOnPrePlayerPointChange);
	Call_PushCell(client);
	Call_PushCell(GetClientPoints(client));
	Call_PushCellRef(points);
	Call_Finish(result);
	if(result > Plugin_Handled) 
	{
		return;
	}
	Call_StartForward(g_hEventOnPlayerPointChange);
	Call_PushCell(client);
	Call_PushCell(GetClientPoints(client));
	Call_PushCell(points);
	Call_Finish(result);
	if(result > Plugin_Handled) 
	{
		return;
	}
	new oldpoints = g_iPlayerPoints[client];
	g_iPlayerPoints[client] = points;
	Call_StartForward(g_hEventOnPlayerPointChanged);
	Call_PushCell(client);
	Call_PushCell(oldpoints);
	Call_PushCell(points);
	Call_Finish();
}
GetClientPoints(client) 
{
	return g_iPlayerPoints[client];
}







