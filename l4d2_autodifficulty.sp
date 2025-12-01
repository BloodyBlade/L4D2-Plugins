#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.10.1"

public Plugin myinfo = 
{
	name = "[L4D2] Autodifficulty",
	author = "Jonny(Edit. by BloodyBlade)",
	description = "",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

float DifficultyMultiplier[MAXPLAYERS + 1] = {0.0, ...};

ConVar l4d2_autodifficulty;
ConVar z_difficulty;
ConVar z_special_spawn_interval;
ConVar special_respawn_interval;
ConVar tank_burn_duration;
ConVar z_hunter_health;
ConVar z_smoker_health;
ConVar z_boomer_health;
ConVar z_charger_health;
ConVar z_spitter_health;
ConVar z_jockey_health;
ConVar z_witch_health;
ConVar z_tank_health;
ConVar z_health;
ConVar z_hunter_limit;
ConVar z_smoker_limit;
ConVar z_boomer_limit;
ConVar z_charger_limit;
ConVar z_spitter_limit;
ConVar z_jockey_limit;
ConVar z_spitter_max_wait_time;
ConVar z_vomit_interval;

ConVar z_smoker_speed;
ConVar z_boomer_speed;
ConVar z_spitter_speed;
ConVar z_tank_speed;

ConVar jockey_pz_claw_dmg;
ConVar smoker_pz_claw_dmg;
ConVar tongue_choke_damage_amount;
ConVar tongue_drag_damage_amount;
ConVar tongue_miss_delay;
ConVar tongue_hit_delay;
ConVar tongue_range;

ConVar grenadelauncher_damage;

ConVar z_spitter_range;
ConVar z_spit_interval;

ConVar l4d2_loot_h_drop_items;
ConVar l4d2_loot_b_drop_items;
ConVar l4d2_loot_s_drop_items;
ConVar l4d2_loot_c_drop_items;
ConVar l4d2_loot_sp_drop_items;
ConVar l4d2_loot_j_drop_items;
ConVar l4d2_loot_t_drop_items;

ConVar IsMapFinished;

//ConVar l4d2_loot_g_chance_nodrop;
bool bFindLootPLugin = false;

public void OnPluginStart()
{
	AddServerTag("autodifficulty");
	l4d2_autodifficulty = CreateConVar("l4d2_autodifficulty", "1", "Is the plugin enabled.");
	CreateConVar("l4d2_autodifficulty_ver", PLUGIN_VERSION, "Version of the [L4D2] Autodifficulty.", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);
	HookConVarChange(l4d2_autodifficulty, Autodifficulty_EnableDisable);

	z_difficulty = FindConVar("z_difficulty");

	z_special_spawn_interval = FindConVar("z_special_spawn_interval");
	special_respawn_interval = FindConVar("director_special_respawn_interval");
	tank_burn_duration = FindConVar("tank_burn_duration");
	z_hunter_health = FindConVar("z_hunter_health");
	z_smoker_health = FindConVar("z_gas_health");
	z_boomer_health = FindConVar("z_exploding_health");
	z_charger_health = FindConVar("z_charger_health");
	z_spitter_health = FindConVar("z_spitter_health");
	z_jockey_health = FindConVar("z_jockey_health");
	z_witch_health = FindConVar("z_witch_health");
	z_tank_health = FindConVar("z_tank_health");
	z_hunter_limit = FindConVar("z_hunter_limit");
	z_smoker_limit = FindConVar("z_smoker_limit");
	z_boomer_limit = FindConVar("z_boomer_limit");
	z_charger_limit = FindConVar("z_charger_limit");
	z_spitter_limit = FindConVar("z_spitter_limit");
	z_jockey_limit = FindConVar("z_jockey_limit");
	z_health = FindConVar("z_health");
	z_spitter_max_wait_time = FindConVar("z_spitter_max_wait_time");
	z_vomit_interval = FindConVar("z_vomit_interval");

	z_smoker_speed = FindConVar("z_gas_speed");
	z_boomer_speed = FindConVar("z_exploding_speed");
	z_spitter_speed = FindConVar("z_spitter_speed");
	z_tank_speed = FindConVar("z_tank_speed");

	grenadelauncher_damage = FindConVar("grenadelauncher_damage");
	
	jockey_pz_claw_dmg = FindConVar("jockey_pz_claw_dmg");
	smoker_pz_claw_dmg = FindConVar("smoker_pz_claw_dmg");
	tongue_choke_damage_amount = FindConVar("tongue_choke_damage_amount");
	tongue_drag_damage_amount = FindConVar("tongue_drag_damage_amount");
	tongue_miss_delay = FindConVar("tongue_miss_delay");
	tongue_hit_delay = FindConVar("tongue_hit_delay");
	tongue_range = FindConVar("tongue_range");
	
	z_spitter_range = FindConVar("z_spitter_range");
	z_spit_interval = FindConVar("z_spit_interval");
	
	IsMapFinished = FindConVar("l4d2_mapfinished");

	RegConsoleCmd("say", Command_Say);

	DifficultyMultiplier[0] = 1.0;
}

public void OnAllPluginsLoaded()
{
	char smxFileName[] = "l4d2_loot.smx";
	Handle hFoundPlugin = FindPluginByFile(smxFileName);
	if (hFoundPlugin)
	{
		bFindLootPLugin = true;
	}
	else
	{
		bFindLootPLugin = false;
	}
}

stock int CheckCvarMin(const int Cvar_Value, int Cvar_Value_Min)
{
	if (Cvar_Value < Cvar_Value_Min)
	{
		return Cvar_Value_Min;
	}
	else
	{
		return Cvar_Value;
	}
}

stock int CheckCvarMax(const int Cvar_Value, int Cvar_Value_Max)
{
	if (Cvar_Value > Cvar_Value_Max)
	{
		return Cvar_Value_Max;
	}
	else
	{
		return Cvar_Value;
	}
}

stock int GetRealClientCount()
{
	int clients = 0;
	char ClientSteamID[12];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			GetClientAuthId(i, AuthId_Steam2, ClientSteamID, sizeof(ClientSteamID));
			if (!StrEqual(ClientSteamID, "BOT", false))
			{
				if (IsClientInGame(i) && !IsFakeClient(i))
				{
					clients++;
				}
			}
		}
	}
	return clients;
}

