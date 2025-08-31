#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_NOTIFY|FCVAR_SPONLY

public Plugin myinfo = 
{
	name = "[L4D] Infinite Reserve",
	author = "BloodyBlade",
	description = "Gives survivors an infinite reserve of ammo. They still have to reload, but they never have to worry about running out of ammo.",
	version = PLUGIN_VERSION,
	url = "https://bloodsiworld.ru"
}

bool bL4D2 = false;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if (engine == Engine_Left4Dead)
	{
		bL4D2 = false;
	}
	else if(engine == Engine_Left4Dead2)
	{
		bL4D2 = true;
	}
	else
	{
		strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead\" game series");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

//Special thanks: https://forums.alliedmods.net/showthread.php?t=96188

PluginData plugin;

enum struct PluginCvars
{
	ConVar hInfiniteReserveOn;
	ConVar hInfiniteReserveGunsOn;
	ConVar hInfiniteReservePipesOn;
	ConVar hInfiniteReserveMolotovsOn;
	ConVar hInfiniteReserveVomitsOn;
	ConVar hInfiniteReserveMedsOn;
	ConVar hInfiniteReservePillsOn;
	ConVar hInfiniteReserveAdrensOn;

	void Init()
	{
		CreateConVar("l4d_infinite_reserve_version", PLUGIN_VERSION, "[L4D] Infinite Reserve plugin version.", CVAR_FLAGS|FCVAR_DONTRECORD);
		this.hInfiniteReserveOn = CreateConVar("l4d_infinite_reserve_on", "1", "Enable/Disable plugin.", CVAR_FLAGS, true, 0.0, true, 1.0);
		this.hInfiniteReserveGunsOn = CreateConVar("l4d_infinite_reserve_guns", "1", "Enable/Disable the infinite ammo for guns.", CVAR_FLAGS, true, 0.0, true, 1.0);
		this.hInfiniteReservePipesOn = CreateConVar("l4d_infinite_reserve_pipebombs", "1", "Enable/Disable the infinite pipebombs.", CVAR_FLAGS, true, 0.0, true, 1.0);
		this.hInfiniteReserveMolotovsOn = CreateConVar("l4d_infinite_reserve_molotovs", "1", "Enable/Disable the infinite molotovs.", CVAR_FLAGS, true, 0.0, true, 1.0);
		this.hInfiniteReserveMedsOn = CreateConVar("l4d_infinite_reserve_medkits", "1", "Enable/Disable the infinite medkits.", CVAR_FLAGS, true, 0.0, true, 1.0);
		this.hInfiniteReservePillsOn = CreateConVar("l4d_infinite_reserve_pills", "1", "Enable/Disable the infinite pills.", CVAR_FLAGS, true, 0.0, true, 1.0);
		if(bL4D2)
		{
			this.hInfiniteReserveVomitsOn = CreateConVar("l4d_infinite_reserve_vomitjars", "0", "Enable/Disable the infinite vomitjars.", CVAR_FLAGS, true, 0.0, true, 1.0);
			this.hInfiniteReserveAdrensOn = CreateConVar("l4d_infinitere_serve_adrenalines", "1", "Enable/Disable the infinite adrenaline.", CVAR_FLAGS, true, 0.0, true, 1.0);
		}

		AutoExecConfig(true,"l4d_infinite_reserve");

		this.hInfiniteReserveOn.AddChangeHook(OnConVarEnableChanged);
		this.hInfiniteReserveGunsOn.AddChangeHook(OnConVarsChanged);
		this.hInfiniteReservePipesOn.AddChangeHook(OnConVarsChanged);
		this.hInfiniteReserveMolotovsOn.AddChangeHook(OnConVarsChanged);
		this.hInfiniteReserveMedsOn.AddChangeHook(OnConVarsChanged);
		this.hInfiniteReservePillsOn.AddChangeHook(OnConVarsChanged);
		if(bL4D2)
		{
			this.hInfiniteReserveVomitsOn.AddChangeHook(OnConVarsChanged);
			this.hInfiniteReserveAdrensOn.AddChangeHook(OnConVarsChanged);
		}
	}
}

enum struct PluginData
{
	PluginCvars cvars;
	bool bHooked;
	bool bPluginOn;
	bool bGuns;
	bool bPipeBombs;
	bool bMolotovs;
	bool bMedKits;
	bool bPills;
	bool bVomitJars;
	bool bAdrenalines;
	int iThrower;

	void Init()
	{
		this.cvars.Init();
		this.iThrower = FindSendPropInfo("CBaseGrenade", "m_hThrower");
	}

