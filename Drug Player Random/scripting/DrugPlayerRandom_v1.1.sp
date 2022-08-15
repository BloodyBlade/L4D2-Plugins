#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <colors>

#define CVAR_FLAGS	FCVAR_NOTIFY

ConVar g_hCvarDrugOn, g_hCvarRandomDrugChance, g_hCvarDrugMode, g_hCvarDrugTimerMode;
bool bCvarDrugOn, Adren[MAXPLAYERS + 1], Pills[MAXPLAYERS + 1];
int iCvarRandomDrugChance, iCvarDrugMode, iCvarDrugTimerMode, PlayerDrugged[MAXPLAYERS + 1];
Handle g_DrugTimers[MAXPLAYERS + 1], TimerDrug[MAXPLAYERS + 1], TimerDamage[MAXPLAYERS + 1];
float g_DrugAngles[20] = {0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 20.0, 15.0, 10.0, 5.0, 0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -20.0, -15.0, -10.0, -5.0};

public Plugin myinfo =
{
	name = "Drug Player Random",
	author = "BS/IW",
	description = "Drug Player Random",
	version = "1.1",
	url = "http://"
};

//Special thanks:
// funcommands plugin by SourceMod

public void OnPluginStart()
{
	LoadTranslations("DrugPlayerRandom.phrases");

	g_hCvarDrugOn = CreateConVar("RandomDrugChance", "1",	"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarRandomDrugChance = CreateConVar("RandomDrugChance", "5",	"Chance of drug player", CVAR_FLAGS );
	g_hCvarDrugMode = CreateConVar("DrugMode", "3",	"1 = Drug & Kill, 2 = Only Drug, 3 = Shake & Kill, 4 = Only Shake", CVAR_FLAGS );
	g_hCvarDrugTimerMode = CreateConVar("DrugTimerMode", "2",	"1 = Kill after 20 sec or only drug or shake(if DrugMode > 0), 2 = Take damage(if DrugMode = 1 or 3)", CVAR_FLAGS );

	bCvarDrugOn = g_hCvarDrugOn.BoolValue;
	iCvarRandomDrugChance = g_hCvarRandomDrugChance.IntValue;
	iCvarDrugMode = g_hCvarDrugMode.IntValue;
	iCvarDrugTimerMode = g_hCvarDrugTimerMode.IntValue;

	g_hCvarDrugOn.AddChangeHook(ConVarChanged_Switch);
	g_hCvarRandomDrugChance.AddChangeHook(ConVarChanged_Chance);
	g_hCvarDrugMode.AddChangeHook(ConVarChanged_Mode);
	g_hCvarDrugTimerMode.AddChangeHook(ConVarChanged_TimerMode);

	Events();
}

public void ConVarChanged_Switch(ConVar convar, const char[] oldValue, const char[] newValue)
{
	Events();
}

public void ConVarChanged_Chance(ConVar convar, const char[] oldValue, const char[] newValue)
{
	iCvarRandomDrugChance = g_hCvarRandomDrugChance.IntValue;
}

public void ConVarChanged_Mode(ConVar convar, const char[] oldValue, const char[] newValue)
{
	iCvarDrugMode = g_hCvarDrugMode.IntValue;
}

public void ConVarChanged_TimerMode(ConVar convar, const char[] oldValue, const char[] newValue)
{
	iCvarDrugTimerMode = g_hCvarDrugTimerMode.IntValue;
}

void Events()
{
	if(bCvarDrugOn)
	{
		HookEvent("pills_used",	Event_Pills, EventHookMode_Post);
		HookEvent("adrenaline_used", Event_Adren, EventHookMode_Post);
		HookEvent("heal_success",	Event_UnDrug, EventHookMode_Post);
		HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
		HookEvent("player_disconnect", Event_Disconnect, EventHookMode_Pre);
	}
	else
	{
		UnhookEvent("pills_used",	Event_Pills, EventHookMode_Post);
		UnhookEvent("adrenaline_used", Event_Adren, EventHookMode_Post);
		UnhookEvent("heal_success",	Event_UnDrug, EventHookMode_Post);
		UnhookEvent("round_end",	Event_RoundEnd, EventHookMode_Post);
		UnhookEvent("player_disconnect", Event_Disconnect, EventHookMode_Pre);
	}
}

public void OnClientPutInServer(int client)
{
	PlayerDrugged[client] = false;
	Adren[client] = false;
	Pills[client] = false;
}

public void Event_UnDrug(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client && IsClientInGame(client) )
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
			if(TimerDrug[client] != null)
			{
				delete TimerDrug[client];
			}
			if(TimerDamage[client] != null)
			{
				delete TimerDamage[client];
			}
		}
	}
}

