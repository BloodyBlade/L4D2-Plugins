/*****************************************************************************************************
*	- version 1.0:													  							 	 *
*		Initial release.													  						 *
*	- version 2.0:													  							     *
*		Added check on the death of the tank.														 *
******************************************************************************************************/
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#tryinclude <left4dhooks>

#define PLUGIN_VERSION "2.0"
#define CVAR_FLAGS FCVAR_NOTIFY
#define WITCH_MODEL "models/infected/witch.mdl"
#define WITCH_BRIDE "models/infected/witch_bride.mdl"

public Plugin myinfo =
{
	name = "[L4D2] Spawn Tank Witch",
	author = "BloodyBlade",
	description = "Spawn Tank or Witch on timers",
	version = PLUGIN_VERSION,
	url = "https://bloodsiworld.ru/"
};

Handle TT, WT;
ConVar TWOn, TDC, TI, WI, WD;
float b_TI, b_WI, b_WD, Pos[3];
bool b_TWOn, b_TDC, TankEvent = false, WitchEvent = false, bLateload = false, bL4DHLib = false, bHooked = false;
int TankCount = 0;
#if !defined _l4dh_included
	#pragma unused bL4DHLib
#endif

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	EngineVersion engine = GetEngineVersion();
	if(engine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2 game.");
		return APLRes_SilentFailure;
	}
	#if defined _l4dh_included
	bLateload = late;
	#endif

	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d2_spawn_tank_witch_version", PLUGIN_VERSION, "[L4D2] Spawn Tank Witch plugin version.", CVAR_FLAGS|FCVAR_DONTRECORD);
	TWOn = CreateConVar("l4d2_spawn_tank_witch_on", "1", "Spawn Tank/Witch on timers", CVAR_FLAGS, true, 0.0, true, 1.0);
	TDC = CreateConVar("l4d2_spawn_tank_witch_tank_death_check", "1", "Check that the tank is dead before you start the countdown to spawn the next tank?", CVAR_FLAGS, true, 0.0, true, 1.0);
	TI = CreateConVar("l4d2_spawn_tank_witch_tank_interval", "200.0", "How many seconds till another tank spawns", CVAR_FLAGS, true, 0.0);
	WI = CreateConVar("l4d2_spawn_tank_witch_witch_interval", "200.0", "How many seconds till another witch spawns", CVAR_FLAGS, true, 0.0);
	WD = CreateConVar("l4d2_spawn_tank_witch_witches_distance", "1500.0", "The range from survivors that witch should be removed. If 0, the plugin will not remove witches", CVAR_FLAGS, false, 0.0, false, 0.0);

	TWOn.AddChangeHook(ConVarChanged_SpawnTankWitchOn);
	TWOn.AddChangeHook(ConVarChanged);
	TDC.AddChangeHook(ConVarChanged);
	TI.AddChangeHook(ConVarChanged);
	WI.AddChangeHook(ConVarChanged);
	WD.AddChangeHook(ConVarChanged);

	AutoExecConfig(true, "l4d2_spawn_tank_witch");

	#if defined _l4dh_included
	if(bLateload)
	{
		bL4DHLib = LibraryExists("left4dhooks");
	}
	#endif
}

#if defined _l4dh_included
public void OnLibraryAdded(const char[] name)
{
	if(strcmp(name, "left4dhooks") == 0)
	{
		bL4DHLib = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if(strcmp(name, "left4dhooks") == 0)
	{
		bL4DHLib = false;
	}
}
#endif

public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarChanged_SpawnTankWitchOn(ConVar hVariable, const char[] strOldValue, const char[] strNewValue)
{
	IsAllowed();
}

void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GCvars();
}

public void OnMapStart()
{
	if(!TankEvent)
	{
		TankEvent = true;
	}

	if(!WitchEvent)
	{
		WitchEvent = true;
	}

	if (!IsModelPrecached(WITCH_MODEL)) PrecacheModel(WITCH_MODEL);
	if (!IsModelPrecached(WITCH_BRIDE)) PrecacheModel(WITCH_BRIDE);
}

void Finale_Radio_Start(Event event, const char[] name, bool dontBroadcast)
{
	TankEvent = false;
	DeleteTimers();
}

void IsAllowed()
{
	b_TWOn = TWOn.BoolValue;
	if(b_TWOn && !bHooked)
	{
		bHooked = true;
		GCvars();
		HookEvent("round_start", RoundEnd, EventHookMode_PostNoCopy);
		HookEvent("finale_radio_start", Finale_Radio_Start, EventHookMode_PostNoCopy);
		HookEvent("finale_start", Finale_Radio_Start, EventHookMode_PostNoCopy);
		#if !defined _l4dh_included
		HookEvent("player_left_start_area", LeftStartZone, EventHookMode_PostNoCopy);
		HookEvent("player_left_checkpoint", LeftStartZone, EventHookMode_PostNoCopy);
		HookEvent("player_spawn", TankSpawn, EventHookMode_PostNoCopy);
		#endif
		HookEvent("player_death", TankKilled, EventHookMode_PostNoCopy);
		HookEvent("round_end",  RoundEnd, EventHookMode_PostNoCopy);
		HookEvent("finale_win",  RoundEnd, EventHookMode_PostNoCopy);
		HookEvent("mission_lost",  RoundEnd, EventHookMode_PostNoCopy);
		HookEvent("map_transition",  RoundEnd, EventHookMode_PostNoCopy);
	}
	else if(!b_TWOn && bHooked)
	{
		bHooked = false;
		DeleteTimers();
		UnhookEvent("round_start", RoundEnd, EventHookMode_PostNoCopy);
		UnhookEvent("finale_radio_start", Finale_Radio_Start, EventHookMode_PostNoCopy);
		UnhookEvent("finale_start", Finale_Radio_Start, EventHookMode_PostNoCopy);
		#if !defined _l4dh_included
		UnhookEvent("player_left_start_area", LeftStartZone, EventHookMode_PostNoCopy);
		UnhookEvent("player_left_checkpoint", LeftStartZone, EventHookMode_PostNoCopy);
		UnhookEvent("player_spawn", TankSpawn, EventHookMode_PostNoCopy);
		#endif
		UnhookEvent("player_death", TankKilled, EventHookMode_PostNoCopy);
		UnhookEvent("round_end", RoundEnd, EventHookMode_PostNoCopy);
		UnhookEvent("finale_win", RoundEnd, EventHookMode_PostNoCopy);
		UnhookEvent("mission_lost", RoundEnd, EventHookMode_PostNoCopy);
		UnhookEvent("map_transition", RoundEnd, EventHookMode_PostNoCopy);
	}
}

