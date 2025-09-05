/*
V1.0
Initial release.

V1.1
Cleaned up the code a bit.
Added all other infected except witch.

V1.2
Added the witch.
Added show witch option to config.
Fixed display not showing properly on tank death.
Improved code performance.

Fork by xZk:
V1.2.1
Fixed bug exceeds 80000 hp
V1.2.2
Fixed hp number appears and disappears

*/
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.2.2"
#define CVAR_FLAGS FCVAR_NOTIFY

public Plugin myinfo =
{
	name = "[L4D2] Infected Hud",
	author = "MasterMind420(Edit. by BloodyBlade)",
	description = "Infected Hud",
	version = PLUGIN_VERSION,
	url = ""
};

PluginData plugin;

enum struct PluginCvars
{
	ConVar show_enable;
	ConVar show_smoker;
	ConVar show_boomer;
	ConVar show_hunter;
	ConVar show_spitter;
	ConVar show_jockey;
	ConVar show_charger;
	ConVar show_tank;
	ConVar show_witch;

	void Init()
	{
		CreateConVar("l4d2_show_version", PLUGIN_VERSION, "[L4D2] Infected Hud plugin version", CVAR_FLAGS|FCVAR_DONTRECORD);
		this.show_enable = CreateConVar("l4d2_show_enable", "0", "[1 = Enable][0 = Disable] Enable/Disable plugin", CVAR_FLAGS, true, 0.0, true, 1.0);
		this.show_smoker = CreateConVar("l4d2_show_smoker", "0", "[1 = Enable][0 = Disable] Show Instuctor Hint For Smoker", CVAR_FLAGS, true, 0.0, true, 1.0);
		this.show_boomer = CreateConVar("l4d2_show_boomer", "0", "[1 = Enable][0 = Disable] Show Instuctor Hint For Boomer", CVAR_FLAGS, true, 0.0, true, 1.0);
		this.show_hunter = CreateConVar("l4d2_show_hunter", "0", "[1 = Enable][0 = Disable] Show Instuctor Hint For Hunter", CVAR_FLAGS, true, 0.0, true, 1.0);
		this.show_spitter = CreateConVar("l4d2_show_spitter", "0", "[1 = Enable][0 = Disable] Show Instuctor Hint For Spitter", CVAR_FLAGS, true, 0.0, true, 1.0);
		this.show_jockey = CreateConVar("l4d2_show_jockey", "0", "[1 = Enable][0 = Disable] Show Instuctor Hint For Jockey", CVAR_FLAGS, true, 0.0, true, 1.0);
		this.show_charger = CreateConVar("l4d2_show_charger", "0", "[1 = Enable][0 = Disable] Show Instuctor Hint For Charger", CVAR_FLAGS, true, 0.0, true, 1.0);
		this.show_tank = CreateConVar("l4d2_show_tank", "1", "[1 = Enable][0 = Disable] Show Instuctor Hint For Tank", CVAR_FLAGS, true, 0.0, true, 1.0);
		this.show_witch = CreateConVar("l4d2_show_witch", "0", "[1 = Enable][0 = Disable] Show Instuctor Hint For Witch", CVAR_FLAGS, true, 0.0, true, 1.0);

		AutoExecConfig(true, "l4d2_infected_hud");
		
		this.show_enable.AddChangeHook(OnConVarPluginOnChange);
		this.show_smoker.AddChangeHook(ConVarChanged_Cvars);
		this.show_boomer.AddChangeHook(ConVarChanged_Cvars);
		this.show_hunter.AddChangeHook(ConVarChanged_Cvars);
		this.show_spitter.AddChangeHook(OnConVarPluginOnChange);
		this.show_jockey.AddChangeHook(ConVarChanged_Cvars);
		this.show_charger.AddChangeHook(ConVarChanged_Cvars);
		this.show_tank.AddChangeHook(ConVarChanged_Cvars);
		this.show_witch.AddChangeHook(ConVarChanged_Cvars);
	}
}