public void StopShake(int client)
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

public void Event_Disconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
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
	if(TimerDrug[client] != null)
	{
		delete TimerDrug[client];
	}
	if(TimerDamage[client] != null)
	{
		delete TimerDamage[client];
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	KillAllDrugs();
	KillTimerDrug();
}

public void Event_Adren(Event event, const char[] name, bool dontBroadcast)
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

public void Event_Pills(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
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
		if(Adren[client]) CPrintToChatAll("%t", "Player %N let shit in their veins. Cure him or he will die!", client);
		else if(Pills[client]) CPrintToChatAll("%t", "Player %N took the tablets with drugs. Cure him or he will die!", client);
		if(iCvarDrugMode == 1 || iCvarDrugMode == 3)
		{
			if(iCvarDrugTimerMode == 1)
			{
				if(!TimerDrug[client])
				{
					TimerDrug[client] = CreateTimer(20.0, TimerKillDrug, client);
				}
			}
			else if(iCvarDrugTimerMode == 2)
			{
				if(!TimerDamage[client])
				{
					TimerDamage[client] = CreateTimer(1.0, TimerDamageDrug, client, TIMER_REPEAT);
				}
			}
		}
	}
}

public Action TimerKillDrug(Handle timer, int client)
{
	if(iCvarDrugMode == 1 || iCvarDrugMode == 3)
	{
		ForcePlayerSuicide(client);
		if(iCvarDrugMode == 3 || iCvarDrugMode == 4)
		{
			StopShake(client);
		}
	}
	else if (iCvarDrugMode == 2)
	{
		KillDrug(client);
	}

	Adren[client] = false;
	Pills[client] = false;
	PlayerDrugged[client] = false;
	TimerDrug[client] = null;
	return Plugin_Stop;
}

public Action TimerDamageDrug(Handle timer, int client)
{
	int iHealth = GetClientHealth(client) - 2;
	float fTempHealth = GetTempHealth(client) - 2.0;
	if(iHealth > 0 || fTempHealth > 0.0)
	{
		if(iHealth > 0)
		{
			SetEntProp(client, Prop_Send, "m_iHealth", iHealth);
		}

		if(fTempHealth > 0.0)
		{
			SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
			SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fTempHealth);
		}
	}
	else
	{
		StopShake(client);
		Adren[client] = false;
		Pills[client] = false;
		PlayerDrugged[client] = false;
		ForcePlayerSuicide(client);
		TimerDamage[client] = null;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

float GetTempHealth(int client)
{
	float fHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	fHealth -= (GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * FindConVar("pain_pills_decay_rate").FloatValue;
	return fHealth < 0.0 ? 0.0 : fHealth;
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
			if(TimerDrug[i] != null)
			{
				delete TimerDrug[i];
			}
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

void KillDrug(int client)
{
	KillDrugTimer(client);

	float angs[3];
	GetClientEyeAngles(client, angs);
	angs[2] = 0.0;
	TeleportEntity(client, NULL_VECTOR, angs, NULL_VECTOR);
}

void KillDrugTimer(int client)
{
	delete g_DrugTimers[client];	
}

int KillAllDrugs()
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

public Action Timer_Drug(Handle timer, any client)
{
	if (!IsClientInGame(client))
	{
		KillDrugTimer(client);
		return Plugin_Handled;
	}

	if (!IsPlayerAlive(client))
	{
		KillDrug(client);		
		return Plugin_Handled;
	}

	float angs[3];
	GetClientEyeAngles(client, angs);
	angs[2] = g_DrugAngles[GetRandomInt(0,100) % 20];
	TeleportEntity(client, NULL_VECTOR, angs, NULL_VECTOR);

	return Plugin_Handled;
}

public Action Shake(int target, float duration)
{
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
