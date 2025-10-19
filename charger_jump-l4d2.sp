#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "2.0"
#define CVAR_FLAGS FCVAR_NOTIFY
#define ZOMBIECLASS_CHARGER 6

ConVar cvarInertiaVault, cvarInertiaVaultPower, cvarInertiaVaultDelay;
bool bHooked = false, isCharging[MAXPLAYERS + 1] = {false, ...}, buttondelay[MAXPLAYERS + 1] = {false, ...}, isInertiaVault = false;
float ivPover = 0.0, ivWait = 0.0;
Handle JumpTimer[MAXPLAYERS + 1] = {null, ...};
int timerElapsed = 0;

public Plugin myinfo = 
{
    name = "[L4D2] Charger Jump",
    author = "Mortiegama(Edit. by BloodyBlade)",
    description = "Allows Chargers To Jump While Charging.",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?p=2116076#post2116076"
};

public void OnPluginStart()
{
	CreateConVar("charger_jump-l4d2_version", PLUGIN_VERSION, "Charger Jump Version", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
	cvarInertiaVault = CreateConVar("charger_jump-l4d2_inertiavault", "1", "Enable/Disable Plugin", CVAR_FLAGS, true, 0.0, false, _);
	cvarInertiaVaultPower = CreateConVar("charger_jump-l4d2_inertiavaultpower", "425.0", "Inertia Vault Value Applied To Charger Jump", CVAR_FLAGS, true, 0.0, false, _);
	cvarInertiaVaultDelay = CreateConVar("charger_jump-l4d2_inertiavaultdelay", "7.0", "Delay Before Inertia Vault Kicks In", CVAR_FLAGS, true, 0.0, false, _);

	AutoExecConfig(true, "charger_jump-l4d2");

	cvarInertiaVault.AddChangeHook(OnPluginEnableChanged);
	cvarInertiaVaultPower.AddChangeHook(OnConVarsChanged);
	cvarInertiaVaultDelay.AddChangeHook(OnConVarsChanged);
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void OnPluginEnableChanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{	
	IsAllowed();
}

void OnConVarsChanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{	
	ivPover = cvarInertiaVaultPower.FloatValue;
	ivWait = cvarInertiaVaultDelay.FloatValue;
}

void IsAllowed()
{
    isInertiaVault = cvarInertiaVault.BoolValue;
    if(!bHooked && isInertiaVault)
    {
        bHooked = true;
        OnConVarsChanged(null, "", "");
        HookEvent("charger_charge_start", Events);
        HookEvent("charger_carry_start", Events);
        HookEvent("charger_charge_end", Events);
        HookEvent("charger_carry_end", Events);
        HookEvent("charger_killed", Events);
    }
    else if(bHooked && !isInertiaVault)
    {
        bHooked = false;
        UnhookEvent("charger_charge_start", Events);
        UnhookEvent("charger_carry_start", Events);
        UnhookEvent("charger_charge_end", Events);
        UnhookEvent("charger_carry_end", Events);
        UnhookEvent("charger_killed", Events);
    }
}

Action Events(Event event, char[] name, bool dontBroadcast)
{
	if (strcmp(name, "charger_charge_start") == 0 || strcmp(name, "charger_carry_start") == 0)
	{
		int charging = GetClientOfUserId(event.GetInt("userid"));
		if (IsValidCharger(charging) && !IsFakeClient(charging))
		{
			isCharging[charging] = true;
			buttondelay[charging] = false;
		}
	}
	else if (strcmp(name, "charger_carry_start") == 0)
	{
		int carrying = GetClientOfUserId(event.GetInt("userid"));
		if (IsValidCharger(carrying) && !IsFakeClient(carrying))
		{
			SetEntPropFloat(carrying, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
			SetEntPropFloat(carrying, Prop_Send, "m_flProgressBarDuration", ivWait);

			if (JumpTimer[carrying] != null)
			{
				delete JumpTimer[carrying];
			}
			JumpTimer[carrying] = CreateTimer(ivWait, CloseJumpHandle, carrying, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else if(strcmp(name, "charger_charge_end") == 0 || strcmp(name, "charger_carry_end") == 0 || strcmp(name, "charger_killed") == 0)
	{
		int attacker = GetClientOfUserId(event.GetInt("userid"));
		if (IsValidCharger(attacker) && !IsFakeClient(attacker))
		{
			SetEntPropFloat(attacker, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
			SetEntPropFloat(attacker, Prop_Send, "m_flProgressBarDuration", 0.0);

			isCharging[attacker] = false;

			if (buttondelay[attacker])
			{
				buttondelay[attacker] = false;

				int target = GetClientOfUserId(event.GetInt("victim"));
				if (IsValidClient(target) && GetClientTeam(target) == 2 && IsPlayerAlive(target) && !IsPlayerOnGround(target))
				{
					float vec[3];
					vec[0] = GetEntPropFloat(target, Prop_Send, "m_vecVelocity[0]");
					vec[1] = GetEntPropFloat(target, Prop_Send, "m_vecVelocity[1]");
					vec[2] = GetEntPropFloat(target, Prop_Send, "m_vecVelocity[2]") + (ivPover * 3);

					TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, vec);

					DataPack releaseFix;
					CreateDataTimer(1.0, CheckForReleases, releaseFix, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT|TIMER_DATA_HNDL_CLOSE);
					releaseFix.WriteCell(GetClientUserId(attacker));
					releaseFix.WriteCell(GetClientUserId(target));
				}
			}
		}
	}
	return Plugin_Continue;
}

Action CheckForReleases(Handle timer, DataPack hReleaseFix)
{
	hReleaseFix.Reset();

	int charger = GetClientOfUserId(hReleaseFix.ReadCell());
	int survivor = GetClientOfUserId(hReleaseFix.ReadCell());
	if (!IsValidCharger(charger) || IsFakeClient(charger) || !IsValidClient(survivor) || GetClientTeam(survivor) != 2 || IsPlayerAlive(survivor))
	{
		if (timerElapsed < 5)
		{
			timerElapsed += 1;
			return Plugin_Continue;
		}
		else
		{
			timerElapsed = 0;
			return Plugin_Stop;
		}
	}

	Event OnPlayerDeath = CreateEvent("player_death", true);
	OnPlayerDeath.SetInt("userid", GetClientUserId(survivor));
	OnPlayerDeath.SetInt("attacker", GetClientUserId(charger));
	OnPlayerDeath.Fire(false);

	return Plugin_Stop;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if ((buttons & IN_JUMP) && IsValidCharger(client) && !IsFakeClient(client) && isCharging[client])
	{
		if (isInertiaVault && buttondelay[client] && IsPlayerOnGround(client))
		{
			float vec[3];
			vec[0] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
			vec[1] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
			vec[2] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]") + ivPover;
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vec);
		}
	}
	return Plugin_Continue;
}

Action CloseJumpHandle(Handle timer, any carrying)
{
	buttondelay[carrying] = true;
	PrintHintText(carrying, "You Can Jump Now!");
	JumpTimer[carrying] = null;
	return Plugin_Stop;
}

public void OnMapEnd()
{
	timerElapsed = 0;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			isCharging[client] = false;
			buttondelay[client] = false;

			if (JumpTimer[client] != null)
			{
				delete JumpTimer[client];
			}
		}
	}
}

stock bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

stock bool IsPlayerOnGround(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_fFlags") & FL_ONGROUND);
}

stock bool IsValidCharger(int client)
{
	return IsValidClient(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == ZOMBIECLASS_CHARGER;
}
