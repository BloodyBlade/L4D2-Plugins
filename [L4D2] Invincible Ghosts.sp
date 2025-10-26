#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_NOTIFY

public Plugin myinfo = 
{
	name = "[L4D2] Invincible Ghosts",
	author = "BloodyBlade",
	description = "Stops infected ghosts dying from fall damage and drowning etc.",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/profiles/76561198078797525/"
}

ConVar hPluginEnabled;
bool bPluginOn = false;
int m_IsGhost = 0;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if (engine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2 game.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

//Special thanks: https://forums.alliedmods.net/showthread.php?t=116198

public void OnPluginStart()
{
	CreateConVar("l4d2_invicible_ghosts_plugin_version", PLUGIN_VERSION, "[L4D2] Invincible Ghosts plugin version", CVAR_FLAGS|FCVAR_DONTRECORD);
	hPluginEnabled = CreateConVar("l4d2_invicible_ghosts_plugin_enabled", "1", " Enable/Disable plugin", CVAR_FLAGS, true, 0.0, true, 1.0);
	hPluginEnabled.AddChangeHook(ConVarsChanged);
	m_IsGhost = FindSendPropInfo("CTerrorPlayer", "m_isGhost");
	AutoExecConfig(true, "l4d2_invicibleghosts");
}

public void OnConfigsExecuted()
{
	ConVarsChanged(null, "", "");
}

void ConVarsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	bPluginOn = hPluginEnabled.BoolValue;
}

public void OnClientPutInServer(int client)
{
    if (bPluginOn && client > 0)
    {
        SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
    }
}

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if(bPluginOn && victim > 0 && victim <= MaxClients && IsClientInGame(victim) && GetClientTeam(victim) == 3 && view_as<bool>(GetEntData(victim, m_IsGhost)))
	{
		if(damagetype & DMG_FALL)
		{
			damage = 0.0;
		}
		else if(damagetype & DMG_DROWN)
		{
			damage = 0.0;
			ClientCommand(victim, "+use");
			ClientCommand(victim, "-use");
		}
	}
    return Plugin_Continue;
}