stock int GetTankHP()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsTank(i))
		{
			return GetClientHealth(i);
		}
	}
	return z_tank_health.IntValue * 2;
}

stock bool IsTankAlive()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsTank(i))
		{
			return true;
		}
	}
	return false;
}

stock bool IsTank(int client) // L4D2
{
	if(client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3)
	{
		int class = GetEntProp(client, Prop_Send, "m_zombieClass");
		if(class == 8)
		{
			return true;
		}
	}
	return false;
}

stock int GetTotalDifficultyMultiplier()
{
	int clients = 0;
	float DifficultySum = 0.0;
	char ClientSteamID[12];

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			GetClientAuthId(i, AuthId_Steam2, ClientSteamID, sizeof(ClientSteamID));
			if (!StrEqual(ClientSteamID, "BOT", false))
			{
				if (IsClientInGame(i) && !IsFakeClient(i))
				{
					clients++;
					if (DifficultyMultiplier[i] < 0.0)
						DifficultyMultiplier[i] = 1.0;
					DifficultySum = DifficultySum + DifficultyMultiplier[i];
				}
			}
		}
	}
	DifficultyMultiplier[0] = DifficultySum / clients;
	DifficultyMultiplier[0] = DifficultyMultiplier[0] * DifficultyMultiplier[0];
	if (DifficultyMultiplier[0] < 0.1)
	{
		DifficultyMultiplier[0] = 0.1;
		return 1;
	}
	else
	{
		return RoundToZero((DifficultySum / clients) * (DifficultySum / clients) * 10);
	}
}

