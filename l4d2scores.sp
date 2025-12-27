#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define SCORE_VERSION "1.3.0"

#define SCORE_DEBUG 0
#define SCORE_DEBUG_LOG 0

#define SCORE_TEAM_A 1
#define SCORE_TEAM_B 2
#define SCORE_TYPE_ROUND 0
#define SCORE_TYPE_CAMPAIGN 1

#define SCORE_DELAY_PLACEMENT 0.1
#define SCORE_DELAY_TEAM_SWITCH 0.1
#define SCORE_DELAY_SWITCH_MAP 1.0
#define SCORE_DELAY_EMPTY_SERVER 3.0
#define SCORE_DELAY_SCORE_SWAPPED 0.5

#define SCORE_LIST_PANEL_LIFETIME 10
#define SCORE_SWAPMENU_PANEL_LIFETIME 10
#define SCORE_SWAPMENU_PANEL_REFRESH 0.5

#define L4D_MAXCLIENTS MaxClients
#define L4D_MAXCLIENTS_PLUS1 (L4D_MAXCLIENTS + 1)
#define L4D_TEAM_SURVIVORS 2
#define L4D_TEAM_INFECTED 3
#define L4D_TEAM_SPECTATE 1

#define L4D_TEAM_NAME(%1) (%1 == 2 ? "Survivors" : (%1 == 3 ? "Infected" : (%1 == 1 ? "Spectators" : "Unknown")))


#define SCORE_CAMPAIGN_OVERRIDE 1
#define SCORE_TEAM_PLACEMENT_OVERRIDE 0

forward void OnReadyRoundRestarted();

public Plugin myinfo =
{
	name = "L4D2 Score/Team Manager",
	author = "Downtown1 & AtomicStryker",
	description = "Manage teams and scores in L4D2",
	version = SCORE_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1029519"
}

float lastDisconnectTime;

Handle SpawnTimer    = null;
ConVar SurvivorLimit = null;
/* Props to:
name        = "L4D Missing Survivors",
author      = "Damizean",
description = "Plugin to use with L4D Downtown to spawn missing survivors.",
url         = "elgigantedeyeso@gmail.com"
*/

ConVar cvarTeamSwapping, cvarVoteScrambling, cvarFullResetOnEmpty, cvarGameMode, cvarGameModeActive;

int roundScores[3];    //store the round score, ignore index 0
Handle mapScores = null;

int mapCounter;
bool skippingLevel;
bool BeforeMapStart = true;

int LastKnownScoreTeamA;
int LastKnownScoreTeamB;

bool roundCounterReset = false;

bool clearedScores = false;
bool roundRestarting = false;

/* Current Mission */
bool pendingNewMission;
char nextMap[128];

/* Team Placement */
Handle teamPlacementTrie = null; //remember what teams to place after map change
int teamPlacementArray[256];  //after client connects, try to place him to this team
int teamPlacementAttempts[256]; //how many times we attempt and fail to place a person

enum TeamSwappingType
{
	DefaultL4D2,
	HighestScoreInfectedFirst,
	SwapNever,
	SwapAlways,
	HighestScoreSurvivorFirstButFin,
};

#if SCORE_DEBUG
bool swapTeamsOverride;
#endif

public void OnPluginStart()
{
	LoadTranslations("common.phrases");

	#if SCORE_DEBUG
	RegConsoleCmd("sm_setscore", Command_SetCampaignScores, "sm_setscore <team> <0|1>");
	RegConsoleCmd("sm_getscore", Command_GetTeamScore, "sm_getscore <team> <0|1>");
	RegConsoleCmd("sm_clearscore", Command_ClearTeamScores);
	RegConsoleCmd("sm_placement", Command_PrintPlacement);
	RegConsoleCmd("sm_changeteam", Command_ChangeTeam);
	RegAdminCmd("sm_swapnext", Command_SwapNext, ADMFLAG_BAN, "sm_swapnext - swap the players between both teams");
	RegAdminCmd("sm_changemap", Command_ChangeMap, ADMFLAG_CHANGEMAP, "sm_changemap <mapname> - change the current l4d map to mapname");
	RegAdminCmd("sm_setnextmap", Command_NextMap, ADMFLAG_CHANGEMAP, "sm_nextmap [mapname] - gets/sets the next map in the mission");
	#endif

	/*
	* Commands
	*/
	RegServerCmd("changelevel", Command_Changelevel);
	RegConsoleCmd("sm_printscores", Command_PrintScores, "sm_printscores");
	RegConsoleCmd("sm_scores", Command_Scores, "sm_scores - bring up a list of round scores");

	RegAdminCmd("sm_swap", Command_Swap, ADMFLAG_BAN, "sm_swap <player1> [player2] ... [playerN] - swap all listed players to opposite teams");
	RegAdminCmd("sm_swapto", Command_SwapTo, ADMFLAG_BAN, "sm_swapto <player1> [player2] ... [playerN] <teamnum> - swap all listed players to <teamnum> (1,2, or 3)");
	RegAdminCmd("sm_swapteams", Command_SwapTeams, ADMFLAG_BAN, "sm_swapteams2 - swap the players between both teams");

	RegAdminCmd("sm_antirage", Command_AntiRage, ADMFLAG_BAN, "sm_antirage - swap teams and scores");
	RegAdminCmd("sm_scrambleteams", Command_ScrambleTeams, ADMFLAG_BAN, "sm_scrambleteams - swap the players randomly between both teams");
	RegAdminCmd("sm_lockteams", Command_LockTeams, ADMFLAG_BAN, "sm_lockteams - keep players in their assigned teams");
	RegConsoleCmd("sm_votescramble", Request_ScrambleTeams, "Allows Clients to call Scramble votes");

	RegAdminCmd("sm_resetscores", Command_ResetScores, ADMFLAG_BAN, "sm_resetscores - reset the currently tracked map scores");

	RegAdminCmd("sm_swapmenu", Command_SwapMenu, ADMFLAG_BAN, "sm_swapmenu - bring up a swap players menu");

	/*
	* Cvars
	*/
	CreateConVar("l4d2_team_manager_ver", SCORE_VERSION, "Version of the score/team manager plugin.", 0|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvarTeamSwapping = CreateConVar("l4d2_team_order", "0", "0 - default L4D2 behaviour; 1 - winning team goes infected first; 2 - teams never get swapped; 3 - ABAB teamswap every map; 4 - on finale winning team goes infected first", 0|FCVAR_NOTIFY);
	cvarVoteScrambling = CreateConVar("l4d2_votescramble_allowed", "1", " Is Player Vote Scrambling admitted ", 0|FCVAR_NOTIFY);
	cvarFullResetOnEmpty = CreateConVar("l4d2_full_reset_on_empty", "0", " does the server load a new map when empty, fully resetting itself ", 0|FCVAR_NOTIFY);
	cvarGameModeActive = CreateConVar("l4d2_scores_gamemodesactive", "versus,teamversus,mutation12", " Set the game modes for which the plugin should be activated (same usage as sv_gametypes, i.e. add all game modes where you want it active separated by comma) ");
	cvarGameMode = FindConVar("mp_gamemode");

	/*
	* ADT Handles
	*/
	teamPlacementTrie = CreateTrie();
	if(teamPlacementTrie == null)
	{
		LogError("Could not create the team placement trie! FATAL ERROR");
	}

	mapScores = CreateArray(2);
	if(mapScores == null)
	{
		LogError("Could not create the map scores array! FATAL ERROR");
	}

	/*
	* Events
	*/

	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_team", Event_PlayerTeam);

	DebugPrintToAll("Map counter = %d", mapCounter);

	//fix missing survivors
	HookEvent("player_first_spawn", Event_PlayerFirstSpawn, EventHookMode_PostNoCopy);
	SurvivorLimit = FindConVar("survivor_limit");

	//fix no OnClearCampaignScores on Vote Changes
	RegConsoleCmd("callvote", Callvote_Handler);
	HookEvent("vote_passed", EventVoteEndSuccess);
	HookEvent("vote_failed", EventVoteEndFail);
}

public void OnPluginEnd()
{
	delete teamPlacementTrie;
	delete mapScores;
}

static bool RoundEndDone;

Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	RoundEndDone = false;

	/* sometimes round_start is invoked before OnMapStart */
	if(BeforeMapStart)
	{
		GetRoundCounter(false, true); //increment false, reset true
	}

	int roundCounter;
	//dont increment the round if round was restarted
	if(roundRestarting)
	{
		roundRestarting = false;
		roundCounter = GetRoundCounter();
	}
	else
	{
		roundCounter = GetRoundCounter(true); //increment
	}

	DebugPrintToAll("Round %d started, round scores: A: %d, B: %d", roundCounter, L4D_GetTeamScore(SCORE_TEAM_A, false), L4D_GetTeamScore(SCORE_TEAM_B, false));
    return Plugin_Continue;
}

Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	CheckZeroIngameBug();

	if(RoundEndDone)
	{
		RoundEndDone = false;
		DebugPrintToAll("Double Round End prevented");
		return Plugin_Continue;
	}

	RoundEndDone = true;

	char gamemode[64]; char gamemodeactive[64];
	cvarGameMode.GetString(gamemode, sizeof(gamemode));

	if (StrContains(gamemode, "scavenge") != -1)
	{
		DebugPrintToAll("Scavenge Round End, nothing to do here.");
		return Plugin_Continue;
	}

	if (StrEqual(gamemode, "coop"))
	{
		DebugPrintToAll("Coop Round End, nothing to do here.");
		return Plugin_Continue;
	}

	if (StrEqual(gamemode, "survival") && GetTeamHumanCount(3) > 0)
	{
		PrintToChatAll("[SM] Modded Survival Round End detected. Teamswap in 10 seconds.");
		CreateTimer(10.0, SurvivalTeamSwap, 0);
		return Plugin_Continue;
	}

	cvarGameModeActive.GetString(gamemodeactive, sizeof(gamemodeactive));
	if (StrContains(gamemodeactive, gamemode) == -1)
	{
		DebugPrintToAll("Gamemode %s round_end - gamemode not among active gamemodes - aborting", gamemode);
		return Plugin_Continue;
	}

	int roundCounter = GetRoundCounter();
	if(roundCounter > 2)
		return Plugin_Continue; // saw round 3 a few times in my logs, and crashes along with it.

	DebugPrintToAll("Round %d end, round scores: A: %d, B: %d", roundCounter, L4D_GetTeamScore(SCORE_TEAM_A, false), L4D_GetTeamScore(SCORE_TEAM_B, false));

	if(roundRestarting)
		return Plugin_Continue;

	//figure out what to put the next map teams with
	//before all the clients are actually disconnected

	if(!IsFirstRound())
	{
		#if SCORE_DEBUG
		if(!swapTeamsOverride && !SCORE_TEAM_PLACEMENT_OVERRIDE)
		#endif

		DebugPrintToAll("Next map Team Placement will be calculated now, Teamswaptype = %i", cvarTeamSwapping.IntValue);
		CalculateNextMapTeamPlacement();

		#if SCORE_DEBUG
		else DebugPrintToAll("Skipping next map team placement, as its overridden");
		#endif
	}
    return Plugin_Continue;
}

