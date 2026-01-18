#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <vip_core>

#define LIMIT_MODE 			1 	//	Режим работы лимита: 1 - X раз за раунд, 0 - X раз за карту

#define USE_AUTORESPAWN		1	//	Использовать ли Авто Возрождение

#define RESPAWN_CMD 		"sm_respawn"	//	Команда для возрождения

#define MIN_ALIVE_MODE		3 	//	Режим работы sm_vip_respawn_min_alive:
								//		0 - Живых в команде игрока
								//		1 - Живых в команде противника игрока
								//		2 - Живых суммарно в обеих командах 
								//		3 - Живых в каждой команде

// #define GAME_CS
// #define GAME_TF2
// #define GAME_L4D
#define GAME_L4D2
// #define GAME_DODS


#if defined GAME_CS
	#include <cstrike>
	#include <sdktools_gamerules>
	#define GAME_NAME	"CS:S/CS:GO"
#elseif defined GAME_TF2
	#include <tf2>
	#include <tf2_stocks>
	#define GAME_NAME	"TF2"
#elseif defined GAME_L4D
	#include <sdktools>
	#define GAME_NAME	"L4D"
#elseif defined GAME_L4D2
	#include <sdktools>
	#define GAME_NAME	"L4D2"
#elseif defined GAME_DODS
	#include <sdktools>
	#define GAME_NAME	"DOD:S"
#else
	#error "Invalid define GAME"
#endif

public Plugin myinfo =
{
	name = "[VIP] Respawn (" ... GAME_NAME ... ")",
	author = "R1KO",
	version = "1.3"
};

static const char g_szFeature[] = "Respawn";
static const char g_szFeatureRespawnWaitTime[] = "RespawnWaitTime";
#if USE_AUTORESPAWN
static const char g_szFeatureAutoRespawn[] = "AutoRespawn";
bool g_bAutoRespawn[MAXPLAYERS + 1] = {false, ...};
#endif

int g_iClientRespawns[MAXPLAYERS + 1] = {0, ...};
float g_fDeathTime[MAXPLAYERS + 1] = {0.0, ...};

bool g_bEnabled = false;
int g_iMapLimit = 0;
float g_fEndDuration = 0.0;
int g_iMinAlive = 0;
int g_iRoundStartTime = 0;

bool g_bEnabledRespawn = false;

Handle g_hTimer = null;
StringMap g_hAuthTrie;

#if defined GAME_L4D || defined GAME_L4D2
Handle g_hRoundRespawn = null;
float g_fDeathPos[MAXPLAYERS + 1][3];
#endif

#if defined GAME_L4D2
Handle g_hBecomeGhost = null;
Handle g_hState_Transition = null;
#elseif defined GAME_DODS
Handle g_hPlayerRespawn = null;
#endif

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if (engine == Engine_Left4Dead || engine == Engine_Left4Dead2 || engine == Engine_DODS)
	{
		return APLRes_Success;
	}
	else
	{
		strcopy(error, err_max, "This game is not supported.");
		return APLRes_SilentFailure;
	}
}