public Action Command_Say(int client, int args)
{
	if (!l4d2_autodifficulty.BoolValue)
		return Plugin_Continue;

	if (!client)
	{
		return Plugin_Continue;
	}
	
	char text[192];
	if (!GetCmdArgString(text, sizeof(text)))
	{
		return Plugin_Continue;
	}
	
	int startidx = 0;
	if(text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
	
	ReplySource old = SetCmdReplySource(SM_REPLY_TO_CHAT);
	
	if (strcmp(text[startidx], "!info", false) == 0)
	{
		char GameDifficulty[24];
		z_difficulty.GetString(GameDifficulty, sizeof(GameDifficulty));
		if (StrEqual(GameDifficulty, "Easy", false))
		{
			GameDifficulty = "Easy";
		}
		else if (StrEqual(GameDifficulty, "Normal", false))
		{
			GameDifficulty = "Normal";
	    }
		else if (StrEqual(GameDifficulty, "Hard", false))
		{
			GameDifficulty = "Hard";
		}
		else if (StrEqual(GameDifficulty, "Impossible", false))
		{
			GameDifficulty = "Expert";
	    }

		PrintToChat(client, "\x05Informantion:\x03");
		PrintToChat(client, "\x05Difficulty: \x04%s\x05 x \x04%f\x05 | Active players: \x04%i\x03", GameDifficulty, DifficultyMultiplier[0], GetRealClientCount());
		if (IsTankAlive())
		{
			PrintToChat(client, "\x05Tank HP: \x03%i\x05 | Witch HP: \x04%i\x05 | Zombie HP: \x04%i\x03", GetTankHP(), z_witch_health.IntValue, z_health.IntValue);
		}
		else
		{
			PrintToChat(client, "\x05Tank HP: \x04%i\x05 | Witch HP: \x04%i\x05 | Zombie HP: \x04%i\x03", GetTankHP(), z_witch_health.IntValue, z_health.IntValue);
		}
		PrintToChat(client, "\x05Hunter HP: \x04%i\x05 | Smoker HP: \x04%i\x05 | Boomer HP: \x04%i\x05 \nCharger HP: \x04%i\x05 | Spitter HP: \x04%i\x05 | Jockey HP: \x04%i\x03", z_hunter_health.IntValue, z_smoker_health.IntValue, z_boomer_health.IntValue, z_charger_health.IntValue, z_spitter_health.IntValue, z_jockey_health.IntValue);
		PrintToChat(client, "\x05Grenade Launcher Damage = \x04%d!", grenadelauncher_damage.IntValue);
	}
	else if (strcmp(text[startidx], "!points", false) == 0 || strcmp(text[startidx], "!usepoints", false) == 0 || strcmp(text[startidx], "!wm", false) == 0 || strcmp(text[startidx], "!cc", false) == 0 || strcmp(text[startidx], "!buy", false) == 0)
	{
		PrintToChat(client, "\x05No points on this server. Only loot drops from special infected.\x03");
		PrintToChat(client, "\x05No commands on this server! Only \x04!easy\x05, \x04!normal\x05, \x04!info\x05, \x04!hard\x05, \x04!next\x05 and standart SM commands like \x04thetime\x03");
	}
	else if (strcmp(text[startidx], "!easy", false) == 0)
	{
		if (DifficultyMultiplier[client] != 0.0)
		{
			SetClientInfo(client, "_dv", "easy");
			DifficultyMultiplier[client] = 0.0;
			GetTotalDifficultyMultiplier();
			Autodifficulty(GetRealClientCount());
			PrintToChat(client, "\x05%N changed Difficulty Multiplier to \x04%f (vote easy)", client, DifficultyMultiplier[0]);
		}
	}
	else if (strcmp(text[startidx], "!normal", false) == 0)
	{
		if (DifficultyMultiplier[client] != 1.0)
		{
			SetClientInfo(client, "_dv", "normal");
			DifficultyMultiplier[client] = 1.0;
			GetTotalDifficultyMultiplier();
			Autodifficulty(GetRealClientCount());
			PrintToChat(client, "\x05%N changed Difficulty Multiplier to \x04%f (vote normal)", client, DifficultyMultiplier[0]);
		}
	}
	else if (strcmp(text[startidx], "!hard", false) == 0)
	{
		if (DifficultyMultiplier[client] != 2.0)
		{
			SetClientInfo(client, "_dv", "hard");
			DifficultyMultiplier[client] = 2.0;
			GetTotalDifficultyMultiplier();
			Autodifficulty(GetRealClientCount());
			PrintToChat(client, "\x05%N changed Difficulty Multiplier to \x04%f (vote hard)", client, DifficultyMultiplier[0]);
		}
	}
	else if (strcmp(text[startidx], "!all easy", false) == 0)
	{
		AdminId adminId = GetUserAdmin(client);
		// Checks if player is registered as an admin
		if (((adminId == INVALID_ADMIN_ID) ? false : GetAdminFlag(adminId, Admin_Root)) == false)
		{
			ReplyToCommand(client, "You don't have enough permissions to use this command.");
			return Plugin_Continue;
		}
		else
		{
			char ClientSteamID[12];
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientConnected(i))
				{
					GetClientAuthId(i, AuthId_Steam2, ClientSteamID, sizeof(ClientSteamID));
					if (!StrEqual(ClientSteamID, "BOT", false))
					{
						if (IsClientInGame(i) && !IsFakeClient(i))
						{
							DifficultyMultiplier[i] = 0.0;
						}       
					}
				}
			}
			GetTotalDifficultyMultiplier();
			Autodifficulty(GetRealClientCount());
			PrintToChat(client, "\x05%N changed Difficulty Multiplier to \x04%f (all easy)", client, DifficultyMultiplier[0]);			
		}
	}
	else if (strcmp(text[startidx], "!all normal", false) == 0)
	{
		AdminId adminId = GetUserAdmin(client);
		// Checks if player is registered as an admin
		if (((adminId == INVALID_ADMIN_ID) ? false : GetAdminFlag(adminId, Admin_Root)) == false)
		{
			ReplyToCommand(client, "You don't have enough permissions to use this command.");
			return Plugin_Continue;
		}
		else
		{
			char ClientSteamID[12];
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientConnected(i))
				{
					GetClientAuthId(i, AuthId_Steam2, ClientSteamID, sizeof(ClientSteamID));
					if (!StrEqual(ClientSteamID, "BOT", false))
					{
						if (IsClientInGame(i) && !IsFakeClient(i))
						{
							DifficultyMultiplier[i] = 1.0;
						}  
					}
				}
			}
			GetTotalDifficultyMultiplier();
			Autodifficulty(GetRealClientCount());
			PrintToChat(client, "\x05%N changed Difficulty Multiplier to \x04%f (all normal)", client, DifficultyMultiplier[0]);			
		}
	}
	else if (strcmp(text[startidx], "!all hard", false) == 0)
	{
		AdminId adminId = GetUserAdmin(client);
		// Checks if player is registered as an admin
		if (((adminId == INVALID_ADMIN_ID) ? false : GetAdminFlag(adminId, Admin_Root)) == false)
		{
			ReplyToCommand(client, "You don't have enough permissions to use this command.");
			return Plugin_Continue;
		}
		else
		{
			char ClientSteamID[12];
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientConnected(i))
				{
					GetClientAuthId(i, AuthId_Steam2, ClientSteamID, sizeof(ClientSteamID));
					if (!StrEqual(ClientSteamID, "BOT", false))
					{
						if (IsClientInGame(i) && !IsFakeClient(i))
						{
							DifficultyMultiplier[i] = 2.0;
						}
					}
				}
			}
			GetTotalDifficultyMultiplier();
			Autodifficulty(GetRealClientCount());
			PrintToChat(client, "\x05%N changed Difficulty Multiplier to \x04%f (all hard)", client, DifficultyMultiplier[0]);
		}
	}
	else
	{
		SetCmdReplySource(old);
	}

	return Plugin_Continue;	
}

