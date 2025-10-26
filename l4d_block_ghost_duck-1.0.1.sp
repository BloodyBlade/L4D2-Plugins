#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define PLUGIN_VERSION "1.0.1"
#define CVAR_FLAGS FCVAR_NOTIFY|FCVAR_SPONLY

public Plugin myinfo = 
{
	name = "[L4D] Block Ghost Duck",
	author = "Thraka(Edit. by BloodyBlade)",
	description = "Forces a player (on spawn) to duck-unduck. Prevents ghosts from using exploits.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=868638"
}

ConVar hPluginEnabled;
bool g_bCvarAllow = false;

public void OnPluginStart()
{
	CreateConVar("l4d_ghost_duck_block_ver", PLUGIN_VERSION, "Version of the ghost block plugin.", CVAR_FLAGS|FCVAR_DONTRECORD);
	hPluginEnabled = CreateConVar("l4d2_invicible_ghosts_plugin_enabled", "1", " Enable/Disable plugin", CVAR_FLAGS, true, 0.0, true, 1.0);
	AutoExecConfig(true, "l4d2_invicibleghosts");
	hPluginEnabled.AddChangeHook(OnConVarEnableChanged);
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void OnConVarEnableChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void IsAllowed()
{
	bool bCvarAllow = hPluginEnabled.BoolValue;
	if(!g_bCvarAllow && bCvarAllow)
	{
		g_bCvarAllow = true;
		HookEvent("player_spawn", PlayerSpawn);
	}
	else if(g_bCvarAllow && !bCvarAllow)
	{
		g_bCvarAllow = false;
		UnhookEvent("player_spawn", PlayerSpawn);
	}
}

Action PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client))
	{
		RequestFrame(DuckPlayer, client);
	}
	return Plugin_Continue;
}

void DuckPlayer(int client)
{
	int iClient = GetClientOfUserId(client);
	if (IsValidClient(iClient))
	{
		if (GetEntProp(client, Prop_Send, "m_bDucked") == 1 && GetEntProp(client, Prop_Send, "m_bDucking") == 0 && GetEntPropFloat(client, Prop_Send, "m_flFallVelocity") == 0.0)
		{
			if (!(GetClientButtons(client) & IN_DUCK)) 
			{
				ClientCommand(client, "+duck");
				RequestFrame(UnDuckPlayer, client);
			}
		}
	}
}

void UnDuckPlayer(int client)
{
	int iClient = GetClientOfUserId(client);
	if (IsValidClient(iClient))
	{
		ClientCommand(client, "-duck");
	}
}

stock bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client) && IsPlayerAlive(client);
}
