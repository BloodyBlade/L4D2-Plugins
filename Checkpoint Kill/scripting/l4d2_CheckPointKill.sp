#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <colors>

ConVar IsMapFinished;
Handle DeathTimer;
char current_map[64];
bool FalsePositive[MAXPLAYERS + 1]/*, Activated*/;

public Plugin myinfo =
{
	name = "L4D2 Checkpoint Kill",
	author = "Accelerator",
	description = "",
	version = "1.0",
	url = "https://core-ss.org"
};

public void OnPluginStart()
{
	LoadTranslations("Checkpoint_Kill.phrases");

	HookEvent("player_entered_checkpoint", Event_CheckPoint, EventHookMode_PostNoCopy);
//	HookEvent("finale_vehicle_ready", Escape, EventHookMode_PostNoCopy);
//	HookEvent("finale_escape_start", Escape, EventHookMode_PostNoCopy);
	HookEvent("round_start", Start, EventHookMode_PostNoCopy);
	HookEvent("round_end", End, EventHookMode_PostNoCopy);
	HookEvent("mission_lost", End, EventHookMode_PostNoCopy);
	HookEvent("map_transition", End, EventHookMode_PostNoCopy);

	IsMapFinished = CreateConVar("mapfinished", "0", "");
	IsMapFinished.AddChangeHook(IsMapFinishedChanged);
}

public void OnMapStart()
{
	GetCurrentMap(current_map, sizeof(current_map));
	OnMapEnd();
}

public void OnMapEnd()
{
	if (DeathTimer) delete DeathTimer;
/*	Activated = false;*/
	for(int i = 1; i <= MaxClients; i++)
	{
		FalsePositive[i] = true;
	}
}

public void Start(Event event, const char[] name, bool dontBroadcast)
{
	IsMapFinished.SetInt(0);
}

public void End(Event event, const char[] name, bool dontBroadcast)
{
	OnMapEnd();
}

/*public Action Escape(Event event, const char[] name, bool dontBroadcast)
{
	if (IsMapFinished.IntValue > 0) return Plugin_Continue;

	int player = GetClientOfUserId(event.GetInt("userid"));
	if (IsPlayerSurvivor(player) && !IsFakeClient(player))
	{
		CheckPointReached();
		CPrintToChatAll("%t", "The final vehicle is ready. \nMode: Sudden death activated.");
		return Plugin_Handled;
	}

	return Plugin_Continue;
}*/

void CheckPointReached()
{
	IsMapFinished.SetInt(1);
}

public void IsMapFinishedChanged(ConVar hVariable, const char[] strOldValue, const char[] strNewValue)
{
	if (StringToInt(strNewValue) > 0)
	{
		CreateTimer(10.0, TimerActivate, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action TimerActivate(Handle timer)
{
//	if(Activated)
//	{
	CPrintToChatAll("%t", "Mode: Sudden death is activated!");
//		Activated = false;
//	}

	if (DeathTimer) delete DeathTimer;
	DeathTimer = CreateTimer(1.0, TimerDeath, _, TIMER_REPEAT);
}

public Action TimerDeath(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{			
		if (IsPlayerSurvivor(i) && (IsPlayerIncapped(i) || IsPlayerLedgeGrab(i)))
			ForcePlayerSuicide(i);
	}

	return Plugin_Continue;
}

public Action Event_CheckPoint(Event event, const char[] name, bool dontBroadcast)
{
	if (IsMapFinished.IntValue > 0) return Plugin_Continue;

	int Door = event.GetInt("door");

	if (Door && GetEntProp(Door, Prop_Data, "m_hasUnlockSequence")) return Plugin_Continue;

	int Target = GetClientOfUserId(event.GetInt("userid"));

	char strBuffer[64];
	event.GetString("doorname", strBuffer, sizeof(strBuffer));

	if (IsPlayerSurvivor(Target) && !IsFakeClient(Target))
	{
		if (StrEqual(strBuffer, "checkpoint_entrance", false))
		{
			CheckPointReached();
			FalsePositive[Target] = false;
		}
		else
		{
			int area = event.GetInt("area");

			if (StrEqual(current_map, "c2m1_highway", false))
			{
				if (area == 89583) CheckPointReached();
				FalsePositive[Target] = false;
			}
			else if (StrEqual(current_map, "c4m4_milltown_b", false))
			{
				if (area == 502575) CheckPointReached();
				FalsePositive[Target] = false;
			}
			else if (StrEqual(current_map, "c5m1_waterfront", false))
			{
				if (area == 54867) CheckPointReached();
				FalsePositive[Target] = false;
			}
			else if (StrEqual(current_map, "c5m2_park", false))
			{
				if (area == 196623) CheckPointReached();
				FalsePositive[Target] = false;
			}
			else if (StrEqual(current_map, "c7m1_docks", false))
			{
				if (area == 4475) CheckPointReached();
				FalsePositive[Target] = false;
			}
			else if (StrEqual(current_map, "c7m2_barge", false))
			{
				if (area == 52626) CheckPointReached();
				FalsePositive[Target] = false;
			}
			else if (StrEqual(current_map, "c9m1_alleys", false))
			{
				if (area == 21211) CheckPointReached();
				FalsePositive[Target] = false;
			}
			else if (StrEqual(current_map, "c10m4_mainstreet", false))
			{
				if (area == 85038) CheckPointReached();
				if (area == 85093) CheckPointReached();
				FalsePositive[Target] = false;
			}
			else if (StrEqual(current_map, "C12m1_hilltop", false))
			{
				if (area == 60481) CheckPointReached();
				FalsePositive[Target] = false;
			}
			else if (StrEqual(current_map, "c13m1_alpinecreek", false))
			{
				if (area == 14681) CheckPointReached();
				FalsePositive[Target] = false;
			}
			else if (StrEqual(current_map, "c13m2_southpinestream", false))
			{
				if (area == 2910) CheckPointReached();
				FalsePositive[Target] = false;
			}
			else if (StrEqual(current_map, "c13m3_memorialbridge", false))
			{
				if (area == 154511) CheckPointReached();
				FalsePositive[Target] = false;
			}
		}

		if (!FalsePositive[Target])
		{
			CPrintToChatAll("%t", "Player %N has entered the safe zone. \nMode: Sudden death is activated after 10 seconds.", Target);
			FalsePositive[Target] = true;
/*			Activated = true;*/
		}
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

stock bool IsPlayerIncapped(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
	return false;
}

stock bool IsPlayerLedgeGrab(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1)) return true;
	return false;
}

stock bool IsPlayerSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && !IsClientInKickQueue(client);
}