enum struct PluginData
{
	PluginCvars cvars;
	bool bHooked;
	bool bPluginOn;
	bool g_bShowSmoker;
	bool g_bShowBoomer;
	bool g_bShowHunter;
	bool g_bShowSpitter;
	bool g_bShowJockey;
	bool g_bShowCharger;
	bool g_bShowTank;
	bool g_bShowWitch;
	char Message[32];
	int HintIndex[2048 + 1];
	int HintEntity[2048 + 1];

	void Init()
	{
		this.cvars.Init();
	}

	void GetCvarValues()
	{
		this.g_bShowSmoker = this.cvars.show_smoker.BoolValue;
		this.g_bShowBoomer = this.cvars.show_boomer.BoolValue;
		this.g_bShowHunter = this.cvars.show_hunter.BoolValue;
		this.g_bShowSpitter = this.cvars.show_spitter.BoolValue;
		this.g_bShowJockey = this.cvars.show_jockey.BoolValue;
		this.g_bShowCharger = this.cvars.show_charger.BoolValue;
		this.g_bShowTank = this.cvars.show_tank.BoolValue;
		this.g_bShowWitch = this.cvars.show_witch.BoolValue;
	}

	void IsAllowed()
	{
		this.bPluginOn = this.cvars.show_enable.BoolValue;
		if(!this.bHooked && this.bPluginOn)
		{
			this.bHooked = true;
			HookEvent("player_spawn", Events);
			HookEvent("player_death", Events, EventHookMode_Pre);
			HookEvent("tank_killed", Events, EventHookMode_Pre);
			HookEvent("infected_hurt", Events);
			HookEvent("witch_spawn", Events);
			HookEvent("witch_killed", Events, EventHookMode_Pre);
		}
		else if(this.bHooked && !this.bPluginOn)
		{
			this.bHooked = false;
			UnhookEvent("player_spawn", Events);
			UnhookEvent("player_death", Events, EventHookMode_Pre);
			UnhookEvent("tank_killed", Events, EventHookMode_Pre);
			UnhookEvent("infected_hurt", Events);
			UnhookEvent("witch_spawn", Events);
			UnhookEvent("witch_killed", Events, EventHookMode_Pre);
		}
	}
}

public void OnPluginStart()
{	
	plugin.Init();
}

public void OnConfigsExecuted()
{
	plugin.IsAllowed();
	plugin.GetCvarValues();
}

void OnConVarPluginOnChange(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	plugin.IsAllowed();
}

void ConVarChanged_Cvars(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	plugin.GetCvarValues();
}

public void OnClientPutInServer(int client)
{
	if(plugin.bHooked && client > 0)
	{
		SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamage);
	}
}

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if(plugin.bHooked && IsValidInfClient(victim) && !IsIncapped(victim))
	{
		int health = GetEntProp(victim, Prop_Data, "m_iHealth");
		Format(plugin.Message, sizeof(plugin.Message), "%d", health);

		switch(GetEntProp(victim, Prop_Send, "m_zombieClass"))
		{
			case 1:
			{
				if(plugin.g_bShowSmoker)
				{
					DisplayInstructorHint(victim, 0.0, 0.0, true, false, "", "", "", false, {255, 255, 0}, plugin.Message);
				}
			}
			case 2:
			{
				if(plugin.g_bShowBoomer)
				{
					DisplayInstructorHint(victim, 0.0, 0.0, true, false, "", "", "", false, {255, 255, 0}, plugin.Message);
				}
			}
			case 3:
			{
				if(plugin.g_bShowHunter)
				{
					DisplayInstructorHint(victim, 0.0, 0.0, true, false, "", "", "", false, {255, 255, 0}, plugin.Message);
				}
			}
			case 4:
			{
				if(plugin.g_bShowSpitter)
				{
					DisplayInstructorHint(victim, 0.0, 0.0, true, false, "", "", "", false, {255, 255, 0}, plugin.Message);
				}
			}
			case 5:
			{
				if(plugin.g_bShowJockey)
				{
					DisplayInstructorHint(victim, 0.0, 0.0, true, false, "", "", "", false, {255, 255, 0}, plugin.Message);
				}
			}
			case 6:
			{
				if(plugin.g_bShowCharger)
				{
					DisplayInstructorHint(victim, 0.0, 0.0, true, false, "", "", "", false, {255, 255, 0}, plugin.Message);
				}
			}
			case 8:
			{
				if(plugin.g_bShowTank)
				{
					DisplayInstructorHint(victim, 0.0, 0.0, true, false, "", "", "", false, {255, 255, 0}, plugin.Message);
				}
			}
		}
	}
	return Plugin_Continue;
}