public void OnConfigsExecuted()
{
    if (l4d2_autodifficulty.BoolValue) 
    {
        ServerCommand("exec autodifficulty_on.cfg");
        Autodifficulty(GetRealClientCount());
    }
}

void Autodifficulty_EnableDisable(ConVar hVariable, const char[] strOldValue, const char[] strNewValue)
{
    if (l4d2_autodifficulty.BoolValue) 
	{
		ServerCommand("exec autodifficulty_on.cfg");
		Autodifficulty(GetRealClientCount());
	}
    else
	{
		z_special_spawn_interval.SetInt(45, false, false);
		special_respawn_interval.SetInt(45, false, false);
		tank_burn_duration.SetInt(75, false, false);
		z_hunter_limit.SetInt(1, false, false);
		z_smoker_limit.SetInt(1, false, false);
		z_boomer_limit.SetInt(1, false, false);
		z_charger_limit.SetInt(1, false, false);
		z_spitter_limit.SetInt(1, false, false);

		z_hunter_health.SetInt(250, false, false);
		z_smoker_health.SetInt(250, false, false);
		z_boomer_health.SetInt(50, false, false);
		z_charger_health.SetInt(600, false, false);
		z_spitter_health.SetInt(50, false, false);
		z_jockey_health.SetInt(325, false, false);
		z_witch_health.SetInt(1000, false, false);

		z_spitter_max_wait_time.SetInt(30, false, false);
		z_vomit_interval.SetInt(30, false, false);

		z_smoker_speed.SetInt(210, false, false);
		z_boomer_speed.SetInt(175, false, false);
		z_spitter_speed.SetInt(210, false, false);
		z_tank_speed.SetInt(210, false, false);
		
		grenadelauncher_damage.SetInt(400, false, false);
		
		tongue_miss_delay.SetInt(15, false, false);
		tongue_range.SetInt(750, false, false);
		
		z_spitter_range.SetInt(850, false, false);
		z_spit_interval.SetInt(20, false, false);
		
		smoker_pz_claw_dmg.SetInt(4, false, false);
		jockey_pz_claw_dmg.SetInt(4, false, false);

		char sGameDifficulty[16];
		z_difficulty.GetString(sGameDifficulty, sizeof(sGameDifficulty));
		if (StrEqual(sGameDifficulty, "Easy", false))
		{
			z_tank_health.SetInt(2000, false, false);
		}
		else if (StrEqual(sGameDifficulty, "Normal", false))
		{
			z_tank_health.SetInt(4000, false, false);
		}
		else if (StrEqual(sGameDifficulty, "Hard", false))
		{
			z_tank_health.SetInt(6000, false, false);
		}
		else if (StrEqual(sGameDifficulty, "Impossible", false))
		{
			z_tank_health.SetInt(8000, false, false);
		}

		z_health.SetInt(50, false, false);

		ServerCommand("exec autodifficulty_off.cfg");
	}
}

