/*
* No Witch Hunting
* 
* Set up:
* ===========================
* The witch. 
* What more is she than a common road block?
* 
* It is really a sob story. She need some fear put back into her.
* Even through in L4D2 she now can wander, it doesnt really help her. So.
*  I set out to find somehow to make her feared again or at least make the
*  survivor regret missing crown / strafe bullet hitting her.
* 
* This will make the survivors go black and white if they got incaped her
*  or instant kill!
* 
* "Fear me! /cries" - The Witch
* 
* Plugin Description:
* ===========================
* An attempt to put some fear back into the witch, survivors can go black
*  and white upon incap or be instant killed by the witch
* 
* Known Problems / Things to Notice:
* =====================================
* This is active on all gamemodes. As I'm really lazy and don't add a
*  gamemode check, may I recommend "Game Mode Config Loader"
*  (http://forums.alliedmods.net/showthread.php?t=93212) to disable
*  this plugin in coop/survival or what not.
* 
* Simply change l4d_nwh_incapaction to 0 upon coop and 
*  l4d_nwh_incapaction to 1/2 upon versus.
* 
* Changelog:
* ===========================
* Legend: 
*  + Added 
*  - Removed 
*  ~ Fixed or changed
* 
* Version 0.9
* -----------------
* Initial release
* 
* - Mr. Zero
*/

// ***********************************************************************
// PREPROCESSOR
// ***********************************************************************
#pragma semicolon 1
#pragma newdecls required
// ========================================================
// Includes
// ========================================================
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

// ***********************************************************************
// CONSTANTS
// ***********************************************************************
#define PLUGIN_VERSION "0.90"
#define CVAR_FLAGS FCVAR_NOTIFY

// ========================================================
// Plugin Info
// ========================================================
public Plugin myinfo = 
{
	name = "No Witch Hunting",
	author = "Mr. Zero(Edit. by BloodyBlade)",
	description = "An attempt to put some fear back into the witch, survivors can go black and white upon incap or be instant killed by the witch",
	version = PLUGIN_VERSION,
	url = "<- URL ->"
}
// ***********************************************************************
// VARIABLES
// ***********************************************************************
ConVar g_hWitchPluginOn, g_hWitchIncapAction, g_hSurvivorMaxIncapCount;
bool bHooked = false;
int g_iIncapAction = 0, g_iSurvivorMaxIncapCount = 2;

// ***********************************************************************
// FUNCTIONS
// ***********************************************************************
public void OnPluginStart()
{
	CreateConVar("l4d_nwh_version", PLUGIN_VERSION, "No Witch Hunting Version", CVAR_FLAGS|FCVAR_DONTRECORD);
	g_hWitchPluginOn = CreateConVar("l4d_nwh_enable", "1", "0 - Disable plugin, 1 - Enable plugin", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hWitchIncapAction = CreateConVar("l4d_nwh_incapaction", "1", "What action to take upon witch incapping a survivor. 0 - Disable plugin, 1 - Survivor becomes black and white, 2 - Instant kill the survivor", CVAR_FLAGS, true, 0.0, true, 2.0);

	AutoExecConfig(true, "NoWitchHunting");

	g_hWitchPluginOn.AddChangeHook(PluginEnableCvarChanged);
	g_hSurvivorMaxIncapCount = FindConVar("survivor_max_incapacitated_count");
	g_hSurvivorMaxIncapCount.AddChangeHook(OnConVarsChanged);
	g_hWitchIncapAction.AddChangeHook(OnConVarsChanged);
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void PluginEnableCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void OnConVarsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(convar == g_hSurvivorMaxIncapCount)
	{
		g_iSurvivorMaxIncapCount = g_hSurvivorMaxIncapCount.IntValue;
	}
	else if(convar == g_hWitchIncapAction)
	{
		g_iIncapAction = g_hWitchIncapAction.IntValue;
	}
}

void IsAllowed()
{
	bool bPluginEnable = g_hWitchPluginOn.BoolValue;
	if(!bHooked && bPluginEnable)
	{
		bHooked = true;
		OnConVarsChanged(g_hSurvivorMaxIncapCount, "", "");
		OnConVarsChanged(g_hWitchIncapAction, "", "");
		HookEvent("player_incapacitated_start", Event_WitchIncap);
	}
	else if(bHooked && !bPluginEnable)
	{
		bHooked = false;
		HookEvent("player_incapacitated_start", Event_WitchIncap);
	}
}

Action Event_WitchIncap(Event event, const char[] name, bool bDontBroadcast)
{
	if(g_iIncapAction > 0)
	{
		int type = event.GetInt("type");
		// Witch damage type: 4
		if(type == 4)
		{
			int client = GetClientOfUserId(event.GetInt("userid"));
			if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
			{
				if(g_iIncapAction == 1)
				{
					int count = GetEntProp(client, Prop_Send, "m_currentReviveCount");
					if(count <= g_iSurvivorMaxIncapCount)
					{
						SetEntProp(client, Prop_Send, "m_currentReviveCount", g_iSurvivorMaxIncapCount);
					}
				}
				else if(g_iIncapAction == 2)
				{
					int attacker = event.GetInt("attackerentid");
					if(attacker > 0)
					{
						SDKHooks_TakeDamage(client, attacker, attacker, 10000.0, type);
					}
				}
			}
		}
	}
	return Plugin_Continue;
}
