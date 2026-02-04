#pragma semicolon 1
#define newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1.0"
#define CVAR_FLAGS FCVAR_NOTIFY

public Plugin myinfo = 
{
	name = "L4D Kill Enabler",
	author = "KawMAN(Rewritten by BloodyBlade)",
	description = "Enable kill command",
	version = PLUGIN_VERSION,
	url = "https://wsciekle.pl/, https://bloodsiworld.ru/"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if (engine != Engine_Left4Dead && engine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

ConVar g_Kill_Block_Mode;
int i_Kill_Block_Mode = 0;

public void OnPluginStart()
{
	RegConsoleCmd("sm_kill", KillMe_Cmd);
	RegConsoleCmd("sm_explode", KillMe_Cmd);
	CreateConVar("l4d_kill_block_version", PLUGIN_VERSION, "L4D Kill Enabler Plugin Version", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
	g_Kill_Block_Mode = CreateConVar("l4d_kill_block_mode", "3", "Kill Enabler Mode [0=Kill Disabled,1=Allow kill for all,2=Allow kill only for Infected, 3=Allow kill only for Infected without Tank]", CVAR_FLAGS, true, 0.0, true, 3.0);
	g_Kill_Block_Mode.AddChangeHook(ConVarsChanged);
	AutoExecConfig(true, "l4d_kill_block");
}

public void OnConfigsExecuted()
{
    ConVarsChanged(null, "", "");
}

void ConVarsChanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{
	i_Kill_Block_Mode = g_Kill_Block_Mode.IntValue;
}

Action KillMe_Cmd(int client, int args)
{
	if(i_Kill_Block_Mode > 0)
	{
		switch(i_Kill_Block_Mode)
		{
			case 1:
			{
				ForcePlayerSuicide(client);
			}
			case 2:
			{
				if (GetClientTeam(client) == 3)
				{
					ForcePlayerSuicide(client);
				}
				else
				{
					PrintToChat(client, "[SM] Kill command is blocked for your team");
				}
			}
			case 3:
			{
				if (GetClientTeam(client) == 3)
				{
					if(GetEntProp(client, Prop_Send, "m_zombieClass") != 8) 
					{
						ForcePlayerSuicide(client);
					}
					else
					{
						PrintToChat(client, "[SM] Kill command is blocked for Tank");
					}
				}
				else
				{
					PrintToChat(client, "[SM] Kill command is blocked for your team");
				}
			}
		}
	}
	return Plugin_Handled;
}
