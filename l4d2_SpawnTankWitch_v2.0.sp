/*
	******************************************************************************************************
	*	- version 1.0:													  							 	 *
	*		Initial release.													  						 *
	*	- version 2.0:													  							     *
	*		Added check on the death of the tank.														 *
	******************************************************************************************************
*/
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define PLUGIN_VERSION "2.0"

#define CVAR_FLAGS FCVAR_NOTIFY

public Plugin myinfo =
{
	name = "Spawn Tank Witch",
	author = "BS/IW",
	description = "Spawn Tank or Witch on timers",
	version = PLUGIN_VERSION,
	url = ""
};

Handle TT, WT;
ConVar TWOn, TDC, TI, WI, WD;
float b_TI, b_WI, b_WD;
bool b_TWOn, b_TDC, TankEvent = false;

public void OnPluginStart()
{
	CreateConVar("spawn_tank_witch_version", PLUGIN_VERSION, "Spawn Tank Witch plugin version.", CVAR_FLAGS|FCVAR_DONTRECORD);
	TWOn = CreateConVar("TankWitchOn", "1", "Spawn Tank/Witch on timers", CVAR_FLAGS, true, 0.0, true, 1.0);
	TDC = CreateConVar("TankDeathCheck", "1", "Check that the tank is dead before you start the countdown to spawn the next tank?", CVAR_FLAGS, true, 0.0, true, 1.0);
	TI = CreateConVar("TankInterval", "200.0", "How many seconds till another tank spawns", CVAR_FLAGS, true, 0.0);
	WI = CreateConVar("WitchInterval", "200.0", "How many seconds till another witch spawns", CVAR_FLAGS, true, 0.0);
	WD = CreateConVar("WitchesDistance", "1500.0", "The range from survivors that witch should be removed. If 0, the plugin will not remove witches", CVAR_FLAGS, false, 0.0, false, 0.0);

	GetCvars();
	TWOn.AddChangeHook(ConVarChanged_SpawnTankWitchOn);
	TDC.AddChangeHook(ConVarChanged);
	TI.AddChangeHook(ConVarChanged);
	WI.AddChangeHook(ConVarChanged);
	WD.AddChangeHook(ConVarChanged);
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

public void ConVarChanged_SpawnTankWitchOn(ConVar hVariable, const char[] strOldValue, const char[] strNewValue)
{
	IsAllowed();
}

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

public void OnMapStart()
{
    if (!TankEvent)
    {
        TankEvent = true;
    }
}

public void Finale_Radio_Start(Event event, const char[] name, bool dontBroadcast)
{
	TankEvent = false;
	DeleteTimers();
}

void IsAllowed()
{
	b_TWOn = TWOn.BoolValue;
	GetCvars();

	if(b_TWOn)
	{
		HookEvent("round_start", RoundEnd, EventHookMode_PostNoCopy);
		HookEvent("finale_radio_start", Finale_Radio_Start, EventHookMode_PostNoCopy);
		HookEvent("finale_start", Finale_Radio_Start, EventHookMode_PostNoCopy);
		HookEvent("gauntlet_finale_start", Finale_Radio_Start, EventHookMode_PostNoCopy);
		HookEvent("player_left_start_area", LeftStartZone, EventHookMode_PostNoCopy);
		HookEvent("player_left_checkpoint", LeftStartZone, EventHookMode_PostNoCopy);
		HookEvent("tank_killed", LeftStartZone, EventHookMode_PostNoCopy);
		HookEvent("round_end",  RoundEnd, EventHookMode_PostNoCopy);
		HookEvent("finale_win",  RoundEnd, EventHookMode_PostNoCopy);
		HookEvent("mission_lost",  RoundEnd, EventHookMode_PostNoCopy);
		HookEvent("map_transition",  RoundEnd, EventHookMode_PostNoCopy);
	}
	else
	{
        DeleteTimers();
        UnhookEvent("round_start", RoundEnd, EventHookMode_PostNoCopy);
        UnhookEvent("finale_radio_start", Finale_Radio_Start, EventHookMode_PostNoCopy);
        UnhookEvent("finale_start", Finale_Radio_Start, EventHookMode_PostNoCopy);
        UnhookEvent("gauntlet_finale_start", Finale_Radio_Start, EventHookMode_PostNoCopy);
        UnhookEvent("player_left_start_area", LeftStartZone, EventHookMode_PostNoCopy);
        UnhookEvent("player_left_checkpoint", LeftStartZone, EventHookMode_PostNoCopy);
        UnhookEvent("tank_killed", LeftStartZone, EventHookMode_PostNoCopy);
        UnhookEvent("round_end", RoundEnd, EventHookMode_PostNoCopy);
        UnhookEvent("finale_win", RoundEnd, EventHookMode_PostNoCopy);
        UnhookEvent("mission_lost", RoundEnd, EventHookMode_PostNoCopy);
        UnhookEvent("map_transition", RoundEnd, EventHookMode_PostNoCopy);
	}
}

void GetCvars()
{
	b_TDC = TDC.BoolValue;
	b_TI = TI.FloatValue;
	b_WI = WI.FloatValue;
	b_WD = WD.FloatValue;
}

stock bool LeftStartArea() 
{
	int maxents = GetMaxEntities();
	for (int i = MaxClients + 1; i <= maxents; i++)
	{
		if (IsValidEntity(i))
		{
			char netclass[64];
			GetEntityNetClass(i, netclass, sizeof(netclass));
			
			if (StrEqual(netclass, "CTerrorPlayerResource"))
			{
				if (GetEntProp(i, Prop_Send, "m_hasAnySurvivorLeftSafeArea"))
				{
					return true;
				}
			}
		}
	}
	return false;
}

public Action LeftStartZone(Event event, const char[] name, bool dontBroadcast)
{
	if(b_TWOn && LeftStartArea())
	{
        StartTimers();
	}
}

void StartTimers()
{
	if(TankEvent)
	{
		if(!TT) TT = CreateTimer(b_TI, Tank, _, TIMER_REPEAT);
		if(!WT) WT = CreateTimer(b_WI, Witch, _, TIMER_REPEAT);
	}
}

public Action Tank(Handle timer)
{
	if(TankEvent)
	{
		for (int i = 1; i <= MaxClients; ++i)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
    			float vecPos[3];
    			if(L4D_GetRandomPZSpawnPosition(i, 8, 5, vecPos))
    			{
    				L4D2_SpawnTank(vecPos, NULL_VECTOR);
    			}
			}
		}
	}
	if(b_TDC)
	{
		TT = null;
		return Plugin_Stop;
	}
	else
	{
		return Plugin_Continue;
	}
}

