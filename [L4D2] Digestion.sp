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

PluginData plugin;

enum struct PluginCvars
{
	ConVar sm_digestion_plugin_on;
	ConVar sm_digestion_hunter_heal;
	ConVar sm_digestion_hunter_healmaxhp;
	ConVar sm_digestion_hunter_incap;
	ConVar sm_digestion_hunter_kill;
	ConVar sm_digestion_hunter_enable;
	ConVar sm_digestion_smoker_heal;
	ConVar sm_digestion_smoker_healmaxhp;
	ConVar sm_digestion_smoker_incap;
	ConVar sm_digestion_smoker_kill;
	ConVar sm_digestion_smoker_enable;
	ConVar sm_digestion_boomer_heal;
	ConVar sm_digestion_boomer_healmaxhp;
	ConVar sm_digestion_boomer_incap;
	ConVar sm_digestion_boomer_kill;
	ConVar sm_digestion_boomer_enable;
	ConVar sm_digestion_charger_heal;
	ConVar sm_digestion_charger_healmaxhp;
	ConVar sm_digestion_charger_incap;
	ConVar sm_digestion_charger_kill;
	ConVar sm_digestion_charger_enable;
	ConVar sm_digestion_tank_heal;
	ConVar sm_digestion_tank_healmaxhp;
	ConVar sm_digestion_tank_incap;
	ConVar sm_digestion_tank_kill;
	ConVar sm_digestion_tank_enable;
	ConVar sm_digestion_spitter_heal;
	ConVar sm_digestion_spitter_healmaxhp;
	ConVar sm_digestion_spitter_incap;
	ConVar sm_digestion_spitter_kill;
	ConVar sm_digestion_spitter_enable;
	ConVar sm_digestion_jockey_heal;
	ConVar sm_digestion_jockey_healmaxhp;
	ConVar sm_digestion_jockey_incap;
	ConVar sm_digestion_jockey_kill;
	ConVar sm_digestion_jockey_enable;

