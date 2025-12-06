#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

ConVar sm_ar_announce, sm_ar_lock_tankalive, sm_ar_lock_farm, sm_ar_DoorLock, sm_ar_DoorLockShow, sm_ar_AntySpam, g_hCvarCountdown, g_hTimout;
Handle g_hTimer = null;
int g_iClock = 0, UseCounter = 0, nShowType = 0, countDown = 0, secs = 0, PlayerUseCounter[66], idKeyman = 0, idGoal = 0, g_iYesCount = 0, g_iNoCount = 0, g_iVoters = 0, g_iPlayers = 0, seconds = 0;
bool isSafeRoom[66], bSafetyLock = false, antifarm_timer_start = false, timer_start = false, AntifarmActivated = false, g_bTempBlock = false, g_bAllVoted = false, g_bReverseVote = false;
float g_GameTime[66], g_fSec = 1077936128.0;
char nmKeyman[128], SoundNotice[128] = "doors/latchlocked2.wav", SoundDoorOpen[128] = "doors/door_squeek1.wav";

public Plugin myinfo =
{
	name = "[L4D2] Anti-Runner System feat.Assault door",
	description = "Only Keyman can open saferoom door.",
	author = "ztar",
	version = "1.0",
	url = "http://ztar.blog7.fc2.com/"
};

public void OnPluginStart()
{
	LoadTranslations("keyman.phrases");
	g_hTimout = CreateConVar("sm_ar_request_timout", "30.0", "", 262144, true, 5.0, true, 30.0);
	sm_ar_announce = CreateConVar("sm_ar_announce", "1", "Announce plugin info(0:OFF 1:ON)", 262464, false, 0.0, false, 0.0);
	sm_ar_lock_tankalive = CreateConVar("sm_ar_lock_tankalive", "1", "Lock door if any Tank is alive(0:OFF 1:ON)", 262464, false, 0.0, false, 0.0);
	sm_ar_lock_farm = CreateConVar("sm_ar_lock_farm", "1", "Lock door if antifarm not activated(0:OFF 1:ON)", 262464, false, 0.0, false, 0.0);
	sm_ar_DoorLock = CreateConVar("sm_ar_doorlock_sec", "60", "number of seconds", 262464, true, 5.0, true, 300.0);
	sm_ar_DoorLockShow = CreateConVar("sm_ar_doorlock_show", "0", "countdown type (def:0 / center text:0 / hint text:1)", 262464, true, 0.0, true, 1.0);
	sm_ar_AntySpam = CreateConVar("sm_ar_door_lock_spam", "3", "Survovors can close the door one time per <your choice> sec", 0, false, 0.0, false, 0.0);
	g_hCvarCountdown = CreateConVar("sm_time", "92", "Время до убийства игроков, не вошедших в убегу. (0=Откл плагин, >0=Включить)", 262144, true, 0.0, false, 0.0);
	ConVar cvar = CreateConVar("anti_console_flood", "3.0", "Дверь можно дернуть не более 7-ти раз в 'x' сек без последствия для игрока", 0, true, 0.1, true, 10.0);
	g_fSec = cvar.FloatValue;
	cvar.AddChangeHook(cvar_changed);

	HookEvent("player_death", Event_Player_Death);
	HookEvent("round_start", Event_Round_Start);
	HookEvent("player_team", Event_Join_Team);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("item_pickup", Event_RoundStartAndItemPickup);
	HookEvent("bot_player_replace", OnBotPlayerReplace);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("mission_lost", Event_RoundEnd);
	HookEvent("map_transition", Event_RoundEnd);
	HookEvent("player_left_checkpoint", OnPlayerLeftCheckpoint);
	HookEvent("player_entered_checkpoint", OnPlayerEnteredCheckpoint);
	RegAdminCmd("sm_initdoor", Command_InintDoor, 256, "", "", 0);
	RegAdminCmd("sm_checkweapons", Command_CheckWeapons, 256, "", "", 0);
}

public void OnMapStart()
{
	PrecacheSound(SoundNotice, true);
	PrecacheSound(SoundDoorOpen, true);
	PrecacheSound("ambient/alarms/klaxon1.wav", true);
	PrecacheSound("npc/mega_mob/mega_mob_incoming.wav", true);
	PrecacheSound("ui/alert_clink.wav", true);
	PrecacheSound("ui/critical_event_1.wav", true);
	PrecacheSound("ui/beep_error01.wav", true);
	ResetTimer();
}

Action Event_RoundEnd(Event event, char[] name, bool dontBroadcast)
{
	ResetTimer();
	return Plugin_Continue;
}

void cvar_changed(ConVar cvar, char[] OldValue, char[] NewValue)
{
	g_fSec = StringToFloat(NewValue);
}

Action Event_Join_Team(Event event, char[] event_name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidEntity(client) || event.GetBool("isbot"))
	{
		return Plugin_Continue;
	}

	if (event.GetInt("team") == 2)
	{
		SelectKeyman();
	}
	return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	if (!IsValidEntity(client))
	{
		return;
	}

	if (idKeyman == client)
	{
		SelectKeyman();
	}
}