void CheckZeroIngameBug()
{
	for (int i=1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
			return;
	}

	OnNewMission();
	GetRoundCounter(false, true); //increment false, reset true
	DebugPrintToAll("Zero-Ingame Bug round end detected, resetting Plugin");
}

Action SurvivalTeamSwap(Handle timer)
{
	ClearTeamPlacement();

	PrintToChatAll("[SM] Survivor and Infected teams have been swapped.");
	for(int i = 1; i < L4D_MAXCLIENTS_PLUS1; i++)
	{
		if(IsClientInGameHuman(i) && GetClientTeam(i) != L4D_TEAM_SPECTATE)
		{
			teamPlacementArray[i] = GetOppositeClientTeam(i);
		}
	}

	TryTeamPlacementDelayed();
    return Plugin_Stop;
}

Action Command_LockTeams(int client, int args)
{
	char gamemode[64];
	cvarGameMode.GetString(gamemode, sizeof(gamemode));

	if (StrEqual(gamemode, "versus", false))
	{
		cvarGameMode.SetString("teamversus");
		PrintToChatAll("[SM] Teams are locked now, you may not change them on your own.");
	}
	else if (StrEqual(gamemode, "teamversus", false))
	{
		cvarGameMode.SetString("versus");
		PrintToChatAll("[SM] Teams are unlocked now, you may change them on your own.");
	}
	else if (StrEqual(gamemode, "scavenge", false))
	{
		cvarGameMode.SetString("teamscavenge");
		PrintToChatAll("[SM] Teams are locked now, you may not change them on your own.");
	}
	else if (StrEqual(gamemode, "teamscavenge", false))
	{
		cvarGameMode.SetString("scavenge");
		PrintToChatAll("[SM] Teams are unlocked now, you may change them on your own.");
	}

	return Plugin_Handled;
}

Action Command_ResetScores(int client, int args)
{
	ResetRoundScores();
	PrintToChatAll("[SM] The Round scores have been reset.");
	return Plugin_Handled;
}

Action Command_SwapTeams(int client, int args)
{
	ClearTeamPlacement();

	PrintToChatAll("[SM] Survivor and Infected teams have been swapped.");

	for(int i = 1; i < L4D_MAXCLIENTS_PLUS1; i++)
	{
		if(IsClientInGameHuman(i) && GetClientTeam(i) != L4D_TEAM_SPECTATE)
		{
			teamPlacementArray[i] = GetOppositeClientTeam(i);
		}
	}

	TryTeamPlacementDelayed();

	return Plugin_Handled;
}

Action Command_AntiRage(int client, int args)
{
	ClearTeamPlacement();

	for(int i = 1; i < L4D_MAXCLIENTS_PLUS1; i++)
	{
		if(IsClientInGameHuman(i) && GetClientTeam(i) != L4D_TEAM_SPECTATE)
		{
			teamPlacementArray[i] = GetOppositeClientTeam(i);
		}
	}

	L4D2_SwapTeams();

	PrintToChatAll("[SM] Teams and Scores swapped. No post-Infected raging for YOU!!!!");

	TryTeamPlacementDelayed();

	return Plugin_Handled;
}

Action Command_Swap(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_swap <player1> [player2] ... [playerN] - swap all listed players to opposite teams");
		return Plugin_Handled;
	}

	char player[64];

	for(int i = 0; i < args; i++)
	{
		GetCmdArg(i+1, player, sizeof(player));
		int player_id = FindTarget(client, player, true /*nobots*/, false /*immunity*/);

		if(player_id == -1)
			continue;

		char authid[128], team;
		GetClientAuthId(player_id, AuthId_Steam2, authid, sizeof(authid));
		if(GetTrieValue(teamPlacementTrie, authid, team))
			RemoveFromTrie(teamPlacementTrie, authid);

		team = GetOppositeClientTeam(player_id);
		teamPlacementArray[player_id] = team;
		PrintToChatAll("[SM] %N has been swapped to the %s team.", player_id, L4D_TEAM_NAME(team));
	}

	TryTeamPlacement();

	return Plugin_Handled;
}