public void OnPluginStart()
{
	#if defined GAME_L4D || defined GAME_L4D2 || defined GAME_DODS
	GameData hGameConf = new GameData("vip_respawn");
	if (hGameConf != null)
	{
		#if defined GAME_L4D || defined GAME_L4D2
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "RoundRespawn");
		g_hRoundRespawn = EndPrepSDKCall();
		if (g_hRoundRespawn == null)
		{
			SetFailState("RoundRespawn Signature broken");
		}
		#endif

		#if defined GAME_L4D2
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "BecomeGhost");
		PrepSDKCall_AddParameter(SDKType_PlainOldData , SDKPass_Plain);
		g_hBecomeGhost = EndPrepSDKCall();
		if (g_hBecomeGhost == null)
		{
			SetFailState("BecomeGhost Signature broken");
		}

		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "State_Transition");
		PrepSDKCall_AddParameter(SDKType_PlainOldData , SDKPass_Plain);
		g_hState_Transition = EndPrepSDKCall();
		if (g_hState_Transition == null)
			SetFailState("State_Transition Signature broken");
		#endif

		#if defined GAME_DODS
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "DODRespawn");
		g_hPlayerRespawn = EndPrepSDKCall();

		if (g_hPlayerRespawn == null)
		{
			SetFailState("Fatal Error: Unable to find signature for \"CDODPlayer::DODRespawn(void)\"!");
		}
		#endif
	}
	else
	{
		SetFailState("Could not find gamedata file (addons/sourcemod/gamedata/vip_respawn.txt)");
	}

	delete hGameConf;
	#endif

	g_hAuthTrie = new StringMap();

	ConVar hCvar = CreateConVar("sm_vip_respawn_enable", "1", "Включен ли плагин (0 - Отключен, 1 - Включен)", 0, true, 0.0, true, 1.0);
	g_bEnabled = hCvar.BoolValue;
	hCvar.AddChangeHook(OnEnabledChange);

	hCvar = CreateConVar("sm_vip_respawn_map_limit", "-1", "Ограничение респавнов за раунд/карту для карты (-1 - нет ограничения, 0 - запрещено, 1 и больше)", 0, true, -1.0);
	g_iMapLimit = hCvar.IntValue;
	hCvar.AddChangeHook(OnMapLimitChange);

	#if defined GAME_CS || defined GAME_TF2 || defined GAME_DODS
	hCvar = CreateConVar("sm_vip_respawn_end_duration", "0.0", "Сколько секунд после начала раунда игрок может возрождаться (0.0 - Отключено)", 0, true, 0.0);
	hCvar.AddChangeHook(OnEndDurationChange);
	g_fEndDuration = hCvar.FloatValue;
	#endif

	hCvar = CreateConVar("sm_vip_respawn_min_alive", "0", "Сколько минимально должно быть живых игроков в команде чтобы игрок мог возрождаться (0 - Отключено)", 0, true, 0.0);
	hCvar.AddChangeHook(OnMinAliveChange);
	g_iMinAlive = hCvar.IntValue;

	AutoExecConfig(true, "VIP_Respawn", "vip");

	RegConsoleCmd(RESPAWN_CMD, Respawn_CMD);

	#if defined GAME_TF2
	HookEventEx("teamplay_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEventEx("teamplay_round_win", Event_RoundEnd, EventHookMode_PostNoCopy);
	#else
	HookEventEx("round_freeze_end", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEventEx("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	#endif

	//	HookEventEx("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	#if defined GAME_L4D || defined GAME_L4D2
	HookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);
	#endif
	HookEvent("player_death", Event_PlayerDeath);

	LoadTranslations("vip_respawn.phrases");
	LoadTranslations("vip_modules.phrases");
	LoadTranslations("vip_core.phrases");

	if(VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
}

void OnEnabledChange(ConVar hCvar, const char[] oldValue, const char[] newValue)	{ g_bEnabled = hCvar.BoolValue; }
void OnMapLimitChange(ConVar hCvar, const char[] oldValue, const char[] newValue)	{ g_iMapLimit = hCvar.IntValue; }
#if defined GAME_CS || defined GAME_TF2 || defined GAME_DODS
void OnEndDurationChange(ConVar hCvar, const char[] oldValue, const char[] newValue)	{ g_fEndDuration = hCvar.FloatValue; }
#endif
void OnMinAliveChange(ConVar hCvar, const char[] oldValue, const char[] newValue)		{ g_iMinAlive = hCvar.IntValue; }

public void VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_szFeature, INT, SELECTABLE, OnSelectItem, OnDisplayItem);
	VIP_RegisterFeature(g_szFeatureRespawnWaitTime, INT, HIDE);
	#if USE_AUTORESPAWN
	VIP_RegisterFeature(g_szFeatureAutoRespawn, BOOL, TOGGLABLE, OnToggleItem, _, OnDrawItem);
	#endif
}

