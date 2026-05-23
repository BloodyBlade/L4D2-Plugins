/*
 * vim: set ts=4 :
 * =============================================================================
 * Left 4 Dead Vote Guard
 * Guards against Player's Abusing the Voting System
 *
 * SourceMod (C)2004-2007 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.2"
#define CVAR_FLAGS FCVAR_NOTIFY

int g_VotesCalled[MAXPLAYERS + 1], iMaxVotes, iBanTime;
float g_LastVoteTime[MAXPLAYERS + 1], flTimeDelay;
/* CVARS */
ConVar cEnabled, cAdminsImmune, cVoteLimit, cVoteDelay, cBanTime, cAdvertise;
bool bHooked, bAdminsImmune, bAdvertise;

public Plugin myinfo = 
{
	name = "L4D Vote Guard",
	author = "Crimson(Edit. by BloodyBlade)",
	description = "Left 4 Dead Vote Features",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

public void OnPluginStart()
{
	CreateConVar("sm_voteguard_version", PLUGIN_VERSION, "L4D Vote Guard Version", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
	cEnabled = CreateConVar("sm_voteguard_enabled", "1", "Enable/Disable L4D Vote Guardian [0 = FALSE, 1 = TRUE]", CVAR_FLAGS, true, 0.0, true, 1.0);
	cAdminsImmune = CreateConVar("sm_voteguard_adminimmune", "1", "Enable/Disable Admin Immunity to Penalties [0 = FALSE, 1 = TRUE]", CVAR_FLAGS, true, 0.0, true, 1.0);
	cVoteLimit = CreateConVar("sm_voteguard_vlimit", "3", "Max Vote Calls Allowed [0 = NO LIMIT]", CVAR_FLAGS, true, 0.0);
	cVoteDelay = CreateConVar("sm_voteguard_vdelay", "60", "Delay before a player can call another Vote [0 = DISABLED]", CVAR_FLAGS, true, 0.0);
	cBanTime = CreateConVar("sm_voteguard_bantime", "10", "Duration of Ban [0 = KICKS PLAYER]", CVAR_FLAGS, true, 0.0);
	cAdvertise = CreateConVar("sm_voteguard_adverts", "1", "Enable/Disable L4D Vote Guardian to Advertise", CVAR_FLAGS, true, 0.0, true, 1.0);

	AutoExecConfig(true, "l4d_voteguard");
	LoadTranslations("l4d_voteguard.phrases");

	cEnabled.AddChangeHook(VoteGuardEnableConVarChanged);
	cAdminsImmune.AddChangeHook(VoteGuardConVarsChanged);
	cVoteLimit.AddChangeHook(VoteGuardConVarsChanged);
	cVoteDelay.AddChangeHook(VoteGuardConVarsChanged);
	cBanTime.AddChangeHook(VoteGuardConVarsChanged);
	cAdvertise.AddChangeHook(VoteGuardConVarsChanged);
}

public void OnMapStart()
{
	Reset();
}

public void OnMapEnd()
{
	Reset();
}

void Reset()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		g_VotesCalled[i] = 0;
		g_LastVoteTime[i] = 0.0;
	}
}

public void OnConfigsExecuted()
{
    IsAllowed();
}

void IsAllowed()
{
	bool bAllowVoteGuard = cEnabled.BoolValue;
	if(!bHooked && bAllowVoteGuard)
	{
		bHooked = true;
		VoteGuardConVarsChanged(cAdminsImmune, "", "");
		VoteGuardConVarsChanged(cVoteLimit, "", "");
		VoteGuardConVarsChanged(cVoteDelay, "", "");
		VoteGuardConVarsChanged(cBanTime, "", "");
		VoteGuardConVarsChanged(cAdvertise, "", "");
		HookEvent("player_disconnect", Event_PlayerDisconnect);
		AddCommandListener(Command_CallVote, "callvote");
	}
	else if(bHooked && !bAllowVoteGuard)
	{
		bHooked = false;
		UnhookEvent("player_disconnect", Event_PlayerDisconnect);
		RemoveCommandListener(Command_CallVote, "callvote");
		Reset();
	}
}

void VoteGuardEnableConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void VoteGuardConVarsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(convar == cAdminsImmune)
	{
		bAdminsImmune = convar.BoolValue;
	}
	else if(convar == cVoteLimit)
	{
		iMaxVotes = convar.IntValue;
	}
	else if(convar == cVoteDelay)
	{
		flTimeDelay = convar.FloatValue;
	}
	else if(convar == cBanTime)
	{
		iBanTime = convar.IntValue;
	}
	else if(convar == cAdvertise)
	{
		bAdvertise = convar.BoolValue;
	}
}