Action AutoDifficulty(Handle timer)
{
    Autodifficulty(GetRealClientCount());
    return Plugin_Stop;
}

public void OnClientPostAdminCheck(int client)
{
	if (client > 0 && !IsFakeClient(client) && l4d2_autodifficulty.BoolValue)
	{
		CreateTimer(3.0, AutoDifficulty);
		char client_difficulty[10];
		// Difficulty Voted
		if (GetClientInfo(client, "_dv", client_difficulty, sizeof(client_difficulty)))
		{
			if (StrEqual(client_difficulty, "easy", false))
			{
				DifficultyMultiplier[client] = 0.0;
			}
			else if (StrEqual(client_difficulty, "normal", false))
			{
				DifficultyMultiplier[client] = 1.0;
			}
			else if (StrEqual(client_difficulty, "hard", false))
			{
				DifficultyMultiplier[client] = 2.0;
			}
			else
			{
				DifficultyMultiplier[client] = 1.7;
				PrintToChat(client, "\x05No difficulty records found. It will be \"Default (1.7)\"", client);
			}
		}
		GetTotalDifficultyMultiplier();
		Autodifficulty(GetRealClientCount());
		PrintToChat(client, "\x05Player \x04%N\x05 has entered the game. Zombies grow stronger!\x03", client);
		PrintToChat(client, "\x05%N changed Difficulty Multiplier to \x04%f.", client, DifficultyMultiplier[0]);
	}
}