public void OnPluginEnd()
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
	{
		VIP_UnregisterFeature(g_szFeature);
		VIP_UnregisterFeature(g_szFeatureRespawnWaitTime);
		#if USE_AUTORESPAWN
		VIP_UnregisterFeature(g_szFeatureAutoRespawn);
		#endif
	}
}

#if LIMIT_MODE == 0
public void OnMapStart()
{
	g_hAuthTrie.Clear();
	for(int i = 1; i <= MaxClients; ++i) g_iClientRespawns[i] = 0;
}
#endif

Action Respawn_CMD(int iClient, int args)
{
	if(iClient)
	{
		if(!g_bEnabled)
		{
			VIP_PrintToChatClient(iClient, "%t", "RESPAWN_OFF");
		}
		if(VIP_IsClientVIP(iClient) && VIP_IsClientFeatureUse(iClient, g_szFeature))
		{
			RespawnClient(iClient);
		}
		else
		{
			VIP_PrintToChatClient(iClient, "%t", "COMMAND_NO_ACCESS");
		}
	}
	return Plugin_Handled;
}

void Event_RoundStart(Event hEvent, const char[] name, bool dontBroadcast)
{
	#if LIMIT_MODE == 1
	g_hAuthTrie.Clear();
	for(int i = 1; i <= MaxClients; ++i) g_iClientRespawns[i] = 0;
	#endif

	if (g_hTimer != null)
	{
		delete g_hTimer;
	}

	g_bEnabledRespawn = true;

	if (g_fEndDuration)
	{
		g_hTimer = CreateTimer(g_fEndDuration, Timer_DisableRespawn);
	}
	
	g_iRoundStartTime = GetTime();
}

Action Timer_DisableRespawn(Handle hTimer)
{
	g_bEnabledRespawn = false;
	g_hTimer = null;
	return Plugin_Stop;
}

void Event_RoundEnd(Event hEvent, const char[] name, bool dontBroadcast)
{
	if(g_bEnabledRespawn)
	{
		g_bEnabledRespawn = false;
	}

	if (g_hTimer != null)
	{
		delete g_hTimer;
	}
}

public void OnClientPutInServer(int iClient)
{
	#if USE_AUTORESPAWN
	g_bAutoRespawn[iClient] = false;
	#endif
	g_iClientRespawns[iClient] = 0;

	char sAuth[32];
	GetClientAuthId(iClient, AuthId_Engine, sAuth, sizeof(sAuth));
	g_hAuthTrie.GetValue(sAuth, g_iClientRespawns[iClient]);
}

#if defined GAME_L4D || defined GAME_L4D2
Action Event_PlayerDeathPre(Event hEvent, const char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", g_fDeathPos[iClient]);
	return Plugin_Continue;
}
#endif

Action Event_PlayerDeath(Event hEvent, const char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	g_fDeathTime[iClient] = GetGameTime();

	#if USE_AUTORESPAWN
	if(g_bAutoRespawn[iClient])
	{
		if (!IsAllowedTimeAfterRoundStart(iClient))
		{
			return Plugin_Continue;
		}

		CreateTimer(1.0, Timer_RespawnClient, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);
	}
	#endif
	return Plugin_Continue;
}

#if USE_AUTORESPAWN
Action Timer_RespawnClient(Handle hTimer, any iUserID)
{
	int iClient = GetClientOfUserId(iUserID);
	if(iClient && IsClientInGame(iClient) && CheckRespawn(iClient, false))
	{
		VIP_PrintToChatClient(iClient, "%t", "AUTORESPAWN_NOTIFY");
		RespawnClient(iClient, false);
	}

	return Plugin_Stop;
}
#endif

