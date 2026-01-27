#pragma semicolon 1
#define newdecls required

#include <sourcemod>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_NOTIFY

public Plugin myinfo = 
{
	name = "[L4D] Disable Saferoom Friendly Fire",
	author = "BloodyBlade",
	description = "Disable SafeRoom Friendly Fire",
	version = PLUGIN_VERSION,
	url = "https://bloodsiworld.ru/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if (engine != Engine_Left4Dead && engine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

ConVar hPluginEnabled, hSafeRoomOnly;
bool bPluginOn = false, bHooked = false, bSafeRoomOnly = false, var_LeftSafeRoom = false, SDKHooked[MAXPLAYERS + 1] = {false, ...};

public void OnPluginStart()
{
	CreateConVar("l4d_toggle_friendly_fire_version", PLUGIN_VERSION, "L4D Toggle Friendly Fire plugin Version.", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_NOTIFY);
	hPluginEnabled = CreateConVar("l4d_toggle_friendly_fire_plugin_enabled", "1", " Enable/Disable plugin", CVAR_FLAGS, true, 0.0, true, 1.0);
	hSafeRoomOnly = CreateConVar("l4d_toggle_friendly_fire_safe_room_only", "1", "Disable friendly fire in safe room only?", CVAR_FLAGS, true, 0.0, true, 1.0);

	AutoExecConfig(true, "l4d_toggle_friendly_fire");

	hPluginEnabled.AddChangeHook(ConVarPluginOnChanged);
	hSafeRoomOnly.AddChangeHook(ConVarSaferoomOnlyChanged);
}

public void OnConfigsExecuted()
{
    IsAllowed();
}

void ConVarPluginOnChanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{
    IsAllowed();
}

void ConVarSaferoomOnlyChanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{
    bSafeRoomOnly = hSafeRoomOnly.BoolValue;
}

void IsAllowed()
{
	bPluginOn = hPluginEnabled.BoolValue;
	if(bPluginOn && !bHooked)
	{
		bHooked = true;
		ConVarSaferoomOnlyChanged(null, "", "");
		HookEvent("player_left_start_area", Events);
		HookEvent("player_left_checkpoint", Events);
		HookEvent("door_open", Events);
		HookEvent("round_start", Events);
		HookEvent("round_end", Events);
		HookEvent("mission_lost", Events);
		HookEvent("map_transition", Events);
	}
	else if(!bPluginOn && bHooked)
	{
		bHooked = false;
		UnhookEvent("player_left_start_area", Events);
		UnhookEvent("player_left_checkpoint", Events);
		UnhookEvent("door_open", Events);
		UnhookEvent("round_start", Events);
		UnhookEvent("round_end", Events);
		UnhookEvent("mission_lost", Events);
		UnhookEvent("map_transition", Events);
	}
}

public void OnClientPutInServer(int client)
{
	if (bHooked && client > 0 && !SDKHooked[client])
	{
		SDKHooked[client] = true;
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public void OnClientDisconnect(int client)
{
	if (client > 0 && SDKHooked[client])
	{
		SDKHooked[client] = false;
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

void Events(Event event, const char[] name, bool dontBroadcast)
{
	if (strcmp(name, "player_left_start_area") == 0 || strcmp(name, "player_left_checkpoint") == 0 || strcmp(name, "door_open") == 0)
	{
		if (!var_LeftSafeRoom)
		{	
			var_LeftSafeRoom = true;
		}
	}
	else if(strcmp(name, "round_start") == 0 || strcmp(name, "round_end") == 0 || strcmp(name, "mission_lost") == 0 || strcmp(name, "map_transition") == 0)
	{
		if (var_LeftSafeRoom)
		{
			var_LeftSafeRoom = false;
		}
	}
}

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) 
{
	if(bHooked && IsSurvivor(victim) && IsSurvivor(attacker) && ((bSafeRoomOnly && !var_LeftSafeRoom) || !bSafeRoomOnly)) 
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

stock bool IsSurvivor(int client) 
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
}