Action Events(Event event, char[] name, bool dontBroadcast)
{
	if (strcmp(name, "player_spawn") == 0)
	{
		int special = GetClientOfUserId(event.GetInt("userid"));
		if (IsValidInfClient(special))
		{
			CreateHintEntity(special);
		}
	}
	else if(strcmp(name, "player_death") == 0)
	{
		int special = GetClientOfUserId(event.GetInt("userid"));
		if (IsValidInfClient(special))
		{
			DestroyHintEntity(special);
		}
	}
	else if(strcmp(name, "tank_killed") == 0)
	{
		int tank = GetClientOfUserId(event.GetInt("userid"));
		if (IsValidInfClient(tank))
		{
			DestroyHintEntity(tank);
		}
	}
	else if(strcmp(name, "infected_hurt") == 0)
	{
		int infected = event.GetInt("entityid");
		if (IsValidWitch(infected))
		{
			char sClassName[10];
			GetEntityClassname(infected, sClassName, sizeof(sClassName));
			if(sClassName[0] != 'w' || !StrEqual(sClassName, "witch"))
			{
				return Plugin_Continue;
			}

			int health = GetEntProp(infected, Prop_Data, "m_iHealth");
			Format(plugin.Message, sizeof(plugin.Message), "%d", health);

			if(plugin.g_bShowWitch)
			{
				DisplayInstructorHint(infected, 0.0, 0.0, true, false, "", "", "", false, {255, 255, 0}, plugin.Message);
			}
		}
	}
	else if(strcmp(name, "witch_spawn") == 0)
	{
		int witch = event.GetInt("witchid");
		if(IsValidWitch(witch))
		{
			CreateHintEntity(witch);
		}
	}
	else if(strcmp(name, "witch_killed") == 0)
	{
		int witch = event.GetInt("witchid");
		if(IsValidWitch(witch))
		{
			DestroyHintEntity(witch);
		}
	}
	return Plugin_Continue;
}