stock void RespawnClient(int iClient, bool bCheck = true)
{
	if(bCheck && !CheckRespawn(iClient, true))
	{
		return;
	}

	++g_iClientRespawns[iClient];

	char sAuth[32];
	GetClientAuthId(iClient, AuthId_Engine, sAuth, sizeof(sAuth));
	g_hAuthTrie.SetValue(sAuth, g_iClientRespawns[iClient]);

	#if defined GAME_CS
	CS_RespawnPlayer(iClient);
	#elseif defined GAME_TF2
	TF2_RespawnPlayer(iClient);
	#elseif defined GAME_L4D
	if(GetClientTeam(iClient) == 2)
	{
		SDKCall(g_hRoundRespawn, iClient);
		EquipPlayerWeapon(iClient, GivePlayerItem(iClient, "weapon_first_aid_kit"));
		EquipPlayerWeapon(iClient, GivePlayerItem(iClient, "weapon_smg"));
		g_fDeathPos[iClient][2] += 40.0;
		TeleportEntity(iClient, g_fDeathPos[iClient], NULL_VECTOR, NULL_VECTOR);
	}
	#elseif defined GAME_L4D2
	switch(GetClientTeam(iClient))
	{
		case 2:
		{
			SDKCall(g_hRoundRespawn, iClient);
			GivePlayerItem(iClient, "weapon_first_aid_kit");
			GivePlayerItem(iClient, "weapon_smg");
			g_fDeathPos[iClient][2] += 40.0;
			TeleportEntity(iClient, g_fDeathPos[iClient], NULL_VECTOR, NULL_VECTOR);
		}
		case 3:
		{
			SDKCall(g_hState_Transition, iClient, 8);
			SDKCall(g_hBecomeGhost, iClient, 1);
			SDKCall(g_hState_Transition, iClient, 6);
			SDKCall(g_hBecomeGhost, iClient, 1);
			g_fDeathPos[iClient][2] += 40.0;
			TeleportEntity(iClient, g_fDeathPos[iClient], NULL_VECTOR, NULL_VECTOR);
		}
	}
	#elseif defined GAME_DODS
	SDKCall(g_hPlayerRespawn, iClient);
	#endif
}

stock bool CheckRespawn(int iClient, bool bNotify)
{
	if(!g_bEnabled)
	{
		VIP_PrintToChatClient(iClient, "%t", "RESPAWN_OFF");
		return false;
	}

	if(g_iMapLimit == 0)
	{
		if(bNotify)
		{
			VIP_PrintToChatClient(iClient, "%t", "RESPAWN_OFF");
		}
		return false;
	}

	if(!g_bEnabledRespawn)
	{
		if(bNotify)
		{
			VIP_PrintToChatClient(iClient, "%t", "RESPAWN_FORBIDDEN");
		}
		return false;
	}

	#if defined GAME_CS
	if(GetEngineVersion() == Engine_CSGO && GameRules_GetProp("m_bWarmupPeriod") == 1) 
    {
		if(bNotify)
		{
			VIP_PrintToChatClient(iClient, "%t", "RESPAWN_FORBIDDEN_ON_WARMUP");
		}
		return false;
	}
	#endif

	if(GetGameTime() < g_fDeathTime[iClient] + 1.0)
	{
		return false;
	}

	int iClientTeam = GetClientTeam(iClient);
	if(iClientTeam < 2)
	{
		if(bNotify)
		{
			VIP_PrintToChatClient(iClient, "%t", "YOU_MUST_BE_ON_TEAM");
		}
		return false;
	}

	if(IsPlayerAlive(iClient))
	{
		if(bNotify)
		{
			VIP_PrintToChatClient(iClient, "%t", "YOU_MUST_BE_DEAD");
		}
		return false;
	}

	if (!IsAllowedTimeAfterRoundStart(iClient))
	{
		if(bNotify)
		{
			VIP_PrintToChatClient(iClient, "%t", "RESPAWN_NOT_AVAILABLE_YET");
		}
		return false;
	}

	int iLimit = VIP_GetClientFeatureInt(iClient, g_szFeature);

	if((g_iMapLimit != -1 && (iLimit == -1 || g_iMapLimit < iLimit) && g_iClientRespawns[iClient] >= g_iMapLimit) ||
	(iLimit != -1 && g_iClientRespawns[iClient] >= iLimit))
	{
		if(bNotify)
		{
			#if LIMIT_MODE == 1
			VIP_PrintToChatClient(iClient, "%t", "REACHED_ROUND_LIMIT");
			#else
			VIP_PrintToChatClient(iClient, "%t", "REACHED_MAP_LIMIT");
			#endif
		}
		return false;
	}

	if(g_iMinAlive)
	{
		int iPlayers[2], i, iTeam;
		iPlayers[0] = iPlayers[1] = 0;
		for(i = 1; i <= MaxClients; ++i)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i) && (iTeam = GetClientTeam(i)) > 1)
			{
				++iPlayers[iTeam-2];
			}
		}

		#if MIN_ALIVE_MODE == 0			//	Живых в команде игрока
		if(iPlayers[iClientTeam == 2 ? 0:1] < g_iMinAlive)
		#elseif MIN_ALIVE_MODE == 1		//	Живых в команде противника игрока
		if(iPlayers[iClientTeam == 2 ? 1:0] < g_iMinAlive)
		#elseif MIN_ALIVE_MODE == 2		//	Живых суммарно в обеих командах 
		if(iPlayers[0] + iPlayers[1] < g_iMinAlive)
		#elseif MIN_ALIVE_MODE == 3		//	Живых в каждой команде
		if(iPlayers[0] < g_iMinAlive || iPlayers[1] < g_iMinAlive)
		#endif
		{
			if(bNotify)
			{
				VIP_PrintToChatClient(iClient, "%t", "NOT_ENOUGH_ALIVE_PLAYERS");
			}
			return false;
		}
	}

	return true;
}

