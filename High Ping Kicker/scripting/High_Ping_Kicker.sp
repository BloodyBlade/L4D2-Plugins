#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <clientprefs>
#include <vip_core>
#include <colors>

#define VERSION "1.0"
#define CVAR_FLAGS FCVAR_NOTIFY

ConVar  hPluginOn, hMaxPing, hCheckRate, hMaxWarnings, hImmunityFlag;
int     iMaxWarnings = 0, iMaxPing = 0, iMaxChecks[MAXPLAYERS + 1] = {0, ...}, TotalPing[MAXPLAYERS + 1] = {0, ...}, g_CI[MAXPLAYERS + 1] = {0, ...};
static 	Cookie hPingImmunityCookie;
Handle	hCheckTimer = null;
bool 	MapStart = false, Hook = false;
float 	fCheckRate = 0.0;
char	CheckImmunity[8], sSteamId[32], Flag[16], ClientCmdRateString[32];

public Plugin myinfo =
{
	name = "High Ping Kicker",
	author = "BS/IW",
	description = "Kick players for high ping",
	version = VERSION,
	url = ""
};

public void OnPluginStart()
{
	LoadTranslations("High_Ping_Kicker.phrases");
	RegConsoleCmd("sm_protectping", HighPingImmunity);
	CreateConVar("HighPingKicker_version", VERSION, "Version of High Ping Kicker", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
	hPluginOn = CreateConVar("sm_plugin_on", "1", "On/Off kick the players for high ping", CVAR_FLAGS);
	hMaxPing = CreateConVar("sm_maxping", "350", "The maximum ping of the player to kick for high ping", CVAR_FLAGS);
	hCheckRate = CreateConVar("sm_checkrate", "6.0", "Period in seconds when rate is checked", CVAR_FLAGS);
	hMaxWarnings = CreateConVar("sm_maxwarnings", "15", "Max warnings before kick the player for high ping", CVAR_FLAGS);
	hImmunityFlag = CreateConVar("sm_ping_immunityflag", "a", "Admin flag used to grant immunity to all ping checking/kicking", CVAR_FLAGS);
	hPingImmunityCookie = new Cookie("HighPingImmunity", "HighPingImmunity", CookieAccess_Public);

	hPluginOn.AddChangeHook(ConVarChange_Allow);
	hMaxPing.AddChangeHook(ConVarsChange);
	hCheckRate.AddChangeHook(ConVarChangeInterval);
	hMaxWarnings.AddChangeHook(ConVarsChange);
	hImmunityFlag.AddChangeHook(ConVarsChange);

	AutoExecConfig(true, "High_Ping_Kicker");

	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			if(AreClientCookiesCached(client)) OnClientCookiesCached(client);
			else g_CI[client] = 0;
		}
	}
}

public void OnMapStart()
{
    MapStart = true;
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarChange_Allow(ConVar convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void ConVarsChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	iMaxPing = hMaxPing.IntValue;
	iMaxWarnings = hMaxWarnings.IntValue;
	hImmunityFlag.GetString(Flag, sizeof(Flag));
}

void ConVarChangeInterval(ConVar convar, const char[] oldValue, const char[] newValue)
{
	fCheckRate = hCheckRate.FloatValue;
	if(hCheckTimer != null) delete hCheckTimer;
	hCheckTimer = CreateTimer(fCheckRate, Timer_CheckPing, _, TIMER_REPEAT);
}

void IsAllowed()
{
	bool hPluginOn = hPluginOn.BoolValue;

	if(hPluginOn && !Hook)
	{
		Hook = true;
		GetCvars();
		HookEvents();
	}
	else if(!hPluginOn && Hook)
	{
		Hook = false;
		HookEvents();
	}
}

void HookEvents()
{
	if(Hook)
	{
	    fCheckRate = hCheckRate.FloatValue;
	    HookEvent("round_start", RoundStart);
	    HookEvent("player_disconnect", PlayerDisconnect);
	    hCheckTimer = CreateTimer(fCheckRate, Timer_CheckPing, _, TIMER_REPEAT);
	}
	else
	{
		UnhookEvent("round_start", RoundStart);
		UnhookEvent("player_disconnect", PlayerDisconnect);
		delete hCheckTimer;
	}
}

public void OnClientPutInServer(int client)
{
	if(Hook && !IsFakeClient(client))
	{
		iMaxChecks[client] = 0;
	}
}

public void OnClientDisconnect(int client)
{
	if(Hook && !IsFakeClient(client))
	{
		iMaxChecks[client] = 0;
	}
}

public void OnClientCookiesCached(int client)
{
    if(Hook)
	{
		hPingImmunityCookie.Get(client, CheckImmunity, sizeof(CheckImmunity));
		if(StringToInt(CheckImmunity) == 0) g_CI[client] = 0;
		else g_CI[client] = StringToInt(CheckImmunity);
	}
}

void RoundStart(Event event, char[] name, bool dontBroadcast)
{
    if(MapStart)
    {
        for (int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i))
			{
				iMaxChecks[i] = 0;
			}
		}
    }
}

Action HighPingImmunity(int client, int args)
{
    if(g_CI[client] == 0)
    {
        hPingImmunityCookie.Set(client, "1");
        CPrintToChat(client, "%t", "Protected");
        GetClientAuthId(client, AuthId_Steam2, sSteamId, sizeof(sSteamId));
        LogToFile("addons/sourcemod/logs/HighPingImmunity.log", "Player %N <%s> protected himself from a kick for a high ping", client, sSteamId);
    }
}

Action Timer_CheckPing(Handle timer)
{
	for(int i = 1; i <= MaxClients; i++)
	{
	    if(IsClientInGame(i) && !IsFakeClient(i))
		{
			int flags = GetUserFlagBits(i) & (ReadFlagString(Flag) | ADMFLAG_ROOT);
			float ClientPing = GetClientAvgLatency(i, NetFlow_Outgoing);
			float TickRate = GetTickInterval();
			GetClientInfo(i, "cl_cmdrate", ClientCmdRateString, sizeof(ClientCmdRateString));
			int ClientCmdRate = StringToInt(ClientCmdRateString);
			if(ClientCmdRate < 20) ClientCmdRate = 20;
			ClientPing -= ((0.5 / ClientCmdRate) + (TickRate * 1.0));
			ClientPing -= (TickRate * 0.5);
			ClientPing *= 1000.0;
			TotalPing[i] = RoundToZero(ClientPing);

			if(TotalPing[i] > iMaxPing && g_CI[i] == 0 && !flags && !VIP_IsClientVIP(i))
			{
				iMaxChecks[i]++;
				if(iMaxChecks[i] > iMaxWarnings) KickClient(i, "%t", "AdvertHighMax", TotalPing[i], iMaxPing);
				else CPrintToChat(i, "%t", "AdvertMax", TotalPing[i], iMaxPing);
			}
			else if(iMaxChecks[i] > 0)
			{
				iMaxChecks[i]--;
			}
		}
	}
	return Plugin_Continue;
}

Action PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client > 0 && !IsFakeClient(client))
	{
		if(AreClientCookiesCached(client))
		{
			Format(CheckImmunity, sizeof(CheckImmunity), "%i", g_CI[client]);
			hPingImmunityCookie.Set(client, CheckImmunity);
		}
	}
	return Plugin_Continue;
}

public void OnMapEnd()
{
    MapStart = false;
    if(hCheckTimer != null)
	{
		delete hCheckTimer;
	}
}

public void OnPluginEnd()
{
    Hook = false;
    HookEvents();
}
