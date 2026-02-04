#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1"
#define CVAR_FLAGS	   FCVAR_NOTIFY

public Plugin myinfo = 
{
	name = "[L4D2] Away for versus",
	author = "V10",
	description = "Left 4 Dead 2: Away for versus",
	version = PLUGIN_VERSION,
	url = "http://sourcemod.v10.name"
}

Handle g_hGoAwayFromKeyboard = null;
ConVar g_hCVEnable, g_hCVAnnounce;
bool bEnable = false, bAnnounce = false;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	if(GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2 game.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d2_away_version", PLUGIN_VERSION, "L4D2 Away for versus version", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
	g_hCVEnable = CreateConVar("l4d2_away_enable", "1", "Enable/Disable plugin", CVAR_FLAGS);
	g_hCVAnnounce = CreateConVar("l4d2_away_announce", "1", "Enable/Disable announce", CVAR_FLAGS);

	AutoExecConfig(true, "l4d2_away");

	g_hCVEnable.AddChangeHook(OnConVarsChanged);
	g_hCVAnnounce.AddChangeHook(OnConVarsChanged);

	RegConsoleCmd("sm_away", Away);

	GameData gConf = new GameData("l4d2_away");
	if(gConf != null)
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "CTerrorPlayer::GoAwayFromKeyboard");
		//PrepSDKCall_SetReturnInfo(SDKType_Bool,SDKPass_Plain);
		g_hGoAwayFromKeyboard = EndPrepSDKCall();
		if (g_hGoAwayFromKeyboard == null)
		{
			LogError("Can't get CTerrorPlayer::GoAwayFromKeyboard SDKCall!");
		}
		delete gConf;
	}
}

public void OnConfigsExecuted()
{
	OnConVarsChanged(null, "", "");
}

void OnConVarsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	bEnable = g_hCVEnable.BoolValue;
	bAnnounce = g_hCVAnnounce.BoolValue;
}

public void OnClientPutInServer(int client)
{
	if (bEnable && bAnnounce && client > 0)
	{
		CreateTimer(30.0, TimerAnnounce, client);
	}
}

Action TimerAnnounce(Handle timer, any client)
{
	if (bEnable && bAnnounce)
	{
		int iClient = GetClientOfUserId(client);
		if (iClient > 0 && IsClientInGame(iClient))
		{
			PrintToChat(iClient, "\x04[SM]\x03 Type !away if you need to go AFK.");
		}
	}
	return Plugin_Stop;
}

Action Away(int client, int args)
{
	if (bEnable && client > 0)
	{
		if(GetClientTeam(client) == 2)
		{
			SDKCall(g_hGoAwayFromKeyboard, client);
		}
		else
		{
			PrintToChat(client, "\x04[SM]\x03 Only survivors can use !away command.");
		}
	}
	return Plugin_Handled;
}
