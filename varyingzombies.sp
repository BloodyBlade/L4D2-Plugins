/*
Varying Zombie Population

ChangeLog:
1.0.0 - Initial Release
1.0.5 - Fixed some bugs that caused server to lag
1.1.0 - Special thanks to Die Teetasse for sdkhooks method of changing infected health
1.2.0 - Added zombie acquire time, fixed some stuff, released both L4D1 and L4D2 versions
1.3.0 - Cvar fixes, L4D1 and 2 both in 1 version
1.4.0 - Added specials, new cvar names, and fixed some bugs

*/
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>

#define CVAR_FLAGS FCVAR_NOTIFY
#define PLUGIN_VERSION "1.4.0"

public Plugin myinfo = 
{
	name = "Varying Zombie Population",
	author = "Luke Penny(Edit. by BloodyBlade)",
	description = "Common infected spawns with random health and random speed.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=116515"
}

//Create Handles
ConVar PluginEnable, CvarHealth, CvarSpeed, CvarRange, CvarTime, CvarHunterHealth, CvarSmokerHealth, CvarBoomerHealth, CvarChargerHealth, CvarJockeyHealth, CvarSpitterHealth, MinHealth, MaxHealth, MinSpeed, MaxSpeed, MinRange, MaxRange;
ConVar MinTime, MaxTime, MinHunterHealth, MaxHunterHealth, MinSmokerHealth, MaxSmokerHealth, MinBoomerHealth, MaxBoomerHealth, MinChargerHealth, MaxChargerHealth, MinJockeyHealth, MaxJockeyHealth, MinSpitterHealth, MaxSpitterHealth;
int iMinHealth = 0, iMaxHealth = 0, iMinSpeed = 0, iMaxSpeed = 0, iMinRange = 0, iMaxRange = 0, iMinTime = 0, iMaxTime = 0, iMinHunterHealth = 0, iMaxHunterHealth = 0, iMinSmokerHealth = 0, iMaxSmokerHealth = 0;
int iMinBoomerHealth = 0, iMaxBoomerHealth = 0, iMinChargerHealth = 0, iMaxChargerHealth = 0, iMinJockeyHealth = 0, iMaxJockeyHealth = 0, iMinSpitterHealth = 0, iMaxSpitterHealth = 0;
bool bLeft4Dead2 = false, bHooked = false;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();
    if (engine == Engine_Left4Dead)
    {
        bLeft4Dead2 = false;
    }
    else if(engine == Engine_Left4Dead2)
    {
        bLeft4Dead2 = true;
    }
    else
    {
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead\" game series");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

