#include <sourcemod>

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
new Handle:g_hDatabase = INVALID_HANDLE;
new g_iPlayerPoints[MAXPLAYERS + 2];
new g_iPlayerID[MAXPLAYERS + 2];
new g_iDefaultPoints = 10;
public APLRes:AskPluginLoad2(Handle:plugin, bool:late, String:error[], err_max) 
{
	CreateNative("GivePlayerPoints", Native_GivePlayerPoints);
	CreateNative("TakePlayerPoints", Native_TakePlayerPoints);
	CreateNative("SetPlayerPoints", Native_SetPlayerPoints);
	CreateNative("GetPlayerPoints", Native_GetPlayerPoints);
	CreateNative("ResetPlayerPoints", Native_ResetPlayerPoints);
	g_hEventOnPrePlayerPointChange = CreateGlobalForward("OnPrePlayerPointsChange", ET_Hook, Param_Cell, Param_Cell, Param_CellByRef);
	g_hEventOnPlayerPointChange = CreateGlobalForward("OnPlayerPointsChange", ET_Event, Param_Cell, Param_Cell, Param_Cell);
	g_hEventOnPlayerPointChanged = CreateGlobalForward("OnPlayerPointsChanged", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hEventOnDatabaseReady = CreateGlobalForward("OnDatabaseReady", ET_Ignore, Param_Cell);
	return APLRes_Success;
}
public OnPluginStart()
{
	g_hCvarDefaultPoints = CreateConVar("pts_default_points","10","Sets the default number of points to give players.",FCVAR_PLUGIN, true, 0.0);
	HookConVarChange(g_hCvarDefaultPoints, ConVar_DefaultPoints);
	SQL_TConnect(SQLCallback_DBConnect, "merx");
}
public OnClientPutInServer(client) 
{
	g_iPlayerPoints[client] = 0;
	g_iPlayerID[client] = -1;
}
public OnClientAuthorized(client, const String:auth[]) 
{
	new String:query[256];
	Format(query, sizeof(query), "SELECT `a`.`player_id`, `b`.`player_points` FROM `merx_players` AS `a` LEFT JOIN `merx_points` AS `b` ON `a`.`player_id` = `b`.`player_id` WHERE `a`.`player_steamid` = '%s';", auth);
	//SQL_TQuery(g_hDatabase, SQLCallback_Connect, query, client);
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
			SQL_FetchRow(hndl);
			g_iPlayerID[client] = SQL_FetchInt(hndl, 0);
			g_iPlayerPoints[client] = SQL_FetchInt(hndl, 1);
		} 
		else 
		{
			new String:query[256];
			new String:auth[32];
			GetClientAuthString(client, auth, sizeof(auth));
			Format(query, sizeof(query), "INSERT INTO `merx_players` (`player_steamid`, `player_name`) VALUES ('%s', '%N');",auth, client);
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
		g_iPlayerID[client] = SQL_GetInsertId(hndl);
		new String:query[256];
		Format(query, sizeof(query), "INSERT INTO `merx_points` (`player_id`, `player_points`, `player_joindate`) VALUES('%d', '%d', NOW());",g_iPlayerID[client], g_iPlayerPoints[client]);
		SQL_TQuery(g_hDatabase, SQLCallback_Void, query);
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
		new String:query[512];
		Format(query, sizeof(query),"DROP TABLE `merx_players`;");
		Format(query, sizeof(query),"DROP TABLE `merx_points`;");
		SQL_Query(g_hDatabase, query);
		Format(query, sizeof(query),"CREATE TABLE IF NOT EXISTS `merx_players` ( \
			`player_id` int(10) unsigned NOT NULL AUTO_INCREMENT, \
			`player_steamid` varchar(32) NOT NULL, \
			`player_name` varchar(32) NOT NULL, \
			`player_joindate` timestamp NULL, \
			`player_lastseen` timestamp NULL ON UPDATE NOW(), \
			PRIMARY KEY (`player_id`) \
			)");
		SQL_TQuery(g_hDatabase, SQLCallback_CreatePlayerTable, query);
	}
}
public SQLCallback_CreatePointsTable(Handle:db, Handle:hndl, const String:error[], any:data) 
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Error creating points table. %s.", error);
	}
	if(g_hDatabase != INVALID_HANDLE) 
	{
		Call_StartForward(g_hEventOnDatabaseReady);
		Call_PushCell(g_hDatabase);
		Call_Finish();
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
		new String:query[256];
		Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS `merx_points` ( \
			`player_id` int(10) unsigned NOT NULL, \
			`player_points` int(11) DEFAULT NULL, \
			PRIMARY KEY (`player_id`) \
			) ENGINE=MyISAM DEFAULT CHARSET=latin1");
		SQL_TQuery(g_hDatabase, SQLCallback_CreatePointsTable,query);
	}
}
public ConVar_DefaultPoints(Handle:convar, String:oldValue[], String:newValue[]) 
{
	new value = StringToInt(newValue);
	if(value == 0) 
	{
		LogError("Invalid value for pts_default_points");
	} 
	else 
	{
		g_iDefaultPoints = value;
	}
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