Action Event_Round_Start(Event event, char[] name, bool dontBroadcast)
{
	AntifarmActivated = false;
	UseCounter = 0;
	antifarm_timer_start = false;
	timer_start = false;
	g_bTempBlock = false;
	secs = 120;
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsValidEntity(i))
		{
			if (IsClientInGame(i))
			{
				PlayerUseCounter[i] = 0;
				if (GetClientTeam(i) == 2)
				{
					isSafeRoom[i] = false;
				}
			}
		}
		i++;
	}
	CreateTimer(30.0, RoundStartDelay, 0, TIMER_REPEAT);
	return Plugin_Continue;
}

public void OnClientConnected(int client)
{
	PlayerUseCounter[client] = 0;
}

Action Event_PlayerSpawn(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && IsValidEntity(client))
	{
		CreateTimer(1.2, TimerCheckSafeRoom, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

void Event_RoundStartAndItemPickup(Event event, char[] name, bool dontBroadcast)
{
	if (g_bTempBlock)
	{
		return;
	}
	g_bTempBlock = true;
	CreateTimer(1.0, LockSafeRoom, 0, TIMER_FLAG_NO_MAPCHANGE);
}

Action OnBotPlayerReplace(Event event, char[] name, bool dontBroadcast)
{
	TimerCheckSafeRoom(INVALID_HANDLE, GetClientOfUserId(event.GetInt("player")));
	return Plugin_Continue;
}

Action LockSafeRoom(Handle timer)
{
	char current_map[56];
	GetCurrentMap(current_map, 54);
	if (StrEqual(current_map, "c10m3_ranchhouse", false) || L4D_IsMissionFinalMap(false))
	{
		return Plugin_Stop;
	}

	if(!L4D_IsMissionFinalMap(false))
	{
		idGoal = L4D_GetCheckpointLast();
		ControlDoor(idGoal, true);
		bSafetyLock = true;
		return Plugin_Stop;
	}
	else
	{
		bSafetyLock = false;
	}

	return Plugin_Stop;
}

Action Command_InintDoor(int client, int args)
{
	CreateTimer(1.0, LockSafeRoom, 0, TIMER_FLAG_NO_MAPCHANGE);
	SelectKeyman();
	return Plugin_Handled;
}

Action RoundStartDelay(Handle timer, int client)
{
	SelectKeyman();
	return Plugin_Stop;
}

void SelectKeyman()
{
	int count = 0, colors = 0, idAlive[66], i = 1;
	while (i <= MaxClients)
	{
		if (IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i))
		{
			if (GetClientTeam(i) == 2)
			{
				idAlive[count] = i;
				count++;
			}
		}
		i++;
	}
	int k = 1;
	while (k <= MaxClients)
	{
		if (IsValidEntity(k) && IsClientInGame(k) && IsPlayerAlive(k) && !IsFakeClient(k))
		{
			if (GetClientTeam(k) == 2)
			{
				int color = GetEntColor(k);
				if (color != 255255255)
				{
					idAlive[colors] = k;
					colors++;
				}
			}
		}
		k++;
	}
	if (colors > 1)
	{
		int key = GetRandomInt(0, colors - 1);
		idKeyman = idAlive[key];
		GetClientName(idKeyman, nmKeyman, 128);
	}
	else
	{
		if (count)
		{
			int key = GetRandomInt(0, count - 1);
			idKeyman = idAlive[key];
			GetClientName(idKeyman, nmKeyman, 128);
		}
		return;
	}
	return;
}

Action Event_Player_Death(Event event, char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid", 0));
	if (idKeyman == victim)
	{
		SelectKeyman();
	}
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	if(!L4D_IsMissionFinalMap(false) && bSafetyLock && client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		if (buttons & IN_USE)
		{
			int Entity = GetClientAimTarget(client, false);
			if(Entity != -1 && Entity == idGoal)
			{
				float vPosClient[3], vPosEnt[3];
				GetClientAbsOrigin(client, vPosClient);
				GetEntPropVector(Entity, Prop_Send, "m_vecOrigin", vPosEnt);
				if (GetVectorDistance(vPosClient, vPosEnt) <= 100.0)
				{
					float fSec = GetGameTime();
					PlayerUseCounter[client]++;
					g_GameTime[client] = fSec;
					if (PlayerUseCounter[client] > 7)
					{
						if (fSec - g_GameTime[client] < g_fSec)
						{
							PlayerUseCounter[client] = 0;
							SlapPlayer(client, 0, false);
						}
						PlayerUseCounter[client] = 0;
					}
					if (!timer_start)
					{
						UseCounter += 1;
						CheckUseCounter();
					}

					if (IsTankAlive() && sm_ar_lock_tankalive.BoolValue)
					{
						EmitSoundToAll(SoundNotice, Entity, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
						PrintHintText(client, "%t!", "All tanks");
						return Plugin_Continue;
					}
					AcceptEntityInput(Entity, "Lock", -1, -1, 0);
					SetEntProp(Entity, view_as<PropType>(1), "m_hasUnlockSequence", view_as<any>(1), 4, 0);

					if (!IsValidEntity(idKeyman) || !IsClientInGame(idKeyman) || !IsPlayerAlive(idKeyman) || IsFakeClient(idKeyman))
					{
						SelectKeyman();
					}
					if (idKeyman == client)
					{
						if (UseCounter > 1)
						{
							if (!timer_start)
							{
								printToRoot("UseCounter > 1");
							}
							if (sm_ar_lock_farm.BoolValue)
							{
								if (antifarm_timer_start)
								{
									if (!timer_start)
									{
										timer_start = true;
										nShowType = sm_ar_DoorLockShow.BoolValue;
										CreateTimer(1.0, TimerDoorCountDown, Entity, TIMER_REPEAT);
										if (sm_ar_announce.BoolValue)
										{
											PrintToChatAll("\x04%t \x05%s\x04 %t!", "The keyman", nmKeyman, "Unblock the safe room");
										}
									}
								}
								else
								{
									PrintHintText(client, "%t", "Please wait antifarm activation");
								}
							}
							if (!timer_start)
							{
								timer_start = true;
								nShowType = sm_ar_DoorLockShow.BoolValue;
								if (countDown > secs)
								{
									countDown = secs + 40;
								}
								CreateTimer(1.0, TimerDoorCountDown, Entity, TIMER_REPEAT);
								if (sm_ar_announce.BoolValue)
								{
									PrintToChatAll("\x04%t \x05%s\x04 %t!", "The keyman", nmKeyman, "Unblock the safe room");
								}
							}
						}
					}
					else
					{
						if (sm_ar_lock_farm.BoolValue)
						{
							if (antifarm_timer_start)
							{
								if (!timer_start)
								{
									EmitSoundToAll(SoundNotice, Entity, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
									PrintHintTextToAll("%t: %s.\n%t", "Keyman is", nmKeyman, "Only the Keyman");
								}
							}
							else
							{
								PrintHintText(client, "%t", "Please wait antifarm activation");
							}
						}
						if (!timer_start)
						{
							EmitSoundToAll(SoundNotice, Entity, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
							PrintHintTextToAll("%t: %s.\n%t", "Keyman is", nmKeyman, "Only the Keyman");
						}
					}
					if (sm_ar_AntySpam.BoolValue)
					{
						HookSingleEntityOutput(Entity, "OnFullyOpen", DL_OutPutOnFullyOpen, false);
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

Action TimerDoorCountDown(Handle timer, any Entity)
{
	if (0 < UseCounter)
	{
		if (0 < countDown)
		{
			if (countDown < 60)
			{
				EmitSoundToAll("ambient/alarms/klaxon1.wav", Entity, 0, 130, 0, 1.0, 95, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
			}
			if (countDown == 30)
			{
				ControlDoor(Entity, false);
			}
			if (!nShowType)
			{
				if (countDown > 30)
				{
					PrintCenterTextAll("[DOOR OPEN] %d sec", countDown);
				}
				else
				{
					int i = 1;
					while (i <= MaxClients)
					{
						if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2)
						{
							PrintHintText(i, "[DOOR OPEN] %d sec", countDown);
						}
						i++;
					}
				}
			}
			else
			{
				int i = 1;
				while (i <= MaxClients)
				{
					if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2)
					{
						PrintHintText(i, "[DOOR OPEN] %d sec", countDown);
					}
					i++;
				}
			}
			countDown -= 1;
			return Plugin_Continue;
		}
		if (timer_start)
		{
			EmitSoundToAll(SoundDoorOpen, Entity, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
			bSafetyLock = false;
			FindConVar("hm_mapfinished").SetInt(1, false, false);
			ServerCommand("sm_weaponscheck");
			if (AntifarmActivated)
			{
				AntiFarmStop();
			}
			g_iClock = g_hCvarCountdown.IntValue - 1;
			g_hTimer = CreateTimer(1.0, NSP_t_Notification, Entity, TIMER_REPEAT);
			CreateTimer(10.0, TimerLoadOnEnd1, TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(30.0, TimerLoadOnEnd2, TIMER_FLAG_NO_MAPCHANGE);

			int i = 1;
			while (i <= MaxClients)
			{
				if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2)
				{
					PrintHintText(i, "DOOR OPENED");
				}
				i++;
			}
		}
	}
	return Plugin_Stop;
}

void ControlDoor(int Entity, bool bOperation)
{
	if (bOperation)
	{
		AcceptEntityInput(Entity, "Close", -1, -1, 0);
		SetEntPropFloat(Entity, view_as<PropType>(1), "m_flSpeed", 3.0, 0);
		AcceptEntityInput(Entity, "ForceClosed", -1, -1, 0);
		AcceptEntityInput(Entity, "Lock", -1, -1, 0);
		SetEntProp(Entity, view_as<PropType>(1), "m_hasUnlockSequence", view_as<any>(1), 4, 0);
		if (b_StandartMap())
		{
			L4D2_SetEntityGlow(Entity, view_as<L4D2GlowType>(3), 700, 0, {0, 96, 100}, false);
		}
	}
	else
	{
		SetEntProp(Entity, view_as<PropType>(1), "m_hasUnlockSequence", view_as<any>(0), 4, 0);
		AcceptEntityInput(Entity, "Unlock", -1, -1, 0);
		AcceptEntityInput(Entity, "ForceClosed", -1, -1, 0);
		AcceptEntityInput(Entity, "Open", -1, -1, 0);
		SetEntPropFloat(Entity, view_as<PropType>(1), "m_flSpeed", 200.0, 0);
		if (b_StandartMap())
		{
			L4D2_SetEntityGlow(Entity, view_as<L4D2GlowType>(3), 700, 0, {252, 97, 54}, false);
		}
	}
}

public void DL_OutPutOnFullyOpen(char[] output, int caller, int activator, float delay)
{
	if (!IsALLinSafeRoom())
	{
		if (b_StandartMap())
		{
			L4D2_SetEntityGlow(activator, view_as<L4D2GlowType>(3), 700, 0, {207, 97, 72}, false);
		}
		AcceptEntityInput(activator, "Lock", -1, -1, 0);
		SetEntProp(activator, view_as<PropType>(1), "m_hasUnlockSequence", view_as<any>(1), 4, 0);
	}
	CreateTimer(sm_ar_AntySpam.FloatValue, DL_t_UnlockSafeRoom, EntIndexToEntRef(activator), TIMER_FLAG_NO_MAPCHANGE);
}

Action DL_t_UnlockSafeRoom(Handle timer, any entity)
{
	if ((entity = EntRefToEntIndex(entity)) != -1)
	{
		SetEntProp(entity, view_as<PropType>(1), "m_hasUnlockSequence", view_as<any>(0), 4, 0);
		AcceptEntityInput(entity, "Unlock", -1, -1, 0);
		if (b_StandartMap())
		{
			L4D2_SetEntityGlow(entity, view_as<L4D2GlowType>(3), 700, 0, {98, 22, 204}, false);
		}
	}
	return Plugin_Stop;
}

void StartTimerAntifarm()
{
	int realsurvivors = GetSurvivorsCount();
	int good_weapon = CountGoodWeapons();
	if (!L4D_IsFirstMapInScenario())
	{
		char Message[512], TempMessage[256];
		if (realsurvivors < 5)
		{
			secs = 120;
			CreateTimer(1.0, TimerAntiFarmStart, 0, TIMER_REPEAT);
			PrintToChatAll("\x04[Antifarm]\x05 Антифарм включится после 2-х минут");
			Format(TempMessage, 256, "\x04[\x05Keyman\x04]\x01 Антифарм 2 минуты, хорошего оружия:");
			StrCat(Message, 512, TempMessage);
		}
		else
		{
			if (!isFarm())
			{
				secs = 60;
				CreateTimer(1.0, TimerAntiFarmStart, 0, TIMER_REPEAT);
				PrintToChatAll("\x04[Antifarm]\x05 Антифарм включится после 1-ой минуты");
				Format(TempMessage, 256, "\x04[\x05Keyman\x04]\x01 Антифарм 2 минуты, хорошего оружия:");
				StrCat(Message, 512, TempMessage);
			}
			secs = 240;
			CreateTimer(1.0, TimerAntiFarmStart, 0, TIMER_REPEAT);
			PrintToChatAll("\x04[Antifarm]\x05 Антифарм включится после 4-х минут");
			Format(TempMessage, 256, "\x04[\x05Keyman\x04]\x01 Антифарм 4 минуты, хорошего оружия:");
			StrCat(Message, 512, TempMessage);
		}
		Format(TempMessage, 256, " \x05%d", good_weapon);
		StrCat(Message, 512, TempMessage);
		printToRoot(Message);
	}
	else
	{
		if (realsurvivors < 5)
		{
			secs = 300;
			CreateTimer(1.0, TimerAntiFarmStart, 0, TIMER_REPEAT);
			PrintToChatAll("\x04[Antifarm]\x05 Антифарм включится после 5-ти минут");
		}
		if (realsurvivors > 4 && realsurvivors < 13)
		{
			secs = 300;
			CreateTimer(1.0, TimerAntiFarmStart, 0, TIMER_REPEAT);
			PrintToChatAll("\x04[Antifarm]\x05 Антифарм включится после 5-ти минут");
		}
		else
		{
			secs = 420;
			CreateTimer(1.0, TimerAntiFarmStart, 0, TIMER_REPEAT);
			PrintToChatAll("\x04[Antifarm]\x05 Антифарм включится после 7-ми минут");
		}
	}
}

void CheckUseCounter()
{
	if (UseCounter == 1)
	{
		if (isFarm())
		{
			VoteOpen();
		}
		else
		{
			CheckWeapons();
			StartTimerAntifarm();
		}
	}
	else
	{
		if (UseCounter == 40)
		{
			SelectKeyman();
			printToRoot("\x05UseCounter:\x04 40");
		}
		if (UseCounter == 80)
		{
			SelectKeyman();
			printToRoot("\x05UseCounter:\x04 80");
		}
		if (UseCounter == 130)
		{
			SelectKeyman();
			printToRoot("\x05UseCounter:\x04 130");
		}
		if (UseCounter == 160)
		{
			SelectKeyman();
			printToRoot("\x05UseCounter:\x04 160");
		}
		if (UseCounter == 200)
		{
			SelectKeyman();
			printToRoot("\x05UseCounter:\x04 200");
		}
		if (UseCounter == 300)
		{
			SelectKeyman();
			printToRoot("\x05UseCounter:\x04 300");
		}
		if (UseCounter == 400)
		{
			SelectKeyman();
			printToRoot("\x05UseCounter:\x04 400");
			AntiFarmStart();
		}
	}
}

Action TimerAntiFarmStart(Handle timer)
{
	if (secs > 0 && UseCounter > 0)
	{
		if (!timer_start)
		{
			PrintHintTextToAll("[ANTIFARM] %d сек. до антифарма", secs);
		}
	}
	else
	{
		if (secs)
		{
			if (secs < 0 || UseCounter < 1)
			{
				return Plugin_Stop;
			}
		}
		if (0 < UseCounter)
		{
			if (!FindConVar("hm_mapfinished").BoolValue)
			{
				AntiFarmStart();
			}
		}
	}
	secs -= 1;
	return Plugin_Continue;
}

void AntiFarmStart()
{
	AntifarmActivated = true;
	antifarm_timer_start = true;
	ServerCommand("sm_cvar monsterbots_on 0");
	ServerCommand("sm_cvar director_no_specials 1");
	PrintToChatAll("\x04[Antifarm Activated]\x05 Антифарм включен");
	ServerCommand("sm_msay \"[Antifarm Activated] Антифарм включен\"");

	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2)
		{
			PrintHintText(i, "[Antifarm Activated] Антифарм включен");
		}
		i++;
	}
	countDown = sm_ar_DoorLock.IntValue;
}

void AntiFarmStop()
{
	AntifarmActivated = false;
	ServerCommand("sm_cvar monsterbots_on 1");
	ServerCommand("sm_cvar director_no_specials 0");
	printToRoot("\x04[Antifarm Deactivated]\x05 Антифарм выключен");
}

stock int IsTankAlive()
{
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i) && IsFakeClient(i))
		{
			if (GetClientZC(i) == 8 && !IsIncapacitated(i))
			{
				if (IsPlayerAlive(i))
				{
					return 1;
				}
			}
		}
		i++;
	}
	return 0;
}

stock int GetClientZC(int client)
{
	if (!IsValidEntity(client) || !IsValidEdict(client))
	{
		return 0;
	}
	return GetEntProp(client, view_as<PropType>(0), "m_zombieClass", 4);
}

stock bool IsIncapacitated(int client)
{
	return view_as<bool>(GetEntProp(client, view_as<PropType>(0), "m_isIncapacitated"));
}

Action TimerLoadOnEnd1(Handle timer, any client)
{
	if (timer_start)
	{
		LoadCFG();
	}
	return Plugin_Stop;
}

void LoadCFG()
{
	ServerCommand("exec hardmod/checkpointreached.cfg");
	EmitSoundToAll("npc/mega_mob/mega_mob_incoming.wav", -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	int bot = CreateFakeClient("mob");
	if (0 < bot)
	{
		if (IsFakeClient(bot))
		{
			SpawntyCommand(bot, "z_spawn_old", "mob auto");
			KickClient(bot, "");
		}
	}
}

Action TimerLoadOnEnd2(Handle timer, any client)
{
	if (timer_start)
	{
		Panic();
	}
	return Plugin_Stop;
}

void Panic()
{
	EmitSoundToAll("npc/mega_mob/mega_mob_incoming.wav", -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	int bot = CreateFakeClient("mob");
	if (0 < bot)
	{
		if (IsFakeClient(bot))
		{
			SpawntyCommand(bot, "z_spawn_old", "mob auto");
			KickClient(bot, "");
		}
	}
}

void SpawntyCommand(int client, char[] command, char[] arguments)
{
	if (client)
	{
		int flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & -16385);
		FakeClientCommand(client, "%s %s", command, arguments);
		SetCommandFlags(command, flags);
	}
}

void CheckWeapons()
{
	int realsurvivors = GetSurvivorsCount();
	int good_weapon = CountGoodWeapons();
	char Message[512], TempMessage[256];
	if (L4D_IsFirstMapInScenario())
	{
		if (realsurvivors < 5)
		{
			countDown = sm_ar_DoorLock.IntValue;
			Format(TempMessage, 256, "\x04[\x05Keyman\x04]\x01 Короткий таймер, хорошего оружия:");
			StrCat(Message, 512, TempMessage);
		}
		else
		{
			if (realsurvivors > 4 && realsurvivors < 14)
			{
				if (!isFarm())
				{
					countDown = sm_ar_DoorLock.IntValue;
					Format(TempMessage, 256, "\x04[\x05Keyman\x04]\x01 Короткий таймер, хорошего оружия:");
					StrCat(Message, 512, TempMessage);
					PrintToChatAll("\x04[\x05KEYMAN\x04] \x01Короткий таймер (мало игроков), хорошего оружия: \x05%d", good_weapon);
				}
				else
				{
					countDown = sm_ar_DoorLock.IntValue + 300;
					Format(TempMessage, 256, "\x04[\x05Keyman\x04]\x01 Таймер \x04 5 \x01минут, хорошего оружия:");
					StrCat(Message, 512, TempMessage);
					PrintToChatAll("\x04[\x05KEYMAN\x04] \x01Таймер \x04 5 \x01минут, хорошего оружия: \x05%d", good_weapon);
				}
			}
			if (realsurvivors > 13)
			{
				if (!isFarm())
				{
					countDown = sm_ar_DoorLock.IntValue;
					Format(TempMessage, 256, "\x04[\x05Keyman\x04]\x01 Короткий таймер, хорошего оружия:");
					StrCat(Message, 512, TempMessage);
					PrintToChatAll("\x04[\x05KEYMAN\x04] \x01Короткий таймер (мало игроков), хорошего оружия: \x05%d", good_weapon);
				}
				countDown = sm_ar_DoorLock.IntValue + 360;
				Format(TempMessage, 256, "\x04[\x05Keyman\x04]\x01 Таймер \x04 7 \x01минут, хорошего оружия:");
				StrCat(Message, 512, TempMessage);
				PrintToChatAll("\x04[\x05KEYMAN\x04] \x01Таймер \x04 7 \x01минут, хорошего оружия: \x05%d", good_weapon);
			}
		}
	}
	else
	{
		if (realsurvivors < 5)
		{
			countDown = sm_ar_DoorLock.IntValue;
			Format(TempMessage, 256, "\x04[\x05Keyman\x04]\x01 Короткий таймер, хорошего оружия:");
			StrCat(Message, 512, TempMessage);
			PrintToChatAll("\x04[\x05KEYMAN\x04] \x01Короткий таймер (мало игроков), хорошего оружия: \x05%d", good_weapon);
		}
		if (!isFarm())
		{
			countDown = sm_ar_DoorLock.IntValue;
			Format(TempMessage, 256, "\x04[\x05Keyman\x04]\x01 Короткий таймер, хорошего оружия:");
			StrCat(Message, 512, TempMessage);
			PrintToChatAll("\x04[\x05KEYMAN\x04] \x01Короткий таймер (достаточно хорошего оружия), хорошего оружия: \x05%d", good_weapon);
		}
		countDown = sm_ar_DoorLock.IntValue + 240;
		Format(TempMessage, 256, "\x04[\x05Keyman\x04]\x01 Увеличенный таймер, хорошего оружия:");
		StrCat(Message, 512, TempMessage);
		PrintToChatAll("\x04[\x05KEYMAN\x04] \x01Таймер \x04 5 \x01минут, хорошего оружия: \x05%d", good_weapon);
		ServerCommand("exec hardmod/farm.cfg");
	}
	Format(TempMessage, 256, " \x05%d", good_weapon);
	StrCat(Message, 512, TempMessage);
	printToRoot(Message);

	if (AntifarmActivated || FindConVar("l4d2_loot_g_chance_nodrop").IntValue >= 50)
	{
		countDown = sm_ar_DoorLock.IntValue;
	}
}

stock int GetSurvivorsCount()
{
	int survivors = 0, i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i))
		{
			survivors++;
		}
		i++;
	}
	return survivors;
}

stock int CountGoodWeapons()
{
	int good_weapon = 0, i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i) && IsPlayerAlive(i))
		{
			bool kid = HaveGoodWeapon(i);
			if (kid)
			{
				good_weapon++;
			}
		}
		i++;
	}
	return good_weapon;
}

