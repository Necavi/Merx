#pragma semicolon 1

#include <sourcemod>
#include <morecolors>

#define MERX_BUILD "CUSTOM"
/*
* 
* Merx_Events.sp natives
* 
*/

native Handle:CreateCustomEvent(const String:name[]);
native SetCustomEventString(Handle:event, const String:key[], const String:value[]);
native SetCustomEventInt(Handle:event, const String:key[], value);
native SetCustomEventBool(Handle:event, const String:key[], bool:value);
native SetCustomEventFloat(Handle:event, const String:key[], Float:value);
native FireCustomEvent(Handle:event);

/*
* 
* Merx_Points.sp natives
* 
*/
native MerxPrintToChat(client, const String:fmt[], any:...);
native MerxPrintToChatAll(const String:fmt[], any:...);
native MerxReplyToCommand(client, const String:fmt[], any:...);
native GivePlayerPoints(client, points);
native TakePlayerPoints(client, points);
native SetPlayerPoints(client, points);
native GetPlayerPoints(client);
native ResetPlayerPoints(client);
native SavePlayerPoints(client);
native Handle:GetDatabaseHandle();
native ValveGame:GetGame();
forward Action:OnPrePlayerPointsChange(client, oldPoints, &newPoints);
forward Action:OnPlayerPointsChange(client, oldPoints, newPoints);
forward OnPlayerPointsChanged(client, oldPoints, newPoints);
forward OnDatabaseReady(Handle:database, DBType:type);

enum DBType
{
	DB_MySQL,
	DB_SQLite
};

enum ValveGame
{
	Game_UNKNOWN,
	Game_CSS,
	Game_CSGO,
	Game_TF2,
	Game_L4D,
	Game_L4D2,
	Game_DOD,
	Game_ND,
	Game_HLDM,
};

stock bool:IsValidPlayer(client)
{
    if(client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client))
    {
        return true;
    }
    return false;
}