Action Command_SwapTo(int client, int args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_swapto <player1> [player2] ... [playerN] <teamnum> - swap all listed players to team <teamnum> (1,2,or 3)");
		return Plugin_Handled;
	}

	char teamStr[64];
	GetCmdArg(args, teamStr, sizeof(teamStr));
	int team = StringToInt(teamStr);

    if (team < 0 || team > 3)
    {
        ReplyToCommand(client, "[SM] Invalid team %s specified, needs to be 1, 2, or 3", teamStr);
        return Plugin_Handled;
    }

	char player[64];

	for(int i = 0; i < args - 1; i++)
	{
		GetCmdArg(i+1, player, sizeof(player));
		int player_id = FindTarget(client, player, true /*nobots*/, false /*immunity*/);

		if(player_id == -1)
			continue;

		char authid[128];
		GetClientAuthId(player_id, AuthId_Steam2, authid, sizeof(authid));
		if(GetTrieValue(teamPlacementTrie, authid, team))
			RemoveFromTrie(teamPlacementTrie, authid);

		team = StringToInt(teamStr);
		teamPlacementArray[player_id] = team;
		PrintToChatAll("[SM] %N has been swapped to the %s team.", player_id, L4D_TEAM_NAME(team));
	}

	TryTeamPlacement();

	return Plugin_Handled;
}

#if SCORE_DEBUG
Action Command_NextMap(int client, int args)
{
	if(args == 0)
	{
		ReplyToCommand(client, "[SM] The next map in the mission is %s", nextMap);
		return Plugin_Handled;
	}

	char arg1[128];
	GetCmdArg(1, arg1, 128);

	if(IsMapValid(arg1))
	{
		strcopy(nextMap, sizeof(nextMap), arg1);
		ReplyToCommand(client, "[SM] Set next map to %s", arg1);
	}
	else
	{
		ReplyToCommand(client, "[SM] %s is not a valid map", arg1);
	}

	return Plugin_Handled;
}
#endif

/*
* This is called when a new "mission" has started
* (by us)
*/
void OnNewMission()
{
	DebugPrintToAll("New mission detected.");
	ResetCampaignScores();
	ClearTeamPlacement();
	pendingNewMission = false;
}

public Action L4D_OnSetCampaignScores(int &scoreA, int &scoreB)
{
	DebugPrintToAll("FORWARD: OnSetCampaignScores(%d,%d)", scoreA, scoreB);

	LastKnownScoreTeamA = scoreA;
	LastKnownScoreTeamB = scoreB;

	if (!scoreA && !scoreB && BeforeMapStart)
		OnNewMission();

	return Plugin_Continue;
}

public Action L4D_OnClearTeamScores(bool newCampaign)
{
	//check if we are on the first map of the campaign
	if(IsFirstMap())
	{
		newCampaign = true;
	}
	else
	{
		newCampaign = false;
	}

	/*
	* this function OnClearTeamScores gets called twice at the beginning of each map
	* skip it the second time
	*/
	if(clearedScores)
	{
		clearedScores = false;
	}
	else
	{
		clearedScores = true;

		DebugPrintToAll("FORWARD: OnClearTeamScores(%b)", newCampaign);

		if (newCampaign) OnNewMission();

		ResetRoundScores();
	}

	return Plugin_Continue;
}

public void OnReadyRoundRestarted()
{
	DebugPrintToAll("FORWARD: OnReadyRoundRestarted triggered");
	roundRestarting = true;
}

public void OnMapStart()
{
	DebugPrintToAll("ON MAP START FUNCTION");
	BeforeMapStart = false;

	if(!roundCounterReset)
		GetRoundCounter(false, true); //increment false, reset true

	#if SCORE_DEBUG
	swapTeamsOverride = false;
	#endif

	char mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));

	//if we are skipping the level
	//do not skip it if we already ended up on it
	if(skippingLevel && !StrEqual(mapname, nextMap, false))
	{
		//we should be skipping to this map lets get to it
		CreateTimer(SCORE_DELAY_SWITCH_MAP, Timer_SwitchToNextMap, _);

		return;
	}

	if(pendingNewMission)
	{
		OnNewMission();
		mapCounter = 0;
	}
	else
	{
		mapCounter++;
		DebugPrintToAll("Map counter now = %d", mapCounter);
	}

	skippingLevel = false;
	nextMap[0] = 0;

	ResetRoundScores();
}

Action Timer_SwitchToNextMap(Handle timer)
{
	ServerCommand("changelevel %s", nextMap);
    return Plugin_Stop;
}

public void OnMapEnd()
{
	roundCounterReset = false;
	BeforeMapStart = true;

	if(skippingLevel)
	{
		skippingLevel = false;
		return;
	}

	/* leaving a map early before its completed/started */
	if(IsFirstRound())
	{
		mapCounter--;
		return;
	}

	/* leaving a map right after the scores were reset */
	if(mapCounter == 1
	&& roundScores[SCORE_TEAM_A] == -1 && roundScores[SCORE_TEAM_B] == -1)
	{
		return;
	}
	DebugPrintToAll("Map counter now = %d", mapCounter);

	/*
	* Update the map scores
	*/
	int scores[2];
	scores[0] = roundScores[SCORE_TEAM_A];
	scores[1] = roundScores[SCORE_TEAM_B];
	PushArrayArray(mapScores, scores);

	/*
	* Is the game about to automatically swap teams on us?
	*/
	bool pendingSwapScores = false;
	if (LastKnownScoreTeamA > LastKnownScoreTeamB)
	{
		pendingSwapScores = true;
	}

	if (pendingSwapScores)
	{
		DebugPrintToAll("pendingSwapScores = true detected, L4D2 will swap teams and scores next map");
	}
	else
	{
		DebugPrintToAll("pendingSwapScores = false detected, L4D2 will keep teams and scores next map");
	}

	/*
	* Try to figure out if we should swap scores
	* at the beginning of the next map
	*/
	TeamSwappingType swapKind = view_as<TeamSwappingType>(cvarTeamSwapping.IntValue);
	bool performSwapNextLevel;

	if (swapKind == HighestScoreSurvivorFirstButFin && IsFinaleMapNextUp())
		{
			swapKind = HighestScoreInfectedFirst;
		}

	switch(swapKind)
	{
		case HighestScoreInfectedFirst: //if Infected are to begin always, we must check current teamflip status and pending score swap
		{
			performSwapNextLevel = GameRules_GetProp("m_bAreTeamsFlipped") ? !pendingSwapScores : pendingSwapScores;
		}
		case SwapAlways:
		{
			performSwapNextLevel = true;
		}
		case SwapNever: //if teams are to remain the same, we must swap everytime L4D2 wants to swap internally
		{
			performSwapNextLevel = pendingSwapScores;
		}
		default:
		{
			performSwapNextLevel = false;
		}
	}

	//schedule a pending skip level to the next map
	if(strlen(nextMap) > 0 && IsMapValid(nextMap))
	{
		skippingLevel = true;
	}

	// Destroy timer if necessary.
	if (SpawnTimer != null)
	{
		KillTimer(SpawnTimer);
		SpawnTimer = null;
	}

	if(performSwapNextLevel)
	{
		L4D2_SwapTeams();
	}
}

