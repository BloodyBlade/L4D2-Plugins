////////////////////////////////////////////////////////////////////////////
////////////////////////////// ``` ////////         ////////////////////////
//////////////////////////////   ////////   /////   ////////////////////////
/////////////////////////////   ////////   /////////////////////////////////
////////////////////////////   ////////   //      //////////////////////////
///////////////////////////   ////////    ////   ///////////////////////////
///////////////////////// ,,, ////////          ////////////////////////////
////////////////////////////////////////////////////////////////////////////
/////////////////////////  I N V I N C I B L E  ////////////////////////////
/////////////////////////////  G H O S T S  ////////////////////////////////
////////////////////////////////////////////////////////////////////////////
//																		  //
//  - Makes infected ghosts invincible (>,<).							  //
//																		  //
//  - This prevents them from being killed by drowning and fall damage.	  //
//																		  //
//  - It's not a huge problem, but it is annoying when it happens; you	  //
//    get a ghost on a ledge or an edge and just as you go to turn 		  //
//    around you fall to your death and have another 30s to wait xP.	  //
//																		  //
//  - With this plugin, any big environmental damage event to a ghost	  //
//    will just cause them to teleport back to the survivors without 	  //
//    getting killed.													  //
//																		  //
////////////////////////////////////////////////////////////////////////////
#pragma semicolon 1
#pragma newdecls required 

#include <sourcemod>

#define PLUGIN_VERSION "0.4"
#define CVAR_FLAGS FCVAR_NOTIFY
#define ZC_SMOKER	1
#define ZC_BOOMER	2
#define ZC_HUNTER	3
#define ZC_SPITTER	4
#define ZC_JOCKEY	5
#define ZC_CHARGER	6
#define ZC_TANK		8

int propinfoghost = 0, g_OldHealth[MAXPLAYERS + 1] = {0, ...};
bool g_bHooked = false, g_IsGhostBuffed[MAXPLAYERS + 1] = {false, ...}, g_IsSwitchedInf[MAXPLAYERS + 1] = {false, ...}, g_HasSpawnTimer[MAXPLAYERS + 1] = {false, ...}, g_IsGhosting[MAXPLAYERS + 1] = {false, ...};
Handle hResetGhostUse[MAXPLAYERS + 1] = {null, ...}, hCheckGhostsTimer[MAXPLAYERS + 1] = {null, ...}, hBuffGhostsTimer[MAXPLAYERS + 1] = {null, ...};
ConVar hEnable, hHunterHealth, hSmokerHealth, hBoomerHealth, hSpitterHealth, hChargerHealth, hJockeyHealth;

public Plugin myinfo = 
{
	name = "Invincible Ghosts",
	author = "extrospect(Edit. by BloodyBlade)",
	description = "Stops infected ghosts dying from fall damage and drowning etc.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=116198"
}

