#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#tryinclude <vip_core>

#define PLUGIN_VERSION  "1.0"
#define CVAR_FLAGS FCVAR_NOTIFY
#define VIP_FLAG ADMFLAG_RESERVATION

ArrayList g_hVIPWeapons;
ConVar g_cvPluginEnabled;
bool g_bEnabled, g_bHasHook[MAXPLAYERS + 1];
float g_fLastMsgTime[MAXPLAYERS + 1];

#if defined _vip_core_included
bool g_bVipCoreLib, bLateload;
#endif

public Plugin myinfo =
{
	name        = "L4D2 VIP Weapon Restrict",
	author      = "BloodyBlade",
	description = "Restricts VIP-only weapons in Versus (VIP Core optional, fallback to ADMFLAG_RESERVATION)",
	version     = PLUGIN_VERSION,
	url         = ""
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	if(GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2 game.");
		return APLRes_SilentFailure;
	}

	#if defined _vip_core_included
	bLateload = late;
	#endif

	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d2_vip_weapon_restrict_version", PLUGIN_VERSION, "L4D2 VIP Weapon Restrict", CVAR_FLAGS|FCVAR_DONTRECORD);
	g_cvPluginEnabled = CreateConVar("l4d2_vip_weapon_restrict_enabled", "1", "Enable/Disable plugin", CVAR_FLAGS, true, 0.0, true, 1.0);

	AutoExecConfig(true, "l4d2_vip_weapon_restrict");
	g_cvPluginEnabled.AddChangeHook(OnConVarEnabledChanged);

	RegAdminCmd("sm_reload_vip_weapons", CmdReloadWeapons, ADMFLAG_CONFIG, "Reload VIP weapons list from config");

	#if defined _vip_core_included
	if(bLateload)
	{
		g_bVipCoreLib = LibraryExists("vip_core");
		if(g_bVipCoreLib)
		{
			PrintToServer("[VIP Restrict] VIP Core detected — using VIP checks.");
		}
		else
		{
			PrintToServer("[VIP Restrict] VIP Core NOT found — falling back to ADMFLAG_RESERVATION check.");
		}
	}
	#else
	PrintToServer("[VIP Restrict] VIP Core NOT found — falling back to ADMFLAG_RESERVATION check.");
	#endif
}

#if defined _vip_core_included
public void VIP_OnVIPLoaded()
{
	g_bVipCoreLib = true;
	PrintToServer("[VIP Restrict] VIP Core detected — using VIP checks.");
}

public void OnLibraryRemoved(const char[] name)
{
	if(strcmp(name, "vip_core") == 0)
	{
		g_bVipCoreLib = false;
		PrintToServer("[VIP Restrict] VIP Core has been removed — falling back to ADMFLAG_RESERVATION check.");
	}
}
#endif

public void OnConfigsExecuted()
{
	OnConVarEnabledChanged(g_cvPluginEnabled, "", "");
}

stock void OnConVarEnabledChanged(ConVar cv, const char[] old, const char[] neu)
{
	g_bEnabled = g_cvPluginEnabled.BoolValue;

	if(!g_bEnabled)
	{
		if(g_hVIPWeapons != null)
		{
			delete g_hVIPWeapons;
		}
		return;
	}

	g_hVIPWeapons = new ArrayList(64);
	LoadVIPWeaponsConfig();

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !g_bHasHook[i])
		{
			g_bHasHook[i] = true;
			SDKHook(i, SDKHook_WeaponCanUse, OnWeaponCanUse);
		}
	}
}

public void OnClientPutInServer(int client)
{
	if(!g_bEnabled || client == 0 || g_bHasHook[client])
	{
		return;
	}

	g_bHasHook[client] = true;
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

public void OnClientDisconnect(int client)
{
	if(client == 0)
	{
		return;
	}

	if(g_bHasHook[client])
	{
		g_bHasHook[client] = false;
	}

	g_fLastMsgTime[client] = 0.0;
}

stock bool IsClientVIP(int client)
{
	#if defined _vip_core_included
	if(g_bVipCoreLib)
	{
		return VIP_IsClientVIP(client);
	}
	#endif

	return (GetUserFlagBits(client) & VIP_FLAG) != 0;
}

stock Action OnWeaponCanUse(int client, int weapon)
{
	if(!g_bEnabled || !IsValidSurv(client))
	{
		return Plugin_Continue;
	}

	char weaponName[64];
	GetEntityClassname(weapon, weaponName, sizeof(weaponName));

	for(int i = 0; i < g_hVIPWeapons.Length; i++)
	{
		char storedName[64];
		g_hVIPWeapons.GetString(i, storedName, sizeof(storedName));

		if(StrEqual(weaponName, storedName, false))
		{
			if(IsClientVIP(client))
			{
				return Plugin_Continue;
			}

			float now = GetEngineTime();
			if(now - g_fLastMsgTime[client] >= 1.0)
			{
				PrintToChat(client, "\x04[VIP]\x01 Это оружие доступно только VIP-игрокам.");
				g_fLastMsgTime[client] = now;
			}

			DataPack dp = new DataPack();
			dp.WriteCell(GetClientUserId(client));
			dp.WriteCell(EntIndexToEntRef(weapon));
			RequestFrame(StripVIPWeapon, dp);

			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

stock void StripVIPWeapon(DataPack dp)
{
	if(!g_bEnabled)
	{
		delete dp;
		return;
	}

	dp.Reset();
	int client = GetClientOfUserId(dp.ReadCell());
	int weapon = EntRefToEntIndex(dp.ReadCell());
	delete dp;

	if(!IsValidSurv(client) || weapon == INVALID_ENT_REFERENCE)
	{
		return;
	}

	if(RemovePlayerItem(client, weapon))
	{
		RemoveEntity(weapon);

		for(int slot = 0; slot <= 4; slot++)
		{
			int slotWeapon = GetPlayerWeaponSlot(client, slot);
			if(slotWeapon != -1)
			{
				EquipPlayerWeapon(client, slotWeapon);
				return;
			}
		}
	}
}

stock void LoadVIPWeaponsConfig()
{
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/l4d2_vip_weapon_restrict/vip_weapons.txt");

	g_hVIPWeapons.Clear();

	File hFile = OpenFile(path, "r");
	if(hFile == null)
	{
		PrintToServer("[VIP Restrict] Config file not found: %s", path);
		PrintToServer("[VIP Restrict] Using empty VIP weapon list.");
		return;
	}

	char line[64];
	while(!hFile.EndOfFile())
	{
		if(!hFile.ReadLine(line, sizeof(line)))
		{
			break;
		}

		TrimString(line);

		if(line[0] == '\0' || line[0] == ';')
			continue;

		if(line[0] == '/' && line[1] == '/')
			continue;

		g_hVIPWeapons.PushString(line);
	}

	delete hFile;

	PrintToServer("[VIP Restrict] Loaded %d VIP weapons from config.", g_hVIPWeapons.Length);
}

stock Action CmdReloadWeapons(int client, int args)
{
	if(!g_bEnabled)
	{
		return Plugin_Handled;
	}

	LoadVIPWeaponsConfig();

	if(client == 0)
	{
		PrintToServer("[VIP Restrict] VIP weapons list reloaded. (%d weapons)", g_hVIPWeapons.Length);
	}
	else
	{
		PrintToChat(client, "\x04[VIP]\x01 Список VIP-оружия перезагружен (%d пушек).", g_hVIPWeapons.Length);
	}

	return Plugin_Handled;
}

stock bool IsValidSurv(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

public void OnPluginEnd()
{
	if(g_hVIPWeapons != null)
	{
		delete g_hVIPWeapons;
	}
}