void CalculateNextMapTeamPlacement()
{
	/*
	* Is the game about to automatically swap teams on us?
	*/
	bool pendingSwapScores = false;
	if (LastKnownScoreTeamA > LastKnownScoreTeamB)
	{
		pendingSwapScores = true;
	}

	bool bAreTeamsFlipped = view_as<bool>(GameRules_GetProp("m_bAreTeamsFlipped"));
	if (bAreTeamsFlipped)
		DebugPrintToAll("Current Map End AreTeamsFlipped = true detected, aka default Order");
	else
		DebugPrintToAll("Current Map End AreTeamsFlipped = false detected, aka swapped Order");

	/*
	* We place everyone on whatever team they should be on
	* according to the set swapping type
	*/
	ClearTeamPlacement();

	char authid[128], team;

	for(int i = 1; i < L4D_MAXCLIENTS_PLUS1; i++)
	{
		if(IsClientInGameHuman(i))
		{
			GetClientAuthId(i, AuthId_Steam2, authid, sizeof(authid));
			team = GetClientTeamForNextMap(i, pendingSwapScores, bAreTeamsFlipped);

			DebugPrintToAll("Next map will place %N, now %d, to %d", i, GetClientTeam(i), team);
			SetTrieValue(teamPlacementTrie, authid, team);
		}
	}
}

/*
* **************
* TEAM PLACEMENT (beginning of map)
* **************
*/

Action Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	if (GetRoundCounter() != 1) return Plugin_Continue; // to avoid phantom swapping prior to mapchange on round 2

	if (BeforeMapStart) return Plugin_Continue;

	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(!IsClientInGameHuman(client)) return Plugin_Continue;

	int team; char authid[256];
	GetClientAuthId(client, AuthId_Steam2, authid, sizeof(authid));

	if(GetTrieValue(teamPlacementTrie, authid, team))
	{
		teamPlacementArray[client] = team;
		RemoveFromTrie(teamPlacementTrie, authid);
		DebugPrintToAll("Team Event: Put %N to team %d as Trie commands", client, team);
	}

	TryTeamPlacementDelayed();
    return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	//DebugPrintToAll("Client %d disconnected", client);

	if (IsClientInGame(client) && IsFakeClient(client)) return;
	//to reduce testing spam solely.

	if(skippingLevel) return;

	TryTeamPlacementDelayed();

	/*
	* See if the server is now empty?
	*/

	float currenttime = GetGameTime();

	if (lastDisconnectTime == currenttime) return;

	CreateTimer(SCORE_DELAY_EMPTY_SERVER, IsNobodyConnected, currenttime);
	lastDisconnectTime = currenttime;
}

Action IsNobodyConnected(Handle timer, any timerDisconnectTime)
{
	if (timerDisconnectTime != lastDisconnectTime) return Plugin_Stop;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i))
			return  Plugin_Stop;
	}

	OnNewMission();
	DebugPrintToAll("Server detected as empty, resetting Plugin");

	FindConVar("sb_all_bot_game").SetInt(0);
	FindConVar("allow_all_bot_survivor_team").SetInt(0);

	if (cvarFullResetOnEmpty.BoolValue)
	{
		DebugPrintToAll("Also doing a full reset by mapchange");
		ServerCommand("map c1m1_hotel");
	}

	return  Plugin_Stop;
}


/*
* Do a delayed "team placement"
*
* This way all the pending team changes will go through instantly
* and we don't end up in TryTeamPlacement again before then
*/
bool pendingTryTeamPlacement;

void TryTeamPlacementDelayed()
{
	if(!pendingTryTeamPlacement)
	{
		CreateTimer(SCORE_DELAY_PLACEMENT, Timer_TryTeamPlacement);
		pendingTryTeamPlacement = true;
	}
}

Action Timer_TryTeamPlacement(Handle timer)
{
	TryTeamPlacement();
	pendingTryTeamPlacement = false;
    return Plugin_Stop;
}

/*
* Try to place people on the right teams
* after some kind of event happens that allows someone to be moved.
*
* Should only be called indirectly by TryTeamPlacementDelayed()
*/
void TryTeamPlacement()
{
	SetConVarInt(FindConVar("sb_all_bot_game"), 1); // necessary to avoid 0 human Survivor server bugs
	SetConVarInt(FindConVar("allow_all_bot_survivor_team"), 1);

	/*
	* Calculate how many free slots a team has
	*/
	int free_slots[4];

	free_slots[L4D_TEAM_SPECTATE] = GetTeamMaxHumans(L4D_TEAM_SPECTATE);
	free_slots[L4D_TEAM_SURVIVORS] = GetTeamMaxHumans(L4D_TEAM_SURVIVORS);
	free_slots[L4D_TEAM_INFECTED] = GetTeamMaxHumans(L4D_TEAM_INFECTED);

	free_slots[L4D_TEAM_SURVIVORS] -= GetTeamHumanCount(L4D_TEAM_SURVIVORS);
	free_slots[L4D_TEAM_INFECTED] -= GetTeamHumanCount(L4D_TEAM_INFECTED);

	DebugPrintToAll("TP: Trying to do team placement (free slots %d/%d)...", free_slots[L4D_TEAM_SURVIVORS], free_slots[L4D_TEAM_INFECTED]);

	/*
	* Try to place people on the teams they should be on.
	*/

	for(int i = 1; i < L4D_MAXCLIENTS_PLUS1; i++)
	{
		if(IsClientInGameHuman(i))
		{
			int team = teamPlacementArray[i];

			//client does not need to be placed? then skip
			if(!team)
			{
				DebugPrintToAll("TP: %N client on team (%d) skipped", i, team);
				continue;
			}

			int old_team = GetClientTeam(i);

			//client is already on the right team
			if(team == old_team)
			{
				teamPlacementArray[i] = 0;
				teamPlacementAttempts[i] = 0;

				DebugPrintToAll("TP: %N is already on correct team (%d)", i, team);
			}
			//there's still room to place him on the right team
			else if (free_slots[team] > 0)
			{
				ChangePlayerTeamDelayed(i, team);
				DebugPrintToAll("TP: Moving %N to %d soon", i, team);

				free_slots[team]--;
				free_slots[old_team]++;
			}
			/*
			* no room to place him on the right team,
			* so lets just move this person to spectate
			* in anticipation of being to move him later
			*/
			else
			{
				DebugPrintToAll("TP: %d attempts to move %N to team %d", teamPlacementAttempts[i], i, team);

				/*
				* don't keep playing in an infinite join spectator loop,
				* let him join another team if moving him fails
				*/
				if(teamPlacementAttempts[i] > 0)
				{
					DebugPrintToAll("TP: Cannot move %N onto %d, team full", i, team);

					//client joined a team after he was moved to spec temporarily
					if(GetClientTeam(i) != L4D_TEAM_SPECTATE)
					{
						DebugPrintToAll("TP: %N has willfully moved onto %d, cancelling placement", i, GetClientTeam(i));
						teamPlacementArray[i] = 0;
						teamPlacementAttempts[i] = 0;
					}
				}
				/*
				* place him to spectator so room on the previous team is available
				*/
				else
				{
					free_slots[L4D_TEAM_SPECTATE]--;
					free_slots[old_team]++;

					DebugPrintToAll("TP: Moved %N to spectator, as %d has no room", i, team);

					ChangePlayerTeamDelayed(i, L4D_TEAM_SPECTATE);

					teamPlacementAttempts[i]++;
				}
			}
		}
		//the player is a bot, or disconnected, etc.
		else
		{
			if(!IsClientConnected(i) || IsFakeClient(i))
			{
				if(teamPlacementArray[i])
					DebugPrintToAll("TP: Defaultly removing %d from placement consideration", i);

				teamPlacementArray[i] = 0;
				teamPlacementAttempts[i] = 0;
			}
		}
	}

	/* If somehow all 8 players are connected and on opposite teams
	*  then unfortunately this function will not work.
	*  but of course this should not be called in that case,
	*  instead swapteams can be used
	*/
}