stock void DisplayInstructorHint(int target, float fHeight, float fRange, bool bFollow, bool bShowOffScreen, char[] sIconOnScreen, char[] sIconOffScreen, char[] sCmd, bool bShowTextAlways, int iColor[3], char sText[32])
{
	if(!IsValidEntRef(plugin.HintIndex[target]))
	{
		CreateHintEntity(target);
	}
	
	char sBuffer[32];

	FormatEx(sBuffer, sizeof(sBuffer), "si_%d", target);
	DispatchKeyValue(target, "targetname", sBuffer);
	DispatchKeyValue(plugin.HintEntity[target], "hint_target", sBuffer);
	DispatchKeyValue(plugin.HintEntity[target], "hint_name", sBuffer);
	DispatchKeyValue(plugin.HintEntity[target], "hint_replace_key", sBuffer);

	FormatEx(sBuffer, sizeof(sBuffer), "%d", !bFollow);
	DispatchKeyValue(plugin.HintEntity[target], "hint_static", sBuffer);
	DispatchKeyValue(plugin.HintEntity[target], "hint_timeout", "0.0");

	FormatEx(sBuffer, sizeof(sBuffer), "%d", RoundToFloor(fHeight));
	DispatchKeyValue(plugin.HintEntity[target], "hint_icon_offset", sBuffer);

	FormatEx(sBuffer, sizeof(sBuffer), "%d", RoundToFloor(fRange));
	DispatchKeyValue(plugin.HintEntity[target], "hint_range", sBuffer);

	FormatEx(sBuffer, sizeof(sBuffer), "%d", !bShowOffScreen);
	DispatchKeyValue(plugin.HintEntity[target], "hint_nooffscreen", sBuffer);

	DispatchKeyValue(plugin.HintEntity[target], "hint_icon_onscreen", sIconOnScreen);
	DispatchKeyValue(plugin.HintEntity[target], "hint_icon_offscreen", sIconOffScreen);

	DispatchKeyValue(plugin.HintEntity[target], "hint_binding", sCmd);

	// Shows text behind walls (false limits distance of seeing hint)
	FormatEx(sBuffer, sizeof(sBuffer), "%d", bShowTextAlways);
	DispatchKeyValue(plugin.HintEntity[target], "hint_forcecaption", sBuffer);

	FormatEx(sBuffer, sizeof(sBuffer), "%d %d %d", iColor[0], iColor[1], iColor[2]);
	DispatchKeyValue(plugin.HintEntity[target], "hint_color", sBuffer);

	//ReplaceString(sText, sizeof(sText), "\n", " ");
	DispatchKeyValue(plugin.HintEntity[target], "hint_caption", sText);
	DispatchKeyValue(plugin.HintEntity[target], "hint_activator_caption", sText);

	DispatchKeyValue(plugin.HintEntity[target], "hint_flags", "0");
	DispatchKeyValue(plugin.HintEntity[target], "hint_display_limit", "0");
	DispatchKeyValue(plugin.HintEntity[target], "hint_suppress_rest", "1");
	DispatchKeyValue(plugin.HintEntity[target], "hint_instance_type", "2");
	DispatchKeyValue(plugin.HintEntity[target], "hint_auto_start", "false"); //true
	DispatchKeyValue(plugin.HintEntity[target], "hint_local_player_only", "true");
	DispatchKeyValue(plugin.HintEntity[target], "hint_allow_nodraw_target", "true");

	DispatchSpawn(plugin.HintEntity[target]);
	AcceptEntityInput(plugin.HintEntity[target], "ShowHint");

	plugin.HintIndex[target] = EntIndexToEntRef(plugin.HintEntity[target]);
}

void DestroyHintEntity(int client)
{
	if(IsValidEntRef(plugin.HintIndex[client]))
	{
		AcceptEntityInput(plugin.HintIndex[client], "Kill");
		plugin.HintIndex[client] = -1;
	}
}

void CreateHintEntity(int client)
{
	if(IsValidEntRef(plugin.HintIndex[client]))
	{
		AcceptEntityInput(plugin.HintIndex[client], "Kill");
		plugin.HintIndex[client] = -1;
	}

	plugin.HintEntity[client] = CreateEntityByName("env_instructor_hint");
	if(plugin.HintEntity[client] < 0) return;
	DispatchSpawn(plugin.HintEntity[client]);
	plugin.HintIndex[client] = EntIndexToEntRef(plugin.HintEntity[client]);
}

stock bool IsValidInfClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && GetClientTeam(client) == 3;
}

stock bool IsIncapped(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
}

static bool IsValidEntRef(int iEntRef)
{
    static int iEntity;
    iEntity = EntRefToEntIndex(iEntRef);
    return iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity);
}

bool IsValidWitch(int witch)
{
	if(witch > 32 && witch <= 2048 && IsValidEdict(witch) && IsValidEntity(witch))
	{
		char classname[32];
		GetEdictClassname(witch, classname, sizeof(classname));
		if(StrEqual(classname, "witch")) return true;
	}
	return false;
}
