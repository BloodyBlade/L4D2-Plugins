#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

#define PLUGIN_VERSION "1.2"
#define CVAR_FLAGS FCVAR_NOTIFY

#define ZOMBIECLASS_SMOKER 1
#define ZOMBIECLASS_BOOMER 2
#define ZOMBIECLASS_HUNTER 3
#define ZOMBIECLASS_SPITTER 4
#define ZOMBIECLASS_JOCKEY 5
#define ZOMBIECLASS_CHARGER 6
#define ZOMBIECLASS_TANK 8

public Plugin myinfo =
{
	name = "Digestion",
	author = "Oshroth(edit. by BloodyBlade)",
	description = "Infected regain health from attacking survivors.",
	version = PLUGIN_VERSION,
	url = "<- URL ->"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();
    if (engine != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "Digestion runs in \"Left 4 Dead 2\" game");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

ConVar sm_digestion_plugin_on, sm_digestion_hunter_heal, sm_digestion_hunter_healmaxhp, sm_digestion_hunter_incap, sm_digestion_hunter_kill, sm_digestion_hunter_enable;
ConVar sm_digestion_smoker_heal, sm_digestion_smoker_healmaxhp, sm_digestion_smoker_incap, sm_digestion_smoker_kill, sm_digestion_smoker_enable;
ConVar sm_digestion_boomer_heal, sm_digestion_boomer_healmaxhp, sm_digestion_boomer_incap, sm_digestion_boomer_kill, sm_digestion_boomer_enable;
ConVar sm_digestion_charger_heal, sm_digestion_charger_healmaxhp, sm_digestion_charger_incap, sm_digestion_charger_kill, sm_digestion_charger_enable;
ConVar sm_digestion_tank_heal, sm_digestion_tank_healmaxhp, sm_digestion_tank_incap, sm_digestion_tank_kill, sm_digestion_tank_enable;
ConVar sm_digestion_spitter_heal, sm_digestion_spitter_healmaxhp, sm_digestion_spitter_incap, sm_digestion_spitter_kill, sm_digestion_spitter_enable;
ConVar sm_digestion_jockey_heal, sm_digestion_jockey_healmaxhp, sm_digestion_jockey_incap, sm_digestion_jockey_kill, sm_digestion_jockey_enable;
bool enable = false, bHooked = false, bDigestionHunterEnable = false, bDigestionSmokerEnable = false, bDigestionBoomerEnable = false, bDigestionChargerEnable = false, bDigestionTankEnable = false, bDigestionSpitterEnable = false, bDigestionJockeyEnable = false;
float recover = 0.0, fDigestionHunterHeal = 0.0, fDigestionSmokerHeal = 0.0, fDigestionBoomerHeal = 0.0, fDigestionChargerHeal = 0.0, fDigestionTankHeal = 0.0, fDigestionSpitterHeal = 0.0, fDigestionJockeyHeal = 0.0;
int bonus = 0, maxHP = 0, oldHealth = 0, newHealth = 0, damage = 0, iDigestionHunterHealMaxHP = 0, iDigestionHunterIncap = 0, iDigestionHunterKill = 0, iDigestionSmokerHealMaxHP = 0, iDigestionSmokerIncap = 0;
int iDigestionBoomerHealMaxHP = 0, iDigestionBoomerIncap = 0, iDigestionChargerHealMaxHP = 0, iDigestionChargerIncap = 0, iDigestionTankHealMaxHP = 0, iDigestionTankIncap = 0, iDigestionSpitterHealMaxHP = 0;
int iDigestionSpitterIncap = 0, iDigestionJockeyHealMaxHP = 0, iDigestionJockeyIncap = 0, iDigestionSmockerKill = 0, iDigestionBoomerKill = 0, iDigestionChargerKill = 0, iDigestionTankKill = 0, iDigestionSpitterKill = 0, iDigestionJockeyKill = 0;

public void OnPluginStart()
{	
	CreateConVar("sm_digestion_version", PLUGIN_VERSION, "Digestion plugin version.", CVAR_FLAGS|FCVAR_REPLICATED);

	sm_digestion_plugin_on = CreateConVar("sm_digestion_plugin_on", "1", "Plugin On/Off", CVAR_FLAGS, true, 0.0, true, 1.0);
	sm_digestion_hunter_heal = CreateConVar("sm_digestion_hunter_heal", "0.5", "Amount of damage converted to health", CVAR_FLAGS, true, 0.0);
	sm_digestion_hunter_healmaxhp = CreateConVar("sm_digestion_hunter_healmaxhp", "750", "Hunter max health", CVAR_FLAGS, true, 0.0, true, 65535.0);
	sm_digestion_hunter_incap = CreateConVar("sm_digestion_hunter_incap", "125", "Amount of health given for incapping a survivor",CVAR_FLAGS, true, 0.0);
	sm_digestion_hunter_kill = CreateConVar("sm_digestion_hunter_kill", "250", "Amount of health given for killing a survivor", CVAR_FLAGS, true, 0.0);
	sm_digestion_hunter_enable = CreateConVar("sm_digestion_hunter_enable", "1", "Enable digestion for hunter", CVAR_FLAGS, true, 0.0, true, 1.0);

	sm_digestion_smoker_heal = CreateConVar("sm_digestion_smoker_heal", "0.5", "Amount of damage converted to health", CVAR_FLAGS, true, 0.0);
	sm_digestion_smoker_healmaxhp = CreateConVar("sm_digestion_smoker_healmaxhp", "750", "Smoker max health", CVAR_FLAGS, true, 0.0, true, 65535.0);
	sm_digestion_smoker_incap = CreateConVar("sm_digestion_smoker_incap", "125", "Amount of health given for incapping a survivor", CVAR_FLAGS, true, 0.0);
	sm_digestion_smoker_kill = CreateConVar("sm_digestion_smoker_kill", "250", "Amount of health given for killing a survivor", CVAR_FLAGS, true, 0.0);
	sm_digestion_smoker_enable = CreateConVar("sm_digestion_smoker_enable", "1", "Enable digestion for smoker", CVAR_FLAGS, true, 0.0, true, 1.0);

	sm_digestion_boomer_heal = CreateConVar("sm_digestion_boomer_heal", "0.5", "Amount of damage converted to health", CVAR_FLAGS, true, 0.0);
	sm_digestion_boomer_healmaxhp = CreateConVar("sm_digestion_boomer_healmaxhp", "300", "Boomer max health", CVAR_FLAGS, true, 0.0, true, 65535.0);
	sm_digestion_boomer_incap = CreateConVar("sm_digestion_boomer_incap", "25", "Amount of health given for incapping a survivor", CVAR_FLAGS, true, 0.0);
	sm_digestion_boomer_kill = CreateConVar("sm_digestion_boomer_kill", "50", "Amount of health given for killing a survivor", CVAR_FLAGS, true, 0.0);
	sm_digestion_boomer_enable = CreateConVar("sm_digestion_boomer_enable", "1", "Enable digestion for boomer", CVAR_FLAGS, true, 0.0, true, 1.0);

	sm_digestion_charger_heal = CreateConVar("sm_digestion_charger_heal", "0.5", "Amount of damage converted to health", CVAR_FLAGS, true, 0.0);
	sm_digestion_charger_healmaxhp = CreateConVar("sm_digestion_charger_healmaxhp", "1950", "Charger max health", CVAR_FLAGS, true, 0.0, true, 65535.0);
	sm_digestion_charger_incap = CreateConVar("sm_digestion_charger_incap", "300", "Amount of health given for incapping a survivor", CVAR_FLAGS, true, 0.0);
	sm_digestion_charger_kill = CreateConVar("sm_digestion_charger_kill", "600", "Amount of health given for killing a survivor", CVAR_FLAGS, true, 0.0);
	sm_digestion_charger_enable = CreateConVar("sm_digestion_charger_enable", "1", "Enable digestion for charger", CVAR_FLAGS, true, 0.0, true, 1.0);

	sm_digestion_tank_heal = CreateConVar("sm_digestion_tank_heal", "0.5", "Amount of damage converted to health", CVAR_FLAGS, true, 0.0);
	sm_digestion_tank_healmaxhp = CreateConVar("sm_digestion_tank_healmaxhp", "18000", "Tank max health", CVAR_FLAGS, true, 0.0, true, 65535.0);
	sm_digestion_tank_incap = CreateConVar("sm_digestion_tank_incap", "500", "Amount of health given for incapping a survivor", CVAR_FLAGS, true, 0.0);
	sm_digestion_tank_kill = CreateConVar("sm_digestion_tank_kill", "1000", "Amount of health given for killing a survivor", CVAR_FLAGS, true, 0.0);
	sm_digestion_tank_enable = CreateConVar("sm_digestion_tank_enable", "1", "Enable digestion for tank", CVAR_FLAGS, true, 0.0, true, 1.0);

	sm_digestion_spitter_heal = CreateConVar("sm_digestion_spitter_heal", "0.5", "Amount of damage converted to health", CVAR_FLAGS, true, 0.0);
	sm_digestion_spitter_healmaxhp = CreateConVar("sm_digestion_spitter_healmaxhp", "300", "Spitter max health", CVAR_FLAGS, true, 0.0, true, 65535.0);
	sm_digestion_spitter_incap = CreateConVar("sm_digestion_spitter_incap", "50", "Amount of health given for incapping a survivor", CVAR_FLAGS, true, 0.0);
	sm_digestion_spitter_kill = CreateConVar("sm_digestion_spitter_kill", "100", "Amount of health given for killing a survivor", CVAR_FLAGS, true, 0.0);
	sm_digestion_spitter_enable = CreateConVar("sm_digestion_spitter_enable", "1", "Enable digestion for spitter", CVAR_FLAGS, true, 0.0, true, 1.0);

	sm_digestion_jockey_heal = CreateConVar("sm_digestion_jockey_heal", "0.5", "Amount of damage converted to health", CVAR_FLAGS, true, 0.0);
	sm_digestion_jockey_healmaxhp = CreateConVar("sm_digestion_jockey_healmaxhp", "975", "Jockey max health", CVAR_FLAGS, true, 0.0, true, 65535.0);
	sm_digestion_jockey_incap = CreateConVar("sm_digestion_jockey_incap", "163", "Amount of health given for incapping a survivor", CVAR_FLAGS, true, 0.0);
	sm_digestion_jockey_kill = CreateConVar("sm_digestion_jockey_kill", "325", "Amount of health given for killing a survivor", CVAR_FLAGS, true, 0.0);
	sm_digestion_jockey_enable = CreateConVar("sm_digestion_jockey_enable", "1", "Enable digestion for jockey", CVAR_FLAGS, true, 0.0, true, 1.0);

	sm_digestion_plugin_on.AddChangeHook(OnConVarPluginOnChange);
	sm_digestion_hunter_heal.AddChangeHook(OnConVarsChange);
	sm_digestion_hunter_healmaxhp.AddChangeHook(OnConVarsChange);
	sm_digestion_hunter_incap.AddChangeHook(OnConVarsChange);
	sm_digestion_hunter_kill.AddChangeHook(OnConVarsChange);
	sm_digestion_hunter_enable.AddChangeHook(OnConVarsChange);

	sm_digestion_smoker_heal.AddChangeHook(OnConVarsChange);
	sm_digestion_smoker_healmaxhp.AddChangeHook(OnConVarsChange);
	sm_digestion_smoker_incap.AddChangeHook(OnConVarsChange);
	sm_digestion_smoker_kill.AddChangeHook(OnConVarsChange);
	sm_digestion_smoker_enable.AddChangeHook(OnConVarsChange);

	sm_digestion_boomer_heal.AddChangeHook(OnConVarsChange);
	sm_digestion_boomer_healmaxhp.AddChangeHook(OnConVarsChange);
	sm_digestion_boomer_incap.AddChangeHook(OnConVarsChange);
	sm_digestion_boomer_kill.AddChangeHook(OnConVarsChange);
	sm_digestion_boomer_enable.AddChangeHook(OnConVarsChange);

	sm_digestion_charger_heal.AddChangeHook(OnConVarsChange);
	sm_digestion_charger_healmaxhp.AddChangeHook(OnConVarsChange);
	sm_digestion_charger_incap.AddChangeHook(OnConVarsChange);
	sm_digestion_charger_kill.AddChangeHook(OnConVarsChange);
	sm_digestion_charger_enable.AddChangeHook(OnConVarsChange);

	sm_digestion_tank_heal.AddChangeHook(OnConVarsChange);
	sm_digestion_tank_healmaxhp.AddChangeHook(OnConVarsChange);
	sm_digestion_tank_incap.AddChangeHook(OnConVarsChange);
	sm_digestion_tank_kill.AddChangeHook(OnConVarsChange);
	sm_digestion_tank_enable.AddChangeHook(OnConVarsChange);

	sm_digestion_spitter_heal.AddChangeHook(OnConVarsChange);
	sm_digestion_spitter_healmaxhp.AddChangeHook(OnConVarsChange);
	sm_digestion_spitter_incap.AddChangeHook(OnConVarsChange);
	sm_digestion_spitter_kill.AddChangeHook(OnConVarsChange);
	sm_digestion_spitter_enable.AddChangeHook(OnConVarsChange);

	sm_digestion_jockey_heal.AddChangeHook(OnConVarsChange);
	sm_digestion_jockey_healmaxhp.AddChangeHook(OnConVarsChange);
	sm_digestion_jockey_incap.AddChangeHook(OnConVarsChange);
	sm_digestion_jockey_kill.AddChangeHook(OnConVarsChange);
	sm_digestion_jockey_enable.AddChangeHook(OnConVarsChange);

	AutoExecConfig(true, "l4d2_digestion");
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void OnConVarPluginOnChange(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	IsAllowed();
}

void OnConVarsChange(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	GetCvarValues();
}

void IsAllowed()
{
	bool bPluginOn = sm_digestion_plugin_on.BoolValue;
	if(!bHooked && bPluginOn)
	{
		bHooked = true;
		GetCvarValues();
		HookEvent("player_hurt", Events);
		HookEvent("player_death", Events);
		HookEvent("player_incapacitated", Events);
	}
	else if(bHooked && !bPluginOn)
	{
		bHooked = false;
		UnhookEvent("player_hurt", Events);
		UnhookEvent("player_death", Events);
		UnhookEvent("player_incapacitated", Events);
	}
}

void GetCvarValues()
{
	fDigestionHunterHeal = sm_digestion_hunter_heal.FloatValue;
	iDigestionHunterHealMaxHP = sm_digestion_hunter_healmaxhp.IntValue;
	iDigestionHunterIncap = sm_digestion_hunter_incap.IntValue;
	iDigestionHunterKill = sm_digestion_hunter_kill.IntValue;
	bDigestionHunterEnable = sm_digestion_hunter_enable.BoolValue;
	
	fDigestionSmokerHeal = sm_digestion_smoker_heal.FloatValue;
	iDigestionSmokerHealMaxHP = sm_digestion_smoker_healmaxhp.IntValue;
	iDigestionSmokerIncap = sm_digestion_smoker_incap.IntValue;
	iDigestionSmockerKill = sm_digestion_smoker_kill.IntValue;
	bDigestionSmokerEnable = sm_digestion_smoker_enable.BoolValue;

	fDigestionBoomerHeal = sm_digestion_boomer_heal.FloatValue;
	iDigestionBoomerHealMaxHP = sm_digestion_boomer_healmaxhp.IntValue;
	iDigestionBoomerIncap = sm_digestion_boomer_incap.IntValue;
	iDigestionBoomerKill = sm_digestion_boomer_kill.IntValue;
	bDigestionBoomerEnable = sm_digestion_boomer_enable.BoolValue;
	
	fDigestionChargerHeal = sm_digestion_charger_heal.FloatValue;
	iDigestionChargerHealMaxHP = sm_digestion_charger_healmaxhp.IntValue;
	iDigestionChargerIncap = sm_digestion_charger_incap.IntValue;
	iDigestionChargerKill = sm_digestion_charger_kill.IntValue;
	bDigestionChargerEnable = sm_digestion_charger_enable.BoolValue;
	
	fDigestionTankHeal = sm_digestion_tank_heal.FloatValue;
	iDigestionTankHealMaxHP = sm_digestion_tank_healmaxhp.IntValue;
	iDigestionTankIncap = sm_digestion_tank_incap.IntValue;
	iDigestionTankKill = sm_digestion_tank_kill.IntValue;
	bDigestionTankEnable = sm_digestion_tank_enable.BoolValue;
	
	fDigestionSpitterHeal = sm_digestion_spitter_heal.FloatValue;
	iDigestionSpitterHealMaxHP = sm_digestion_spitter_healmaxhp.IntValue;
	iDigestionSpitterIncap = sm_digestion_spitter_incap.IntValue;
	iDigestionSpitterKill = sm_digestion_spitter_kill.IntValue;
	bDigestionSpitterEnable = sm_digestion_spitter_enable.BoolValue;
	
	fDigestionJockeyHeal = sm_digestion_jockey_heal.FloatValue;
	iDigestionJockeyHealMaxHP = sm_digestion_jockey_healmaxhp.IntValue;
	iDigestionJockeyIncap = sm_digestion_jockey_incap.IntValue;
	iDigestionJockeyKill = sm_digestion_jockey_kill.IntValue;
	bDigestionJockeyEnable = sm_digestion_jockey_enable.BoolValue;
}

Action Events(Event event, char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int target = GetClientOfUserId(event.GetInt("userid"));
	if(IsValidSurv(target) && IsValidInf(attacker))
	{
		int class = GetEntProp(attacker, Prop_Send, "m_zombieClass");
		if (strcmp(name, "player_hurt") == 0)
		{
			damage = event.GetInt("dmg_health");
			switch (class)  
			{	
				case ZOMBIECLASS_BOOMER:
				{
					recover = fDigestionBoomerHeal;
					maxHP = iDigestionBoomerHealMaxHP;
					enable = bDigestionBoomerEnable;
				}
				case ZOMBIECLASS_CHARGER:
				{
					recover = fDigestionChargerHeal;
					maxHP = iDigestionChargerHealMaxHP;
					enable = bDigestionChargerEnable;
				}
				case ZOMBIECLASS_JOCKEY:
				{
					recover = fDigestionJockeyHeal;
					maxHP = iDigestionJockeyHealMaxHP;
					enable = bDigestionJockeyEnable;
				}
				case ZOMBIECLASS_HUNTER:
				{
					recover = fDigestionHunterHeal;
					maxHP = iDigestionHunterHealMaxHP;
					enable = bDigestionHunterEnable;
				}
				case ZOMBIECLASS_SMOKER:
				{
					recover = fDigestionSmokerHeal;
					maxHP = iDigestionSmokerHealMaxHP;
					enable = bDigestionSmokerEnable;
				}
				case ZOMBIECLASS_SPITTER:
				{
					recover = fDigestionSpitterHeal;
					maxHP = iDigestionSpitterHealMaxHP;
					enable = bDigestionSpitterEnable;
				}
				case ZOMBIECLASS_TANK:
				{
					recover = fDigestionTankHeal;
					maxHP = iDigestionTankHealMaxHP;
					enable = bDigestionTankEnable;
				}
			}

			if(!enable || recover <= 0.0)
			{
				return Plugin_Continue;
			}
			oldHealth = GetClientHealth(attacker);
			newHealth = RoundToCeil(damage * recover) + oldHealth;
			//PrintToChatAll("%N OM NOM NOM NOM'd %N", atacker, target);
			//PrintToChatAll("%N got %d HP back for %d damage.", attacker, RoundToCeil(damage * recover), damage);
		}
		else if(strcmp(name, "player_death") == 0)
		{
			switch (class)  
			{	
				case ZOMBIECLASS_BOOMER:
				{
					bonus = iDigestionBoomerKill;
					maxHP = iDigestionBoomerHealMaxHP;
					enable = bDigestionBoomerEnable;
				}
				case ZOMBIECLASS_CHARGER:
				{
					bonus = iDigestionChargerKill;
					maxHP = iDigestionChargerHealMaxHP;
					enable = bDigestionChargerEnable;
				}
				case ZOMBIECLASS_JOCKEY:
				{
					bonus = iDigestionJockeyKill;
					maxHP = iDigestionJockeyHealMaxHP;
					enable = bDigestionJockeyEnable;
				}
				case ZOMBIECLASS_HUNTER:
				{
					bonus = iDigestionHunterKill;
					maxHP = iDigestionHunterHealMaxHP;
					enable = bDigestionHunterEnable;
				}
				case ZOMBIECLASS_SMOKER:
				{
					bonus = iDigestionSmockerKill;
					maxHP = iDigestionSmokerHealMaxHP;
					enable = bDigestionSmokerEnable;
				}
				case ZOMBIECLASS_SPITTER:
				{
					bonus = iDigestionSpitterKill;
					maxHP = iDigestionSpitterHealMaxHP;
					enable = bDigestionSpitterEnable;
				}
				case ZOMBIECLASS_TANK:
				{
					bonus = iDigestionTankKill;
					maxHP = iDigestionTankHealMaxHP;
					enable = bDigestionTankEnable;
				}
			}

			if(!enable || bonus <= 0)
			{
				return Plugin_Continue;
			}
			oldHealth = GetClientHealth(attacker);
			newHealth = bonus + oldHealth;
			PrintHintTextToAll("%N got %d health for killing %N.", attacker, bonus, target);
		}
		else if(strcmp(name, "player_incapacitated") == 0)
		{
			switch (class)  
			{	
				case ZOMBIECLASS_BOOMER:
				{
					bonus = iDigestionBoomerIncap;
					maxHP = iDigestionBoomerHealMaxHP;
					enable = bDigestionBoomerEnable;
				}
				case ZOMBIECLASS_CHARGER:
				{
					bonus = iDigestionChargerIncap;
					maxHP = iDigestionChargerHealMaxHP;
					enable = bDigestionChargerEnable;
				}
				case ZOMBIECLASS_JOCKEY:
				{
					bonus = iDigestionJockeyIncap;
					maxHP = iDigestionJockeyHealMaxHP;
					enable = bDigestionJockeyEnable;
				}
				case ZOMBIECLASS_HUNTER:
				{
					bonus = iDigestionHunterIncap;
					maxHP = iDigestionHunterHealMaxHP;
					enable = bDigestionHunterEnable;
				}
				case ZOMBIECLASS_SMOKER:
				{
					bonus = iDigestionSmokerIncap;
					maxHP = iDigestionSmokerHealMaxHP;
					enable = bDigestionSmokerEnable;
				}
				case ZOMBIECLASS_SPITTER:
				{
					bonus = iDigestionSpitterIncap;
					maxHP = iDigestionSpitterHealMaxHP;
					enable = bDigestionSpitterEnable;
				}
				case ZOMBIECLASS_TANK:
				{
					bonus = iDigestionTankIncap;
					maxHP = iDigestionTankHealMaxHP;
					enable = bDigestionTankEnable;
				}
			}

			if(!enable || bonus <= 0)
			{
				return Plugin_Continue;
			}
			oldHealth = GetClientHealth(attacker);
			newHealth = bonus + oldHealth;
			PrintHintTextToAll("%N got %d health for incapping %N.", attacker, bonus, target);
		}

		if(newHealth > maxHP)
		{
			newHealth = maxHP;
		}

		if(newHealth <= 65355)
		{
			SetEntityHealth(attacker, newHealth);
		}
	}
	return Plugin_Continue;
}

bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client);
}

bool IsValidSurv(int client)
{
	return IsValidClient(client) && GetClientTeam(client) == 2;
}

bool IsValidInf(int client)
{
	return IsValidClient(client) && GetClientTeam(client) == 3 && IsPlayerAlive(client);
}