void ClearTeamPlacement()
{
	for(int i = 1; i < L4D_MAXCLIENTS_PLUS1; i++)
	{
		teamPlacementArray[i] = 0;
		teamPlacementAttempts[i] = 0;
	}

	ClearTrie(teamPlacementTrie);
}


/*
* When we are at the end of a map,
* we will need to swap clients around based on the swapping type
*
* Figure out which team the client will go on next map.
*/
int GetClientTeamForNextMap(int client, bool pendingSwapScores = false, bool AreTeamsFlipped)
{
	TeamSwappingType swapKind = view_as<TeamSwappingType>(cvarTeamSwapping.IntValue);
	int team;

	//same type of logic except on the finale, in which we flip it
	if(swapKind == HighestScoreSurvivorFirstButFin)
	{
		if (!IsFinaleMapNextUp())
			swapKind = DefaultL4D2;
		else swapKind = HighestScoreInfectedFirst;
	}

	switch(GetClientTeam(client))
	{
		case L4D_TEAM_INFECTED:
		{
			//default, dont swap teams
			team = L4D_TEAM_SURVIVORS;

			switch(swapKind)
			{
				case HighestScoreInfectedFirst:
				{
					if (AreTeamsFlipped)
						team = !pendingSwapScores ? L4D_TEAM_SURVIVORS : L4D_TEAM_INFECTED;
					else
						team = pendingSwapScores ? L4D_TEAM_SURVIVORS : L4D_TEAM_INFECTED;
				}
				case SwapAlways:
				{
					team = L4D_TEAM_INFECTED;
				}
				case SwapNever:
				{
					team = L4D_TEAM_SURVIVORS;
				}
				case DefaultL4D2:
				{
					if (AreTeamsFlipped)
						team = pendingSwapScores ? L4D_TEAM_SURVIVORS : L4D_TEAM_INFECTED;
					else
						team = !pendingSwapScores ? L4D_TEAM_SURVIVORS : L4D_TEAM_INFECTED;
				}
			}
		}

		case L4D_TEAM_SURVIVORS:
		{
			//default, dont swap teams
			team = L4D_TEAM_INFECTED;

			switch(swapKind)
			{
				case HighestScoreInfectedFirst:
				{
					if (AreTeamsFlipped)
						team = pendingSwapScores ? L4D_TEAM_SURVIVORS : L4D_TEAM_INFECTED;
					else
						team = !pendingSwapScores ? L4D_TEAM_SURVIVORS : L4D_TEAM_INFECTED;
				}
				case SwapAlways:
				{
					team = L4D_TEAM_SURVIVORS;
				}
				case SwapNever:
				{
					team = L4D_TEAM_INFECTED;
				}
				case DefaultL4D2:
				{
					if (AreTeamsFlipped)
						team = !pendingSwapScores ? L4D_TEAM_SURVIVORS : L4D_TEAM_INFECTED;
					else
						team = pendingSwapScores ? L4D_TEAM_SURVIVORS : L4D_TEAM_INFECTED;
				}
			}
		}

		default:
		{
			team = L4D_TEAM_SPECTATE;
		}
	}

	DebugPrintToAll("Applying final teamswap %d to %N, new team = %i", swapKind, client, team);
	return team;
}

void ResetCampaignScores()
{
	mapCounter = 1;
	ClearArray(mapScores);
	DebugPrintToAll("Round/Map scores have been reset.");
}

void ResetRoundScores()
{
	roundScores[SCORE_TEAM_A] = -1;
	roundScores[SCORE_TEAM_B] = -1;
}

/*
* ****************
* STOCK FUNCTIONS
* ****************
*/

stock bool IsFirstRound()
{
	return GetRoundCounter() == 1;
}

stock int OppositeLogicalTeam(int logical_team)
{
	if(logical_team == SCORE_TEAM_A)
		return SCORE_TEAM_B;

	else if(logical_team == SCORE_TEAM_B)
		return SCORE_TEAM_A;

	else
	return -1;
}

/*
* Return the opposite team of that the client is on
*/
stock int GetOppositeClientTeam(int client)
{
	return OppositeCurrentTeam(GetClientTeam(client));
}

stock int OppositeCurrentTeam(int team)
{
	if(team == L4D_TEAM_INFECTED)
		return L4D_TEAM_SURVIVORS;
	else if(team == L4D_TEAM_SURVIVORS)
		return L4D_TEAM_INFECTED;
	else if(team == L4D_TEAM_SPECTATE)
		return L4D_TEAM_SPECTATE;

	else
	return -1;
}

stock void ChangePlayerTeamDelayed(int client, int team)
{
	Handle pack;

	CreateDataTimer(SCORE_DELAY_TEAM_SWITCH, Timer_ChangePlayerTeam, pack);

	WritePackCell(pack, client);
	WritePackCell(pack, team);
}

Action Timer_ChangePlayerTeam(Handle timer, Handle pack)
{
	ResetPack(pack);

	int client = ReadPackCell(pack);
	int team = ReadPackCell(pack);

	ChangePlayerTeam(client, team);
    return Plugin_Stop;
}

stock bool ChangePlayerTeam(int client, int team)
{
	if(GetClientTeam(client) == team) return true;

	if(team != L4D_TEAM_SURVIVORS)
	{
		//we can always swap to infected or spectator, it has no actual limit
		ChangeClientTeam(client, team);
		return true;
	}

	if(GetTeamHumanCount(team) == GetTeamMaxHumans(team))
	{
		DebugPrintToAll("ChangePlayerTeam() : Cannot switch %N to team %d, as team is full", client, team);
		return false;
	}

	int bot;
	//for survivors its more tricky
	for(bot = 1;
	bot < L4D_MAXCLIENTS_PLUS1 && (!IsClientConnected(bot) || !IsFakeClient(bot) || (GetClientTeam(bot) != L4D_TEAM_SURVIVORS));
	bot++) {}

	if(bot == L4D_MAXCLIENTS_PLUS1)
	{
		DebugPrintToAll("Could not find a survivor bot, adding a bot ourselves");

		char command[] = "sb_add";
		int flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);

		ServerCommand("sb_add");

		SetCommandFlags(command, flags);

		DebugPrintToAll("Added a survivor bot, trying again...");
		return false;
	}

	//have to do this to give control of a survivor bot
	L4D_SetHumanSpec(bot, client);
	L4D_TakeOverBot(client);

	return true;
}

//client is in-game and not a bot
stock bool IsClientInGameHuman(int client)
{
	if (client > 0) return IsClientInGame(client) && !IsFakeClient(client);
	else return false;
}

stock int GetTeamHumanCount(int team)
{
	int humans = 0;

	for(int i = 1; i < L4D_MAXCLIENTS_PLUS1; i++)
	{
		if(IsClientInGameHuman(i) && GetClientTeam(i) == team)
		{
			humans++;
		}
	}

	return humans;
}

