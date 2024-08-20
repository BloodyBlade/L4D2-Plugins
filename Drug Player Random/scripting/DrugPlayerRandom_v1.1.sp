#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <colors>

#define CVAR_FLAGS	FCVAR_NOTIFY

ConVar g_hCvarDrugOn, g_hCvarRandomDrugChance, g_hCvarDrugMode;
bool Adren[MAXPLAYERS + 1] = {false, ...}, Pills[MAXPLAYERS + 1] = {false, ...};
int iCvarRandomDrugChance, iCvarDrugMode, PlayerDrugged[MAXPLAYERS + 1] = {0, ...};
Handle g_DrugTimers[MAXPLAYERS + 1] = {null, ...}, TimerDamage[MAXPLAYERS + 1] = {null, ...};
float g_DrugAngles[20] = {0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 20.0, 15.0, 10.0, 5.0, 0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -20.0, -15.0, -10.0, -5.0};

public Plugin myinfo =
{
	name = "Drug Player Random",
	author = "BS/IW",
	description = "Drug Player Random",
	version = "1.1.1",
	url = "http://bloodsiworld.ru/"
};

public void OnPluginStart()
{
	LoadTranslations("DrugPlayerRandom.phrases");

	g_hCvarDrugOn = CreateConVar("RandomDrugChance", "1", "0=Plugin off, 1=Plugin on.", CVAR_FLAGS);
	g_hCvarRandomDrugChance = CreateConVar("RandomDrugChance", "5",	"Chance of drug player", CVAR_FLAGS);
	g_hCvarDrugMode = CreateConVar("DrugMode", "1",	"1 = Drug & Kill, 2 = Only Drug, 3 = Shake & Kill, 4 = Only Shake", CVAR_FLAGS);

	g_hCvarDrugOn.AddChangeHook(ConVarChanged_Switch);
	g_hCvarRandomDrugChance.AddChangeHook(ConVarChanged);
	g_hCvarDrugMode.AddChangeHook(ConVarChanged);

	AutoExecConfig(true, "DrugPlayerRandom");
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarChanged_Switch(ConVar convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void IsAllowed()
{
	bool bCvarDrugOn = g_hCvarDrugOn.BoolValue;
	if(bCvarDrugOn)
	{
		GetCvars();
		HookEvent("pills_used",	Event_Pills, EventHookMode_Post);
		HookEvent("adrenaline_used", Event_Adren, EventHookMode_Post);
		HookEvent("heal_success",	Event_HealSucces, EventHookMode_Post);
		HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
		HookEvent("player_disconnect", Event_Disconnect, EventHookMode_Pre);
		HookEvent("map_transition", Event_RoundEnd, EventHookMode_Post);
	}
	else
	{
		UnhookEvent("pills_used",	Event_Pills, EventHookMode_Post);
		UnhookEvent("adrenaline_used", Event_Adren, EventHookMode_Post);
		UnhookEvent("heal_success",	Event_HealSucces, EventHookMode_Post);
		UnhookEvent("round_end",	Event_RoundEnd, EventHookMode_Post);
		UnhookEvent("player_disconnect", Event_Disconnect, EventHookMode_Pre);
		UnhookEvent("map_transition", Event_RoundEnd, EventHookMode_Post);
		OnMapEnd();
	}
}

void GetCvars()
{
	iCvarRandomDrugChance = g_hCvarRandomDrugChance.IntValue;
	iCvarDrugMode = g_hCvarDrugMode.IntValue;
}

public void OnClientPutInServer(int client)
{
	PlayerDrugged[client] = false;
	Adren[client] = false;
	Pills[client] = false;
}

void Event_HealSucces(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	if(client && IsClientInGame(client))
	{
		if(PlayerDrugged[client])
		{
			if(iCvarDrugMode == 1 || iCvarDrugMode == 2)
			{
				KillDrug(client);
			}
			else if(iCvarDrugMode == 3 || iCvarDrugMode == 4)
			{
				StopShake(client);
			}
			PlayerDrugged[client] = false;
			Adren[client] = false;
			Pills[client] = false;
			if(TimerDamage[client] != null)
			{
				delete TimerDamage[client];
			}
		}
	}
}

void Event_Disconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client && IsClientInGame(client))
	{
		if(PlayerDrugged[client])
		{
			if(iCvarDrugMode == 1 || iCvarDrugMode == 2)
			{
				KillDrug(client);
			}
			else if(iCvarDrugMode == 3 || iCvarDrugMode == 4)
			{
				StopShake(client);
			}
			PlayerDrugged[client] = false;
			Adren[client] = false;
			Pills[client] = false;
			if(TimerDamage[client] != null)
			{
				delete TimerDamage[client];
			}
		}
	}
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	KillAllDrugs();
	KillTimerDrug();
}

void Event_Adren(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client && IsClientInGame(client) && !IsFakeClient(client))
	{
		int DrugRandom = GetRandomInt(0, 100);
		if(DrugRandom < iCvarRandomDrugChance)
		{
			Adren[client] = true;
			DrugFunction(client);
		}
	}
}

void Event_Pills(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	if( client && IsClientInGame(client) && !IsFakeClient(client))
	{
		int DrugRandom = GetRandomInt(0, 100);
		if(DrugRandom < iCvarRandomDrugChance)
		{
			Pills[client] = true;
			DrugFunction(client);
		}
	}
}

