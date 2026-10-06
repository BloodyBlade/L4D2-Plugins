#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_NOTIFY
#define DEBUG 0

static const char g_sYellSounds[12][3][PLATFORM_MAX_PATH] =
{
    {"player/survivor/voice/gambler/battlecry04.wav",  "player/survivor/voice/gambler/battlecry01.wav",  "player/survivor/voice/gambler/deathscream02.wav"},
    {"player/survivor/voice/producer/battlecry01.wav", "player/survivor/voice/producer/battlecry02.wav", "player/survivor/voice/producer/hurtmajor01.wav"},
    {"player/survivor/voice/mechanic/battlecry01.wav", "player/survivor/voice/mechanic/battlecry03.wav", "player/survivor/voice/mechanic/deathscream01.wav"},
    {"player/survivor/voice/coach/battlecry09.wav",   "player/survivor/voice/coach/battlecry06.wav",   "player/survivor/voice/coach/battlecry04.wav"},
    {"player/hunter/voice/warn/hunter_warn_10.wav",   "player/hunter/voice/warn/hunter_warn_14.wav",  "player/hunter/voice/warn/hunter_warn_18.wav"},
    {"player/smoker/voice/warn/smoker_warn_01.wav",   "player/smoker/voice/warn/smoker_warn_04.wav",  "player/smoker/voice/warn/smoker_warn_05.wav"},
    {"player/spitter/voice/warn/spitter_warn_01.wav", "player/spitter/voice/warn/spitter_warn_02.wav","player/spitter/voice/warn/spitter_warn_03.wav"},
    {"player/jockey/voice/warn/jockey_06.wav",       "player/jockey/voice/idle/jockey_lurk06.wav",  "player/jockey/voice/idle/jockey_lurk09.wav"},
    {"player/charger/voice/warn/charger_warn_01.wav","player/charger/voice/warn/charger_warn_02.wav", "player/charger/voice/warn/charger_warn_03.wav"},
    {"player/boomer/voice/action/male_zombie10_growl5.wav", "player/boomer/voice/action/male_zombie10_growl6.wav", "player/boomer/voice/alert/male_boomer_alert_05.wav"},
    {"player/boomer/voice/action/female_zombie10_growl4.wav","player/boomer/voice/action/female_zombie10_growl5.wav","player/boomer/voice/action/female_zombie10_growl3.wav"},
    {"player/tank/voice/pain/tank_fire_01.wav",      "player/tank/voice/pain/tank_fire_03.wav",      "player/tank/voice/yell/tank_throw_04.wav"}
};

static const char g_sYellModels[12][] =
{
    "models/survivors/survivor_gambler.mdl",
    "models/survivors/survivor_producer.mdl",
    "models/survivors/survivor_mechanic.mdl",
    "models/survivors/survivor_coach.mdl",
    "models/infected/hunter.mdl",
    "models/infected/smoker.mdl",
    "models/infected/spitter.mdl",
    "models/infected/jockey.mdl",
    "models/infected/charger.mdl",
    "models/infected/boomer.mdl",
    "models/infected/boomette.mdl",
    "models/infected/tank.mdl"
};