stock int GetTeamMaxHumans(int team)
{
	if(team == L4D_TEAM_SURVIVORS)
	{
		return FindConVar("survivor_limit").IntValue;
	}
	else if(team == L4D_TEAM_INFECTED)
	{
		return FindConVar("z_max_player_zombies").IntValue;
	}
	else if(team == L4D_TEAM_SPECTATE)
	{
		return L4D_MAXCLIENTS;
	}

	return -1;
}

#if SCORE_DEBUG
Action Command_ChangeMap(int client, int args)
{
	if(args == 0)
	{
		ReplyToCommand(client, "[SM] Usage: sm_changemap <mapname>");
	}
	if(args > 0)
	{
		char map[128];
		GetCmdArg(1, map, 128);

		if(IsMapValid(map))
		{
			ReplyToCommand(client, "[SM] The map is now changing to %s", map);
			ServerCommand("changelevel %s", map);

			pendingNewMission = true;
		}
		else
		{
			ReplyToCommand(client, "[SM] The map specified is invalid");
		}
	}
	return Plugin_Handled;
}
#endif

//***********************************************************************************************

Action Command_ScrambleTeams(int client, int args)
{
	PrintToChatAll("[SM] Teams are being scrambled now.");
	ScrambleTeams();
	return Plugin_Handled;
}

bool VoteWasDone;

Action Request_ScrambleTeams(int client, int args)
{
	if (!cvarVoteScrambling.BoolValue)
	{
		ReplyToCommand(client, "The server currently does not allow vote scrambling.");
		return Plugin_Handled;
	}

	if (!VoteWasDone)
	{
		DisplayScrambleVote();
		VoteWasDone = true;
		CreateTimer(60.0, ResetVoteDelay, 0);
	}
	else ReplyToCommand(client, "Vote was called already.");

	return Plugin_Handled;
}

Action ResetVoteDelay(Handle timer)
{
	VoteWasDone = false;
    return Plugin_Stop;
}

stock void ScrambleTeams()
{
	int humanspots = GetTeamMaxHumans(L4D_TEAM_SURVIVORS);
	int infspots = GetTeamMaxHumans(L4D_TEAM_INFECTED);
	int humanplayers, infplayers, players;

	// get ingame player count
	for(int i = 1; i < L4D_MAXCLIENTS_PLUS1; i++)
	{
		if(IsClientInGameHuman(i) && GetClientTeam(i) != L4D_TEAM_SPECTATE)
			players++;
	}
	// half of that
	players = players/2;

	for(int i = 1; i < L4D_MAXCLIENTS_PLUS1; i++)
	{
		if(IsClientInGameHuman(i) && GetClientTeam(i) != L4D_TEAM_SPECTATE)
		{
			switch(GetRandomInt(2,3))
			{
				case 2:
				{
					if (humanspots < 1 || humanplayers >= players) // if theres no spots or half players are allocated already
					{
						teamPlacementArray[i] = 3;
					}
					else
					{
						teamPlacementArray[i] = 2;
						humanplayers++;
						humanspots--;
					}
				}
				case 3:
				{
					if (infspots < 1 || infplayers >= players) // if theres no spots or half players are allocated already
					{
						teamPlacementArray[i] = 2;
					}
					else
					{
						teamPlacementArray[i] = 3;
						infplayers++;
						infspots--;
					}
				}
			}
		}
	}

	TryTeamPlacementDelayed();
}

void DisplayScrambleVote()
{
	Menu ScrambleVoteMenu = new Menu(Handler_VoteCallback, view_as<MenuAction>(MENU_ACTIONS_ALL));
	ScrambleVoteMenu.SetTitle("Do you want teams scrambled?");

	ScrambleVoteMenu.AddItem("0", "No");
	ScrambleVoteMenu.AddItem("1", "Yes");

	ScrambleVoteMenu.ExitButton = false;

	VoteMenuToAll(ScrambleVoteMenu, 20);
}

float GetVotePercent(int votes, int totalVotes)
{
	return float(votes) / float(totalVotes);
}

int Handler_VoteCallback(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}

	else if (action == MenuAction_VoteCancel && param1 == VoteCancel_NoVotes)
	{
		PrintToChatAll("No votes detected on the scramble vote.");
	}

	else if (action == MenuAction_VoteEnd)
	{
		char item[256]; char display[256]; float percent;
		int votes;
		int	totalVotes;

		GetMenuVoteInfo(param2, votes, totalVotes);
		menu.GetItem(param1, item, sizeof(item), _, display, sizeof(display));

		percent = GetVotePercent(votes, totalVotes);

		PrintToChatAll("Scramble vote successful: %s (Received %i%% of %i votes)", display, RoundToNearest(100.0*percent), totalVotes);

		int winner = StringToInt(item);
		if (winner) ScrambleTeams();
	}
	return 0;
}

/*
* Detect 'rcon changelevel' and print warning messages
*/
Action Command_Changelevel(int args)
{
	if(args > 0)
	{
		char map[128];
		GetCmdArg(1, map, 128);
		if(IsMapValid(map) && !skippingLevel)
		{
			DebugPrintToAll("Changelevel execute detected");
		}
	}
	return Plugin_Continue;
}

Action Command_PrintScores(int client, int args)
{
	DebugPrintToAll("Command_PrintScores, mapCounter = %d", mapCounter);

	int i;
	int scores[2];
	int curscore;
	int scoresSize = GetArraySize(mapScores);
	PrintToChatAll("[SM] Printing map scores:");

	PrintToChatAll("Lobby Survivors: ");
	for(i = 0; i < scoresSize; i++)
	{
		GetArrayArray(mapScores, i, scores);
		curscore = scores[0];
		PrintToChatAll("%d. %d", i+1, curscore);
	}
	PrintToChatAll("- Campaign: %d", LastKnownScoreTeamA);

	PrintToChatAll("Lobby Infected: ");
	for(i = 0; i < scoresSize; i++)
	{
		GetArrayArray(mapScores, i, scores);
		curscore = scores[1];
		PrintToChatAll("%d. %d", i+1, curscore);
	}
	PrintToChatAll("- Campaign: %d", LastKnownScoreTeamB);

	return Plugin_Handled;
}

//show a menu of round and total scores
Action Command_Scores(int client, int args)
{
	DebugPrintToAll("Command_Scores, mapCounter = %d", mapCounter);

	Panel panel = new Panel();
	char panelLine[1024];

	int i;
	int scores[2];
	int curscore;
	int scoresSize = GetArraySize(mapScores);

	panel.DrawText("Team Scores");
	panel.DrawText(" ");

	Format(panelLine, sizeof(panelLine), "SURVIVORS (%d)", LastKnownScoreTeamA);
	panel.DrawText(panelLine);
	for(i = 0; i < scoresSize; i++)
	{
		GetArrayArray(mapScores, i, scores);
		curscore = scores[0];
		Format(panelLine, sizeof(panelLine), "->%d. %d", i+1, curscore);
		panel.DrawText(panelLine);
	}

	panel.DrawText(" ");
	Format(panelLine, sizeof(panelLine), "INFECTED (%d)", LastKnownScoreTeamB);
	panel.DrawText(panelLine);
	for(i = 0; i < scoresSize; i++)
	{
		GetArrayArray(mapScores, i, scores);
		curscore = scores[1];
		Format(panelLine, sizeof(panelLine), "->%d. %d", i+1, curscore);
		panel.DrawText(panelLine);
	}

	panel.Send(client, Menu_ScorePanel, SCORE_LIST_PANEL_LIFETIME);

	delete panel;

	return Plugin_Handled;
}