void GCvars()
{
	b_TDC = TDC.BoolValue;
	b_TI = TI.FloatValue;
	b_WI = WI.FloatValue;
	b_WD = WD.FloatValue;
}

#if defined _l4dh_included
public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
	if(bL4DHLib && IsValidSurvivor(client))
	{
		StartTimers();
	}
	return Plugin_Continue;
}

public void L4D_OnSpawnTank_Post(int client, const float vecPos[3], const float vecAng[3])
{
	if(bL4DHLib && IsValidTank(client))
	{
		TankCount++;
	}
}
#else
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

Action LeftStartZone(Event event, const char[] name, bool dontBroadcast)
{
	if(LeftStartArea())
	{
		StartTimers();
	}
	return Plugin_Continue;
}

Action TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if(IsValidTank(client))
	{
		TankCount++;
	}
	return Plugin_Continue;
}
#endif

Action TankKilled(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(IsValidTank(client))
	{
		TankCount--;
		if(TankCount < 0) TankCount = 0;
		if(TankCount == 0)
		{
			StartTimers();
		}
	}
	return Plugin_Continue;
}

void StartTimers()
{
	if(TankEvent)
	{
		if(TT == null)
		{
			TT = CreateTimer(b_TI, Tank, _, TIMER_REPEAT);
		}
	}

	if(WitchEvent)
	{
		if(WT == null)
		{
			WT = CreateTimer(b_WI, Witch, _, TIMER_REPEAT);
		}
	}
}

Action Tank(Handle timer)
{
	if(TankEvent && TankCount == 0)
	{
		#if defined _l4dh_included
		if (bL4DHLib && L4D_GetRandomPZSpawnPosition(0, 8, 5, Pos))
		{
			L4D2_SpawnTank(Pos, NULL_VECTOR);
		}
		#else
		for (int i = 1; i <= MaxClients; ++i)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				int spawnflags = GetCommandFlags("z_spawn_old");
				SetCommandFlags("z_spawn_old", spawnflags & ~FCVAR_CHEAT);
				FakeClientCommand(i, "z_spawn_old tank auto");
				SetCommandFlags("z_spawn_old", spawnflags);
				break;
			}
		}
		#endif
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

Action Witch(Handle timer)
{
	if(WitchEvent)
	{
		switch(GetRandomInt(1, 2))
		{
			case 1:
			{
				#if defined _l4dh_included
				if (bL4DHLib && L4D_GetRandomPZSpawnPosition(0, 7, 5, Pos))
				{
					L4D2_SpawnWitch(Pos, NULL_VECTOR);
				}
				#else
				for (int i = 1; i <= MaxClients; ++i)
				{
					if (IsClientInGame(i) && !IsFakeClient(i))
					{
						int spawnflags = GetCommandFlags("z_spawn_old");
						SetCommandFlags("z_spawn_old", spawnflags & ~FCVAR_CHEAT);
						FakeClientCommand(i, "z_spawn_old witch auto");
						SetCommandFlags("z_spawn_old", spawnflags);
						break;
					}
				}
				#endif
			}
			case 2:
			{
				#if defined _l4dh_included
				if (bL4DHLib && L4D_GetRandomPZSpawnPosition(0, 7, 5, Pos))
				{
					L4D2_SpawnWitchBride(Pos, NULL_VECTOR);
				}
				#else
				for (int i = 1; i <= MaxClients; ++i)
				{
					if (IsClientInGame(i) && !IsFakeClient(i))
					{
						int spawnflags = GetCommandFlags("z_spawn_old");
						SetCommandFlags("z_spawn_old", spawnflags & ~FCVAR_CHEAT);
						FakeClientCommand(i, "z_spawn_old witch_bride auto");
						SetCommandFlags("z_spawn_old", spawnflags);
						break;
					}
				}
				#endif
			}
		}
		GetWitchesInRange();
	}
	return Plugin_Continue;
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

Action RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	OnMapEnd();
	return Plugin_Continue;
}

public void OnMapEnd()
{
	TankEvent = true;
	WitchEvent = true;
	TankCount = 0;
	DeleteTimers();
}

void DeleteTimers()
{
	if(TT != null)
	{
		delete TT;
	}

	if(WT != null)
	{
		delete WT;
	}
}

bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

bool IsValidSurvivor(int client)
{
	return IsValidClient(client) && !IsFakeClient(client) && GetClientTeam(client) == 2;
}

bool IsValidTank(int client)
{
	return IsValidClient(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 8;
}