bool   g_bHooked, g_bExBoomer, g_bExTank, g_bExCharger, g_bExSpitter, g_bExHunter, g_bExJockey, g_bExSmoker, g_bCvarSurvivor, g_bCvarInfected, g_bCvarDefault, g_bCvarBind, g_bCvarAdvert;
bool   g_bPounced[MAXPLAYERS + 1], g_bChoked[MAXPLAYERS + 1], g_bRiden[MAXPLAYERS + 1], g_bPummel[MAXPLAYERS + 1], g_bIncap[MAXPLAYERS + 1], g_bCdown[MAXPLAYERS + 1], g_bYCdown[MAXPLAYERS + 1];
bool   g_bCvarPounced, g_bCvarChoked, g_bCvarRiden, g_bCvarPummel, g_bCvarIncap, g_bCvarBurn;
float  g_fCvarRadius, g_fCvarPower, g_fCvarInterval, g_fCvarCooldown;
int    g_iYells, g_iYellAttempts, g_iCvarLuck, g_iCvarBurnLuck, g_iSecondaryButton, g_iOldButtons[MAXPLAYERS + 1];
char   g_sCvarKey[12];
ConVar g_cvarYellEnabled, g_cvarYellPounced, g_cvarYellChoked, g_cvarYellRiden, g_cvarYellIncap, g_cvarYellPummel, g_cvarYellPower, g_cvarYellRadius, g_cvarYellInterval, g_cvarYellLuck;
ConVar g_cvarYellExclude, g_cvarYellDefault, g_cvarYellBind, g_cvarYellBindKey, g_cvarYellAdvert, g_cvarYellSurvivor, g_cvarYellInfected, g_cvarYellCooldown, g_cvarYellBurn, g_cvarYellBurnLuck;

