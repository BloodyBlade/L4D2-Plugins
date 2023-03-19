#pragma semicolon 1
#pragma newdecls required
#include <sdktools>
#include <left4dhooks>
#include <vip_core>

#define PLUGIN_VERSION "3.6.2"
#define CVAR_FLAGS FCVAR_NOTIFY

ConVar Countdown_on, Countdown_delay, Countdown_autoopen, Enable_sound, Freeze_players, Admin_Immune, Warp_survivor;
ConVar GlowAllow, GlowRange, LockColor, OpenColor;
bool bCountdown_on, bCountdown_autoopen, bEnable_sound, bFreeze_players, bAdmin_Immune, bWarp_survivor, bGlowAllow;
int Delay = 0, CountDownTimer = 0, iCountdown_delay, iGlowRange, iLockColors[3], iUnlockColors[3];
bool TimerEnd = false, RoundTwo = false, LockTimerRepeate = true, bCvarAllow = false;
char current_map[53], sLockColor[16], sUnlockColor[16];

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
	CreateConVar("l4d2_countdown_version", PLUGIN_VERSION, "Version of the L4D2 Countdown.", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
	Countdown_on = CreateConVar("countdown_on", "1", "Enable plugin", CVAR_FLAGS, true, 0.0, true, 1.0);
	Countdown_delay = CreateConVar("countdown_delay", "20", "Number of seconds to count down before the round goes live.", CVAR_FLAGS, true, 0.0, true, 60.0);
	Countdown_autoopen = CreateConVar("countdown_autoopen", "0", "Auto-Open Safe Room door after count down timer is end?", CVAR_FLAGS, true, 0.0, true, 1.0);
	Enable_sound = CreateConVar("enable_sound", "1", "Enable sound during countdown?", CVAR_FLAGS, true, 0.0, true, 1.0);
	Freeze_players = CreateConVar("freeze_players", "1", "Freeze players when countdown is live?", CVAR_FLAGS, true, 0.0, true, 1.0);
	Admin_Immune = CreateConVar("admin_immune", "1", "Admin immune to freeze?", CVAR_FLAGS, true, 0.0, true, 1.0);
	Warp_survivor = CreateConVar("warp_survivor", "1", "Should we warp the entire player when a player attempts to leave saferoom?", CVAR_FLAGS);
	GlowAllow = CreateConVar("glow_allow", "1", "Allow Glowing of the saferoom door", CVAR_FLAGS);
	GlowRange = CreateConVar("doorlock_glow_range", "500", "Set The Glow Range For Saferoom Doors", CVAR_FLAGS);
	LockColor = CreateConVar("lock_glow_color",	"255 0 0", "Set Saferoom Lock Glow Color, (0-255) Separated By Spaces.", CVAR_FLAGS);
	OpenColor = CreateConVar("unlock_glow_color", "0 255 0", "Set Saferoom Unlock Glow Color, (0-255) Separated By Spaces.", CVAR_FLAGS);

	AutoExecConfig(true, "L4D2_Countdown");
}

public void OnConfigsExecuted()
{
	GetCurrentMap(current_map, sizeof(current_map));
	PrecacheSound("buttons/blip1.wav");
	ResetBools();
	IsAllowed();
}

public void ConVarChanged_Allow(ConVar convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

public void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void IsAllowed()
{
	bCountdown_on = Countdown_on.BoolValue;
	GetCvars();

	if(!bCvarAllow && bCountdown_on)
	{
        bCvarAllow = true;
        HookEvent("player_spawn",		PlayerSpawn);
        HookEvent("round_start",		RoundStart);
        HookEvent("round_end",			RoundEnd);
        HookEvent("player_left_start_area", LeftSafeZone);
        HookEvent("player_left_checkpoint", LeftSafeZone);
        HookEvent("player_disconnect", PlayerDisconnect);
	}
	else if(bCvarAllow && !bCountdown_on)
	{
        ResetBools();
        bCvarAllow = false;
        UnhookEvent("player_spawn",		PlayerSpawn);
        UnhookEvent("round_start",		RoundStart);
        UnhookEvent("round_end",		RoundEnd);
        UnhookEvent("player_left_start_area", LeftSafeZone);
        UnhookEvent("player_left_checkpoint", LeftSafeZone);
        UnhookEvent("player_disconnect", PlayerDisconnect);
	}
}

void GetCvars()
{
	bCountdown_autoopen = Countdown_autoopen.BoolValue;
	bEnable_sound = Enable_sound.BoolValue;
	bFreeze_players = Freeze_players.BoolValue;
	LockColor.GetString(sLockColor, sizeof(sLockColor));
	OpenColor.GetString(sUnlockColor, sizeof(sUnlockColor));
	bAdmin_Immune = Admin_Immune.BoolValue;
	bWarp_survivor = Warp_survivor.BoolValue;
	bGlowAllow = GlowAllow.BoolValue;
	iGlowRange = GlowRange.IntValue;
	iCountdown_delay = Countdown_delay.IntValue;
}

public void OnClientPutInServer(int client)
{
	if(bCountdown_on)
	{
    	if(!IsFakeClient(client) || AllPlayersIsFinishedLoading() )
    	{
    		if(!RoundTwo && !TimerEnd && LockTimerRepeate)
    		{
    			Delay = iCountdown_delay;
    			if( L4D_IsFirstMapInScenario() )
    			{
    				LockTimerRepeate = false;
    				if(!CountDownTimer)
    				{
    					CountDownTimer = 1;
    					CreateTimer(15.0, CountDownDelay_Timer, INVALID_HANDLE);
    					LockAllRotatingSaferoomDoors();
    				}
    			}
    			else
    			{
    				LockTimerRepeate = false;
    				if(!CountDownTimer)
    				{
    					CountDownTimer = 1;
    					CreateTimer(1.5, CountDownDelay_Timer, INVALID_HANDLE);
    					LockAllRotatingSaferoomDoors();
    				}
    			}
    		}
    	}
	}
}

public void PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if(bCountdown_on)
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		if (client && IsClientInGame(client))
		{
			if(GetClientTeam(client) == 3)
			{
				if(!TimerEnd)
				{
					ForcePlayerSuicide(client);
				}
			}
		}
	}
}