stock bool HaveGoodWeapon(int client)
{
	char getweapon[32];
	int KidSlot = GetPlayerWeaponSlot(client, 0);
	if (KidSlot != -1)
	{
		GetEdictClassname(KidSlot, getweapon, 32);
		if (StrEqual(getweapon, "weapon_sniper_scout", true))
		{
			return true;
		}
		if (StrEqual(getweapon, "weapon_sniper_awp", true))
		{
			return true;
		}
		if (StrEqual(getweapon, "weapon_rifle_ak47", true))
		{
			return true;
		}
		if (StrEqual(getweapon, "weapon_grenade_launcher", true))
		{
			return true;
		}
		if (StrEqual(getweapon, "weapon_rifle_m60", true))
		{
			return true;
		}
		if (StrEqual(getweapon, "weapon_shotgun_spas", true))
		{
			return true;
		}
	}
	return false;
}

bool isFarm()
{
	float percent = 0.0;
	int survivors = GetSurvivorsCount();
	int good_weapon = CountGoodWeapons();
	percent = 1.0 * good_weapon * 100 / survivors;
	if (RoundToNearest(percent) < 33)
	{
		return true;
	}
	return false;
}

void printToRoot(char[] format)
{
	AdminId adminID;
	char buffer[1024];
	VFormat(buffer, 1024, format, 2);
	int i = 1;
	while (MaxClients > i)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			adminID = GetUserAdmin(i);
			if (adminID != INVALID_ADMIN_ID)
			{
				if (GetAdminFlag(adminID, view_as<AdminFlag>(14), view_as<AdmAccessMode>(1)))
				{
					PrintToChat(i, "\x04[\x01%s\x04]", buffer);
				}
			}
		}
		i++;
	}
}

