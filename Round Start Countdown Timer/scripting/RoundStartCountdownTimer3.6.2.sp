#pragma semicolon 1
#pragma newdecls required
#include <sdktools>
#include <left4dhooks>
#include <vip_core>

#define PLUGIN_VERSION "3.6.2"

ConVar Countdown_on, Countdown_delay, Enable_sound, Admin_Immune, Warp_survivor;
int Delay = 0;
bool TimerEnd = false, RoundTwo = false, LockTimerRepeate = true;
char current_map[53];

public Plugin myinfo =
{
	name = "L4D2_Countdown",
	author = "BS/IW",
	description = "During the countdown to the start of the round, players will be frozen.",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/profiles/76561198078797525/"
};

public void OnPluginStart()
{
	LoadTranslations("l4d2_countdown.phrases");
	CreateConVar("l4d2_countdown_version", PLUGIN_VERSION, "Version of the L4D2 Countdown.", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);
	Countdown_on = CreateConVar("countdown_on", "1", "Enable plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	Countdown_delay = CreateConVar("countdown_delay", "20", "Number of seconds to count down before the round goes live.", FCVAR_NOTIFY, true, 0.0, true, 60.0);
	Enable_sound = CreateConVar("enable_sound", "1", "Enable sound during countdown?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	Admin_Immune = CreateConVar("admin_immune", "1", "Admin immune to freeze?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	Warp_survivor = CreateConVar("warp_survivor", "1", "Should we warp the entire player when a player attempts to leave saferoom?", FCVAR_NOTIFY);

	HookEvent("round_start", RoundStart);
	HookEvent("round_end", RoundEnd);
	HookEvent("player_spawn", Event_PlayerSpawn);
//	HookEvent("player_spawn", LeftSafeZone);
	HookEvent("player_left_start_area", LeftSafeZone);
	HookEvent("player_left_checkpoint", LeftSafeZone);
	HookEvent("player_disconnect", PlayerDisconnect, EventHookMode_Pre);

	AutoExecConfig(true, "L4D2_Countdown");
}

bool VersusModes()
{
	char GameMode[13];
	ConVar gamecvar_mp_gamemode = FindConVar("mp_gamemode");
	GetConVarString(gamecvar_mp_gamemode, GameMode, sizeof(GameMode));
	if (StrEqual(GameMode, "versus", false) == true 
	||  StrEqual(GameMode, "mutation11", false) == true 
	||  StrEqual(GameMode, "mutation12", false) == true 
	||  StrEqual(GameMode, "mutation18", false) == true 
	||  StrEqual(GameMode, "mutation19", false) == true 
	||  StrEqual(GameMode, "community3", false) == true 
	||  StrEqual(GameMode, "community6", false) == true
	)
	{
		return true;
	}
	return false;
}

public void OnMapStart()
{
	if(Countdown_on.IntValue == 1)
	{
		GetCurrentMap(current_map, sizeof(current_map));
		PrecacheSound("buttons/blip1.wav");
		ResetBools();
	}
}

/*
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (IsClientInGame(client) && GetClientTeam(client) != 1)
	{
		if (!TimerEnd)
		{
			if (IsValidEntity(client))
			{
				if(!RoundTwo)
				{
					if(Admin_Immune.IntValue == 1)
					{
						if(!((GetUserFlagBits(client) & (ADMFLAG_ROOT | ADMFLAG_RESERVATION)) || !VIP_IsClientVIP(client)))
							SetEntityMoveType(client, MOVETYPE_NONE);
					}
					else SetEntityMoveType(client, MOVETYPE_NONE);
				}
				else SetEntityMoveType(client, MOVETYPE_WALK);
			}
		}
		else
		{
			SetEntityMoveType(client, MOVETYPE_WALK);
		}
	}
}
*/

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if(Countdown_on.IntValue == 1)
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		if (client && IsClientInGame(client) && GetClientTeam(client) == 2 && (!IsFakeClient(client) || AllPlayersIsFinishedLoading() ))
		{
			if(!RoundTwo && !TimerEnd && LockTimerRepeate)
			{
				if( L4D_IsFirstMapInScenario() )
				{
					LockTimerRepeate = false;
					Delay = Countdown_delay.IntValue;
					CreateTimer(15.0, CountDownDelay_Timer, INVALID_HANDLE);
				}
				else
				{
					LockTimerRepeate = false;
					Delay = Countdown_delay.IntValue;
					CreateTimer(1.5, CountDownDelay_Timer, INVALID_HANDLE);
				}
			}
		}
	}
}

public void RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(Countdown_on.IntValue == 1)
	{
		if( VersusModes() )
		{
			if(RoundTwo)
			{
				TimerEnd = false;
				Delay = Countdown_delay.IntValue;
				CreateTimer(1.0, CountDownDelay_Timer, INVALID_HANDLE);
			}
		}
	}
}

