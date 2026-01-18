#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <vip_core>

#define VERSION "1.1.0"
#define CVAR_FLAGS FCVAR_NOTIFY
#define VIP_SD	"ShowDamage"

public Plugin myinfo =
{
	name = "[VIP] Show Damage",
	author = "R1KO, vadrozh",
	description = "Показ урона VIP-игрокам",
	version = VERSION,
	url = "https://hlmod.ru"
};

ConVar hShowDamageOn, hShowDamageType;
bool bHooked = false, bShowDamageType = false;

public void OnPluginStart()
{
	CreateConVar("vip_show_damage_version", VERSION, "[VIP] Show Damage plugin version", CVAR_FLAGS|FCVAR_DONTRECORD);
	hShowDamageOn = CreateConVar("vip_show_damage_on", "1", "Enable/Disable plugin", CVAR_FLAGS);
	hShowDamageType = CreateConVar("vip_show_damage_type", "0", "0 = Center, 1 = Hint Text", CVAR_FLAGS);

	AutoExecConfig(true, "vip_show_damage");

	hShowDamageOn.AddChangeHook(OnConVarEnableChange);
	hShowDamageType.AddChangeHook(OnConVarsChanged);

	if(VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void OnConVarEnableChange(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	IsAllowed();
}

void OnConVarsChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	bShowDamageType = hShowDamageType.BoolValue;
}

void IsAllowed()
{
	bool bPluginOn = hShowDamageOn.BoolValue;
	if(!bHooked && bPluginOn)
	{
		bHooked = true;
		OnConVarsChanged(null, "", "");
		HookEventEx("player_hurt", Event_PlayerHurt);
	}
	else if(bHooked && !bPluginOn)
	{
		bHooked = false;
		UnhookEvent("player_hurt", Event_PlayerHurt);
	}
}

public void OnPluginEnd()
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterMe") == FeatureStatus_Available)
	{
		VIP_UnregisterMe();
	}
}

public void VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(VIP_SD, BOOL);
}

void Event_PlayerHurt(Event hEvent, const char[] name, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("attacker"));
	int iVictim = GetClientOfUserId(hEvent.GetInt("userid"));
	int iDmgHealth = hEvent.GetInt("dmg_health");
	if(IsValidClient(iClient) && IsValidClient(iVictim) && iClient != iVictim && VIP_IsClientVIP(iClient) && VIP_IsClientFeatureUse(iClient, VIP_SD))
	{
		if(!bShowDamageType)
		{
			PrintCenterText(iClient, "- %i HP", iDmgHealth);
		}
		else
		{
			PrintHintText(iClient, "- %i HP", iDmgHealth);
		}
	}
}

stock bool IsValidClient(int client) 
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}
