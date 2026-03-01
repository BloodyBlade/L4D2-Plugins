#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define PLUGIN_VERSION "1.0.2"
#define CVAR_FLAGS FCVAR_NOTIFY

bool bMapStart = false, bHooked = false;
float g_fSafeRoomArea[3];
ConVar g_Cvar_NoKitsEnable, g_Cvar_NoKitsModes, g_Cvar_NoKitsChange, hGameMode;
char ItemName[64], GameMode[64], GameInfo[64], EdictClassName[128];
float NearestMedkit[3], fLocation[3];
int iEntityCount = 0;

public Plugin myinfo = 
{
	name = "[L4D2] No Safe Room Medkits",
	author = "Crimson_Fox, Updated by alasfourom & BloodyBlade",
	description = "Replaces safe room first aid kits with pills.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1032403"
};

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

public void OnPluginStart()
{
	CreateConVar ("L4D_NoSafeRoomMedKits_version", PLUGIN_VERSION, "L4D NoSafeRoomMedKits" , CVAR_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
	g_Cvar_NoKitsEnable = CreateConVar("l4d_no_saferoom_medkits_enable", "1", "Enable NoSafreRoomMedKits Plugin [1 = Enable, 0 = Disable]", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_Cvar_NoKitsModes 	= CreateConVar("l4d_no_saferoom_medkits_mode", "versus,coop", "Add The Modes You Want To Enable This Plugin In It [Seperated by Comma (,) With No Spaces]", CVAR_FLAGS);
	g_Cvar_NoKitsChange = CreateConVar("l4d_no_saferoom_medkits_change", "weapon_pain_pills_spawn", "You Can Replace Med-Kits With Either [weapon_adrenaline_spawn] Or [weapon_pain_pills_spawn] While [Empty For No Items]", CVAR_FLAGS);

	AutoExecConfig(true, "L4D_NoSafeRoomMedKits");

	g_Cvar_NoKitsEnable.AddChangeHook(OnConVarEnableChanged);
	g_Cvar_NoKitsModes.AddChangeHook(OnConVarEnableChanged);
	g_Cvar_NoKitsChange.AddChangeHook(OnConVarsChanged);

	hGameMode = FindConVar("mp_gamemode");
}

public void OnMapStart()
{
	bMapStart = true;
}

public void OnMapEnd()
{
	bMapStart = false;
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void OnConVarEnableChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	IsAllowed();
}

void OnConVarsChanged(ConVar convar, const char[] oValue, const char[] nValue)
{
	g_Cvar_NoKitsChange.GetString(ItemName, sizeof(ItemName));
}

stock bool IsAllowedGameMode()
{
	g_Cvar_NoKitsModes.GetString(GameInfo, sizeof(GameInfo));
	hGameMode.GetString(GameMode, sizeof(GameMode));
	return StrContains(GameInfo, GameMode) != -1;
}

void IsAllowed()
{
	bool bPluginOn = g_Cvar_NoKitsEnable.BoolValue;
	OnConVarsChanged(null, "", "");
	if(!bHooked && bPluginOn && IsAllowedGameMode())
	{
		bHooked = true;
		HookEvent("round_start", Event_OnRoundStart, EventHookMode_PostNoCopy);
		TimerCheck();
	}
	else if(bHooked && (!bPluginOn || !IsAllowedGameMode()))
	{
		bHooked = false;
		UnhookEvent("round_start", Event_OnRoundStart, EventHookMode_PostNoCopy);
	}
}

void Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(bMapStart)
	{
		TimerCheck();
	}
}

void TimerCheck()
{
	CreateTimer(1.0, Timer_StartFiltering, TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_StartFiltering (Handle timer)
{
	if(bHooked)
	{
		Search_StartRoomArea();
		Replace_FirstAidKits();
	}
	return Plugin_Stop;
}

void Search_StartRoomArea()
{
	iEntityCount = GetEntityCount();
	
	for (int i = 0; i <= iEntityCount; i++)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, EdictClassName, sizeof(EdictClassName));
			if ((StrContains(EdictClassName, "prop_door_rotating_checkpoint", false) != -1) && (GetEntProp(i, Prop_Send, "m_bLocked") == 1))
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", fLocation);
				g_fSafeRoomArea = fLocation;
				return;
			}
		}
	}

	for (int i = 0; i <= iEntityCount; i++)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, EdictClassName, sizeof(EdictClassName));
			if (StrContains(EdictClassName, "info_survivor_position", false) != -1)
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", fLocation);
				g_fSafeRoomArea = fLocation;
				return;
			}
		}
	}
}

void Replace_FirstAidKits()
{
	iEntityCount = GetEntityCount();

	for (int i = 0; i <= iEntityCount; i++)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, EdictClassName, sizeof(EdictClassName));
			if (StrContains(EdictClassName, "weapon_first_aid_kit", false) != -1)
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", fLocation);
				
				if ((NearestMedkit[0] + NearestMedkit[1] + NearestMedkit[2]) == 0.0)
				{
					NearestMedkit = fLocation;
					continue;
				}
				if (GetVectorDistance(g_fSafeRoomArea, fLocation, false) < GetVectorDistance(g_fSafeRoomArea, NearestMedkit, false)) NearestMedkit = fLocation;
			}
		}
	}

	for (int i = 0; i <= iEntityCount; i++)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, EdictClassName, sizeof(EdictClassName));
			if (StrContains(EdictClassName, "weapon_first_aid_kit", false) != -1)
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", fLocation);
				if (GetVectorDistance(NearestMedkit, fLocation, false) < 400)
				{
					Format(ItemName, sizeof(ItemName), "%s", ItemName);
					
					int index = CreateEntityByName(ItemName);
					if (index != -1)
					{
						float Angle[3];
						GetEntPropVector(i, Prop_Send, "m_angRotation", Angle);
						TeleportEntity(index, fLocation, Angle, NULL_VECTOR);
						DispatchSpawn(index);
					}				
					AcceptEntityInput(i, "Kill");
				}
			}
		}
	}
}
