#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_NOTIFY

ConVar hTankHPOn, hBasicTankHP, hAddTankHP, hDiffuculty;
int iClassTank = 0, TankBasicHP = 0, TankAddHP = 0;
bool bHooked = false, g_bLeft4Dead2 = false;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if (engine == Engine_Left4Dead)
	{
		g_bLeft4Dead2 = false;
		iClassTank = 5;
	}
	else if(engine == Engine_Left4Dead2)
	{
		g_bLeft4Dead2 = true;
		iClassTank = 8;
	}
	else
	{
		strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead\" game series.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public Plugin myinfo = 
{
	name = "[L4D] Tank HP",
	author = "BloodyBlade",
	description = "Sets the tank's spawning health based on the number of survivors alive and the difficulty multiplier.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=306880"
}

public void OnPluginStart()
{
    CreateConVar("l4d_tank_hp_version", PLUGIN_VERSION, "Tank HP plugin version", CVAR_FLAGS|FCVAR_DONTRECORD);
    hTankHPOn = CreateConVar("l4d_tank_hp_on", "1", "Enable/Disable plugin", CVAR_FLAGS, true, 0.0, true, 1.0);
    hBasicTankHP = CreateConVar("l4d_basic_hp", "4000", "Tank basic health", CVAR_FLAGS);
    hAddTankHP = CreateConVar("l4d_add_hp", "1000", "each additional player Tank increases health", CVAR_FLAGS);

    hDiffuculty = FindConVar("z_difficulty");

    AutoExecConfig(true, "l4d_tank_hp", "sourcemod");

    hTankHPOn.AddChangeHook(OnConVarEnableChanged);
    hBasicTankHP.AddChangeHook(OnConVarsChanged);
    hAddTankHP.AddChangeHook(OnConVarsChanged);
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void OnConVarEnableChanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{
	IsAllowed();
}

void OnConVarsChanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{
	TankBasicHP = hBasicTankHP.IntValue;
	TankAddHP = hAddTankHP.IntValue;
}

void IsAllowed()
{
	bool bPluginOn = hTankHPOn.BoolValue;
	if(!bHooked && bPluginOn)
	{
		bHooked = true;
		OnConVarsChanged(null, "", "");
		HookEvent("player_spawn", Event_PlayerSpawn);
	}
	else if(bHooked && !bPluginOn)
	{
		bHooked = false;
		UnhookEvent("player_spawn", Event_PlayerSpawn);
	}
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && IsClientInGame(client) && GetClientTeam(client) == 3 && IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_zombieClass") == iClassTank)
    {
        float fMultiple = 0.0;
        int SetTankHP = 0, iPlayersCount = 0;
        TankBasicHP = hBasicTankHP.IntValue;
        TankAddHP = hAddTankHP.IntValue;

        char cDifficulty[16];
        hDiffuculty.GetString(cDifficulty, sizeof(cDifficulty));
        if(StrEqual(cDifficulty, "Easy", false))
        {
            fMultiple = 0.5;
        }
        else if(StrEqual(cDifficulty, "Medium", false) || (g_bLeft4Dead2 && StrEqual(cDifficulty, "Normal", false)))
        {
            fMultiple = 1.0;
        }
        else if(StrEqual(cDifficulty, "Hard", false))
        {
            fMultiple = 1.5;
        }
        else if(StrEqual(cDifficulty, "Expert", false) || (g_bLeft4Dead2 && StrEqual(cDifficulty, "Impossible", false)))
        {
            fMultiple = 2.0;
        }

        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i) && IsPlayerAlive(i))
            {
                iPlayersCount++;
            }
        }

        if (iPlayersCount <= 4) iPlayersCount = 4;
        SetTankHP = RoundToCeil((TankBasicHP * fMultiple) + (TankAddHP * (iPlayersCount - 4)));
        SetEntProp(client, Prop_Data, "m_iMaxHealth", SetTankHP);
        SetEntProp(client, Prop_Data, "m_iHealth", SetTankHP);
        PrintToChatAll("\x03The tank has been spawned! \x04Tank Health: \x03%d", SetTankHP);
    }
}
