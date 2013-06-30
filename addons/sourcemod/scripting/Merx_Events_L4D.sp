#include <sourcemod>
#include "include/Merx"

public Plugin:myinfo = 
{
	name = "Merx L4D specific Events",
	author = "necavi",
	description = "Rewards players with points for certain events",
	version = MERX_BUILD,
	url = "http://necavi.org"
}

public OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
}
public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new String:victim[256];
	GetEventString(event, "victimname", victim, sizeof(victim));
	if(StrEqual(victim, "jockey") || \
			StrEqual(victim, "smoker") || \
			StrEqual(victim, "boomer") || \
			StrEqual(victim, "hunter") || \
			StrEqual(victim, "spitter") || \
			StrEqual(victim, "charger") || \
			StrEqual(victim, "witch"))
		{
			new Handle:customEvent = CreateCustomEvent("special_infected_death");
			SetCustomEventString(customEvent, "victimname", victim);
			SetCustomEventInt(customEvent, "userid", GetEventInt(event, "userid"));
			SetCustomEventInt(customEvent, "entityid", GetEventInt(event, "entityid"));
			SetCustomEventInt(customEvent, "attacker", GetEventInt(event, "attacker"));
			new String:weapon[64];
			GetEventString(event, "weapon", weapon, sizeof(weapon));
			SetCustomEventString(customEvent, "weapon", weapon);
		}
}
