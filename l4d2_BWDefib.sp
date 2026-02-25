#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_NOTIFY

public Plugin myinfo =
{
	name = "[L4D2] Black and White on Defib",
	author = "Crimson_Fox(edit. by BloodyBlade)",
	description = "Defibed survivors are brought back to life with no incaps remaining.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1012022"
}

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

PluginData plugin;

enum struct PluginCvars
{
	ConVar h_Enabled;
	ConVar h_RemainingIncaps;
	ConVar h_Health;
	ConVar h_TempHealth;

	void Init()
	{
		CreateConVar("bwdefib_version", PLUGIN_VERSION, "The version of Black and White on Defib.", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
		this.h_Enabled = CreateConVar("l4d2_bwdefib", "1", "Is Black and White on Defib enabled?", CVAR_FLAGS);
		this.h_RemainingIncaps = CreateConVar("l4d2_bwdefib_incaps", "0", "Number of remaining incaps with which a defibed survivor is brought back.", CVAR_FLAGS);	
		this.h_Health = CreateConVar("l4d2_bwdefib_health", "1", "Amount of health with which a defibed survivor is brought back.", CVAR_FLAGS, true, 1.0, true, 100.0);
		this.h_TempHealth = CreateConVar("l4d2_bwdefib_temphealth", "30.0", "Amount of temporary health with which a defibed survivor is brought back.", CVAR_FLAGS, true, 0.0, true, 100.0);

		AutoExecConfig(true, "l4d2_bwdefib");

		this.h_Enabled.AddChangeHook(ConVarChanged_Allow);
		this.h_RemainingIncaps.AddChangeHook(ConVarsChanged);
		this.h_Health.AddChangeHook(ConVarsChanged);
		this.h_TempHealth.AddChangeHook(ConVarsChanged);
	}
}

enum struct PluginData
{
    PluginCvars cvars;
    bool bHooked;
    bool bPluginOn;
    int iMaxIncaps;
    int iRemainingIncaps;
    int iHealth;
    float fTempHealth;

    void Init()
    {
        this.cvars.Init();
        this.iMaxIncaps = FindConVar("survivor_max_incapacitated_count").IntValue;
    }

    void GetCvarValues()
    {
        this.iRemainingIncaps = this.cvars.h_RemainingIncaps.IntValue;
        this.iHealth = this.cvars.h_Health.IntValue;
        this.fTempHealth = this.cvars.h_TempHealth.FloatValue;
    }

    void IsAllowed()
    {
        this.bPluginOn = this.cvars.h_Enabled.BoolValue;
        if(!this.bHooked && this.bPluginOn)
        {
            this.bHooked = true;
            HookEvent("defibrillator_used", Event_PlayerDefibed);
        }
        else if(this.bHooked && !this.bPluginOn)
        {
            this.bHooked = false;
            UnhookEvent("defibrillator_used", Event_PlayerDefibed);
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

void ConVarChanged_Allow(ConVar convar, const char[] oldValue, const char[] newValue)
{
	plugin.IsAllowed();
}

void ConVarsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	plugin.GetCvarValues();
}

//When a player is defibed,
Action Event_PlayerDefibed(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		//set the players' incap count,
		SetEntProp(client, Prop_Send, "m_currentReviveCount", plugin.iMaxIncaps - plugin.iRemainingIncaps);	
		//turn on isGoingToDie mode if the player is on their last incap,
		if (GetEntProp(client, Prop_Send, "m_currentReviveCount") == plugin.iMaxIncaps)
		{
			SetEntProp(client, Prop_Send, "m_isGoingToDie", 1);
		}
		//set their permanent health,
		SetEntProp(client, Prop_Send, "m_iHealth", plugin.iHealth);
		//and their temp health.
		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", plugin.fTempHealth);
		SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	}
	return Plugin_Continue;
}