public Plugin myinfo =
{
    name        = "[L4D2] Last Resource (fork)",
    author      = "honorcode23 (Updated, fixed and optimized by BloodyBlade)",
    description = "Allow survivors and infected to 'yell' as their last resource",
    version     = PLUGIN_VERSION,
    url         = "https://sourcemod.net"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    if (GetEngineVersion() != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "Last Resource supports Left 4 Dead 2 only!");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d2_last_resource_fork_version", PLUGIN_VERSION, "[L4D2] Last Resource (fork) plugin version", CVAR_FLAGS | FCVAR_SPONLY | FCVAR_DONTRECORD);

	g_cvarYellEnabled   = CreateConVar("l4d2_last_resource_enabled",        "1",      "Enable/disable the plugin",         CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarYellAdvert   = CreateConVar("l4d2_last_resource_advert",          "1",      "Tell the players about the feature", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarYellSurvivor = CreateConVar("l4d2_last_resource_survivor",        "1",      "Enable yelling on survivors?",       CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarYellInfected = CreateConVar("l4d2_last_resource_infected",        "1",      "Enable yelling on infected?",        CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarYellPounced  = CreateConVar("l4d2_last_resource_pounced",         "1",      "Enable yelling when pounced by hunter?",   CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarYellChoked   = CreateConVar("l4d2_last_resource_choked",          "1",      "Enable yelling when choked by smoker?",    CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarYellRiden    = CreateConVar("l4d2_last_resource_jockeyed",        "1",      "Enable yelling when caught by a jockey?",   CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarYellIncap    = CreateConVar("l4d2_last_resource_incapped",        "1",      "Enable yelling when incapacitated?",        CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarYellPummel   = CreateConVar("l4d2_last_resource_pummel",          "1",      "Enable yelling when pummeled by charger?",   CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarYellPower    = CreateConVar("l4d2_last_resource_power",           "500.0",  "Power of every yell",                  CVAR_FLAGS, true, 0.0);
	g_cvarYellRadius   = CreateConVar("l4d2_last_resource_radius",          "180.0",  "Maximum radius of every yell",          CVAR_FLAGS, true, 0.0);
	g_cvarYellInterval = CreateConVar("l4d2_last_resource_interval",        "1.0",    "Cooldown between attempts to yell",    CVAR_FLAGS, true, 0.1);
	g_cvarYellCooldown = CreateConVar("l4d2_last_resource_cooldown",        "5.0",    "Cooldown between successful yells",   CVAR_FLAGS, true, 0.1);
	g_cvarYellLuck     = CreateConVar("l4d2_last_resource_chance",          "3",      "Chance of gaining the yell power (1=100%, 2=50%, 3=33%)", CVAR_FLAGS, true, 1.0);
	g_cvarYellExclude  = CreateConVar("l4d2_last_resource_exclude",         "tank",   "Infected not affected by the yell, separated by commas (tank, spitter, charger, jockey, hunter, smoker, boomer)", CVAR_FLAGS);
	g_cvarYellDefault  = CreateConVar("l4d2_last_resource_default_key",     "1",      "Allow the SHIFT key to be the default key of yelling", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarYellBind     = CreateConVar("l4d2_last_resource_bind_key",        "0",      "Enable a secondary key for yelling?", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarYellBindKey  = CreateConVar("l4d2_last_resource_bind_key_string", "",       "Specify the secondary key for yelling (duck, reload, use, zoom, walk, speed, jump, attack, attack2, score)", CVAR_FLAGS);
	g_cvarYellBurn     = CreateConVar("l4d2_last_resource_ignite",          "1",      "Ignite special infected around when a survivor yells?", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarYellBurnLuck = CreateConVar("l4d2_last_resource_ignite_chance",   "3",      "Chance to ignite the special infected when yelling", CVAR_FLAGS, true, 1.0);

	RegConsoleCmd("sm_yell",      CmdYell,      "Will yell only if it is possible");
	RegAdminCmd("sm_forceyell",   CmdForceYell, ADMFLAG_SLAY, "Will force a yell even if it isn't enabled");

	AutoExecConfig(true, "l4d2_last_resource");

	g_cvarYellEnabled.AddChangeHook(OnConVarEnableChanged);
	g_cvarYellSurvivor.AddChangeHook(OnConVarChanged);
	g_cvarYellInfected.AddChangeHook(OnConVarChanged);
	g_cvarYellDefault.AddChangeHook(OnConVarChanged);
	g_cvarYellBind.AddChangeHook(OnConVarChanged);
	g_cvarYellAdvert.AddChangeHook(OnConVarChanged);
	g_cvarYellPounced.AddChangeHook(OnConVarChanged);
	g_cvarYellChoked.AddChangeHook(OnConVarChanged);
	g_cvarYellRiden.AddChangeHook(OnConVarChanged);
	g_cvarYellPummel.AddChangeHook(OnConVarChanged);
	g_cvarYellIncap.AddChangeHook(OnConVarChanged);
	g_cvarYellBurn.AddChangeHook(OnConVarChanged);
	g_cvarYellPower.AddChangeHook(OnConVarChanged);
	g_cvarYellRadius.AddChangeHook(OnConVarChanged);
	g_cvarYellInterval.AddChangeHook(OnConVarChanged);
	g_cvarYellCooldown.AddChangeHook(OnConVarChanged);
	g_cvarYellLuck.AddChangeHook(OnConVarChanged);
	g_cvarYellBurnLuck.AddChangeHook(OnConVarChanged);
	g_cvarYellBindKey.AddChangeHook(OnConVarChanged);
	g_cvarYellExclude.AddChangeHook(OnConVarChanged);
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

stock void IsAllowed()
{
	bool g_bEnabled = g_cvarYellEnabled.BoolValue;
	if(!g_bHooked && g_bEnabled)
	{
		g_bHooked = true;
		OnConVarChanged(g_cvarYellSurvivor, "", "");
		OnConVarChanged(g_cvarYellInfected, "", "");
		OnConVarChanged(g_cvarYellDefault, "", "");
		OnConVarChanged(g_cvarYellBind, "", "");
		OnConVarChanged(g_cvarYellAdvert, "", "");
		OnConVarChanged(g_cvarYellPounced, "", "");
		OnConVarChanged(g_cvarYellChoked, "", "");
		OnConVarChanged(g_cvarYellRiden, "", "");
		OnConVarChanged(g_cvarYellPummel, "", "");
		OnConVarChanged(g_cvarYellIncap, "", "");
		OnConVarChanged(g_cvarYellBurn, "", "");
		OnConVarChanged(g_cvarYellRadius, "", "");
		OnConVarChanged(g_cvarYellPower, "", "");
		OnConVarChanged(g_cvarYellInterval, "", "");
		OnConVarChanged(g_cvarYellCooldown, "", "");
		OnConVarChanged(g_cvarYellLuck, "", "");
		OnConVarChanged(g_cvarYellBurnLuck, "", "");
		OnConVarChanged(g_cvarYellBindKey, "", "");
		OnConVarChanged(g_cvarYellExclude, "", "");

		HookEvent("round_start_post_nav",  OnRoundStart);
		HookEvent("round_end",             OnRoundEnd);
		HookEvent("jockey_ride",           OnJockeyRideStart);
		HookEvent("lunge_pounce",          OnHunterPounceStart);
		HookEvent("choke_start",            OnSmokerChokeStart);
		HookEvent("jockey_ride_end",        OnJockeyRideEnd);
		HookEvent("pounce_stopped",         OnHunterPounceEnd);
		HookEvent("tongue_pull_stopped",    OnSmokerChokeEnd);
		HookEvent("charger_pummel_start",  OnPummelStart);
		HookEvent("charger_pummel_end",    OnPummelEnd);
		HookEvent("player_incapacitated",  OnIncap);
		HookEvent("revive_success",        OnRevived);
		HookEvent("player_death",          OnPlayerDeath);
	}
	else if(g_bHooked && !g_bEnabled)
	{
		g_bHooked = false;
		UnhookEvent("round_start_post_nav",  OnRoundStart);
		UnhookEvent("round_end",             OnRoundEnd);
		UnhookEvent("jockey_ride",           OnJockeyRideStart);
		UnhookEvent("lunge_pounce",          OnHunterPounceStart);
		UnhookEvent("choke_start",            OnSmokerChokeStart);
		UnhookEvent("jockey_ride_end",        OnJockeyRideEnd);
		UnhookEvent("pounce_stopped",         OnHunterPounceEnd);
		UnhookEvent("tongue_pull_stopped",    OnSmokerChokeEnd);
		UnhookEvent("charger_pummel_start",  OnPummelStart);
		UnhookEvent("charger_pummel_end",    OnPummelEnd);
		UnhookEvent("player_incapacitated",  OnIncap);
		UnhookEvent("revive_success",        OnRevived);
		UnhookEvent("player_death",          OnPlayerDeath);
	}
}

stock void OnConVarEnableChanged(ConVar cv, const char[] old, const char[] neu)
{
	IsAllowed();
}

void OnConVarChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
{
    if(cvar == g_cvarYellSurvivor)
	{
		g_bCvarSurvivor = cvar.BoolValue;
    }
	else if(cvar == g_cvarYellInfected)
	{
		g_bCvarInfected = cvar.BoolValue;
    }
	else if(cvar == g_cvarYellDefault)
	{
		g_bCvarDefault = cvar.BoolValue;
    }
	else if(cvar == g_cvarYellBind)
	{
		g_bCvarBind = cvar.BoolValue;
    }
	else if(cvar == g_cvarYellAdvert)
	{
		g_bCvarAdvert = cvar.BoolValue;
    }
	else if(cvar == g_cvarYellPounced)
	{
		g_bCvarPounced  = cvar.BoolValue;
    }
	else if(cvar == g_cvarYellChoked)
	{
		g_bCvarChoked = cvar.BoolValue;
    }
	else if(cvar == g_cvarYellRiden)
	{
		g_bCvarRiden = cvar.BoolValue;
    }
	else if(cvar == g_cvarYellPummel)
	{
		g_bCvarPummel = cvar.BoolValue;
    }
	else if(cvar == g_cvarYellIncap)
	{
		g_bCvarIncap = cvar.BoolValue;
    }
	else if(cvar == g_cvarYellBurn)
	{
		g_bCvarBurn = cvar.BoolValue;
    }
	else if(cvar == g_cvarYellRadius)
	{
		g_fCvarRadius = cvar.FloatValue;
    }
	else if(cvar == g_cvarYellPower)
	{
		g_fCvarPower = cvar.FloatValue;
    }
	else if(cvar == g_cvarYellInterval)
	{
		g_fCvarInterval = cvar.FloatValue;
    }
	else if(cvar == g_cvarYellCooldown)
	{
		g_fCvarCooldown = cvar.FloatValue;
    }
	else if(cvar == g_cvarYellLuck)
	{
		g_iCvarLuck = cvar.IntValue;
    }
	else if(cvar == g_cvarYellBurnLuck)
	{
		g_iCvarBurnLuck = cvar.IntValue;
	}
	else if(cvar == g_cvarYellBindKey)
	{
		cvar.GetString(g_sCvarKey, sizeof(g_sCvarKey));
		g_iSecondaryButton = GetButtonFromString(g_sCvarKey);
	}
	else if(cvar == g_cvarYellExclude)
	{
		CheckAffectedClasses();
	}
}

public void OnMapStart()
{
    ResetStats(0);

    for (int i = 0; i < sizeof(g_sYellSounds); i++)
    {
        for (int j = 0; j < sizeof(g_sYellSounds[]); j++)
        {
            PrecacheSound(g_sYellSounds[i][j]);
            PrefetchSound(g_sYellSounds[i][j]);
        }
    }

    #if DEBUG
    PrintToServer("Sounds have been precached and prefetched");
    #endif
}

public void OnMapEnd()
{
    #if DEBUG
    PrintToServer("[Last Resource] Total yell attempts: %i", g_iYellAttempts);
    PrintToServer("[Last Resource] Total successful yells: %i", g_iYells);
    g_iYellAttempts = 0;
    g_iYells = 0;
    #endif
    ResetStats(0);
}

public void OnClientPutInServer(int client)
{
	if (!client || IsFakeClient(client))
	{
		return;
	}

	ResetStats(client);

	if (g_bCvarAdvert)
	{
		RunAdvert(client);
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
    if (!g_bHooked || !IsValidClient(client))
        return Plugin_Continue;

    int pressed = buttons & ~g_iOldButtons[client];

    if (g_bCvarDefault && (pressed & IN_SPEED))
        TryYell(client);

    if (g_bCvarBind && g_iSecondaryButton && (pressed & g_iSecondaryButton))
        TryYell(client);

    g_iOldButtons[client] = buttons;
    return Plugin_Continue;
}

stock void TryYell(int client)
{
	if (!TestPosibilities(client) || g_bCdown[client] || g_bYCdown[client])
	{
		return;
	}

	g_iYellAttempts++;

	if (GetRandomInt(1, g_iCvarLuck) == 1)
	{
		Yell(client);
		g_iYells++;
		g_bYCdown[client] = true;
		CreateTimer(g_fCvarCooldown, timerYellCooldown, GetClientUserId(client));

		#if DEBUG
		char name[256];
		GetClientName(client, name, sizeof(name));
		PrintToServer("[Last Resource] %s(%i) Yelled.", name, client);
		#endif
	}

	g_bCdown[client] = true;
	CreateTimer(g_fCvarInterval, timerCooldown, GetClientUserId(client));

	#if DEBUG
	PrintToConsole(client, "[Last Resource] Cooldown in progress");
	#endif
}

stock Action CmdYell(int client, int args)
{
	if(!g_bHooked)
	{
		return Plugin_Handled;
	}

	TryYell(client);
	return Plugin_Handled;
}

stock Action CmdForceYell(int client, int args)
{
	if(!g_bHooked)
	{
		return Plugin_Handled;
	}

	if (IsValidClient(client))
	{
		g_iYells++;
		Yell(client);
	}
	return Plugin_Handled;
}

stock Action timerCooldown(Handle timer, any client)
{
    g_bCdown[GetClientOfUserId(client)] = false;
    return Plugin_Stop;
}

stock Action timerYellCooldown(Handle timer, any client)
{
    g_bYCdown[GetClientOfUserId(client)] = false;
    return Plugin_Stop;
}

stock void Yell(int client)
{
    float pos[3];
    GetClientAbsOrigin(client, pos);
    YellAtPosition(client, pos);
}

stock void YellAtPosition(int client, float pos[3])
{
	EmitYell(client);

	bool survivorYell = (GetClientTeam(client) == 2);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i) || !IsPlayerAlive(i) || GetClientTeam(client) == GetClientTeam(i))
			continue;

		float tpos[3];
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", tpos);

		float distance[3];
		distance[0] = pos[0] - tpos[0];
		distance[1] = pos[1] - tpos[1];
		distance[2] = pos[2] - tpos[2];

		float realDistance = SquareRoot(distance[0] * distance[0] + distance[1] * distance[1]);

		if (realDistance > g_fCvarRadius || FloatAbs(distance[2]) > 50.0)
			continue;

		float hypot = realDistance;
		if (hypot < 0.01)
			hypot = 0.01;

		float ratio0 = distance[0] / hypot;
		float ratio1 = distance[1] / hypot;

		float addVel[3];
		addVel[0] = -ratio0 * g_fCvarPower;
		addVel[1] = -ratio1 * g_fCvarPower;
		addVel[2] = g_fCvarPower;

		if (survivorYell)
		{
			if (IsAffected(i))
			{
				ReleaseVictimsFromInfected(i);
				L4D2_CTerrorPlayer_Fling(i, client, addVel);

				if (g_bCvarBurn && GetRandomInt(1, g_iCvarBurnLuck) == 1)
				{
					IgniteEntity(i, 20.0);
				}
			}
		}
		else
		{
			L4D2_CTerrorPlayer_Fling(i, client, addVel);
		}

		#if DEBUG
		PrintToConsole(client, "Target %i got flung!", GetClientUserId(i));
		#endif
	}
}

stock void ReleaseVictimsFromInfected(int infected)
{
	int victim;

	if ((victim = L4D_GetVictimCharger(infected)) > 0)
	{
		L4D2_Charger_EndPummel(victim, infected);
	}

	if ((victim = L4D_GetVictimCarry(infected)) > 0)
	{
		L4D2_Charger_EndCarry(victim, infected);
	}

	if ((victim = L4D_GetVictimJockey(infected)) > 0)
	{
		L4D2_Jockey_EndRide(victim, infected);
	}

	if ((victim = L4D_GetVictimHunter(infected)) > 0)
	{
		L4D_Hunter_ReleaseVictim(victim, infected);
	}

	if ((victim = L4D_GetVictimSmoker(infected)) > 0)
	{
		L4D_Smoker_ReleaseVictim(victim, infected);
	}
}

stock void EmitYell(int client)
{
    char cModel[256];
    GetClientModel(client, cModel, sizeof(cModel));

    for (int i = 0; i < sizeof(g_sYellModels); i++)
    {
        if (StrEqual(cModel, g_sYellModels[i]))
        {
            int snd = GetRandomInt(0, 2);
            EmitSoundToAll(g_sYellSounds[i][snd], client);
            return;
        }
    }

    #if DEBUG
    PrintToChat(client, "ROAAAARRRR!");
    #endif
}

stock bool TestPosibilities(int client)
{
	if (!IsValidClient(client))
	{
		return false;
	}

	int team = GetClientTeam(client);

	if (team == 2)
	{
		if (!g_bCvarSurvivor)
		{
			return false;
		}

		if (g_bPounced[client]  && g_bCvarPounced)  return true;
		if (g_bChoked[client]   && g_bCvarChoked)    return true;
		if (g_bRiden[client]    && g_bCvarRiden)     return true;
		if (g_bPummel[client]   && g_bCvarPummel)    return true;
		if (g_bIncap[client]    && g_bCvarIncap)     return true;
		return false;
	}

	if (team == 3)
	{
		return g_bCvarInfected;
	}

	return false;
}

stock bool IsAffected(int client)
{
    switch (GetEntProp(client, Prop_Send, "m_zombieClass"))
    {
        case 1:  return !g_bExSmoker;
        case 2:  return !g_bExBoomer;
        case 3:  return !g_bExHunter;
        case 4:  return !g_bExSpitter;
        case 5:  return !g_bExJockey;
        case 6:  return !g_bExCharger;
        case 8:  return !g_bExTank;
    }
    return true;
}

stock void CheckAffectedClasses()
{
    char exinfected[256];
    g_cvarYellExclude.GetString(exinfected, sizeof(exinfected));

    g_bExBoomer  = (StrContains(exinfected, "boomer")  != -1);
    g_bExSpitter = (StrContains(exinfected, "spitter") != -1);
    g_bExHunter  = (StrContains(exinfected, "hunter")  != -1);
    g_bExJockey  = (StrContains(exinfected, "jockey")  != -1);
    g_bExCharger = (StrContains(exinfected, "charger") != -1);
    g_bExSmoker  = (StrContains(exinfected, "smoker")  != -1);
    g_bExTank    = (StrContains(exinfected, "tank")    != -1);
}

stock void ResetStats(int client)
{
    if (client == 0)
    {
        for (int i = 0; i <= MaxClients; i++)
        {
            g_bPounced[i] = false;
            g_bChoked[i]  = false;
            g_bRiden[i]   = false;
            g_bPummel[i]  = false;
            g_bIncap[i]   = false;
            g_bCdown[i]   = false;
            g_bYCdown[i]  = false;
            g_iOldButtons[i] = 0;
        }
    }
    else
    {
        g_bPounced[client] = false;
        g_bChoked[client]  = false;
        g_bRiden[client]   = false;
        g_bPummel[client]  = false;
        g_bIncap[client]   = false;
        g_bCdown[client]   = false;
        g_bYCdown[client]  = false;
        g_iOldButtons[client] = 0;
    }
}

stock void TellToPress(int client)
{
	if (!g_bCvarSurvivor)
	{
		return;
	}

	char msg[256];

	if (g_bCvarDefault && g_bCvarBind && g_sCvarKey[0])
	{
		Format(msg, sizeof(msg), "Press SHIFT or the %s key to yell as your last resource!", g_sCvarKey);
	}
	else if (g_bCvarDefault)
	{
		Format(msg, sizeof(msg), "Press SHIFT to yell as your last resource!");
	}
	else if (g_bCvarBind && g_sCvarKey[0])
	{
		Format(msg, sizeof(msg), "Press the %s key to yell as your last resource!", g_sCvarKey);
	}
	else
	{
		return;
	}

	PrintHintText(client, msg);
}

stock void RunAdvert(int client)
{
	if (!IsValidClient(client) || IsFakeClient(client) || !g_bCvarDefault && !g_bCvarBind)
	{
		return;
	}

	DataPack pack;
	CreateDataTimer(15.0, timerAdvert, pack);
	pack.WriteCell(GetClientUserId(client));
	pack.WriteCell(g_bCvarDefault ? 1 : 0);
	pack.WriteCell(g_bCvarBind ? 1 : 0);
	pack.WriteString(g_sCvarKey);
}

stock Action timerAdvert(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	bool useDefault = (pack.ReadCell() != 0);
	bool useBind = (pack.ReadCell() != 0);
	char key[12];
	pack.ReadString(key, sizeof(key));

	if (!IsValidClient(client))
	{
		return Plugin_Stop;
	}

	if (useDefault && useBind && key[0])
	{
		PrintToChat(client, "\x04[SM]\x03 If you are in trouble, press the SHIFT key as your last resource. As an alternative, you can press the %s key", key);
	}
	else if (useDefault)
	{
		PrintToChat(client, "\x04[SM]\x03 If you are in trouble, press the SHIFT key as your last resource!");
	}
	else if (useBind && key[0])
	{
		PrintToChat(client, "\x04[SM]\x03 If you are in trouble, you can press the %s key to try to release yourself from the problem", key);
	}

	return Plugin_Stop;
}

stock void OnRoundStart(Event event, const char[] event_name, bool dontBroadcast)
{
    ResetStats(0);
}

stock void OnRoundEnd(Event event, const char[] event_name, bool dontBroadcast)
{
    #if DEBUG
    PrintToServer("[Last Resource] Total yell attempts: %i", g_iYellAttempts);
    PrintToServer("[Last Resource] Total successful yells: %i", g_iYells);
    #endif
    ResetStats(0);
}

stock Action OnHunterPounceStart(Event event, const char[] event_name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("victim"));
	if (IsValidClient(victim))
	{
		g_bPounced[victim] = true;
		TellToPress(victim);
	}
	return Plugin_Continue;
}

stock Action OnHunterPounceEnd(Event event, const char[] event_name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("victim"));
	if (IsValidClient(victim))
	{
		g_bPounced[victim] = false;
	}
	return Plugin_Continue;
}

stock Action OnSmokerChokeStart(Event event, const char[] event_name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("victim"));
	if (IsValidClient(victim))
	{
		g_bChoked[victim] = true;
		TellToPress(victim);
	}
	return Plugin_Continue;
}

stock Action OnSmokerChokeEnd(Event event, const char[] event_name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("victim"));
	if (IsValidClient(victim))
	{
		g_bChoked[victim] = false;
	}
	return Plugin_Continue;
}

stock Action OnJockeyRideStart(Event event, const char[] event_name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("victim"));
	if (IsValidClient(victim))
	{
		g_bRiden[victim] = true;
		TellToPress(victim);
	}
	return Plugin_Continue;
}

stock Action OnJockeyRideEnd(Event event, const char[] event_name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("victim"));
	if (IsValidClient(victim))
	{
		g_bRiden[victim] = false;
	}
	return Plugin_Continue;
}

stock Action OnPummelStart(Event event, const char[] event_name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("victim"));
    if (IsValidClient(victim))
    {
        g_bPummel[victim] = true;
        TellToPress(victim);
    }
    return Plugin_Continue;
}

stock Action OnPummelEnd(Event event, const char[] event_name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("victim"));
	if (IsValidClient(victim))
	{
		g_bPummel[victim] = false;
	}
	return Plugin_Continue;
}

stock Action OnIncap(Event event, const char[] event_name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (IsValidClient(client))
    {
        g_bIncap[client] = true;
        TellToPress(client);
    }
    return Plugin_Continue;
}

stock Action OnRevived(Event event, const char[] event_name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	if (IsValidClient(client))
	{
		g_bIncap[client] = false;
	}
	return Plugin_Continue;
}

stock Action OnPlayerDeath(Event event, const char[] event_name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (client > 0 && client <= MaxClients)
    {
        g_bPounced[client] = false;
        g_bChoked[client]  = false;
        g_bRiden[client]   = false;
        g_bPummel[client]  = false;
        g_bIncap[client]   = false;
        g_bCdown[client]   = false;
        g_bYCdown[client]  = false;
    }

    if (g_bCvarInfected && IsValidClient(client) && GetClientTeam(client) == 3)
    {
        if (GetRandomInt(1, g_iCvarLuck) == 1)
        {
            float pos[3];
            pos[0] = event.GetFloat("victim_x");
            pos[1] = event.GetFloat("victim_y");
            pos[2] = event.GetFloat("victim_z") + 10.0;
            YellAtPosition(client, pos);
        }
    }

    return Plugin_Continue;
}

stock bool IsValidClient(int client)
{
    return client > 0 && client <= MaxClients && IsClientInGame(client);
}

stock int GetButtonFromString(const char[] s)
{
    if (StrEqual(s, "duck", false))     return IN_DUCK;
    if (StrEqual(s, "reload", false))   return IN_RELOAD;
    if (StrEqual(s, "use", false))      return IN_USE;
    if (StrEqual(s, "zoom", false))     return IN_ZOOM;
    if (StrEqual(s, "walk", false))     return IN_ALT1;
    if (StrEqual(s, "speed", false))    return IN_SPEED;
    if (StrEqual(s, "jump", false))     return IN_JUMP;
    if (StrEqual(s, "attack", false))   return IN_ATTACK;
    if (StrEqual(s, "attack2", false))  return IN_ATTACK2;
    if (StrEqual(s, "score", false))    return IN_SCORE;
    return 0;
}