	void Init()
	{
		CreateConVar("sm_digestion_version", PLUGIN_VERSION, "Digestion plugin version.", CVAR_FLAGS|FCVAR_REPLICATED);

		this.sm_digestion_plugin_on = CreateConVar("sm_digestion_plugin_on", "1", "Plugin On/Off", CVAR_FLAGS, true, 0.0, true, 1.0);
		this.sm_digestion_hunter_heal = CreateConVar("sm_digestion_hunter_heal", "0.5", "Amount of damage converted to health", CVAR_FLAGS, true, 0.0);
		this.sm_digestion_hunter_healmaxhp = CreateConVar("sm_digestion_hunter_healmaxhp", "750", "Hunter max health", CVAR_FLAGS, true, 0.0, true, 65535.0);
		this.sm_digestion_hunter_incap = CreateConVar("sm_digestion_hunter_incap", "125", "Amount of health given for incapping a survivor",CVAR_FLAGS, true, 0.0);
		this.sm_digestion_hunter_kill = CreateConVar("sm_digestion_hunter_kill", "250", "Amount of health given for killing a survivor", CVAR_FLAGS, true, 0.0);
		this.sm_digestion_hunter_enable = CreateConVar("sm_digestion_hunter_enable", "1", "Enable digestion for hunter", CVAR_FLAGS, true, 0.0, true, 1.0);

		this.sm_digestion_smoker_heal = CreateConVar("sm_digestion_smoker_heal", "0.5", "Amount of damage converted to health", CVAR_FLAGS, true, 0.0);
		this.sm_digestion_smoker_healmaxhp = CreateConVar("sm_digestion_smoker_healmaxhp", "750", "Smoker max health", CVAR_FLAGS, true, 0.0, true, 65535.0);
		this.sm_digestion_smoker_incap = CreateConVar("sm_digestion_smoker_incap", "125", "Amount of health given for incapping a survivor", CVAR_FLAGS, true, 0.0);
		this.sm_digestion_smoker_kill = CreateConVar("sm_digestion_smoker_kill", "250", "Amount of health given for killing a survivor", CVAR_FLAGS, true, 0.0);
		this.sm_digestion_smoker_enable = CreateConVar("sm_digestion_smoker_enable", "1", "Enable digestion for smoker", CVAR_FLAGS, true, 0.0, true, 1.0);

		this.sm_digestion_boomer_heal = CreateConVar("sm_digestion_boomer_heal", "0.5", "Amount of damage converted to health", CVAR_FLAGS, true, 0.0);
		this.sm_digestion_boomer_healmaxhp = CreateConVar("sm_digestion_boomer_healmaxhp", "300", "Boomer max health", CVAR_FLAGS, true, 0.0, true, 65535.0);
		this.sm_digestion_boomer_incap = CreateConVar("sm_digestion_boomer_incap", "25", "Amount of health given for incapping a survivor", CVAR_FLAGS, true, 0.0);
		this.sm_digestion_boomer_kill = CreateConVar("sm_digestion_boomer_kill", "50", "Amount of health given for killing a survivor", CVAR_FLAGS, true, 0.0);
		this.sm_digestion_boomer_enable = CreateConVar("sm_digestion_boomer_enable", "1", "Enable digestion for boomer", CVAR_FLAGS, true, 0.0, true, 1.0);

		this.sm_digestion_charger_heal = CreateConVar("sm_digestion_charger_heal", "0.5", "Amount of damage converted to health", CVAR_FLAGS, true, 0.0);
		this.sm_digestion_charger_healmaxhp = CreateConVar("sm_digestion_charger_healmaxhp", "1950", "Charger max health", CVAR_FLAGS, true, 0.0, true, 65535.0);
		this.sm_digestion_charger_incap = CreateConVar("sm_digestion_charger_incap", "300", "Amount of health given for incapping a survivor", CVAR_FLAGS, true, 0.0);
		this.sm_digestion_charger_kill = CreateConVar("sm_digestion_charger_kill", "600", "Amount of health given for killing a survivor", CVAR_FLAGS, true, 0.0);
		this.sm_digestion_charger_enable = CreateConVar("sm_digestion_charger_enable", "1", "Enable digestion for charger", CVAR_FLAGS, true, 0.0, true, 1.0);

		this.sm_digestion_tank_heal = CreateConVar("sm_digestion_tank_heal", "0.5", "Amount of damage converted to health", CVAR_FLAGS, true, 0.0);
		this.sm_digestion_tank_healmaxhp = CreateConVar("sm_digestion_tank_healmaxhp", "18000", "Tank max health", CVAR_FLAGS, true, 0.0, true, 65535.0);
		this.sm_digestion_tank_incap = CreateConVar("sm_digestion_tank_incap", "500", "Amount of health given for incapping a survivor", CVAR_FLAGS, true, 0.0);
		this.sm_digestion_tank_kill = CreateConVar("sm_digestion_tank_kill", "1000", "Amount of health given for killing a survivor", CVAR_FLAGS, true, 0.0);
		this.sm_digestion_tank_enable = CreateConVar("sm_digestion_tank_enable", "1", "Enable digestion for tank", CVAR_FLAGS, true, 0.0, true, 1.0);

		this.sm_digestion_spitter_heal = CreateConVar("sm_digestion_spitter_heal", "0.5", "Amount of damage converted to health", CVAR_FLAGS, true, 0.0);
		this.sm_digestion_spitter_healmaxhp = CreateConVar("sm_digestion_spitter_healmaxhp", "300", "Spitter max health", CVAR_FLAGS, true, 0.0, true, 65535.0);
		this.sm_digestion_spitter_incap = CreateConVar("sm_digestion_spitter_incap", "50", "Amount of health given for incapping a survivor", CVAR_FLAGS, true, 0.0);
		this.sm_digestion_spitter_kill = CreateConVar("sm_digestion_spitter_kill", "100", "Amount of health given for killing a survivor", CVAR_FLAGS, true, 0.0);
		this.sm_digestion_spitter_enable = CreateConVar("sm_digestion_spitter_enable", "1", "Enable digestion for spitter", CVAR_FLAGS, true, 0.0, true, 1.0);

		this.sm_digestion_jockey_heal = CreateConVar("sm_digestion_jockey_heal", "0.5", "Amount of damage converted to health", CVAR_FLAGS, true, 0.0);
		this.sm_digestion_jockey_healmaxhp = CreateConVar("sm_digestion_jockey_healmaxhp", "975", "Jockey max health", CVAR_FLAGS, true, 0.0, true, 65535.0);
		this.sm_digestion_jockey_incap = CreateConVar("sm_digestion_jockey_incap", "163", "Amount of health given for incapping a survivor", CVAR_FLAGS, true, 0.0);
		this.sm_digestion_jockey_kill = CreateConVar("sm_digestion_jockey_kill", "325", "Amount of health given for killing a survivor", CVAR_FLAGS, true, 0.0);
		this.sm_digestion_jockey_enable = CreateConVar("sm_digestion_jockey_enable", "1", "Enable digestion for jockey", CVAR_FLAGS, true, 0.0, true, 1.0);

		this.sm_digestion_plugin_on.AddChangeHook(OnConVarPluginOnChange);
		this.sm_digestion_hunter_heal.AddChangeHook(OnConVarsChange);
		this.sm_digestion_hunter_healmaxhp.AddChangeHook(OnConVarsChange);
		this.sm_digestion_hunter_incap.AddChangeHook(OnConVarsChange);
		this.sm_digestion_hunter_kill.AddChangeHook(OnConVarsChange);
		this.sm_digestion_hunter_enable.AddChangeHook(OnConVarsChange);

		this.sm_digestion_smoker_heal.AddChangeHook(OnConVarsChange);
		this.sm_digestion_smoker_healmaxhp.AddChangeHook(OnConVarsChange);
		this.sm_digestion_smoker_incap.AddChangeHook(OnConVarsChange);
		this.sm_digestion_smoker_kill.AddChangeHook(OnConVarsChange);
		this.sm_digestion_smoker_enable.AddChangeHook(OnConVarsChange);

		this.sm_digestion_boomer_heal.AddChangeHook(OnConVarsChange);
		this.sm_digestion_boomer_healmaxhp.AddChangeHook(OnConVarsChange);
		this.sm_digestion_boomer_incap.AddChangeHook(OnConVarsChange);
		this.sm_digestion_boomer_kill.AddChangeHook(OnConVarsChange);
		this.sm_digestion_boomer_enable.AddChangeHook(OnConVarsChange);

		this.sm_digestion_charger_heal.AddChangeHook(OnConVarsChange);
		this.sm_digestion_charger_healmaxhp.AddChangeHook(OnConVarsChange);
		this.sm_digestion_charger_incap.AddChangeHook(OnConVarsChange);
		this.sm_digestion_charger_kill.AddChangeHook(OnConVarsChange);
		this.sm_digestion_charger_enable.AddChangeHook(OnConVarsChange);

		this.sm_digestion_tank_heal.AddChangeHook(OnConVarsChange);
		this.sm_digestion_tank_healmaxhp.AddChangeHook(OnConVarsChange);
		this.sm_digestion_tank_incap.AddChangeHook(OnConVarsChange);
		this.sm_digestion_tank_kill.AddChangeHook(OnConVarsChange);
		this.sm_digestion_tank_enable.AddChangeHook(OnConVarsChange);

		this.sm_digestion_spitter_heal.AddChangeHook(OnConVarsChange);
		this.sm_digestion_spitter_healmaxhp.AddChangeHook(OnConVarsChange);
		this.sm_digestion_spitter_incap.AddChangeHook(OnConVarsChange);
		this.sm_digestion_spitter_kill.AddChangeHook(OnConVarsChange);
		this.sm_digestion_spitter_enable.AddChangeHook(OnConVarsChange);

		this.sm_digestion_jockey_heal.AddChangeHook(OnConVarsChange);
		this.sm_digestion_jockey_healmaxhp.AddChangeHook(OnConVarsChange);
		this.sm_digestion_jockey_incap.AddChangeHook(OnConVarsChange);
		this.sm_digestion_jockey_kill.AddChangeHook(OnConVarsChange);
		this.sm_digestion_jockey_enable.AddChangeHook(OnConVarsChange);

		AutoExecConfig(true, "l4d2_digestion");
	}
}