//Create and set ConVars
public void OnPluginStart()
{
	CreateConVar("l4d_vzp_version", PLUGIN_VERSION, "Varying Zombie Population version", CVAR_FLAGS|FCVAR_DONTRECORD);
	//Common Infected
	PluginEnable = CreateConVar("vz_plugin_enable", "1", "Enable/Disable plugin(default: 1)", CVAR_FLAGS);
	MinHealth = CreateConVar("vz_health_min", "25", "Common min health - minimum health value zombies can have (default 50)", CVAR_FLAGS);
	MaxHealth = CreateConVar("vz_health_max", "100", "Common max health - maximum health value zombies can have (default 50)", CVAR_FLAGS);
	MinSpeed = CreateConVar("vz_speed_min", "200", "Common min speed - minimum speed value zombies can have (default 250", CVAR_FLAGS);
	MaxSpeed = CreateConVar("vz_speed_max", "300", "Common max speed - maximum speed value zombies can have (default 250)", CVAR_FLAGS);
	MinRange = CreateConVar("vz_range_min", "2000", "Common minimum sight - minimum range zombies will acquire targets", CVAR_FLAGS);
	MaxRange = CreateConVar("vz_range_max", "3000", "Common max sight - maximum range zombies will acquire targets", CVAR_FLAGS);
	MinTime = CreateConVar("vz_time_min", "2", "Common min acquire time - minimum time it takes zombies to acquire targets", CVAR_FLAGS);
	MaxTime = CreateConVar("vz_time_max", "8", "Common max acquire time - maximum time it takes zombies to acquire targets", CVAR_FLAGS);
	//Specials
	MinHunterHealth = CreateConVar("vz_hunter_min_health", "200", "Minimum Hunter Health (Default 250)", CVAR_FLAGS);
	MaxHunterHealth = CreateConVar("vz_hunter_max_health", "300", "Maximum Hunter Health (Default 250)", CVAR_FLAGS);
	MinSmokerHealth = CreateConVar("vz_smoker_min_health", "200", "Minimum Smoker Health (Default 250)", CVAR_FLAGS);
	MaxSmokerHealth = CreateConVar("vz_smoker_max_health", "300", "Minimum Smoker Health (Default 250)", CVAR_FLAGS);
	MinBoomerHealth = CreateConVar("vz_boomer_min_health", "25", "Minimum Boomer Health (Default 50)", CVAR_FLAGS);
	MaxBoomerHealth = CreateConVar("vz_boomer_max_health", "75", "Minimum Boomer Health (Default 50)", CVAR_FLAGS);

	if (bLeft4Dead2)
	{
		MinChargerHealth = CreateConVar("vz_charger_min_health", "500", "Minimum Charger Health (Default 600)", CVAR_FLAGS);
		MaxChargerHealth = CreateConVar("vz_charger_max_health", "700", "Minimum Charger Health (Default 600)", CVAR_FLAGS);
		MinJockeyHealth = CreateConVar("vz_jockey_min_health", "275", "Minimum Jockey Health (Default 325)", CVAR_FLAGS);
		MaxJockeyHealth = CreateConVar("vz_jockey_max_health", "375", "Minimum Jockey Health (Default 325)", CVAR_FLAGS);
		MinSpitterHealth = CreateConVar("vz_spitter_min_health", "75", "Minimum Spitter Health (Default 100)", CVAR_FLAGS);
		MaxSpitterHealth = CreateConVar("vz_spitter_max_health", "125", "Minimum Spitter Health (Default 100)", CVAR_FLAGS);
	}

	AutoExecConfig(true, "varyingzombies");

	PluginEnable.AddChangeHook(OnConVarEnableChanged);
	MinHealth.AddChangeHook(OnConVarsChanged);
	MaxHealth.AddChangeHook(OnConVarsChanged);
	MinSpeed.AddChangeHook(OnConVarsChanged);
	MaxSpeed.AddChangeHook(OnConVarsChanged);
	MinRange.AddChangeHook(OnConVarsChanged);
	MaxRange.AddChangeHook(OnConVarsChanged);
	MinTime.AddChangeHook(OnConVarsChanged);
	MaxTime.AddChangeHook(OnConVarsChanged);
	MinHunterHealth.AddChangeHook(OnConVarsChanged);
	MaxHunterHealth.AddChangeHook(OnConVarsChanged);
	MinSmokerHealth.AddChangeHook(OnConVarsChanged);
	MaxSmokerHealth.AddChangeHook(OnConVarsChanged);
	MinBoomerHealth.AddChangeHook(OnConVarsChanged);
	MaxBoomerHealth.AddChangeHook(OnConVarsChanged);

	CvarHealth = FindConVar("z_health");
	CvarSpeed = FindConVar("z_speed");
	CvarRange = FindConVar("z_acquire_far_range");
	CvarTime = FindConVar("z_acquire_far_time");

	CvarHunterHealth = FindConVar("z_hunter_health");
	CvarSmokerHealth = FindConVar("z_gas_health");
	CvarBoomerHealth = FindConVar("z_exploding_health");

	if (bLeft4Dead2)
	{
		MinChargerHealth.AddChangeHook(OnConVarsChanged);
		MaxChargerHealth.AddChangeHook(OnConVarsChanged);
		MinJockeyHealth.AddChangeHook(OnConVarsChanged);
		MaxJockeyHealth.AddChangeHook(OnConVarsChanged);
		MinSpitterHealth.AddChangeHook(OnConVarsChanged);
		MaxSpitterHealth.AddChangeHook(OnConVarsChanged);
		CvarChargerHealth = FindConVar("z_charger_health");
		CvarJockeyHealth = FindConVar("z_jockey_health");
		CvarSpitterHealth = FindConVar("z_spitter_health");
	}
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void OnConVarEnableChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	IsAllowed();
}

void OnConVarsChanged(ConVar convar, const char[] oValue, const char[] nValue)
{
	if(convar == MinHealth)
	{
		iMinHealth = convar.IntValue;
	}
	else if(convar == MaxHealth)
	{
		iMaxHealth = convar.IntValue;
	}
	else if(convar == MinSpeed)
	{
		iMinSpeed = convar.IntValue;
	}
	else if(convar == MaxSpeed)
	{
		iMaxSpeed = convar.IntValue;
	}
	else if(convar == MinRange)
	{
		iMinRange = convar.IntValue;
	}
	else if(convar == MaxRange)
	{
		iMaxRange = convar.IntValue;
	}
	else if(convar == MinTime)
	{
		iMinTime = convar.IntValue;
	}
	else if(convar == MaxTime)
	{
		iMaxTime = convar.IntValue;
	}
	else if(convar == MinHunterHealth)
	{
		iMinHunterHealth = convar.IntValue;
	}
	else if(convar == MaxHunterHealth)
	{
		iMaxHunterHealth = convar.IntValue;
	}
	else if(convar == MinSmokerHealth)
	{
		iMinSmokerHealth = convar.IntValue;
	}
	else if(convar == MaxSmokerHealth)
	{
		iMaxSmokerHealth = convar.IntValue;
	}
	else if(convar == MinBoomerHealth)
	{
		iMinBoomerHealth = convar.IntValue;
	}
	else if(convar == MaxBoomerHealth)
	{
		iMaxBoomerHealth = convar.IntValue;
	}
	else if(convar == MinChargerHealth)
	{
		iMinChargerHealth = convar.IntValue;
	}
	else if(convar == MaxChargerHealth)
	{
		iMaxChargerHealth = convar.IntValue;
	}
	else if(convar == MinJockeyHealth)
	{
		iMinJockeyHealth = convar.IntValue;
	}
	else if(convar == MaxJockeyHealth)
	{
		iMaxJockeyHealth = convar.IntValue;
	}
	else if(convar == MinSpitterHealth)
	{
		iMinSpitterHealth = convar.IntValue;
	}
	else if(convar == MaxSpitterHealth)
	{
		iMaxSpitterHealth = convar.IntValue;
	}
}