void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_VotesCalled[client] = 0;
	g_LastVoteTime[client] = 0.0;
}

Action Command_CallVote(int client, const char[] command, int args)
{
	if(!bHooked || client == 0)
	{
		return Plugin_Continue;
	}

	char sVoteType[32], sTarget[12];
	GetCmdArg(1, sVoteType, sizeof(sVoteType));
	GetCmdArg(2, sTarget, sizeof(sTarget));

	/* If the Callvote is a Kick, Check Immunity */
	if(strcmp(sVoteType, "kick") == 0)
	{
		int target = GetClientOfUserId(StringToInt(sTarget));
		if(target > 0)
		{
			if(IsAdmin(target))
			{
				char sKickerName[32];
				GetClientName(client, sKickerName, sizeof(sKickerName));
				/* Tell client they cant kick the admin */
				CPrintToChat(client, "%t", "CannotCall");
				/* Tell admin whose trying to kick them */
				CPrintToChat(target, "%t", "AttemptToKick", sKickerName);
				return Plugin_Handled;
			}
		}
	}

	/* If this player hasnt called any votes */
	if(g_VotesCalled[client] == 0)
	{
		g_LastVoteTime[client] = GetEngineTime();
		g_VotesCalled[client]++;

		if(bAdvertise)
		{
			CPrintToChatAll("%t", "VoteCalled", client, sVoteType);
		}
	}
	else if(g_LastVoteTime[client] <= (GetEngineTime() - flTimeDelay))
	{
		g_LastVoteTime[client] = GetEngineTime();

		/* If the plugin is enabled */
		if(bHooked)
		{
			/*If Client Has Exceeded Max Call Votes */
			if((g_VotesCalled[client] == iMaxVotes) && iMaxVotes != 0)
			{
				/* If the players not an admin */
				if(!IsAdmin(client))
				{
					if(IsClientConnected(client))
					{
						if(iBanTime == 0)
						{
							if(IsClientInGame(client))
							{
								char sName[MAX_NAME_LENGTH];
								GetClientName(client, sName, sizeof(sName));
								CPrintToChatAll("%t", "KickedForAbuse", sName);
								KickClient(client, "Kicked for Vote Abuse");
							}
						}
						else if(iBanTime > 0)
						{
							if(IsClientInGame(client))
							{
								char sName[MAX_NAME_LENGTH];
								GetClientName(client, sName, sizeof(sName));
								CPrintToChatAll("%t", "BannedForAbuse", sName, iBanTime);
								BanClient(client, iBanTime, BANFLAG_AUTO, "Banned", "Banned", _, client);
							}
						}
					}
				}
			}
			/*Warns Client upon reaching the Max Call Votes */
			else if(g_VotesCalled[client] == (iMaxVotes - 1))
			{
				CPrintToChat(client, "%t", "HaveReachedMaxVotes");	
				g_VotesCalled[client]++;
			}
			else
			{
				g_VotesCalled[client]++;
			}
		}
	}
	else
	{
		CPrintToChat(client, "%t", "\x04[SM] \x01You must wait %d Seconds before starting another Vote", RoundToNearest(flTimeDelay - (GetEngineTime() - g_LastVoteTime[client])));
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

/* Is Player Admin Check */
stock bool IsAdmin(int client)
{
	if(!bAdminsImmune || GetUserAdmin(client) == INVALID_ADMIN_ID)
	{
		return false;
	}
	return true;
}

stock void CPrintToChatAll(const char[] format, any ...) // print chat to all, but exclude one specified player
{
	static char buffer[192];
	for( int i = 1; i <= MaxClients; i++ )
	{
		if(IsClientInGame(i) && !IsFakeClient(i) )
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, sizeof(buffer), format, 3);
			ReplaceColor(buffer, sizeof(buffer));
			PrintToChat(i, "\x01%s", buffer);
		}
	}
}

stock void CPrintToChat(int client, const char[] format, any ...)
{
    static char buffer[192];
    SetGlobalTransTarget(client);
    VFormat(buffer, sizeof(buffer), format, 3);
    ReplaceColor(buffer, sizeof(buffer));
    PrintToChat(client, "\x01%s", buffer);
}

stock void ReplaceColor(char[] message, int maxLen)
{
    ReplaceString(message, maxLen, "{white}", "\x01", false);
    ReplaceString(message, maxLen, "{cyan}", "\x03", false);
    ReplaceString(message, maxLen, "{orange}", "\x04", false);
    ReplaceString(message, maxLen, "{green}", "\x05", false);
}
