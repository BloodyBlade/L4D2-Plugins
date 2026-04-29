#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_NOTIFY|FCVAR_SPONLY

ConVar sm_dad_on, sm_dad_drag, sm_dad_pounce, sm_dad_incap, sm_dad_pummel, sm_dad_jockey, sm_dad_incap_grenade, sm_dad_pistols, sm_dad_bots;
bool bL4D2 = false, bDadOn = false, bHooked = false, bDadDrag = false, bDadPounce = false, bDadIncap = false;
bool bDadPummel = false, bDadJockey = false, bDadIncapGrenade = false, bDadPistols = false, bDadBots = false;

public Plugin myinfo =
{
	name = "[L4D] Drag and Drop",
	author = "Crimson_Fox(Rewritten by BloodyBlade)",
	description = "Survivors drop equipped item on smoker drag or incap.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=950571"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if (engine == Engine_Left4Dead)
	{
		bL4D2 = false;
	}
	else if(engine == Engine_Left4Dead2)
	{
		bL4D2 = true;
	}
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("sm_dad_version", PLUGIN_VERSION, "[L4D] Drag and Drop plugin version.", CVAR_FLAGS|FCVAR_DONTRECORD);
	sm_dad_on = CreateConVar("sm_dad_on", "1", "Enable/Disable plugin.", CVAR_FLAGS);
	sm_dad_drag = CreateConVar("sm_dad_drag", "1", "Survivors drop equipped item on Smoker drag.", CVAR_FLAGS);
	sm_dad_pounce = CreateConVar("sm_dad_pounce", "1", "Survivors drop equipped item on Hunter pounce.", CVAR_FLAGS);
	sm_dad_incap = CreateConVar("sm_dad_incap", "1", "Survivors drop equipped item when they become incapacitated.", CVAR_FLAGS);
	sm_dad_pummel = CreateConVar("sm_dad_pummel", "1", "Survivors drop equipped item when pummeled by Charger.", CVAR_FLAGS);
	sm_dad_jockey = CreateConVar("sm_dad_jockey", "1", "Survivors drop equipped item when jockeyed by Jockey.", CVAR_FLAGS);
	sm_dad_incap_grenade = CreateConVar("sm_dad_incap_grenade", "1", "Survivors drop their grenade when they become incapacitated.", CVAR_FLAGS);
	sm_dad_pistols = CreateConVar("sm_dad_pistols", "0", "Will survivors drop second pistol?", CVAR_FLAGS);
	sm_dad_bots = CreateConVar("sm_dad_bots", "1", "Will bots drop equipped item?", CVAR_FLAGS);

	AutoExecConfig(true, "sm_dad");

	sm_dad_on.AddChangeHook(ConVarPluginOnChanged);
	sm_dad_drag.AddChangeHook(ConVarsChanged);
	sm_dad_pounce.AddChangeHook(ConVarsChanged);
	sm_dad_incap.AddChangeHook(ConVarsChanged);
	sm_dad_pummel.AddChangeHook(ConVarsChanged);
	sm_dad_jockey.AddChangeHook(ConVarsChanged);
	sm_dad_incap_grenade.AddChangeHook(ConVarsChanged);
	sm_dad_pistols.AddChangeHook(ConVarsChanged);
	sm_dad_bots.AddChangeHook(ConVarsChanged);
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarPluginOnChanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{
	IsAllowed();
}

void ConVarsChanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{
	if(cvar == sm_dad_drag)
	{
		bDadDrag = cvar.BoolValue;
	}
	else if(cvar == sm_dad_pounce)
	{
		bDadPounce = cvar.BoolValue;
	}
	else if(cvar == sm_dad_incap)
	{
		bDadIncap = cvar.BoolValue;
	}
	else if(cvar == sm_dad_pummel)
	{
		bDadPummel = cvar.BoolValue;
	}
	else if(cvar == sm_dad_jockey)
	{
		bDadJockey = cvar.BoolValue;
	}
	else if(cvar == sm_dad_incap_grenade)
	{
		bDadIncapGrenade = cvar.BoolValue;
	}
	else if(cvar == sm_dad_pistols)
	{
		bDadPistols = cvar.BoolValue;
	}
	else if(cvar == sm_dad_bots)
	{
		bDadBots = cvar.BoolValue;
	}
}

void IsAllowed()
{
	bDadOn = sm_dad_on.BoolValue;
	if(!bHooked && bDadOn)
	{
		bHooked = true;
		ConVarsChanged(sm_dad_drag, "", "");
		ConVarsChanged(sm_dad_pounce, "", "");
		ConVarsChanged(sm_dad_incap, "", "");
		ConVarsChanged(sm_dad_pummel, "", "");
		ConVarsChanged(sm_dad_jockey, "", "");
		ConVarsChanged(sm_dad_incap_grenade, "", "");
		ConVarsChanged(sm_dad_pistols, "", "");
		ConVarsChanged(sm_dad_bots, "", "");
		HookEvent("tongue_grab", Events, EventHookMode_Post);
		HookEvent("lunge_pounce", Events, EventHookMode_Post);
		HookEvent("player_incapacitated", Events, EventHookMode_Post);
		HookEvent("charger_pummel_start", Events, EventHookMode_Post);
		HookEvent("jockey_ride", Events, EventHookMode_Post);
	}
	else if(bHooked && !bDadOn)
	{
		bHooked = false;
		UnhookEvent("tongue_grab", Events, EventHookMode_Post);
		UnhookEvent("lunge_pounce", Events, EventHookMode_Post);
		UnhookEvent("player_incapacitated", Events, EventHookMode_Post);
		UnhookEvent("charger_pummel_start", Events, EventHookMode_Post);
		UnhookEvent("jockey_ride", Events, EventHookMode_Post);
	}
}

void Events(Event event, const char[] name, bool dontBroadcast)
{
    if (strcmp(name, "tongue_grab") == 0 && bDadDrag)
    {
    	int client = GetClientOfUserId(event.GetInt("victim"));
    	if(IsValidSurv(client))
    	{
    		RequestFrame(DropItemDelay, client);
    	}
    }
    else if(strcmp(name, "lunge_pounce") == 0 && bDadPounce)
    {
    	int client = GetClientOfUserId(event.GetInt("victim"));
    	if(IsValidSurv(client))
    	{
    		RequestFrame(DropItemDelay, client);
    	}
    }
    else if(strcmp(name, "player_incapacitated") == 0 && bDadIncap)
    {
    	int client = GetClientOfUserId(event.GetInt("userid"));
    	if(IsValidSurv(client) && (!IsFakeClient(client) || (IsFakeClient(client) && bDadBots)))
    	{
    		RequestFrame(DropItemDelay, client);
    	}
    }
    else if(strcmp(name, "charger_pummel_start") == 0 && bDadPummel)
    {
    	int client = GetClientOfUserId(event.GetInt("victim"));
    	if(IsValidSurv(client))
    	{
    		RequestFrame(DropItemDelay, client);
    	}
    }
    else if(strcmp(name, "jockey_ride") == 0 && bDadJockey) 
    {
    	int client = GetClientOfUserId(event.GetInt("victim"));
    	if(IsValidSurv(client))
    	{
    		RequestFrame(DropItemDelay, client);
    	}
    }
}

void DropItemDelay(int client)
{
	if(IsValidSurv(client))
	{
		int iActiveWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		char cWeapon[32];
		GetEntityClassname(iActiveWeapon, cWeapon, sizeof(cWeapon));
		if (!StrEqual(cWeapon, "weapon_pistol") || (StrEqual(cWeapon, "weapon_pistol") && bDadPistols))
		{
			DropItem(client, iActiveWeapon);
		}

		if (bDadIncapGrenade)
		{
			int iSlot2 = GetPlayerWeaponSlot(client, 2);
			GetEntityClassname(iSlot2, cWeapon, sizeof(cWeapon));
			if ((bL4D2 && (StrEqual(cWeapon, "weapon_molotov") || StrEqual(cWeapon, "weapon_vomitjar"))) || StrEqual(cWeapon, "weapon_pipe_bomb"))
			{
				DropItem(client, iSlot2);
			}
		}
	}
}

stock void DropItem(int client, int iWeapon)
{
	float vel[3];
	vel[0] = GetRandomFloat(-200.0, 200.0);
	vel[1] = GetRandomFloat(-200.0, 200.0);
	vel[2] = GetRandomFloat(40.0, 80.0);
	SDKHooks_DropWeapon(client, iWeapon, NULL_VECTOR, vel);
}

stock bool IsValidSurv(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
}