public void OnPluginStart()
{
    CreateConVar("l4d2_ig_ver", PLUGIN_VERSION, "Invincible Ghosts version", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
    hEnable = CreateConVar("l4d2_ig_enable", "1", "Enables this plugin.", CVAR_FLAGS, true, 0.0, true, 1.0);
    AutoExecConfig(true, "l4d2_ig");
    hEnable.AddChangeHook(OnConVarPluginOnChange);

    hHunterHealth = FindConVar("z_hunter_health");
    hSmokerHealth = FindConVar("z_gas_health");
    hBoomerHealth = FindConVar("z_exploding_health");
    hSpitterHealth = FindConVar("z_spitter_health");
    hChargerHealth = FindConVar("z_charger_health");
    hJockeyHealth = FindConVar("z_jockey_health");
    propinfoghost = FindSendPropInfo("CTerrorPlayer", "m_isGhost");
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void OnConVarPluginOnChange(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	IsAllowed();
}

void IsAllowed()
{
    bool bPluginOn = hEnable.BoolValue;
    if(!g_bHooked && bPluginOn)
    {
        g_bHooked = true;
        HookEvent("player_team", Events);
        HookEvent("player_hurt", Events, EventHookMode_Pre);
        HookEvent("player_death", Events, EventHookMode_Pre);
        HookEvent("player_spawn", Events);
        HookEvent("player_first_spawn", Events);
        HookEvent("ghost_spawn_time", Events);
    }
    else if(g_bHooked && !bPluginOn)
    {
        g_bHooked = false;
        UnhookEvent("player_team", Events);
        UnhookEvent("player_hurt", Events, EventHookMode_Pre);
        UnhookEvent("player_death", Events, EventHookMode_Pre);
        UnhookEvent("player_spawn", Events);
        UnhookEvent("player_first_spawn", Events);
        UnhookEvent("ghost_spawn_time", Events);
    }
}

Action Events(Event event, char[] name, bool dontBroadcast)
{
    if (strcmp(name, "player_team") == 0)
    {
        int client = GetClientOfUserId(event.GetInt("userid"));
        if(event.GetInt("team") == 3 && IsClientInGame(client) && !IsFakeClient(client))
        {
            DataPack switchPack;
            hCheckGhostsTimer[client] = CreateDataTimer(1.0, CheckGhost, switchPack);
            switchPack.WriteCell(client);
            switchPack.WriteFloat(1.0);		
            g_IsSwitchedInf[client] = true;
        }
    }
    else if(strcmp(name, "player_hurt") == 0)
    {
        int client = GetClientOfUserId(event.GetInt("userid"));
        if(!IsPlayerValid(client) || !IsPlayerSpawnGhost(client) || !g_IsGhostBuffed[client])
            return Plugin_Continue;
        
        char weapon[64] = "";
        event.GetString("weapon", weapon, sizeof(weapon));
        
        g_OldHealth[client] = GetClientHealth(client);
        
        if(StrEqual(weapon,""))
        {	
            ClientCommand(client, "+use");
        }

        hResetGhostUse[client] = CreateTimer(0.1, ResetGhostUse, client);
        g_IsGhostBuffed[client] = false;
    }
    else if (strcmp(name, "player_death") == 0)
    {
        int client = GetClientOfUserId(event.GetInt("userid"));
        if(!IsPlayerValid(client)) return Plugin_Continue;

        //If the dead client was a ghosting infected then start checking for them becoming a
        //ghost again after a delay which is based upon the # of players on the infected team.
        if(g_IsGhosting[client])
        {
            int infCount = GetInfectedCount();
            
            float delay = 0.0;

            if(infCount == 2)
            {
                delay = 4.0;
            }
            else if(infCount == 3)
            {
                delay = 6.0;
            }
            else if(infCount > 3)
            {
                delay = 8.0;
            }
            else
            {
                delay = 2.0;
            }
            
            CreateTimer(delay, DeadGhostSpawnTimeCheck, client);
        }
        
        g_IsGhosting[client] = false;
        g_IsGhostBuffed[client] = false;
        g_IsSwitchedInf[client] = false;
    }
    else if (strcmp(name, "player_spawn") == 0)
    {
        int client = GetClientOfUserId(event.GetInt("userid"));
        if(!IsPlayerValid(client)) return Plugin_Continue;
        
        if(IsPlayerSpawnGhost(client))
        {
            SetEntityHealth(client, 20000);
            g_IsGhostBuffed[client] = true;
            g_OldHealth[client] = GetClientHealth(client);
            g_IsGhosting[client] = true;
        }
        else
        {
            int class = GetEntProp(client,Prop_Send,"m_zombieClass");
            int health = 100;

            if(class == ZC_HUNTER)
            {
                health = GetConVarInt(hHunterHealth);
            }
            if(class == ZC_SMOKER)
            {
                health = GetConVarInt(hSmokerHealth);
            }
            if(class == ZC_BOOMER)
            {
                health = GetConVarInt(hBoomerHealth);
            }
            if(class == ZC_SPITTER)
            {
                health = GetConVarInt(hSpitterHealth);
            }
            if(class == ZC_CHARGER)
            {
                health = GetConVarInt(hChargerHealth);
            }
            if(class == ZC_JOCKEY)
            {
                health = GetConVarInt(hJockeyHealth);
            }
            if(class == ZC_TANK)
            {
                g_IsGhostBuffed[client] = false;
                g_IsGhosting[client] = false;
                
                return Plugin_Continue;
            }
                
            SetEntityHealth(client, health);

            g_IsGhostBuffed[client] = false;
            g_IsGhosting[client] = false;
        }
    }
    else if (strcmp(name, "player_first_spawn") == 0)
    {
        int client = GetClientOfUserId(event.GetInt("userid"));
        if(!IsPlayerValid(client) || !IsPlayerSpawnGhost(client))
            return Plugin_Continue;
        
        //Check if the client was already checking for ghosting due to switching to infected
        if(g_IsSwitchedInf[client])
        {
            //If the client has a ghost check coming cuz they swapped then kill the timer for 
            //it now that we know they won't be ghosting for X seconds 
            if (hCheckGhostsTimer[client] != null)
            {
                delete hCheckGhostsTimer[client];
            }
            //If the client has a ghost buff coming cuz they swapped then kill the timer for 
            //it now that we know they won't be ghosting for X seconds 
            if (hBuffGhostsTimer[client] != null)
            {
                delete hBuffGhostsTimer[client];
            }

            g_IsSwitchedInf[client] = false;
        }
        
        SetEntityHealth(client, 20000);
        g_IsGhostBuffed[client] = true;
        g_OldHealth[client] = GetClientHealth(client);
        
        g_IsGhosting[client] = true;
    }
    else if (strcmp(name, "ghost_spawn_time") == 0)
    {
        int client = GetClientOfUserId(event.GetInt("userid"));
        //Check if the client was already checking for ghosting due to switching to infected
        if(g_IsSwitchedInf[client])
        {
            //If the client has a ghost check coming cuz they swapped then kill the timer for 
            //it now that we know they won't be ghosting for X seconds 
            if (hCheckGhostsTimer[client] != null)
            {
                delete hCheckGhostsTimer[client];
            }
            //If the client has a ghost buff coming cuz they swapped then kill the timer for 
            //it now that we know they won't be ghosting for X seconds 
            if (hBuffGhostsTimer[client] != null)
            {
                delete hBuffGhostsTimer[client];
            }

            g_IsSwitchedInf[client] = false;
        }

        g_HasSpawnTimer[client] = true;

        if(!IsPlayerValid(client)) return Plugin_Continue;

        float tilSpawn = event.GetInt("spawntime") - 4.0;

        DataPack checkPack;
        hCheckGhostsTimer[client] = CreateDataTimer(tilSpawn, CheckGhost, checkPack);
        checkPack.WriteCell(client);
        checkPack.WriteFloat(0.25);
    }
    return Plugin_Continue;
}

//This starts a repeating timer which checks whether the client is a ghost yet
//and then buffs their hp to 20000 once they are.
Action CheckGhost(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = pack.ReadCell();
	float loopTime = pack.ReadFloat();
	hBuffGhostsTimer[client] = CreateTimer(loopTime, BuffGhost, client, TIMER_REPEAT);
	hCheckGhostsTimer[client] = null;
	return Plugin_Stop;
}

//This function is a repeating timer which checks whether the client is a ghost yet, if not
//then it carries on looping, otherwise it buff's their HP to 20k to make them 'invincible'
Action BuffGhost(Handle timer, int client)
{
	if(!IsPlayerValid(client))
	{
		hBuffGhostsTimer[client] = null;
		return Plugin_Stop;
	}
	else
	{
		if(IsPlayerSpawnGhost(client))
		{
			SetEntityHealth(client, 20000);
			g_IsGhostBuffed[client] = true;
			g_OldHealth[client] = GetClientHealth(client);
			
			if(g_IsSwitchedInf[client]) g_IsSwitchedInf[client] = false;
			if(g_HasSpawnTimer[client]) g_HasSpawnTimer[client] = false;
			g_IsGhosting[client] = true;
			hBuffGhostsTimer[client] = null;
			return Plugin_Stop;
		}
		else if(IsPlayerAlive(client))
		{
			hBuffGhostsTimer[client] = null;
			return Plugin_Stop;
		}
		else
		{
			return Plugin_Continue;
		}
	}
}

//This just resets the ghost's 20k hp and releases use so they only teleport once [or twice >,<]
Action ResetGhostUse(Handle timer, int client)
{
	ClientCommand(client,"-use");

	if(IsPlayerValid(client) && IsPlayerSpawnGhost(client))
	{
		SetEntityHealth(client,20000);
		g_IsGhostBuffed[client] = true;
		g_OldHealth[client] = GetClientHealth(client);
	}

	hResetGhostUse[client] = null;
	return Plugin_Stop;
}


//Gets the number of players currently on the infected team (both living and dead + including bots)
stock int GetInfectedCount()
{
	int count = 0, i = 1;
	while(i <= MaxClients)
	{
		if(IsClientInGame(i))
		{
			if(GetClientTeam(i) == 3)
			{
				count++;
			}
		}		
		i++;
	}
	return count;
}

//If the player to be checked is still valid then start the repeating timer to
//check if they're a ghost and buff them accordingly by initiating the checkghost timer
Action DeadGhostSpawnTimeCheck(Handle timer, int client)
{
	if(!IsPlayerValid(client) || g_HasSpawnTimer[client])
		return Plugin_Continue;
	
	DataPack deadPack;
	hCheckGhostsTimer[client] = CreateDataTimer(0.6, CheckGhost, deadPack);
	deadPack.WriteCell(client);
	deadPack.WriteFloat(0.4);
	
	return Plugin_Continue;
}

//Checks that the player is ingame, on infected and not a bot
stock bool IsPlayerValid(int client)
{
	return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 3;
}

//Checks if the player is currently a ghost
stock bool IsPlayerSpawnGhost(int client)
{
	return view_as<bool>(GetEntData(client, propinfoghost));
}

//Timer kills for OnClientDisconnect
public void OnClientDisconnect(int client)
{
	if(client > 0)
	{
		//If the client has a ghost check coming but has left then kill the timer for it
		if (hCheckGhostsTimer[client] != null)
		{
			delete hCheckGhostsTimer[client];
		}
		//If the client has a ghost buff coming but has left then kill the timer for it
		if (hBuffGhostsTimer[client] != null)
		{
			delete hBuffGhostsTimer[client];
		}
		//If the client needs use(-) applying but has left then kill the timer for it
		if (hResetGhostUse[client] != null)
		{
			delete hResetGhostUse[client];
		}
		g_OldHealth[client] = 0;
		g_IsGhostBuffed[client] = false;
		g_IsSwitchedInf[client] = false;
		g_HasSpawnTimer[client] = false;
	}
}
