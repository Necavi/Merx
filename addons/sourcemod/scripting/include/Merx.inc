#pragma semicolon 1

#include <sourcemod>

native GivePlayerPoints(client, points);
native TakePlayerPoints(client, points);
native SetPlayerPoints(client, points);
native GetPlayerPoints(client);
native ResetPlayerPoints(client);
native SavePlayerPoints(client);
native Handle:GetDatabaseHandle();
forward Action:OnPrePlayerPointsChange(client, oldPoints, &newPoints);
forward Action:OnPlayerPointsChange(client, oldPoints, newPoints);
forward OnPlayerPointsChanged(client, oldPoints, newPoints);
forward OnDatabaseReady(Handle:database, DBType:type);


enum DBType
{
	DB_MySQL,
	DB_SQLite
};

stock bool:IsValidPlayer(client)
{
    if(client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client))
    {
        return true;
    }
    return false;
}