	void GetCvarValues()
	{
		this.bGuns = this.cvars.hInfiniteReserveGunsOn.BoolValue;
		this.bPipeBombs = this.cvars.hInfiniteReservePipesOn.BoolValue;
		this.bMolotovs = this.cvars.hInfiniteReserveMolotovsOn.BoolValue;
		this.bMedKits = this.cvars.hInfiniteReserveMedsOn.BoolValue;
		this.bPills = this.cvars.hInfiniteReservePillsOn.BoolValue;
		if(bL4D2)
		{
			this.bVomitJars = this.cvars.hInfiniteReserveVomitsOn.BoolValue;
			this.bAdrenalines = this.cvars.hInfiniteReserveAdrensOn.BoolValue;
		}
	}

	void IsAllowed()
	{
		this.bPluginOn = this.cvars.hInfiniteReserveOn.BoolValue;
		if(!this.bHooked && this.bPluginOn)
		{
			this.bHooked = true;
			HookEvent("adrenaline_used", Events);
			HookEvent("pills_used", Events);
			HookEvent("heal_success", Events);
		}
		else if(this.bHooked && !this.bPluginOn)
		{
			this.bHooked = false;
			UnhookEvent("adrenaline_used", Events);
			UnhookEvent("pills_used", Events);
			UnhookEvent("heal_success", Events);
		}
	}
}

public void OnPluginStart()
{	
	plugin.Init();
}

public void OnConfigsExecuted()
{
	plugin.IsAllowed();
	plugin.GetCvarValues();
}

void OnConVarEnableChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	plugin.IsAllowed();
}

void OnConVarsChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	plugin.GetCvarValues();
}

public void OnEntityCreated(int iEntity, const char[] sClassname)
{
	if(plugin.bHooked)
	{
		if(plugin.bGuns && StrContains(sClassname, "weapon_", false) != -1)
		{
			SDKHook(iEntity, SDKHook_ReloadPost, ReloadPost);
		}

		if (StrContains(sClassname, "_projectile") != -1)
		{
			if (plugin.bMolotovs || plugin.bPipeBombs || plugin.bVomitJars)
			{
				DataPack hPack;
				CreateDataTimer(0.3, OnSpawnProjectile, hPack);
				hPack.WriteCell(EntIndexToEntRef(iEntity));
				if (plugin.bMolotovs && StrEqual(sClassname, "molotov_projectile", false))
				{
					hPack.WriteString("weapon_molotov");
				}
				else if(plugin.bPipeBombs && StrEqual(sClassname, "pipe_bomb_projectile", false))
				{
					hPack.WriteString("weapon_pipe_bomb");
				}
				else if(bL4D2)
				{
					if(plugin.bVomitJars && StrEqual(sClassname, "vomitjar_projectile", false))
					{
						hPack.WriteString("weapon_vomitjar");
					}
					else
					{
						hPack.WriteString("weapon_none");
					}
				}
				else
				{
					hPack.WriteString("weapon_none");
				}
			}
		}
	}
}

void ReloadPost(int iWeapon, bool bSuccess)
{
	if(plugin.bHooked && plugin.bGuns && IsValidEntity(iWeapon) && bSuccess)
	{
		int iClient = GetEntPropEnt(iWeapon, Prop_Data, "m_hOwner");
		if(IsValidSurv(iClient))
		{
			GivePlayerItem(iClient, "ammo");
		}
	}
}

Action OnSpawnProjectile(Handle timer, DataPack pack)
{
	if(plugin.bHooked && (plugin.bMolotovs || plugin.bPipeBombs || plugin.bVomitJars))
	{
		int iEntity = EntRefToEntIndex(pack.ReadCell());
		if (iEntity != INVALID_ENT_REFERENCE && IsValidEntity(iEntity))
		{
			int iClient = GetEntDataEnt2(iEntity, plugin.iThrower);
			if(IsValidSurv(iClient))
			{
				char szBuffer[256];
				pack.ReadString(szBuffer, sizeof(szBuffer));
				if(!StrEqual(szBuffer, "weapon_none", false))
				{
					GivePlayerItem(iClient, szBuffer);
				}
			}
		}
	}
	return Plugin_Stop;
}

Action Events(Event event, char[] name, bool dontBroadcast)
{
    if(StrEqual(name, "heal_success", false))
    {
        int iClient = GetClientOfUserId(event.GetInt("userid"));
        if (plugin.bMedKits && IsValidSurv(iClient))
        {
            GivePlayerItem(iClient, "weapon_first_aid_kit");
        }
    }
    else if (StrEqual(name, "pills_used", false))
    {
        int iClient = GetClientOfUserId(event.GetInt("userid"));
        if (plugin.bPills && IsValidSurv(iClient))
        {
            GivePlayerItem(iClient, "weapon_pain_pills");
        }
    }
    else if(bL4D2)
    {
        if(StrEqual(name, "adrenaline_used", false))
        {
            int iClient = GetClientOfUserId(event.GetInt("userid"));
            if (plugin.bAdrenalines && IsValidSurv(iClient))
            {
                GivePlayerItem(iClient, "weapon_adrenaline");
            }
        }
    }
    return Plugin_Continue;
}

stock bool IsValidSurv(int client)
{
	return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
}