int Menu_ScorePanel(Menu menu, MenuAction action, int param1, int param2)
{
    return 0;
}

/*
* SWAP MENU FUNCTIONALITY
*/

int swapClients[256];
Action Command_SwapMenu(int client, int args)
{
	DebugPrintToAll("Command_Scores, mapCounter = %d", mapCounter);

	//Handle panel = CreatePanel();
	char panelLine[1024];
	char itemValue[32];

	//int i, numPlayers = 0;
	//->%d. %s makes the text yellow
	// otherwise the text is white

	#if SCORE_DEBUG
	int teamIdx[] = {2, 3, 1, 3};
	char teamNames[][] = {"SURVIVORS","INFECTED","SPECTATORS","INFECTED"};
	#else
	int teamIdx[] = {2, 3, 1};
	char teamNames[][] = {"SURVIVORS","INFECTED","SPECTATORS"};
	#endif

	Menu menu = new Menu(Menu_SwapPanel);
	SetMenuPagination(menu, MENU_NO_PAGINATION);

	int i = Helper_GetNonEmptyTeam(teamIdx, sizeof(teamIdx), 0);
	int itemIdx = 0;

	if (i != -1)
	{
		menu.SetTitle(teamNames[i]);
	}
	while(i != -1)
	{
		int idxNext = Helper_GetNonEmptyTeam(teamIdx, sizeof(teamIdx), i+1);

		int team = teamIdx[i];
		int teamCount = GetTeamHumanCount(team);

		int numPlayers = 0;
		for(int j = 1; j < L4D_MAXCLIENTS_PLUS1; j++)
		{
			if(IsClientInGameHuman(j) && GetClientTeam(j) == team)
			{
				numPlayers++;

				if(numPlayers != teamCount || idxNext == -1)
				{
					Format(panelLine, 1024, "%N", j);
				}
				else
				{
					Format(panelLine, 1024, "%N\n%s", j, teamNames[idxNext]);
				}
				Format(itemValue, sizeof(itemValue), "%d", j);
				DebugPrintToAll("Added item with value = %s", itemValue);

				menu.AddItem(itemValue, panelLine);

				swapClients[itemIdx] = j;
				itemIdx++;
			}
		}

		i = idxNext;
	}

	menu.Display(client, SCORE_SWAPMENU_PANEL_LIFETIME);

	return Plugin_Handled;
}

//iterate through all teamIdx and find first non-empty team, return that team idx
int Helper_GetNonEmptyTeam(const int[] teamIdx, int size, int startIdx)
{
	if(startIdx >= size || startIdx < 0)
	{
		return -1;
	}

	for(int i = startIdx; i < size; i++)
	{
		int team = teamIdx[i];

		int humans = GetTeamHumanCount(team);
		if(humans > 0)
		{
			return i;
		}
	}

	return -1;
}

int Menu_SwapPanel(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		int client = param1;
		int itemPosition = param2;

		DebugPrintToAll("MENUSWAP: Action %d You selected item: %d", action, param2);

		char infobuf[16];
		menu.GetItem(itemPosition, infobuf, sizeof(infobuf));

		DebugPrintToAll("MENUSWAP: Menu item was %s", infobuf);

		int player_id = swapClients[itemPosition];

		//swap and redraw menu
		int team = GetOppositeClientTeam(player_id);
		teamPlacementArray[player_id] = team;
		PrintToChatAll("[SM] %N has been swapped to the %s team.", player_id, L4D_TEAM_NAME(team));
		TryTeamPlacementDelayed();

		//redraw in like 0.5 seconds or so
		Delayed_DisplaySwapMenu(client);

	} else if (action == MenuAction_Cancel) {
		int reason = param2;
		int client = param1;

		DebugPrintToAll("MENUSWAP: Action %d Client %d's menu was cancelled.  Reason: %d", action, client, reason);

		//display swap menu till exit is pressed
		if(reason == MenuCancel_Timeout)
		{
			//Command_SwapMenu(client, 0);
		}
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		delete menu;
	}
    return 0;
}

void Delayed_DisplaySwapMenu(int client)
{
	CreateTimer(SCORE_SWAPMENU_PANEL_REFRESH, Timer_DisplaySwapMenu, client, _);
	DebugPrintToAll("Delayed display swap menu on %N", client);
}

Action Timer_DisplaySwapMenu(Handle timer, any client)
{
	Command_SwapMenu(client, 0);
    return Plugin_Stop;
}

/*
*
* DEBUG TESTING FUNCTIONS
*
*/


#if SCORE_DEBUG

public Action Command_PrintPlacement(client, args)
{
	for(int i = 1; i < L4D_MAXCLIENTS_PLUS1; i++)
	{
		if(teamPlacementArray[i])
		{
			DebugPrintToAll("Placement for %N to %d", i, teamPlacementArray[i]);
		}
	}

	return Plugin_Handled;
}

public Action Command_SwapNext(client, args)
{
	DebugPrintToAll("Will swap teams on map restart...");

	/*
	* We place everyone on whatever team they should be on
	* according to the set swapping type
	*/
	ClearTeamPlacement();

	if(args > 0)
	{
		DebugPrintToAll("Will simply override team swapping");
		swapTeamsOverride = true;
		return Plugin_Handled;
	}

	char authid[128];
	int i;

	int team;
	for(i = 1; i < L4D_MAXCLIENTS_PLUS1; i++)
	{
		if(IsClientInGameHuman(i))
		{
			GetClientAuthId(i, AuthId_Steam2, authid, sizeof(authid));
			team = GetOppositeClientTeam(i);

			DebugPrintToAll("Next map will place %N to %d", i, team);
			SetTrieValue(teamPlacementTrie, authid, team);
		}
	}

	swapTeamsOverride = true;

	DebugPrintToAll("Overriding built-in swap teams mechanism");

	return Plugin_Handled;
}

Action Command_ChangeTeam(int client, int args)
{
	char arg1[128];

	GetCmdArg(1, arg1, 128);

	int team = StringToInt(arg1);

	ChangePlayerTeamDelayed(client, team);

	return Plugin_Handled;
}

Action Command_GetTeamScore(int client, int args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_getscore <team> <0|1>");
		return Plugin_Handled;
	}

	if(fGetTeamScore == null)
	{
		DebugPrintToAll("Could not load GetTeamScore function");
		return Plugin_Handled;
	}

	char arg1[64], char arg2[64];
	GetCmdArg(1, arg1, 64);
	GetCmdArg(2, arg2, 64);

	int team = StringToInt(arg1);
	bool b1 = view_as<bool>(StringToInt(arg2));

	int score = L4D_GetTeamScore(team, b1);

	DebugPrintToAll("Team score is %d", score);

	return Plugin_Handled;
}

Action Command_SetCampaignScores(int client, int args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setscore <team> <0|1>");
		return Plugin_Handled;
	}

	char arg1[64], char arg2[64];
	GetCmdArg(1, arg1, 64);
	GetCmdArg(2, arg2, 64);

	int team = StringToInt(arg1);
	int score = StringToInt(arg2);

	int iLastScoreTeamA, iLastScoreTeamB;
	if(team == 2)
	{
		iLastScoreTeamB = L4D_GetTeamScore(3, true);
		L4D_SetCampaignScores(score, iLastScoreTeamB);
	}

	if(team == 3)
	{
		iLastScoreTeamA = L4D_GetTeamScore(2, true);
		L4D_SetCampaignScores(iLastScoreTeamA, score);
	}

	DebugPrintToAll("Set game campaign score for team %d to %d", team, score);

	return Plugin_Handled;
}