enum struct PluginData
{
	PluginCvars cvars;
	bool bHooked;
	bool bPluginOn;
	bool enable;
	bool bDigestionHunterEnable;
	bool bDigestionSmokerEnable;
	bool bDigestionBoomerEnable;
	bool bDigestionChargerEnable;
	bool bDigestionTankEnable;
	bool bDigestionSpitterEnable;
	bool bDigestionJockeyEnable;
	float recover;
	float fDigestionHunterHeal;
	float fDigestionSmokerHeal;
	float fDigestionBoomerHeal;
	float fDigestionChargerHeal;
	float fDigestionTankHeal;
	float fDigestionSpitterHeal;
	float fDigestionJockeyHeal;
	int iDigestionHunterHealMaxHP;
	int iDigestionHunterIncap;
	int iDigestionHunterKill;
	int iDigestionSmokerHealMaxHP;
	int iDigestionSmokerIncap;
	int iDigestionBoomerHealMaxHP;
	int iDigestionBoomerIncap;
	int iDigestionChargerHealMaxHP;
	int iDigestionChargerIncap;
	int iDigestionTankHealMaxHP;
	int iDigestionTankIncap;
	int iDigestionSpitterHealMaxHP;
	int iDigestionSpitterIncap;
	int iDigestionJockeyHealMaxHP;
	int iDigestionJockeyIncap;
	int iDigestionSmockerKill;
	int iDigestionBoomerKill;
	int iDigestionChargerKill;
	int iDigestionTankKill;
	int iDigestionSpitterKill;
	int iDigestionJockeyKill;
	int bonus;
	int maxHP;
	int oldHealth;
	int newHealth;
	int damage;