public void OnClientDisconnect(int client)
{
	if (client > 0 && !IsFakeClient(client) && l4d2_autodifficulty.BoolValue)
	{
		if (GetRealClientCount() > 0)
		{
			Autodifficulty(GetRealClientCount());
			CreateTimer(3.0, AutoDifficulty);
			PrintToChatAll("\x05Player \x04%N\x05 has left the game. Zombies weaken! \x03", client);
			PrintToChat(client, "\x05%N changed Difficulty Multiplier to \x04%f.", client, DifficultyMultiplier[0]);
		}
		else
		{
            ServerCommand("exec clear.cfg");
		}
	}
}

stock int GetGameMode()
{
	char GameMode[13];
	ConVar gamecvar_mp_gamemode = FindConVar("mp_gamemode");
	gamecvar_mp_gamemode.GetString(GameMode, sizeof(GameMode));
	if (StrEqual(GameMode, "coop", false) == true)
	{
		return 1;
	}
	else if (StrEqual(GameMode, "realism", false) == true)
	{
		return 2;
	}
	else if (StrEqual(GameMode, "survival", false) == true)
	{
		return 3;
	}
	else if (StrEqual(GameMode, "versus", false) == true)
	{
		return 4;
	}
	else if (StrEqual(GameMode, "teamversus", false) == true)
	{
		return 5;
	}
	else if (StrEqual(GameMode, "scavenge", false) == true)
	{
		return 6;
	}
	else if (StrEqual(GameMode, "teamscavenge", false) == true)
	{
		return 7;
	}
	else if (StrEqual(GameMode, "mutation3", false) == true)
	{
		return 8;
	}
	else if (StrEqual(GameMode, "mutation12", false) == true)
	{
		return 9;
	}
	return 0;
}