Action Command_CheckWeapons(int client, int args)
{
	if (!client)
	{
		return Plugin_Handled;
	}
	int good_weapon = CountGoodWeapons();
	char Message[256], TempMessage[64];
	Format(TempMessage, 64, "\x04[\x05Keyman\x04]\x01 Хорошего оружия:");
	StrCat(Message, 256, TempMessage);
	Format(TempMessage, 64, " \x05%d", good_weapon);
	StrCat(Message, 256, TempMessage);
	printToRoot(Message);
	return Plugin_Handled;
}

stock bool b_StandartMap()
{
	char MapName[128];
	GetCurrentMap(MapName, 128);

	if (StrContains(MapName, "c1m1", true) > -1 || StrContains(MapName, "c1m2", true) > -1 || StrContains(MapName, "c1m3", true) > -1 || StrContains(MapName, "c1m4", true) > -1 || StrContains(MapName, "c2m1", true) > -1 || StrContains(MapName, "c2m2", true) > -1 || StrContains(MapName, "c2m3", true) > -1 || StrContains(MapName, "c2m4", true) > -1 || StrContains(MapName, "c2m5", true) > -1 || StrContains(MapName, "c3m1", true) > -1 || StrContains(MapName, "c3m2", true) > -1 || StrContains(MapName, "c3m3", true) > -1 || StrContains(MapName, "c3m4", true) > -1 || StrContains(MapName, "c4m1", true) > -1 || StrContains(MapName, "c4m2", true) > -1 || StrContains(MapName, "c4m3", true) > -1 || StrContains(MapName, "c4m4", true) > -1 || StrContains(MapName, "c4m5", true) > -1 || StrContains(MapName, "c5m1", true) > -1 || StrContains(MapName, "c5m2", true) > -1 || StrContains(MapName, "c5m3", true) > -1 || StrContains(MapName, "c5m4", true) > -1 || StrContains(MapName, "c5m5", true) > -1 || StrContains(MapName, "c6m1", true) > -1 || StrContains(MapName, "c6m2", true) > -1 || StrContains(MapName, "c6m3", true) > -1 || StrContains(MapName, "c7m1", true) > -1 || StrContains(MapName, "c7m2", true) > -1 || StrContains(MapName, "c7m3", true) > -1 || StrContains(MapName, "c8m1", true) > -1 || StrContains(MapName, "c8m2", true) > -1 || StrContains(MapName, "c8m3", true) > -1 || StrContains(MapName, "c8m4", true) > -1 || StrContains(MapName, "c8m5", true) > -1 || StrContains(MapName, "c9m1", true) > -1 || StrContains(MapName, "c9m2", true) > -1 || StrContains(MapName, "c10m1", true) > -1 || StrContains(MapName, "c10m2", true) > -1 || StrContains(MapName, "c10m3", true) > -1 || StrContains(MapName, "c10m4", true) > -1 || StrContains(MapName, "c10m5", true) > -1 || StrContains(MapName, "c11m1", true) > -1 || StrContains(MapName, "c11m2", true) > -1 || StrContains(MapName, "c11m3", true) > -1 || StrContains(MapName, "c11m4", true) > -1 || StrContains(MapName, "c11m5", true) > -1 || StrContains(MapName, "c12m1", true) > -1 || StrContains(MapName, "c12m2", true) > -1 || StrContains(MapName, "c12m3", true) > -1 || StrContains(MapName, "c12m4", true) > -1 || StrContains(MapName, "c12m5", true) > -1 || StrContains(MapName, "c13m1", true) > -1 || StrContains(MapName, "c13m2", true) > -1 || StrContains(MapName, "c13m3", true) > -1 || StrContains(MapName, "c13m4", true) > -1)
	{
		return true;
	}
	return false;
}