public void RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(bCountdown_on)
	{
		if( L4D_IsVersusMode() )
		{
			if(RoundTwo)
			{
				TimerEnd = false;
				Delay = iCountdown_delay;
				if(!CountDownTimer)
				{
					CountDownTimer = 1;
					CreateTimer(1.0, CountDownDelay_Timer, INVALID_HANDLE);
				}
			}
		}
	}
}

/* =============================================================================================================== *
 *													Locking All Saferoom Dorrs									   *
 *================================================================================================================ */

void LockAllRotatingSaferoomDoors()
{
	int iCheckPointDoor = L4D_GetCheckpointFirst();
	if (!IsValidEnt(iCheckPointDoor)) return;

	AcceptEntityInput(iCheckPointDoor, "Close");
	AcceptEntityInput(iCheckPointDoor, "Lock");
	SetVariantString("spawnflags 40960");
	AcceptEntityInput(iCheckPointDoor, "AddOutput");

	if(bGlowAllow)
	{
		GetColor(iLockColors, sLockColor);
		L4D2_SetEntityGlow(iCheckPointDoor, L4D2Glow_Constant, iGlowRange, 0, iLockColors, false);
	}
	
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && IsPlayerAlive(i)) SetEntProp (i, Prop_Data, "m_takedamage", 0);
}

/* =============================================================================================================== *
 *													Unlocking All Saferoom Dorrs								   *
 *================================================================================================================ */

void UnLockAllRotatingSaferoomDoors()
{
	int iCheckPointDoor = L4D_GetCheckpointFirst();
	if (!IsValidEnt(iCheckPointDoor)) return;

	SetVariantString("spawnflags 8192");
	AcceptEntityInput(iCheckPointDoor, "AddOutput");
	AcceptEntityInput(iCheckPointDoor, "Unlock");
	if(bCountdown_autoopen)
	{
	    AcceptEntityInput(iCheckPointDoor, "Open");
	}
	AcceptEntityInput(iCheckPointDoor, "StartGlowing");

	if(bGlowAllow)
	{
		GetColor(iUnlockColors, sUnlockColor);
		L4D2_SetEntityGlow(iCheckPointDoor, L4D2Glow_Constant, iGlowRange, 0, iUnlockColors, false);
	}
	
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && IsPlayerAlive(i)) SetEntProp (i, Prop_Data, "m_takedamage", 2);
}

public void RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if(bCountdown_on)
	{
		if( L4D_IsVersusMode() )
		{
			RoundTwo = true;
			CountDownTimer = 0;
		}
	}
}

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
				    if(bFreeze_players)
				    {
    					SetEntityMoveType(i, MOVETYPE_NONE);
    					if(bAdmin_Immune)
    					{
    						if((GetUserFlagBits(i) & (ADMFLAG_ROOT | ADMFLAG_RESERVATION)) || VIP_IsClientVIP(i))
    							SetEntityMoveType(i, MOVETYPE_WALK);
    					}
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
				if(!RoundTwo)
				{
				    if(bFreeze_players)
				    {
    					SetEntityMoveType(i, MOVETYPE_WALK);
				    }
				    UnLockAllRotatingSaferoomDoors();
				}
			}
		}
		TimerEnd = true;
		PrintCountdown();
		CountDownTimer = 0;
		return Plugin_Stop;
	}
}

void PrintCountdown()
{
	if(!TimerEnd && Delay > 0)
	{
		PrintHintTextToAll("%t", "Live in: %d", Delay);
		if(bEnable_sound) EmitSoundToAll("buttons/blip1.wav", _, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
	}
	else PrintHintTextToAll("%t", "Round is live!");
}

public void LeftSafeZone(Event event, const char[] name, bool dontBroadcast)
{
	if(bCountdown_on && bWarp_survivor && !TimerEnd)
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

/* =============================================================================================================== *
 *											Change Saferoom Doors Lock/Unlock Colors							   *
 *================================================================================================================ */

void GetColor(int[] array, char[] sTemp)
{
	if(StrEqual(sTemp, ""))
	{
		array[0] = array[1] = array[2] = 0;
		return;
	}
	
	char sColors[3][4];
	int color = ExplodeString(sTemp, " ", sColors, 3, 4);

	if( color != 3 )
	{
		array[0] = array[1] = array[2] = 0;
		return;
	}
	array[0] = StringToInt(sColors[0]);
	array[1] = StringToInt(sColors[1]);
	array[2] = StringToInt(sColors[2]);
}

stock bool IsValidEnt(int entity)
{
	return (entity > 0 && IsValidEntity(entity) && IsValidEdict(entity));
}

void ResetBools()
{
	RoundTwo = false;
	TimerEnd = false;
	LockTimerRepeate = true;
	if(CountDownTimer) CountDownTimer = 0;
}