	void Init()
	{
		this.cvars.Init();
	}

	void GetCvarValues()
	{
		this.fDigestionHunterHeal = this.cvars.sm_digestion_hunter_heal.FloatValue;
		this.iDigestionHunterHealMaxHP = this.cvars.sm_digestion_hunter_healmaxhp.IntValue;
		this.iDigestionHunterIncap = this.cvars.sm_digestion_hunter_incap.IntValue;
		this.iDigestionHunterKill = this.cvars.sm_digestion_hunter_kill.IntValue;
		this.bDigestionHunterEnable = this.cvars.sm_digestion_hunter_enable.BoolValue;
		
		this.fDigestionSmokerHeal = this.cvars.sm_digestion_smoker_heal.FloatValue;
		this.iDigestionSmokerHealMaxHP = this.cvars.sm_digestion_smoker_healmaxhp.IntValue;
		this.iDigestionSmokerIncap = this.cvars.sm_digestion_smoker_incap.IntValue;
		this.iDigestionSmockerKill = this.cvars.sm_digestion_smoker_kill.IntValue;
		this.bDigestionSmokerEnable = this.cvars.sm_digestion_smoker_enable.BoolValue;

		this.fDigestionBoomerHeal = this.cvars.sm_digestion_boomer_heal.FloatValue;
		this.iDigestionBoomerHealMaxHP = this.cvars.sm_digestion_boomer_healmaxhp.IntValue;
		this.iDigestionBoomerIncap = this.cvars.sm_digestion_boomer_incap.IntValue;
		this.iDigestionBoomerKill = this.cvars.sm_digestion_boomer_kill.IntValue;
		this.bDigestionBoomerEnable = this.cvars.sm_digestion_boomer_enable.BoolValue;
		
		this.fDigestionChargerHeal = this.cvars.sm_digestion_charger_heal.FloatValue;
		this.iDigestionChargerHealMaxHP = this.cvars.sm_digestion_charger_healmaxhp.IntValue;
		this.iDigestionChargerIncap = this.cvars.sm_digestion_charger_incap.IntValue;
		this.iDigestionChargerKill = this.cvars.sm_digestion_charger_kill.IntValue;
		this.bDigestionChargerEnable = this.cvars.sm_digestion_charger_enable.BoolValue;
		
		this.fDigestionTankHeal = this.cvars.sm_digestion_tank_heal.FloatValue;
		this.iDigestionTankHealMaxHP = this.cvars.sm_digestion_tank_healmaxhp.IntValue;
		this.iDigestionTankIncap = this.cvars.sm_digestion_tank_incap.IntValue;
		this.iDigestionTankKill = this.cvars.sm_digestion_tank_kill.IntValue;
		this.bDigestionTankEnable = this.cvars.sm_digestion_tank_enable.BoolValue;
		
		this.fDigestionSpitterHeal = this.cvars.sm_digestion_spitter_heal.FloatValue;
		this.iDigestionSpitterHealMaxHP = this.cvars.sm_digestion_spitter_healmaxhp.IntValue;
		this.iDigestionSpitterIncap = this.cvars.sm_digestion_spitter_incap.IntValue;
		this.iDigestionSpitterKill = this.cvars.sm_digestion_spitter_kill.IntValue;
		this.bDigestionSpitterEnable = this.cvars.sm_digestion_spitter_enable.BoolValue;
		
		this.fDigestionJockeyHeal = this.cvars.sm_digestion_jockey_heal.FloatValue;
		this.iDigestionJockeyHealMaxHP = this.cvars.sm_digestion_jockey_healmaxhp.IntValue;
		this.iDigestionJockeyIncap = this.cvars.sm_digestion_jockey_incap.IntValue;
		this.iDigestionJockeyKill = this.cvars.sm_digestion_jockey_kill.IntValue;
		this.bDigestionJockeyEnable = this.cvars.sm_digestion_jockey_enable.BoolValue;
	}