stock int GetEntColor(int entity)
{
	if(entity > 0)
	{
		int offset = GetEntSendPropOffs(entity, "m_clrRender");
		int r = GetEntData(entity, offset, 1);
		int g = GetEntData(entity, offset + 1, 1);
		int b = GetEntData(entity, offset + 2, 1);
		char rgb[10];
		Format(rgb, sizeof(rgb), "%d%d%d", r,g,b);
		int color = StringToInt(rgb);
		return color;
	}
	return 0;
}

void VoteOpen()
{
	if (!timer_start)
	{
		timer_start = true;
	}
	if (UseCounter != 1)
	{
		printToRoot("\x05UseCounter \x04!=\x03 1");
		return;
	}
	PrintToChatAll("\x04[\x05KEYMAN\x04] \x05Началось голосование.");
	g_iYesCount = 0;
	g_iNoCount = 0;
	g_iVoters = 0;
	g_iPlayers = 0;
	g_bAllVoted = false;
	int ReverseRnd = GetRandomInt(1, 2);
	if (ReverseRnd == 1)
	{
		g_bReverseVote = true;
	}
	else
	{
		g_bReverseVote = false;
	}
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			ShowVotePanel(i);
			g_iVoters += 1;
			g_iPlayers += 1;
		}
		i++;
	}
	seconds = g_hTimout.IntValue;
	CreateTimer(g_hTimout.FloatValue + 1.0, Timer_VoteCheck, 0, TIMER_REPEAT);
	CreateTimer(1.0, TimerInfo, 0, TIMER_REPEAT);
}