void IsAllowed()
{
	bool bPluginOn = PluginEnable.BoolValue;
	if(!bHooked && bPluginOn)
	{
		bHooked = true;
		OnConVarsChanged(MinHealth, "", "");
		OnConVarsChanged(MaxHealth, "", "");
		OnConVarsChanged(MinSpeed, "", "");
		OnConVarsChanged(MaxSpeed, "", "");
		OnConVarsChanged(MinRange, "", "");
		OnConVarsChanged(MaxRange, "", "");
		OnConVarsChanged(MinTime, "", "");
		OnConVarsChanged(MaxTime, "", "");
		OnConVarsChanged(MinHunterHealth, "", "");
		OnConVarsChanged(MaxHunterHealth, "", "");
		OnConVarsChanged(MinSmokerHealth, "", "");
		OnConVarsChanged(MaxSmokerHealth, "", "");
		OnConVarsChanged(MinBoomerHealth, "", "");
		OnConVarsChanged(MaxBoomerHealth, "", "");
		OnConVarsChanged(MinChargerHealth, "", "");
		OnConVarsChanged(MaxChargerHealth, "", "");
		OnConVarsChanged(MinJockeyHealth, "", "");
		OnConVarsChanged(MaxJockeyHealth, "", "");
		OnConVarsChanged(MinSpitterHealth, "", "");
		OnConVarsChanged(MaxSpitterHealth, "", "");
		CreateTimer(5.0, SpecialTimer, _, TIMER_REPEAT);
	}
	else if(bHooked && !PluginEnable)
	{
		bHooked = false;
		MinHealth.RestoreDefault();
		MaxHealth.RestoreDefault();
		MinSpeed.RestoreDefault();
		MaxSpeed.RestoreDefault();
		MinRange.RestoreDefault();
		MaxRange.RestoreDefault();
		MinTime.RestoreDefault();
		MaxTime.RestoreDefault();
		MinHunterHealth.RestoreDefault();
		MaxHunterHealth.RestoreDefault();
		MinSmokerHealth.RestoreDefault();
		MaxSmokerHealth.RestoreDefault();
		MinBoomerHealth.RestoreDefault();
		MaxBoomerHealth.RestoreDefault();
		MinChargerHealth.RestoreDefault();
		MaxChargerHealth.RestoreDefault();
		MinJockeyHealth.RestoreDefault();
		MaxJockeyHealth.RestoreDefault();
		MinSpitterHealth.RestoreDefault();
		MaxSpitterHealth.RestoreDefault();
	}
}

//This will change the values that zombies are spawned with after every individual zombie is spawned, so the next zombie spawned will have a different value
public void OnEntityCreated(int entity, const char[] classname)
{
	if(bHooked)
	{
		if (StrEqual(classname, "infected"))
		{
			//Set the zombie attributes to the new randomized values
			CvarHealth.SetInt(GetRandomInt(iMinHealth, iMaxHealth));
			CvarSpeed.SetInt(GetRandomInt(iMinSpeed, iMaxSpeed));
			CvarRange.SetInt(GetRandomInt(iMinRange, iMaxRange));
			CvarTime.SetInt(GetRandomInt(iMinTime, iMaxTime));
		}
	}
}

Action SpecialTimer(Handle timer)
{
	if(bHooked)
	{
		CvarHunterHealth.SetInt(GetRandomInt(iMinHunterHealth, iMaxHunterHealth));
		CvarSmokerHealth.SetInt(GetRandomInt(iMinSmokerHealth, iMaxSmokerHealth));
		CvarBoomerHealth.SetInt(GetRandomInt(iMinBoomerHealth, iMaxBoomerHealth));
		if (bLeft4Dead2)
		{
			CvarChargerHealth.SetInt(GetRandomInt(iMinChargerHealth, iMaxChargerHealth));
			CvarJockeyHealth.SetInt(GetRandomInt(iMinJockeyHealth, iMaxJockeyHealth));
			CvarSpitterHealth.SetInt(GetRandomInt(iMinSpitterHealth, iMaxSpitterHealth));
		}
		return Plugin_Continue;
	}
	else
	{
		return Plugin_Stop;
	}
}