	void IsAllowed()
	{
		this.bPluginOn = this.cvars.sm_digestion_plugin_on.BoolValue;
		if(!this.bHooked && this.bPluginOn)
		{
			this.bHooked = true;
			HookEvent("player_hurt", Events);
			HookEvent("player_death", Events);
			HookEvent("player_incapacitated", Events);
		}
		else if(this.bHooked && !this.bPluginOn)
		{
			this.bHooked = false;
			UnhookEvent("player_hurt", Events);
			UnhookEvent("player_death", Events);
			UnhookEvent("player_incapacitated", Events);
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

void OnConVarsChange(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	plugin.GetCvarValues();
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
			plugin.damage = event.GetInt("dmg_health");
			switch (class)  
			{	
				case ZOMBIECLASS_BOOMER:
				{
					plugin.recover = plugin.fDigestionBoomerHeal;
					plugin.maxHP = plugin.iDigestionBoomerHealMaxHP;
					plugin.enable = plugin.bDigestionBoomerEnable;
				}
				case ZOMBIECLASS_CHARGER:
				{
					plugin.recover = plugin.fDigestionChargerHeal;
					plugin.maxHP = plugin.iDigestionChargerHealMaxHP;
					plugin.enable = plugin.bDigestionChargerEnable;
				}
				case ZOMBIECLASS_JOCKEY:
				{
					plugin.recover = plugin.fDigestionJockeyHeal;
					plugin.maxHP = plugin.iDigestionJockeyHealMaxHP;
					plugin.enable = plugin.bDigestionJockeyEnable;
				}
				case ZOMBIECLASS_HUNTER:
				{
					plugin.recover = plugin.fDigestionHunterHeal;
					plugin.maxHP = plugin.iDigestionHunterHealMaxHP;
					plugin.enable = plugin.bDigestionHunterEnable;
				}
				case ZOMBIECLASS_SMOKER:
				{
					plugin.recover = plugin.fDigestionSmokerHeal;
					plugin.maxHP = plugin.iDigestionSmokerHealMaxHP;
					plugin.enable = plugin.bDigestionSmokerEnable;
				}
				case ZOMBIECLASS_SPITTER:
				{
					plugin.recover = plugin.fDigestionSpitterHeal;
					plugin.maxHP = plugin.iDigestionSpitterHealMaxHP;
					plugin.enable = plugin.bDigestionSpitterEnable;
				}
				case ZOMBIECLASS_TANK:
				{
					plugin.recover = plugin.fDigestionTankHeal;
					plugin.maxHP = plugin.iDigestionTankHealMaxHP;
					plugin.enable = plugin.bDigestionTankEnable;
				}
			}

			if(!plugin.enable || plugin.recover <= 0.0)
			{
				return Plugin_Continue;
			}
			plugin.oldHealth = GetClientHealth(attacker);
			plugin.newHealth = RoundToCeil(plugin.damage * plugin.recover) + plugin.oldHealth;
			//PrintToChatAll("%N OM NOM NOM NOM'd %N", atacker, target);
			//PrintToChatAll("%N got %d HP back for %d damage.", attacker, RoundToCeil(plugin.damage * plugin.recover), plugin.damage);
		}
		else if(strcmp(name, "player_death") == 0)
		{
			switch (class)  
			{	
				case ZOMBIECLASS_BOOMER:
				{
					plugin.bonus = plugin.iDigestionBoomerKill;
					plugin.maxHP = plugin.iDigestionBoomerHealMaxHP;
					plugin.enable = plugin.bDigestionBoomerEnable;
				}
				case ZOMBIECLASS_CHARGER:
				{
					plugin.bonus = plugin.iDigestionChargerKill;
					plugin.maxHP = plugin.iDigestionChargerHealMaxHP;
					plugin.enable = plugin.bDigestionChargerEnable;
				}
				case ZOMBIECLASS_JOCKEY:
				{
					plugin.bonus = plugin.iDigestionJockeyKill;
					plugin.maxHP = plugin.iDigestionJockeyHealMaxHP;
					plugin.enable = plugin.bDigestionJockeyEnable;
				}
				case ZOMBIECLASS_HUNTER:
				{
					plugin.bonus = plugin.iDigestionHunterKill;
					plugin.maxHP = plugin.iDigestionHunterHealMaxHP;
					plugin.enable = plugin.bDigestionHunterEnable;
				}
				case ZOMBIECLASS_SMOKER:
				{
					plugin.bonus = plugin.iDigestionSmockerKill;
					plugin.maxHP = plugin.iDigestionSmokerHealMaxHP;
					plugin.enable = plugin.bDigestionSmokerEnable;
				}
				case ZOMBIECLASS_SPITTER:
				{
					plugin.bonus = plugin.iDigestionSpitterKill;
					plugin.maxHP = plugin.iDigestionSpitterHealMaxHP;
					plugin.enable = plugin.bDigestionSpitterEnable;
				}
				case ZOMBIECLASS_TANK:
				{
					plugin.bonus = plugin.iDigestionTankKill;
					plugin.maxHP = plugin.iDigestionTankHealMaxHP;
					plugin.enable = plugin.bDigestionTankEnable;
				}
			}

			if(!plugin.enable || plugin.bonus <= 0)
			{
				return Plugin_Continue;
			}
			plugin.oldHealth = GetClientHealth(attacker);
			plugin.newHealth = plugin.bonus + plugin.oldHealth;
			PrintHintTextToAll("%N got %d health for killing %N.", attacker, plugin.bonus, target);
		}
		else if(strcmp(name, "player_incapacitated") == 0)
		{
			switch (class)  
			{	
				case ZOMBIECLASS_BOOMER:
				{
					plugin.bonus = plugin.iDigestionBoomerIncap;
					plugin.maxHP = plugin.iDigestionBoomerHealMaxHP;
					plugin.enable = plugin.bDigestionBoomerEnable;
				}
				case ZOMBIECLASS_CHARGER:
				{
					plugin.bonus = plugin.iDigestionChargerIncap;
					plugin.maxHP = plugin.iDigestionChargerHealMaxHP;
					plugin.enable = plugin.bDigestionChargerEnable;
				}
				case ZOMBIECLASS_JOCKEY:
				{
					plugin.bonus = plugin.iDigestionJockeyIncap;
					plugin.maxHP = plugin.iDigestionJockeyHealMaxHP;
					plugin.enable = plugin.bDigestionJockeyEnable;
				}
				case ZOMBIECLASS_HUNTER:
				{
					plugin.bonus = plugin.iDigestionHunterIncap;
					plugin.maxHP = plugin.iDigestionHunterHealMaxHP;
					plugin.enable = plugin.bDigestionHunterEnable;
				}
				case ZOMBIECLASS_SMOKER:
				{
					plugin.bonus = plugin.iDigestionSmokerIncap;
					plugin.maxHP = plugin.iDigestionSmokerHealMaxHP;
					plugin.enable = plugin.bDigestionSmokerEnable;
				}
				case ZOMBIECLASS_SPITTER:
				{
					plugin.bonus = plugin.iDigestionSpitterIncap;
					plugin.maxHP = plugin.iDigestionSpitterHealMaxHP;
					plugin.enable = plugin.bDigestionSpitterEnable;
				}
				case ZOMBIECLASS_TANK:
				{
					plugin.bonus = plugin.iDigestionTankIncap;
					plugin.maxHP = plugin.iDigestionTankHealMaxHP;
					plugin.enable = plugin.bDigestionTankEnable;
				}
			}

			if(!plugin.enable || plugin.bonus <= 0)
			{
				return Plugin_Continue;
			}
			plugin.oldHealth = GetClientHealth(attacker);
			plugin.newHealth = plugin.bonus + plugin.oldHealth;
			PrintHintTextToAll("%N got %d health for incapping %N.", attacker, plugin.bonus, target);
		}

		if(plugin.newHealth > plugin.maxHP)
		{
			plugin.newHealth = plugin.maxHP;
		}

		if(plugin.newHealth <= 65355)
		{
			SetEntityHealth(attacker, plugin.newHealth);
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