void ShowVotePanel(int client)
{
	Panel panel = new Panel();
	char buffer[128], buffer1[32], buffer2[32], buffer3[64];
	Format(buffer, 128, "%t", "panel", client);
	panel.SetTitle(buffer);
	Format(buffer3, 64, "%t", "vote", client);
	panel.DrawItem(buffer3, 0);
	if (g_bReverseVote)
	{
		Format(buffer2, 32, "%t", "Yes", client);
		panel.DrawItem(buffer2);
		Format(buffer1, 32, "%t", "No", client);
		DrawPanelItem(panel, buffer1);
	}
	else
	{
		Format(buffer1, 32, "%t", "No", client);
		panel.DrawItem(buffer1);
		Format(buffer2, 32, "%t", "Yes", client);
		panel.DrawItem(buffer2);
	}
	panel.Send(client, FarmVoteHandler, g_hTimout.IntValue);
	panel.Close();
}

int FarmVoteHandler(Menu menu, MenuAction action, int client, int choice)
{
	if (action == MenuAction_Select)
	{
		int g_iVotes = g_iNoCount + g_iYesCount;
		if (!g_bAllVoted)
		{
			EmitSoundToClient(client, "ui/alert_clink.wav", -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
			PrintHintText(client, "%t %d/%d, %t %d sec\n%t (%d)\n%t (%d)", "Votes", g_iVotes, g_iPlayers, "left", seconds, "No", g_iNoCount, "Yes", g_iYesCount);
		}

		if (choice == 1)
		{
			ShowVotePanel(client);
		}
		else if (choice == 2)
		{
			if (g_bReverseVote)
			{
				g_iYesCount += 1;
				g_iVoters -= 1;
			}
			else
			{
				g_iNoCount += 1;
				g_iVoters -= 1;
			}
		}
		else if(choice == 3)
		{
			if (g_bReverseVote)
			{
				g_iNoCount += 1;
				g_iVoters -= 1;
			}
			else
			{
				g_iYesCount += 1;
				g_iVoters -= 1;
			}
		}

		if (g_iVoters)
		{
		}
		else
		{
			g_bAllVoted = true;
			seconds = 0;
			CountVotes();
		}
	}
	return 0;
}

Action Timer_VoteCheck(Handle timer)
{
	if (!g_bAllVoted)
	{
		g_bAllVoted = true;
		CountVotes();
	}
	return Plugin_Continue;
}

Action TimerInfo(Handle timer)
{
	int g_iVotes = g_iNoCount + g_iYesCount;
	if (0 <= seconds)
	{
		int i = 1;
		while (i <= MaxClients)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				PrintHintText(i, "%t %d/%d, %t %d sec\n%t (%d)\n%t (%d)", "Votes", g_iVotes, g_iPlayers, "left", seconds, "No", g_iNoCount, "Yes", g_iYesCount);
			}
			i++;
		}
	}
	else
	{
		if (seconds < 0 || g_bAllVoted)
		{
			return Plugin_Stop;
		}
	}
	seconds -= 1;
	return Plugin_Continue;
}

