#include <sourcemod>
#include "include/Merx"

public Plugin:myinfo = 
{
	name = "Merx TF2 specific Events",
	author = "necavi",
	description = "Rewards players with points for certain events",
	version = MERX_BUILD,
	url = "http://necavi.org"
}

public OnPluginStart()
{
	if(GetGame() == Game_TF2)
	{
		HookEvent("npc_hurt", Event_NPCHurt);
	}
}
public Event_NPCHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new health = GetEventInt(event, "health");
	new damage = GetEventInt(event, "damageamount");
	if(damage > health)
	{
		new String:victim[256];
		new entity = GetEventInt(event, "entindex");
		GetEntityClassname(entity, victim, sizeof(victim));
		if(StrEqual(victim, "eyeball_boss"))
		{
			FireBossEvent(event, "monoculus_death", "Monoculus");
		}
		else if(StrEqual(victim, "headless_hatman"))
		{
			FireBossEvent(event, "horsemann_death", "Horsemann");
		}
		else if(StrEqual(victim, "merasmus"))
		{
			FireBossEvent(event, "merasmus_death", "Merasmus");
		}
		else
		{
			return;
		}
		FireBossEvent(event, "boss_death", victim);
	}
}
FireBossEvent(Handle:event, const String:name[], const String:boss_type[])
{
	new entity = GetEventInt(event, "entindex");
	new Handle:customEvent = CreateCustomEvent(name);
	SetCustomEventInt(customEvent, "attacker", GetEventInt(event, "attacker_player"));
	SetCustomEventInt(customEvent, "entity", entity);
	SetCustomEventString(customEvent, "boss_type", boss_type);
	FireCustomEvent(customEvent);
}