void DrugFunction(int client)
{
	if(!PlayerDrugged[client])
	{
		PlayerDrugged[client] = true;
		if(iCvarDrugMode == 1 || iCvarDrugMode == 2)
		{
			CreateDrug(client);
		}
		else if(iCvarDrugMode == 3 || iCvarDrugMode == 4)
		{
			Shake(client, 20.0);
		}
		if(Adren[client]) CPrintToChatAll("%t", "AdrenDrugs", client);
		else if(Pills[client]) CPrintToChatAll("%t", "PillsDrugs", client);
		if(iCvarDrugMode == 1 || iCvarDrugMode == 3)
		{
			if(!TimerDamage[client])
			{
				TimerDamage[client] = CreateTimer(1.0, TimerDamageDrug, client, TIMER_REPEAT);
			}
		}
	}
}

Action TimerDamageDrug(Handle timer, int client)
{
	ClientCommand(client, "vocalize PlayerLaugh");
	int iTotalHealth = GetClientHealth(client);
	float fTotalTempHealth = (GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - (GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) *FindConVar("pain_pills_decay_rate").FloatValue);
	int iSetHealth = GetClientHealth(client) - 2;
	float fSetTempHealth = fTotalTempHealth - 2;
	if((iTotalHealth + fTotalTempHealth) > iTotalHealth)
	{
		SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fSetTempHealth);
	}
	else if(iTotalHealth > 0)
	{
		SetEntProp(client, Prop_Send, "m_iHealth", iSetHealth);
	}
	else
	{
		if (iCvarDrugMode == 1 || iCvarDrugMode == 2)
		{
			KillDrug(client);
		}
		else if(iCvarDrugMode == 3 || iCvarDrugMode == 4)
		{
			StopShake(client);
		}

		Adren[client] = false;
		Pills[client] = false;
		PlayerDrugged[client] = false;
		ForcePlayerSuicide(client);
		TimerDamage[client] = null;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public void OnMapEnd()
{
	KillAllDrugs();
	KillTimerDrug();
}

void KillTimerDrug()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(PlayerDrugged[i]) PlayerDrugged[i] = false;
			if(TimerDamage[i] != null)
			{
				delete TimerDamage[i];
			}
			StopShake(i);
		}
	}
}

void CreateDrug(int client)
{
	g_DrugTimers[client] = CreateTimer(1.0, Timer_Drug, client, TIMER_REPEAT);	
}

Action Timer_Drug(Handle timer, any client)
{
	if (!IsClientInGame(client))
	{
		KillDrugTimer(client);
		return Plugin_Stop;
	}

	if (!IsPlayerAlive(client))
	{
		KillDrug(client);		
		return Plugin_Stop;
	}

	float pos[3], angs[3];
	GetClientAbsOrigin(client, pos);
	GetClientEyeAngles(client, angs);
	angs[2] = g_DrugAngles[GetRandomInt(0,100) % 20];	
	TeleportEntity(client, pos, angs, NULL_VECTOR);

	int clients[2];
	clients[0] = client;	

	Handle message = StartMessageEx(GetUserMessageId("Fade"), clients, 1);
	BfWriteShort(message, 255);
	BfWriteShort(message, 255);
	BfWriteShort(message, (0x0002));
	BfWriteByte(message, GetRandomInt(0,255));
	BfWriteByte(message, GetRandomInt(0,255));
	BfWriteByte(message, GetRandomInt(0,255));
	BfWriteByte(message, 128);
	EndMessage();

	return Plugin_Continue;
}

void KillDrug(int client)
{
	KillDrugTimer(client);

	float pos[3], angs[3];
	GetClientAbsOrigin(client, pos);
	GetClientEyeAngles(client, angs);
	angs[2] = 0.0;	
	TeleportEntity(client, pos, angs, NULL_VECTOR);	

	int clients[2];
	clients[0] = client;	

	Handle message = StartMessageEx(GetUserMessageId("Fade"), clients, 1);
	BfWriteShort(message, 1536);
	BfWriteShort(message, 1536);
	BfWriteShort(message, (0x0001 | 0x0010));
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	EndMessage();	
}

void KillDrugTimer(int client)
{
	delete g_DrugTimers[client];	
}

void KillAllDrugs()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_DrugTimers[i] != null)
		{
			if(IsClientInGame(i))
			{
				KillDrug(i);
			}
			else
			{
				KillDrugTimer(i);
			}
		}
	}
}

void Shake(int target, float duration)
{
	if(!IsClientInGame(target) || GetClientTeam(target) != 2 || !IsPlayerAlive(target)) return;

	Handle hBf = StartMessageOne("Shake", target);
	if(hBf)
	{
		BfWriteByte(hBf, 0);                
		BfWriteFloat(hBf, 16.0);            // shake magnitude/amplitude
		BfWriteFloat(hBf, 0.5);                // shake noise frequency
		BfWriteFloat(hBf, duration);                // shake lasts this long
		EndMessage();
	}
}

void StopShake(int client)
{
	Handle hBf = StartMessageOne("Shake", client);
	if(hBf)
	{
		BfWriteByte(hBf, 0);                
		BfWriteFloat(hBf, 0.0);            // shake magnitude/amplitude
		BfWriteFloat(hBf, 0.0);                // shake noise frequency
		BfWriteFloat(hBf, 0.0);                // shake lasts this long
		EndMessage();
	}
}
