#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_NOTIFY

static 	const 	float	BLOCKTIME 			= 0.3;
static 	const	char	PISTOLNETCLASS[]	= "CPistol";
bool bHooked = false, g_bProhibitClientUse[MAXPLAYERS + 1] = {false, ...};
ConVar hBlockPistolSpamEnabled;

public Plugin myinfo = 
{
	name = "Block Pistol Spam",
	author = "Mr. Zero(Edit. by BloodyBlade)",
	description = "Prevents people from mass spawning pistols by using an exploit",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=121483"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    if(GetEngineVersion() == Engine_Left4Dead2)
	{
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead 2\" game");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d2_blockpistolspam_version", PLUGIN_VERSION, "Block Pistol Spam Version", CVAR_FLAGS|FCVAR_DONTRECORD);
	hBlockPistolSpamEnabled = CreateConVar("l4d2_blockpistolspam_enable", "1", "Enable/Disable the plugin.", CVAR_FLAGS, true, 0.0, true, 1.0);
	AutoExecConfig(true, "l4d2_blockpistolspam");
	hBlockPistolSpamEnabled.AddChangeHook(ConVarAllowChanged);
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarAllowChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    IsAllowed();
}

void IsAllowed()
{
	bool bPluginOn = hBlockPistolSpamEnabled.BoolValue;
	if(bPluginOn && !bHooked)
	{
		bHooked = true;
		HookEvent("player_use", PlayerUse_Event);
	}
	else
	{
		bHooked = false;
		UnhookEvent("player_use", PlayerUse_Event);
	}
}

void PlayerUse_Event(Event event, const char[] name, bool dontBroadcast)
{
	char sBuffer[32];
	GetEntityNetClass(event.GetInt("targetid"), sBuffer, sizeof(sBuffer));
	if (StrEqual(PISTOLNETCLASS, sBuffer))
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		if(client > 0)
		{
			g_bProhibitClientUse[client] = true;
			CreateTimer(BLOCKTIME, BlockUse_Timer, client);
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (bHooked && g_bProhibitClientUse[client] && (buttons & IN_USE))
	{
		buttons = buttons^IN_USE;
	}
	return Plugin_Continue;
}

Action BlockUse_Timer(Handle timer, any client)
{
	g_bProhibitClientUse[client] = false;
	return Plugin_Stop;
}
