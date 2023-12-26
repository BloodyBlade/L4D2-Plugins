#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <colors>

ConVar PliginOnOff, cMaxLimit, cShowMessage;
int iMaxLimit;
bool bShowMessage;

public Plugin myinfo =
{
	name = "Auto Balance",
	author = "BloodyBlade",
	version = "1.0",
	url = "https://bloodsiworld.ru/"
};

public void OnPluginStart()
{
	PliginOnOff = CreateConVar("PluginOnOff", "1", "Plugin on/off", FCVAR_NOTIFY);
	cMaxLimit = CreateConVar("MaxLimit", "1", "Max disbalance limit", FCVAR_NOTIFY);
	cShowMessage = CreateConVar("ShowMessage", "1", "Show chat message about change team", FCVAR_NOTIFY);

	PliginOnOff.AddChangeHook(CvarPluginOn_Changed);
	cMaxLimit.AddChangeHook(Cvars_Changed);
	cShowMessage.AddChangeHook(Cvars_Changed);

	AutoExecConfig(true, "auto_balance");

	LoadTranslations("auto_balance.phrases");
}

public void OnConfigsExecuted()
{
    IsAllowed();
}

void IsAllowed()
{
    bool Allowed = PliginOnOff.BoolValue;
    if(Allowed)
    {
        Cvars();
        HookEvent("player_death", Event_Death);
    }
    else
    {
        UnhookEvent("player_death", Event_Death);
    }
}

void CvarPluginOn_Changed(ConVar cvar, char[] OldValue, char[] NewValue)
{
    IsAllowed();
}

void Cvars_Changed(ConVar cvar, char[] OldValue, char[] NewValue)
{
    Cvars();
}

void Cvars()
{
    iMaxLimit = cMaxLimit.IntValue;
    bShowMessage = cShowMessage.BoolValue;
}

void Event_Death(Event event, const char[] sName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(event.GetInt("userid"));
	int iTeam = GetClientTeam(iClient);
 	int ClientSurv, ClientInf;
 	for(int i = 1; i <= MaxClients; i++)
	{
		if(ValidClient(i)) 
		{
            switch(GetClientTeam(i))
            {
                case 2:
                {
            	    ClientSurv++;
                }
                case 3:
                {
            	    ClientInf++;
                }
            }
		}
	}

	int flags = GetUserFlagBits(iClient) & (ADMFLAG_ROOT|ADMFLAG_RESERVATION);
	if(ClientSurv > ClientInf)
	{
		if(ClientSurv - ClientInf > iMaxLimit && ValidClient(iClient) && iTeam == 2 && !flags)
		{
			FakeClientCommand(iClient, "jointeam 3");
			if(bShowMessage)
			{
			    CPrintToChat(iClient, "%T", "Infected", iClient);
			}
		}
	}
	else if(ClientSurv < ClientInf)
	{
		if(ClientInf - ClientSurv > iMaxLimit && ValidClient(iClient) && iTeam == 3 && !flags)
		{
			FakeClientCommand(iClient, "jointeam 2");
			if(bShowMessage)
			{
			    CPrintToChat(iClient, "%T", "Survivors", iClient);
			}
		}
	}
}

stock bool ValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client);
}