public void RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if(Countdown_on.IntValue == 1)
	{
		if( VersusModes() )
		{
			RoundTwo = true;
		}
	}
}

/*
public Action CountDownDelay_Timer(Handle timer, any client)
{
	if(Delay > 0)
	{
		Delay--;
		TimerEnd = false;
		PrintCountdown();
		CreateTimer(1.0, CountDownDelay_Timer, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Continue;
	}
	else
	{
		TimerEnd = true;
		PrintCountdown();
		return Plugin_Stop;
	}
}
*/

public Action CountDownDelay_Timer(Handle timer, any client)
{
	if(Delay > 0)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && GetClientTeam(i) == 2)
			{
				if(!RoundTwo)
				{
					SetEntityMoveType(i, MOVETYPE_NONE);
					if(Admin_Immune.IntValue == 1)
					{
						if((GetUserFlagBits(i) & (ADMFLAG_ROOT | ADMFLAG_RESERVATION)) || VIP_IsClientVIP(i))
							SetEntityMoveType(i, MOVETYPE_WALK);
					}
				}
			}
		}
		Delay--;
		TimerEnd = false;
		LockTimerRepeate = false;
		PrintCountdown();
		CreateTimer(1.0, CountDownDelay_Timer, INVALID_HANDLE);
		return Plugin_Continue;
	}
	else
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && GetClientTeam(i) == 2)
			{
				if(!RoundTwo) SetEntityMoveType(i, MOVETYPE_WALK);
			}
		}
		TimerEnd = true;
		PrintCountdown();
		return Plugin_Stop;
	}
}

void PrintCountdown()
{
	if(!TimerEnd && Delay > 0)
	{
		PrintHintTextToAll("%t", "Live in: %d", Delay);
		if(Enable_sound.IntValue == 1) EmitSoundToAll("buttons/blip1.wav", _, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
	}
	else PrintHintTextToAll("%t", "Round is live!");
}

public void LeftSafeZone(Event event, const char[] name, bool dontBroadcast)
{
	if(Countdown_on.IntValue == 1 && Warp_survivor.IntValue == 1 && !TimerEnd)
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		if (client && IsClientInGame(client) && GetClientTeam(client) == 2)
		{
			int warp_flags = GetCommandFlags("warp_to_start_area");
			SetCommandFlags("warp_to_start_area", warp_flags & ~FCVAR_CHEAT);
			FakeClientCommand(client, "warp_to_start_area");
			PrintHintText(client, "%t", "%N, do not leave the saferoom until the beginning of the round.", client);
			SetCommandFlags("warp_to_start_area", warp_flags);
		}
	}
}

public Action PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if((!client || !IsFakeClient(client)) && !RealPlayerConnected(client))
	{
		CreateTimer(1.5, Reset);
	}
	return Plugin_Continue;
}

public Action Reset(Handle timer)
{
	if(!RealPlayerConnected())
	{
        ResetBools();
	}
	return Plugin_Stop;
}

public void OnMapEnd()
{
	ResetBools();
}

bool RealPlayerConnected(int Exclude = 0)
{
	for( int i = 1; i < MaxClients; i++ )
	{
		if(i != Exclude && IsClientConnected(i))
		{
			if(!IsFakeClient(i))
			{
				return true;
			}
		}
	}
	return false;
}

bool AllPlayersIsFinishedLoading()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			if (!IsClientInGame(i) || IsFakeClient(i)) return false;
			else return true;
		}
		else return false;
	}
	return false;
}

void ResetBools()
{
	RoundTwo = false;
	TimerEnd = false;
	LockTimerRepeate = true;
}
/*
bool FirstMap()
{
	if (StrEqual(current_map, "c1m1_hotel", false)
	||  StrEqual(current_map, "c7m1_docks", false)
	||  StrEqual(current_map, "c6m1_riverbank", false)
	||  StrEqual(current_map, "c2m1_highway", false)
	||  StrEqual(current_map, "c3m1_plankcountry", false)
	||  StrEqual(current_map, "c4m1_milltown_a", false)
	||  StrEqual(current_map, "c5m1_waterfront", false)
	||  StrEqual(current_map, "c13m1_alpinecreek", false)
	||  StrEqual(current_map, "c8m1_apartment", false)
	||  StrEqual(current_map, "c9m1_alleys", false) 
	||  StrEqual(current_map, "c10m1_caves", false) 
	||  StrEqual(current_map, "c11m1_greenhouse", false) 
	||  StrEqual(current_map, "c12m1_hilltop", false) 
	||  StrEqual(current_map, "c14m1_junkyard", false)
	)
		return true;
	return false;
}*/
