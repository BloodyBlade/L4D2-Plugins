#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_AUTHOR "DeathChaos25"
#define PLUGIN_VERSION "1.1"

#define GRENADE_LAUNCHER	"models/w_models/weapons/w_grenade_launcher.mdl"
#define M60	                "models/w_models/weapons/w_m60.mdl"

static ArrayList ShouldPickUp = null;
static const int GRENADE_LAUNCHER_OFFSET_IAMMO = 68;

char sWeapons[15][] = 
{
	"models/w_models/weapons/w_shotgun.mdl", 
	"models/w_models/weapons/w_autoshot_m4super.mdl", 
	"models/w_models/weapons/w_smg_uzi.mdl", 
	"models/w_models/weapons/w_rifle_m16a2.mdl", 
	"models/w_models/weapons/w_smg_a.mdl", 
	"models/w_models/weapons/w_pumpshotgun_a.mdl", 
	"models/w_models/weapons/w_desert_rifle.mdl", 
	"models/w_models/weapons/w_shotgun_spas.mdl", 
	"models/w_models/weapons/w_rifle_ak47.mdl", 
	"models/w_models/weapons/w_smg_mp5.mdl", 
	"models/w_models/weapons/w_rifle_sg552.mdl", 
	"models/w_models/weapons/w_sniper_mini14.mdl", 
	"models/w_models/weapons/w_sniper_military.mdl", 
	"models/w_models/weapons/w_sniper_awp.mdl", 
	"models/w_models/weapons/w_sniper_scout.mdl"
};

char ModelName[128], Classname[128];
float Origin[3], TOrigin[3], distance;

public Plugin myinfo = 
{
	name = "[L4D2] Bots Pickup T3s", 
	author = PLUGIN_AUTHOR, 
	description = "Allows bots to use Tier 3 guns (Grenade Launchers and M60s)", 
	version = PLUGIN_VERSION, 
	url = "https://forums.alliedmods.net/showthread.php?t=262276"
};

public void OnPluginStart()
{
	CreateConVar("sm_tier3_bots_version", PLUGIN_VERSION, "[L4D2] Tier 3 using bots Version", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);
	ShouldPickUp = new ArrayList();
	CreateTimer(5.0, CheckForWeapons, _, TIMER_REPEAT);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (entity > 0 && entity <= 2048 && classname[0] == 'w')
	{
	    CreateTimer(2.0, CheckEntityForGrab, entity);
	}
}

Action CheckForWeapons(Handle Timer)
{
    // trying to account for late loading and unexpected
    // or unreported weapons (stripper created weapons dont seem to fire OnEntityCreated)
    if (IsServerProcessing())
    {
    	for (int entity = 0; entity < 2048; entity++)
    	{
    		if (IsValidEntity(entity))
    		{
        		GetEntPropString(entity, Prop_Data, "m_ModelName", ModelName, 128);
        		GetEntityClassname(entity, Classname, sizeof(Classname));
        		if (StrEqual(ModelName, GRENADE_LAUNCHER, false) || StrEqual(ModelName, M60, false)
        			 || StrEqual(Classname, "weapon_rifle_m60_spawn", false)
        			 || StrEqual(Classname, "weapon_rifle_m60", false)
        			 || StrEqual(Classname, "weapon_grenade_launcher_spawn", false)
        			 || StrEqual(Classname, "weapon_grenade_launcher", false))
        		{
        			if (!IsT3Owned(entity))
        			{
        				for (int i = 0; i <= ShouldPickUp.Length - 1; i++)
        				{
        					if (entity == ShouldPickUp.Get(i))
        					{
        						return Plugin_Continue;
        					}
        					else if (!IsValidEntity(ShouldPickUp.Get(i)))
        					{
        						ShouldPickUp.Erase(i);
        					}
        				}
        				ShouldPickUp.Push(entity);
        			}
        		}
    		}
    	}
    }
    return Plugin_Continue;
}

