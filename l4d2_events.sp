#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS FCVAR_NOTIFY|FCVAR_SPONLY
#define PLAYERS_ENABLED false

#define PLUGIN_NAME "L4D2 Events"
#define PLUGIN_AUTHOR "Jonny"
#define PLUGIN_DESCRIPTION "L4D2 Events"
#define PLUGIN_VERSION "1.0.4"
#define PLUGIN_URL ""

bool First_Player_Transitioned = false;

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();
    if (engine != Engine_Left4Dead && engine != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead\" and \"Left 4 Dead 2\" game");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

ConVar Plugin_Mode, Configs_Dir;

public void OnPluginStart()
{
	char cvar_sm_logfile_events[256] = "logs/events.log";
	if (!StrEqual(cvar_sm_logfile_events, "", false))
	{
		char file[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, file, sizeof(file), cvar_sm_logfile_events);	
		LogToFileEx(file, "OnPluginStart()");
	}

	CreateConVar("l4d2_advanced", PLUGIN_VERSION, "[L4D2] Events Version", CVAR_FLAGS|FCVAR_UNLOGGED|FCVAR_DONTRECORD);
	Plugin_Mode = CreateConVar("l4d2_advanced_mode", "2", "", CVAR_FLAGS);
	Configs_Dir = CreateConVar("l4d2_config_dir", "events", "", CVAR_FLAGS);
	HookL4D2Events();
}

void HookL4D2Events()
{
	HookEvent("round_freeze_end", Event_ExecConfig);
	HookEvent("round_start_pre_entity", Event_ExecConfig);
	HookEvent("round_start_post_nav", Event_ExecConfig);
	HookEvent("nav_generate", Event_ExecConfig);
	HookEvent("round_end_message", Event_ExecConfig);
	HookEvent("round_end", Event_ExecConfig);
	HookEvent("difficulty_changed", Event_ExecConfig);
	HookEvent("finale_start", Event_ExecConfig);
	HookEvent("finale_rush", Event_ExecConfig);
	HookEvent("finale_escape_start", Event_ExecConfig);
	HookEvent("finale_vehicle_incoming", Event_ExecConfig);
	HookEvent("finale_vehicle_ready", Event_ExecConfig);
	HookEvent("finale_vehicle_leaving", Event_ExecConfig);
	HookEvent("finale_win", Event_ExecConfig);
	HookEvent("mission_lost", Event_ExecConfig);
	HookEvent("finale_radio_start", Event_ExecConfig);
	HookEvent("finale_radio_damaged", Event_ExecConfig);
	HookEvent("final_reportscreen", Event_ExecConfig);
	HookEvent("map_transition", Event_ExecConfig);
	HookEvent("player_transitioned", Event_PlayerTransitioned);
	HookEvent("player_left_start_area", Event_ExecConfig);
	HookEvent("witch_spawn", Event_ExecConfig);
	HookEvent("witch_killed", Event_ExecConfig);
	HookEvent("tank_spawn", Event_ExecConfig);
	HookEvent("create_panic_event", Event_ExecConfig);
	HookEvent("weapon_spawn_visible", Event_ExecConfig);
	HookEvent("gameinstructor_draw", Event_ExecConfig);
	HookEvent("gameinstructor_nodraw", Event_ExecConfig);
	HookEvent("request_weapon_stats", Event_ExecConfig);
	HookEvent("player_talking_state", Event_ExecConfig);
	HookEvent("weapon_pickup", Event_ExecConfig);
	HookEvent("hunter_punched", Event_ExecConfig);
	HookEvent("tank_killed", Event_ExecConfig);
	HookEvent("gauntlet_finale_start", Event_ExecConfig);
	HookEvent("mounted_gun_start", Event_ExecConfig);
	HookEvent("mounted_gun_overheated", Event_ExecConfig);
	HookEvent("punched_clown", Event_ExecConfig);
	HookEvent("charger_killed", Event_ExecConfig);
	HookEvent("spitter_killed", Event_ExecConfig);
	HookEvent("jockey_killed", Event_ExecConfig, EventHookMode_Post);
	HookEvent("triggered_car_alarm", Event_ExecConfig);
	HookEvent("panic_event_finished", Event_ExecConfig);
	HookEvent("song_played", Event_ExecConfig);
}

public void OnMapStart()
{
	First_Player_Transitioned = false;
	ExecuteCFG("map_start");
}

void ExecuteCFG(const char[] FileName)
{
	if (Plugin_Mode.IntValue < 1) return;
	else if (Plugin_Mode.IntValue == 2)
	{
		int count = 0;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				count++;
			}
		}
		if (!count) return;
	}
	char cvar_l4d2_config_dir[256], CfgFileName[256], CfgFullFileName[256];
	Configs_Dir.GetString(cvar_l4d2_config_dir, sizeof(cvar_l4d2_config_dir));
	Format(CfgFileName, sizeof(CfgFileName), "%s/%s.cfg", cvar_l4d2_config_dir, FileName);
	Format(CfgFullFileName, sizeof(CfgFullFileName), "cfg/%s/%s.cfg", cvar_l4d2_config_dir, FileName);
	PrintToServer("exec %s", CfgFileName);
	if (FileExists(CfgFullFileName, false)) ServerCommand("exec %s", CfgFileName);
}

Action Event_PlayerTransitioned(Event event, const char[] name, bool dontBroadcast)
{
	if (!First_Player_Transitioned)
	{
		First_Player_Transitioned = true;
		ExecuteCFG("first_player_transitioned");
	}
	else Event_ExecConfig(event, name, dontBroadcast);
	return Plugin_Continue;
}

Action Event_ExecConfig(Event event, const char[] name, bool dontBroadcast)
{
	ExecuteCFG(name);
	return Plugin_Continue;
}