stock int GetVotesForFarm(int vote_Yes, int vote_No)
{
	int votes = vote_No + vote_Yes;
	int prcnt = (vote_Yes * 100) / votes;
	return prcnt;
}

void CountVotes()
{
	int g_iVotes = g_iNoCount + g_iYesCount;
	if (GetVotesForFarm(g_iYesCount, g_iNoCount) < 60)
	{
		countDown = sm_ar_DoorLock.IntValue;
		PrintToChatAll("%t", "Players decided not to farm. 60%% vote required (Received %d%% of %d votes)", GetVotesForFarm(g_iYesCount, g_iNoCount), g_iVotes);
		EmitSoundToAll("ui/beep_error01.wav", -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		StartTimerAntifarm();
		timer_start = false;
	}
	else
	{
		PrintToChatAll("%t", "Players decided to farm. (Received %d%% of %d votes)", GetVotesForFarm(g_iYesCount, g_iNoCount), g_iVotes);
		EmitSoundToAll("ui/critical_event_1.wav", -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		CheckWeapons();
		StartTimerAntifarm();
		timer_start = false;
	}
}

Action OnPlayerLeftCheckpoint(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		isSafeRoom[client] = false;
	}
	return Plugin_Continue;
}

Action OnPlayerEnteredCheckpoint(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		isSafeRoom[client] = true;
	}
	return Plugin_Continue;
}