public Action Witch(Handle timer)
{
    for (int i = 1; i <= MaxClients; ++i)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
			float vecPos[3];
			if(L4D_GetRandomPZSpawnPosition(i, 7, 5, vecPos))
			{
				L4D2_SpawnWitch(vecPos, NULL_VECTOR);
			}
        }
    }
    GetWitchesInRange();
}

// Kill witches out of range
void GetWitchesInRange()
{
	int i, index = -1;
	bool bInRange;
	float WitchPos[3], PlayerPos[3], distance;

	while( (index = FindEntityByClassname(index, "witch")) != -1 )
	{
		if( b_WD > 0.0 )
		{
			GetEntPropVector(index, Prop_Send, "m_vecOrigin", WitchPos);
			bInRange = false;
			
			for( i = 1; i <= MaxClients; i++ )
			{
				if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
				{
					GetClientAbsOrigin(i, PlayerPos);
					distance = GetVectorDistance(WitchPos, PlayerPos);
					if (distance < b_WD)
					{
						bInRange = true;
						break;
					}
				}
			}

			if( !bInRange ) AcceptEntityInput(index, "Kill");
		}
	}
}

public Action RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	TankEvent = true;
	DeleteTimers();
}

public void OnMapEnd()
{
	DeleteTimers();
}

void DeleteTimers()
{
	if(TT) delete TT;
	if(WT) delete WT;
}