stock bool IsAllowedTimeAfterRoundStart(int iClient)
{
	int iWaitRespawn = VIP_GetClientFeatureInt(iClient, g_szFeatureRespawnWaitTime);
	if (iWaitRespawn)
	{
		return (GetTime() < g_iRoundStartTime + iWaitRespawn);
	}

	return true;
}

public bool OnSelectItem(int iClient, const char[] sFeatureName)
{
	if(!g_bEnabled)
	{
		return true;
	}

	if(!CheckRespawn(iClient, true))
	{
		return true;
	}
		
	RespawnClient(iClient);
	return true;
}

public bool OnDisplayItem(int iClient, const char[] sFeatureName, char[] sDisplay, int maxlen)
{
	if(VIP_GetClientFeatureStatus(iClient, g_szFeature) == ENABLED)
	{
		int iLimit = VIP_GetClientFeatureInt(iClient, g_szFeature);
		if(iLimit != -1)
		{
			if(g_iMapLimit != -1 && g_iMapLimit < iLimit)
			{
				iLimit = g_iMapLimit - g_iClientRespawns[iClient];
			}
			else
			{
				iLimit -= g_iClientRespawns[iClient];
			}

			FormatEx(sDisplay, maxlen, "%T [%T]", g_szFeature, iClient, "Left", iClient, iLimit);
			return true;
		}
	}

	return false;
}

#if USE_AUTORESPAWN
public Action OnToggleItem(int iClient, const char[] sFeatureName, VIP_ToggleState OldStatus, VIP_ToggleState &NewStatus)
{
	g_bAutoRespawn[iClient] = (VIP_IsClientFeatureUse(iClient, g_szFeature) && NewStatus == ENABLED);
	return Plugin_Continue;
}

public int OnDrawItem(int iClient, const char[] sFeatureName, int iStyle)
{
	if(VIP_GetClientFeatureStatus(iClient, g_szFeature) == ENABLED && VIP_GetClientFeatureStatus(iClient, g_szFeatureAutoRespawn) != NO_ACCESS)
	{
		return ITEMDRAW_DEFAULT;
	}

	return ITEMDRAW_RAWLINE;
}

public void VIP_OnVIPClientLoaded(int iClient)
{
	g_bAutoRespawn[iClient] = VIP_IsClientFeatureUse(iClient, g_szFeature) && VIP_IsClientFeatureUse(iClient, g_szFeatureAutoRespawn);
}
#endif