Action TimerCheckSafeRoom(Handle timer, any client)
{
	if (client <= 0 || !IsClientConnected(client) || !IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) == 2)
	{
		return Plugin_Stop;
	}
	float vec[3], vecPlayer[3];
	GetClientAbsOrigin(client, vecPlayer);
	int i = 1;
	while (i <= MaxClients)
	{
		if (i != client && isSafeRoom[i] && IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			GetClientAbsOrigin(i, vec);
			if (FloatAbs(vec[0] - vecPlayer[0]) + FloatAbs(vec[1] - vecPlayer[1]) + FloatAbs(vec[2] - vecPlayer[2]) < 500.0)
			{
				isSafeRoom[client] = true;
				return Plugin_Stop;
			}
		}
		i++;
	}
	return Plugin_Stop;
}

stock int IsALLinSafeRoom()
{
	int count = 0, alive = 0, i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			if (isSafeRoom[i])
			{
				count++;
			}
			alive++;
		}
		i++;
	}
	int var2 = 0;
	if (alive <= count)
	{
		var2 = 1;
	}
	else
	{
		var2 = 0;
	}
	return var2;
}

Action NSP_t_Notification(Handle timer, any entity)
{
	g_iClock -= 1;
	if (0 < g_iClock)
	{
		int i = 1;
		while (i <= MaxClients)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
			{
				if (!isSafeRoom[i])
				{
					PrintHintText(i, "%t", "Please go inside a safe room or you die!\nTime: %d sec.", g_iClock);
				}
				PrintHintText(i, "%t", "Round ends after: %d sec.", g_iClock);
			}
			i++;
		}
		return Plugin_Continue;
	}
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			if (!isSafeRoom[i])
			{
				ForcePlayerSuicide(i);
				PrintHintText(i, "%t", "You are not entered in to the save room!");
			}
		}
		i++;
	}
	if ((entity = EntRefToEntIndex(entity)) != -1)
	{
		AcceptEntityInput(entity, "Close", -1, -1, 0);
	}
	g_hTimer = null;
	return Plugin_Stop;
}

void ResetTimer()
{
	g_iClock = 0;
	g_bTempBlock = false;
	if (g_hTimer)
	{
		delete g_hTimer;
	}
}

 