public void Autodifficulty(int playerscount)
{
	if (playerscount < 4)
		playerscount = 4;
		
	int BonusDrop = 0;
	if (GetGameMode() == 8)
	{
		BonusDrop = 2;
	}
		
	int ItemsDropCount[7];

	//	GetTotalDifficultyMultiplier();

	if(bFindLootPLugin)
	{
		l4d2_loot_h_drop_items = FindConVar("l4d2_loot_h_drop_items");
		l4d2_loot_b_drop_items = FindConVar("l4d2_loot_b_drop_items");
		l4d2_loot_s_drop_items = FindConVar("l4d2_loot_s_drop_items");
		l4d2_loot_c_drop_items = FindConVar("l4d2_loot_c_drop_items");
		l4d2_loot_sp_drop_items = FindConVar("l4d2_loot_sp_drop_items");
		l4d2_loot_j_drop_items = FindConVar("l4d2_loot_j_drop_items");
		l4d2_loot_t_drop_items = FindConVar("l4d2_loot_t_drop_items");   
	//	l4d2_loot_g_chance_nodrop = FindConVar("l4d2_loot_g_chance_nodrop");
	}

	ConVar sv_disable_glow_survivors = FindConVar("sv_disable_glow_survivors");

	if (DifficultyMultiplier[0] < 5)
	{
		sv_disable_glow_survivors.SetInt(0, false, false);
	}
	else
	{
		sv_disable_glow_survivors.SetInt(1, false, false);
	}

	if (playerscount > 4)
	{
		tank_burn_duration.SetInt(RoundToZero(18.75 * playerscount), false, false);

		z_spitter_max_wait_time.SetInt(34 - playerscount, false, false);
		z_vomit_interval.SetInt(34 - playerscount, false, false);

		z_smoker_speed.SetInt(210 + RoundToZero(3.0 * (playerscount - 4) * DifficultyMultiplier[0]), false, false); 
		z_boomer_speed.SetInt(175 + RoundToZero(3.0 * (playerscount - 4) * DifficultyMultiplier[0]), false, false); 
		z_spitter_speed.SetInt(160 + RoundToZero(15.0 * playerscount * DifficultyMultiplier[0]), false, false);
		z_tank_speed.SetInt(210 + RoundToZero((playerscount - 4) * 5 * DifficultyMultiplier[0]), false, false);

		z_hunter_limit.SetInt(RoundToZero(2.5 + (playerscount / 5)), false, false);
		z_smoker_limit.SetInt(RoundToZero(1.5 + (playerscount / 6)), false, false);
		z_boomer_limit.SetInt(RoundToZero(1.5 + (playerscount / 7)), false, false);
		z_charger_limit.SetInt(RoundToZero(0.3 + (playerscount / 7)), false, false);
		z_spitter_limit.SetInt(RoundToZero(1.4 + (playerscount / 6)), false, false);
		z_jockey_limit.SetInt(RoundToZero(0.5 + (playerscount / 8)), false, false);

		if(bFindLootPLugin)
		{	
			ItemsDropCount[0] = CheckCvarMin(RoundToZero((playerscount / 5.3) * SquareRoot(DifficultyMultiplier[0])), 1);
			ItemsDropCount[1] = CheckCvarMin(RoundToZero((playerscount / 4.0) * SquareRoot(DifficultyMultiplier[0])), 1);
			ItemsDropCount[2] = CheckCvarMin(RoundToZero((playerscount / 4.0) * SquareRoot(DifficultyMultiplier[0])), 1);
			ItemsDropCount[3] = CheckCvarMin(RoundToZero((playerscount / 4.6) * SquareRoot(DifficultyMultiplier[0])), 1);
			ItemsDropCount[4] = CheckCvarMin(RoundToZero((playerscount / 4.6) * SquareRoot(DifficultyMultiplier[0])), 1);
			ItemsDropCount[5] = CheckCvarMin(RoundToZero((playerscount / 4.6) * SquareRoot(DifficultyMultiplier[0])), 1);
			ItemsDropCount[6] = CheckCvarMin(RoundToZero(playerscount * 5 * SquareRoot(DifficultyMultiplier[0])), 5);
			
			l4d2_loot_h_drop_items.SetInt(CheckCvarMax(ItemsDropCount[0], 2) + BonusDrop, false, false);
			l4d2_loot_b_drop_items.SetInt(CheckCvarMax(ItemsDropCount[1], 4) + BonusDrop, false, false);
			l4d2_loot_s_drop_items.SetInt(CheckCvarMax(ItemsDropCount[2], 2) + BonusDrop, false, false);
			l4d2_loot_c_drop_items.SetInt(CheckCvarMax(ItemsDropCount[3], 4) + BonusDrop, false, false);
			l4d2_loot_sp_drop_items.SetInt(CheckCvarMax(ItemsDropCount[4], 3) + BonusDrop, false, false);
			l4d2_loot_j_drop_items.SetInt(CheckCvarMax(ItemsDropCount[5], 3) + BonusDrop, false, false);
			l4d2_loot_t_drop_items.SetInt(CheckCvarMax(ItemsDropCount[6] + (BonusDrop * 3), playerscount) + BonusDrop, false, false);
		}

		z_hunter_health.SetInt(RoundToZero(30.0 * playerscount * DifficultyMultiplier[0]), false, false);
		z_smoker_health.SetInt(RoundToZero(52.5 * playerscount * DifficultyMultiplier[0]), false, false);
		z_boomer_health.SetInt(RoundToZero(8.5 * playerscount * DifficultyMultiplier[0]), false, false);
		z_charger_health.SetInt(CheckCvarMax(RoundToZero(75.0 * playerscount * DifficultyMultiplier[0]), 2000), false, false);
		z_spitter_health.SetInt(RoundToZero(20.0 * playerscount * DifficultyMultiplier[0]), false, false);
		z_jockey_health.SetInt(RoundToZero(50.25 * playerscount * DifficultyMultiplier[0]), false, false);
//		z_witch_health.SetInt(CheckCvarMax(RoundToZero(250.0 * playerscount * DifficultyMultiplier[0]), 3000), false, false);
		z_health.SetInt(RoundToZero(8.5 * playerscount * DifficultyMultiplier[0]), false, false);
		
		grenadelauncher_damage.SetInt(RoundToZero((187.5 * playerscount) + 0.3), false, false);
		
		z_special_spawn_interval.SetInt(CheckCvarMin(49 - (playerscount * 3), 5), false, false);
		special_respawn_interval.SetInt(CheckCvarMin(49 - (playerscount * 3), 5), false, false);		
	}
	else
	{
		z_hunter_health.SetInt(250, false, false);
		z_smoker_health.SetInt(250, false, false);
		z_boomer_health.SetInt(50, false, false);
		z_charger_health.SetInt(600, false, false);
		z_spitter_health.SetInt(100, false, false);
		z_jockey_health.SetInt(325, false, false);
//		z_witch_health.SetInt(1000, false, false);
		z_health.SetInt(50, false, false);

		z_special_spawn_interval.SetInt(45, false, false);

		z_hunter_limit.SetInt(1, false, false);
		z_smoker_limit.SetInt(1, false, false);
		z_boomer_limit.SetInt(1, false, false);
		z_charger_limit.SetInt(1, false, false);
		z_spitter_limit.SetInt(1, false, false);
		z_jockey_limit.SetInt(1, false, false);

		z_smoker_speed.SetInt(210, false, false);
		z_spitter_max_wait_time.SetInt(30, false, false);
		z_boomer_speed.SetInt(175, false, false);
		z_spitter_speed.SetInt(210, false, false);
		z_tank_speed.SetInt(210, false, false);

		grenadelauncher_damage.SetInt(400, false, false);
	}

	smoker_pz_claw_dmg.SetInt(playerscount, false, false);
	jockey_pz_claw_dmg.SetInt(playerscount, false, false);
	tongue_choke_damage_amount.SetInt(RoundToZero((10 + (playerscount - 4) * 1.666) * DifficultyMultiplier[0]), false, false);
	tongue_drag_damage_amount.SetInt(RoundToZero(playerscount * 0.75 * DifficultyMultiplier[0]), false, false);
	tongue_miss_delay.SetInt(CheckCvarMin(17 - playerscount, 1), false, false);
	tongue_hit_delay.SetInt(CheckCvarMin(17 - playerscount, 1), false, false);

//	l4d2_loot_g_chance_nodrop.SetInt(CheckCvarMin(RoundToZero(65 / DifficultyMultiplier[0]), 5), false, false);
	if(IsMapFinished != null)
	{
		if (IsMapFinished.BoolValue)
		{
			ConVar monsterbots_interval = FindConVar("monsterbots_interval");
			monsterbots_interval.SetInt(CheckCvarMin(26 - playerscount, 7), false, false);
		}
	}

	tongue_range.SetInt(750 + RoundToZero((playerscount - 4) * 20 * DifficultyMultiplier[0]), false, false);

	z_spitter_range.SetInt(850 + RoundToZero((playerscount - 4) * 20 * DifficultyMultiplier[0]), false, false);
	z_spit_interval.SetInt(CheckCvarMin(20 - RoundToZero((playerscount - 4) * 0.83 * DifficultyMultiplier[0]), 5), false, false);

	char sGameDifficulty[16];
	z_difficulty.GetString(sGameDifficulty, sizeof(sGameDifficulty));

	int TankHP = 4000;
	if (StrEqual(sGameDifficulty, "Easy", false))
	{
		TankHP = RoundToZero(500 * playerscount * DifficultyMultiplier[0]);
	}
	else if (StrEqual(sGameDifficulty, "Normal", false))
	{
		TankHP = RoundToZero(600 * playerscount * DifficultyMultiplier[0]);
	}
	else if (StrEqual(sGameDifficulty, "Hard", false))
	{
		TankHP = RoundToZero(700 * playerscount * DifficultyMultiplier[0]);
	}
	else if (StrEqual(sGameDifficulty, "Impossible", false))
	{
		TankHP = RoundToZero(800 * DifficultyMultiplier[0] * playerscount);
	}
	TankHP = CheckCvarMin(TankHP, 4000);
	TankHP = CheckCvarMax(TankHP, 35000);
	z_tank_health.SetInt(TankHP, false, false);
}
