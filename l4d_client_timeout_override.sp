#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_NOTIFY|FCVAR_SPONLY

public Plugin myinfo =
{
	name = "[L4D] Client timeout override",
	author = "djromero (SkyDavid)(Edit. by BloodyBlade)",
	description = "Overrides client's timeout to prevent disconnect on long map changes",
	version = PLUGIN_VERSION,
	url = "www.theskyclan.com"
}

ConVar h_timeout_enable, h_timeout_value;
bool bTimeOutEnable = false;
int iTimeOutValue = 0;

public void OnPluginStart()
{
	CreateConVar("l4d_client_timeout_override_version", PLUGIN_VERSION, "[L4D] Client timeout override plugin version", CVAR_FLAGS|FCVAR_DONTRECORD);
	h_timeout_enable = CreateConVar("l4d_client_timeout_enable", "1", "Enable/Disable plugin", CVAR_FLAGS, true, 0.0, true, 1.0);
	h_timeout_value = CreateConVar("l4d_client_timeout_value", "120", "Value to override client's timeout", CVAR_FLAGS, true, 0.0, true, 300.0);
	AutoExecConfig(true, "l4d_client_timeout");
	h_timeout_value.AddChangeHook(OnConVarsChanged);
}

public void OnConfigsExecuted()
{
	OnConVarsChanged(null, "", "");
}

void OnConVarsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	bTimeOutEnable = h_timeout_enable.BoolValue;
	iTimeOutValue = h_timeout_value.IntValue;
}

public void OnClientPutInServer(int client) 
{
	if(bTimeOutEnable && client > 0 && !IsFakeClient(client))
	{
		char ipaddr[24], cmd[100];
		GetClientIP(client, ipaddr, sizeof(ipaddr));
		if (!StrEqual(ipaddr, "loopback", false))
		{
			// We change the timeout
			Format (cmd, sizeof(cmd), "cl_timeout %i", iTimeOutValue);
			ClientCommand(client, cmd);
		}
	}
}
