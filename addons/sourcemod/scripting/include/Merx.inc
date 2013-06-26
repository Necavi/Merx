#pragma semicolon 1

#include <sourcemod>
#include <morecolors>

#define MERX_TAG "{red}[{olive}MERX{red}]{default} "
#define MERX_BUILD "CUSTOM"

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