Action CheckEntityForGrab(Handle timer, any entity)
{
	if (IsValidEntity(entity) && ShouldPickUp != null)
	{
		GetEntPropString(entity, Prop_Data, "m_ModelName", ModelName, 128);
		GetEntityClassname(entity, Classname, sizeof(Classname));
		if (StrEqual(ModelName, GRENADE_LAUNCHER, false) || StrEqual(ModelName, M60, false)
			 || StrEqual(Classname, "weapon_rifle_m60_spawn", false)
			 || StrEqual(Classname, "weapon_rifle_m60", false)
			 || StrEqual(Classname, "weapon_grenade_launcher_spawn", false)
			 || StrEqual(Classname, "weapon_grenade_launcher", false))
		{
			//PrintToChatAll("Weapon %s added to array!", modelname);
			ShouldPickUp.Push(entity);
		}
	}
	return Plugin_Stop;
}

public void OnEntityDestroyed(int entity)
{
    if (entity > 0 && entity <= 2048)
    {
    	if (ShouldPickUp != null)
    	{
    		for (int i = 0; i <= ShouldPickUp.Length - 1; i++)
    		{
    			if (entity == ShouldPickUp.Get(i))
    			{
    				ShouldPickUp.Erase(i);
    			}
    		}
    	}
    }
}

public Action L4D2_OnFindScavengeItem(int client, int &item)
{
	if (!item)
	{
		if (ShouldPickUp != null)
		{
			for (int i = 0; i <= ShouldPickUp.Length - 1; i++)
			{
				if(!IsValidEdict(i))
				{
					ShouldPickUp.Erase(i);
					continue;
				}
				GetEntPropVector(ShouldPickUp.Get(i), Prop_Send, "m_vecOrigin", Origin);
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
				distance = GetVectorDistance(TOrigin, Origin);
				if (distance < 300)
				{
					item = ShouldPickUp.Get(i);
					return Plugin_Changed;
				}
			}
		}
	}
	else if (item > 0)
	{
		if (IsValidEdict(GetPlayerWeaponSlot(client, 0)))
		{
			int Primary = GetPlayerWeaponSlot(client, 0);
			GetEdictClassname(Primary, Classname, sizeof(Classname));

			if (StrEqual(Classname, "weapon_rifle_m60"))
			{
				GetEntPropString(item, Prop_Data, "m_ModelName", ModelName, 128);
				int clip = GetEntProp(Primary, Prop_Send, "m_iClip1");
				int iPrimType = GetEntProp(Primary, Prop_Send, "m_iPrimaryAmmoType");
				int ammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, iPrimType);

				for (int i = 0; i <= 14; i++)
				{
					if (StrEqual(ModelName, sWeapons[i]) && (ammo + clip) > 0)
					{
						return Plugin_Handled;
					}
				}
			}
			else if (StrEqual(Classname, "weapon_grenade_launcher"))
			{
				int iAmmoOffset = FindDataMapInfo(client, "m_iAmmo");
				int GLAmmo = GetEntData(client, iAmmoOffset + GRENADE_LAUNCHER_OFFSET_IAMMO);
				if (GLAmmo != 0)
				{
					GetEntPropString(item, Prop_Data, "m_ModelName", ModelName, 128);
					for (int i = 0; i <= 14; i++)
					{
						if (StrEqual(ModelName, sWeapons[i]) && GLAmmo < 0)
						{
							return Plugin_Handled;
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

stock void GetSafeEntityName(int entity, char[] TheName, int TheNameSize)
{
	if (entity > 0 && IsValidEntity(entity))
	{
		GetEntityClassname(entity, TheName, TheNameSize);
	}
	else
	{
		strcopy(TheName, TheNameSize, "Invalid");
	}
}

stock bool IsT3Owned(int weapon)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			if (GetPlayerWeaponSlot(i, 0) == weapon)
			{
				return true;
			}
		}
	}
	return false;
}

public void OnMapEnd()
{
	ShouldPickUp.Clear();
}

public void OnPluginEnd()
{
	delete ShouldPickUp;
}