Action Command_ClearTeamScores(int client, int args)
{
	char arg1[64];
	GetCmdArg(1, arg1, 64);
	L4D_OnClearTeamScores(true);
	DebugPrintToAll("Team scores have been cleared");
	return Plugin_Handled;
}

#endif

void DebugPrintToAll(const char[] format, any ...)
{
	#if SCORE_DEBUG	|| SCORE_DEBUG_LOG
	char buffer[192];
	int i;

	VFormat(buffer, sizeof(buffer), format, 2);

	#if SCORE_DEBUG
	//PrintToChatAll("%s", buffer);
		for ( i = 1; i <= MaxClients; i++ ) {
				if ( IsClientInGameHuman( i ) )
				{
						PrintToConsole(i, "%s", buffer);
				}
		}
	//PrintToConsole(0, "%s", buffer);
	#endif

	LogMessage("[SCORE] %s", buffer);
	#else
	//suppress "format" never used warning
	if(format[0])
		return;
	else
	return;
	#endif
}

int GetRoundCounter(bool increment_counter = false, bool reset_counter = false)
{
	#define DEBUG_ROUND_COUNTER 0

	static int counter = 0;
	if(reset_counter)
	{
		roundCounterReset = true;
		counter = 0;
		#if DEBUG_ROUND_COUNTER
		DebugPrintToAll("RoundCounter -- reset to 0");
		#endif
	}
	else if(increment_counter)
	{
		counter++;
		#if DEBUG_ROUND_COUNTER
		DebugPrintToAll("RoundCounter -- incremented to %d", counter);
		#endif
	}
	else
	{
		#if DEBUG_ROUND_COUNTER
		DebugPrintToAll("RoundCounter -- returned %d", counter);
		#endif
	}

	return counter;
}

stock bool IsFinaleMapNextUp()
{
	char mapname[256];
	GetCurrentMap(mapname, sizeof(mapname));

	if (StrContains(mapname, "c1m3_mall", false) != -1
	|| StrContains(mapname, "c2m4_barns", false) != -1
	|| StrContains(mapname, "c3m3_shantytown", false) != -1
	|| StrContains(mapname, "c4m4_milltown_b", false) != -1
	|| StrContains(mapname, "c5m4_quarter", false) != -1
	|| StrContains(mapname, "c6m2_bedlam", false) != -1
	|| StrContains(mapname, "c7m2_barge", false) != -1
	|| StrContains(mapname, "1_alleys", false) != -1
	|| StrContains(mapname, "4_interior", false) != -1
	|| StrContains(mapname, "4_mainstreet", false) != -1
	|| StrContains(mapname, "4_terminal", false) != -1
	|| StrContains(mapname, "4_barn", false) != -1
	|| StrContains(mapname, "3_memorialbridge", false) != -1)
	return true;

	else return false;
}

stock bool IsFinaleMapNow()
{
	return L4D_IsMissionFinalMap();

	/*
	char mapname[256];
	GetCurrentMap(mapname, sizeof(mapname));

	if (StrContains(mapname, "c1m4_atrium", false) != -1
	|| StrContains(mapname, "c2m5_concert", false) != -1
	|| StrContains(mapname, "c3m4_plantation", false) != -1
	|| StrContains(mapname, "c4m5_milltown_escape", false) != -1
	|| StrContains(mapname, "c5m5_bridge", false) != -1
	|| StrContains(mapname, "c6m3_port", false) != -1
	|| StrContains(mapname, "c7m3_port", false) != -1
	|| StrContains(mapname, "5_rooftop", false) != -1
	|| StrContains(mapname, "2_lots", false) != -1
	|| StrContains(mapname, "5_cornfield", false) != -1
	|| StrContains(mapname, "5_houseboat", false) != -1
	|| StrContains(mapname, "5_runway", false) != -
	|| StrContains(mapname, "4_cutthroatcreek", false) != -1)
	return true;

	else return false;
	*/
}

void Event_PlayerFirstSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (SpawnTimer != null) return;
	SpawnTimer = CreateTimer(30.0, SpawnTick, _, TIMER_REPEAT);
}

Action SpawnTick(Handle hTimer, any Junk)
{
	int NumSurvivors;
	int MaxSurvivors = SurvivorLimit.IntValue;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientConnected(i)) continue;
		if (!IsClientInGame(i))    continue;
		if (GetClientTeam(i) != 2) continue;

		NumSurvivors++;
	}

	// It's impossible to have less than 4 survivors. Set the lower
	// limit to 4 in order to prevent errors with the respawns. Try
	// again later.
	if (NumSurvivors < 4) return Plugin_Continue;

	// Create missing bots
	for (;NumSurvivors < MaxSurvivors; NumSurvivors++)
		SpawnFakeClient();

	// Once the missing bots are made, dispose of the timer
	SpawnTimer = null;
	return Plugin_Stop;
}

void SpawnFakeClient()
{
	// Spawn bot survivor.
	int Bot = CreateFakeClient("SurvivorBot");
	if (!Bot) return;

	ChangeClientTeam(Bot, 2);
	DispatchKeyValue(Bot, "classname", "SurvivorBot");
	CreateTimer(2.5, KickFakeClient, Bot);
}

Action KickFakeClient(Handle hTimer, any Client)
{
	if (IsClientInGame(Client)
	&& IsFakeClient(Client))
		KickClient(Client, "Free slot.");

	return Plugin_Handled;
}

bool MissionChangerVote;

Action Callvote_Handler(int client, int args)
{
	char voteName[32];
	GetCmdArg(1,voteName,sizeof(voteName));

	if ((StrEqual(voteName,"ReturnToLobby", false) || StrEqual(voteName,"ChangeMission", false)))
	{
		DebugPrintToAll("Mission Changing Vote by %N caught", client);
		MissionChangerVote = true;
	}

    return Plugin_Continue;
}

void EventVoteEndSuccess(Event event, const char[] name, bool dontBroadcast)
{
	if (!MissionChangerVote) return;

	char details[256]; char param1[256];
	GetEventString(event, "details", details, sizeof(details));
	GetEventString(event, "param1", param1, sizeof(param1));

	DebugPrintToAll("Mission Changing Vote End caught, details: %s ; param1: %s ", details, param1);
	MissionChangerVote = false;

	if (strcmp(details, "#L4D_vote_passed_mission_change", false) == 0)
	{
		DebugPrintToAll("New Campaign Vote Success caught, executing OnNewMission()");
		OnNewMission();
	}

	if (strcmp(details, "#L4D_vote_passed_return_to_lobby", false) == 0)
	{
		DebugPrintToAll("Return To Lobby Vote Success caught, executing OnNewMission()");
		OnNewMission();
	}
}

void EventVoteEndFail(Event event, const char[] name, bool dontBroadcast)
{
	if (MissionChangerVote) MissionChangerVote = false;
}

bool IsFirstMap()
{
	return !IsServerProcessing() || (GetFeatureStatus(FeatureType_Native, "L4D_IsFirstMapInScenario") == FeatureStatus_Available && L4D_IsFirstMapInScenario());
}
/**/

