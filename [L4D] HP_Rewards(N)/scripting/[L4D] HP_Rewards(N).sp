#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <left4dhooks>
#include <colors>

#define PLUGIN_VERSION "2.1"
#define CVAR_FLAGS FCVAR_NOTIFY
#define SOUND_HEARTBEAT	"player/heartbeatloop.wav"

public Plugin myinfo =
{
	name = "[L4D & L4D2] HP Rewards(Extended)",
	author = "cravenge(Edit. by BloodyBlade)",
	description = "Grants Full Health After Killing Tanks And Witches, Additional Health For Killing SI.",
	version = PLUGIN_VERSION,
	url = ""
}

bool IsL4D2 = false;
int zClassTank = 5;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if (engine == Engine_Left4Dead)
	{
		IsL4D2 = false;
		zClassTank = 5;
	}
	else if(engine == Engine_Left4Dead2)
	{
		IsL4D2 = true;
		zClassTank = 8;
	}
	else
	{
		strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead 2\" game");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

PluginData plugin;

enum struct PluginCvars
{
	ConVar hHRPluginOn;
	ConVar hHRFirst;
	ConVar hHRSecond;
	ConVar hHRThird;
	ConVar hHRSI;
	ConVar hHRCI;
	ConVar hHRCIHP;
	ConVar hHRHS;
	ConVar hHRHSHP;
	ConVar hHRMax;
	ConVar hHRDistance;
	ConVar hHRNotifications;
	ConVar hHRTank;
	ConVar hHRWitch;
	ConVar hHRRemoveBW;
	ConVar hHRRemoveIncaps;

	void Init()
	{
		CreateConVar("l4d_hp_rewards_version", PLUGIN_VERSION, "[L4D & L4D2] HP Rewards(Extended) plugin version", CVAR_FLAGS|FCVAR_DONTRECORD);
		this.hHRPluginOn = CreateConVar("l4d_hp_rewards_on", "1", "Plugin On/Off", CVAR_FLAGS);
		this.hHRFirst = CreateConVar("l4d_hp_rewards_first", "2", "Rewarded HP For Killing Boomers And Spitters", CVAR_FLAGS);
		this.hHRSecond = CreateConVar("l4d_hp_rewards_second", "3", "Rewarded HP For Killing Smokers And Jockeys");
		this.hHRThird = CreateConVar("l4d_hp_rewards_third", "5", "Rewarded HP For Killing Hunters And Chargers");
		this.hHRSI = CreateConVar("l4d_hp_rewards_si", "1", "Enable/Disable Rewarded HP For Killing Special Infected", CVAR_FLAGS);
		this.hHRCI = CreateConVar("l4d_hp_rewards_ci", "1", "Enable/Disable Rewarded HP For Killing Common Infected", CVAR_FLAGS);
		this.hHRCIHP = CreateConVar("l4d_hp_rewards_ci_hp", "1", "Rewarded HP For Killing Common Infected", CVAR_FLAGS);
		this.hHRHS = CreateConVar("l4d_hp_rewards_headshot", "1", "Enable/Disable Rewarded HP For Headshot", CVAR_FLAGS);
		this.hHRHSHP = CreateConVar("l4d_hp_rewards_headshot_hp", "1", "Rewarded HP For Headshot", CVAR_FLAGS);
		this.hHRMax = CreateConVar("l4d_hp_rewards_max", "150", "Max HP Limit(-1 = Inlimit, > 0 = max value)", CVAR_FLAGS);
		this.hHRDistance = CreateConVar("l4d_hp_rewards_distance", "1", "Enable/Disable Distance Calculations", CVAR_FLAGS);
		this.hHRNotifications = CreateConVar("l4d_hp_rewards_notify", "1", "Notifications Mode: 0=Center Text, 1=Hint Box", CVAR_FLAGS);
		this.hHRTank = CreateConVar("l4d_hp_rewards_tank", "1", "Enable/Disable Tank Rewards", CVAR_FLAGS);
		this.hHRWitch = CreateConVar("l4d_hp_rewards_witch", "1", "Enable/Disable Witch Rewards", CVAR_FLAGS);
		this.hHRRemoveBW = CreateConVar("l4d_hp_rewards_remove_bw", "1", "Remove Black & White?", CVAR_FLAGS);
		this.hHRRemoveIncaps = CreateConVar("l4d_hp_rewards_remove_incaps", "1", "Remove incaps?", CVAR_FLAGS);

		AutoExecConfig(true, "hp_Awards");

		this.hHRPluginOn.AddChangeHook(HRConVarPluginOnChanged);
		this.hHRFirst.AddChangeHook(HRConfigsChanged);
		this.hHRSecond.AddChangeHook(HRConfigsChanged);
		this.hHRThird.AddChangeHook(HRConfigsChanged);
		this.hHRSI.AddChangeHook(HRConfigsChanged);
		this.hHRCI.AddChangeHook(HRConfigsChanged);
		this.hHRCIHP.AddChangeHook(HRConfigsChanged);
		this.hHRHS.AddChangeHook(HRConfigsChanged);
		this.hHRHSHP.AddChangeHook(HRConfigsChanged);
		this.hHRMax.AddChangeHook(HRConfigsChanged);
		this.hHRDistance.AddChangeHook(HRConfigsChanged);
		this.hHRNotifications.AddChangeHook(HRConfigsChanged);
		this.hHRTank.AddChangeHook(HRConfigsChanged);
		this.hHRWitch.AddChangeHook(HRConfigsChanged);
		this.hHRRemoveBW.AddChangeHook(HRConfigsChanged);
		this.hHRRemoveIncaps.AddChangeHook(HRConfigsChanged);
	}
}

enum struct PluginData
{
	PluginCvars cvars;
	bool bHooked;
	bool bPluginOn;
	bool bSI;
	bool bCI;
	bool bHS;
	bool bDistance;
	bool bNotifications;
	bool bTank;
	bool bWitch;
	bool bRemoveBW;
	bool bRemoveIncaps;
	int iFirst;
	int iSecond;
	int iThird;
	int iMax;
	int iCIHP;
	int iHSHP;

	void Init()
	{
		this.cvars.Init();
		LoadTranslations("hp_rewards.phrases");
	}

	void GetCvarValues()
	{
		this.iFirst = this.cvars.hHRFirst.IntValue;
		this.iSecond = this.cvars.hHRSecond.IntValue;
		this.iThird = this.cvars.hHRThird.IntValue;
		this.iMax = this.cvars.hHRMax.IntValue;
		this.bSI = this.cvars.hHRSI.BoolValue;
		this.bCI = this.cvars.hHRCI.BoolValue;
		this.iCIHP = this.cvars.hHRCIHP.IntValue;
		this.bHS = this.cvars.hHRHS.BoolValue;
		this.iHSHP = this.cvars.hHRHSHP.IntValue;
		this.bDistance = this.cvars.hHRDistance.BoolValue;
		this.bNotifications = this.cvars.hHRNotifications.BoolValue;
		this.bTank = this.cvars.hHRTank.BoolValue;
		this.bWitch = this.cvars.hHRWitch.BoolValue;
		this.bRemoveBW = this.cvars.hHRRemoveBW.BoolValue;
		this.bRemoveIncaps = this.cvars.hHRRemoveIncaps.BoolValue;
	}

	void IsAllowed()
	{
		this.bPluginOn = this.cvars.hHRPluginOn.BoolValue;
		if(!this.bHooked && this.bPluginOn)
		{
			this.bHooked = true;
			HookEvent("player_death", Events);
			HookEvent("witch_killed", Events);
		}
		else if(this.bHooked && !this.bPluginOn)
		{
			this.bHooked = false;
			UnhookEvent("player_death", Events);
			UnhookEvent("witch_killed", Events);	
		}
	}
}

public void OnPluginStart()
{
    plugin.Init();
}

public void OnMapStart()
{
	PrecacheSound(SOUND_HEARTBEAT, true);
}

public void OnConfigsExecuted()
{
	plugin.IsAllowed();
	plugin.GetCvarValues();
}

void HRConVarPluginOnChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	plugin.IsAllowed();
}

void HRConfigsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	plugin.GetCvarValues();
}

Action Events(Event event, char[] name, bool dontBroadcast)
{
	if (strcmp(name, "player_death") == 0)
	{
		int client = GetClientOfUserId(event.GetInt("userid")), shooter = GetClientOfUserId(event.GetInt("attacker")), iEntity = event.GetInt("entityid"), sHealth = 0, aHealth = 0, dHealth = 0;
		bool bHeadShot = event.GetBool("headshot");

		if(IsValidSurv(shooter) && !L4D_IsPlayerIncapacitated(shooter))
		{
			if(plugin.bSI)
			{
				if(IsValidSI(client))
				{
					int cClass = GetEntProp(client, Prop_Send, "m_zombieClass");
					if(plugin.bTank)
					{
						if(cClass == zClassTank)
						{
							if(IsValidSurv(shooter))
							{
								sHealth = GetClientHealth(shooter);
								if(((sHealth < plugin.iMax) || plugin.iMax == -1) && !L4D_IsPlayerIncapacitated(shooter))
								{
									GiveHealth(shooter, plugin.iMax, false, true);
								}
							}

							for (int attacker = 1; attacker <= MaxClients; attacker++)
							{
								if(IsValidSurv(attacker))
								{
									if(L4D_IsPlayerIncapacitated(attacker))
									{
										GiveHealth(attacker, plugin.iMax, true, true);
									}
								}
							}

							if(plugin.bNotifications)
							{
								CPrintToChatAll("%t", "TankFinallyKilledBy", shooter);
							}
						}
					}

					if(plugin.bDistance)
					{
						float cOrigin[3], sOrigin[3];
						GetEntPropVector(client, Prop_Send, "m_vecOrigin", cOrigin);
						GetEntPropVector(shooter, Prop_Send, "m_vecOrigin", sOrigin);

						float oDistance = GetVectorDistance(cOrigin, sOrigin);
						if(oDistance < 10000.0)
						{
							dHealth = RoundToZero(oDistance * 0.02);
						}
						else if(oDistance >= 10000.0)
						{
							dHealth = 200;
						}
					}

					if(cClass == 2 || (IsL4D2 && cClass == 4))
					{
						if(plugin.bDistance)
						{
							aHealth = plugin.iFirst + dHealth;
						}
						else
						{
							aHealth = plugin.iFirst;
						}

						if(plugin.bHS && bHeadShot)
						{
							aHealth = plugin.iFirst + plugin.iHSHP;
						}
					}
					else if(cClass == 1 || (IsL4D2 && cClass == 5))
					{
						if(plugin.bDistance)
						{
							aHealth = plugin.iSecond + dHealth;
						}
						else
						{
							aHealth = plugin.iSecond;
						}

						if(plugin.bHS && bHeadShot)
						{
							aHealth = plugin.iSecond + plugin.iHSHP;
						}
					}
					else if(cClass == 3 || (IsL4D2 && cClass == 6))
					{
						if(plugin.bDistance)
						{
							aHealth = plugin.iThird + dHealth;
						}
						else
						{
							aHealth = plugin.iThird;
						}

						if(plugin.bHS && bHeadShot)
						{
							aHealth = plugin.iThird + plugin.iHSHP;
						}
					}

					sHealth = GetClientHealth(shooter);
					if(plugin.iMax > 0)
					{
						if((sHealth + aHealth) < plugin.iMax)
						{
							GiveHealth(shooter, sHealth + aHealth, false, false);
						}
						else
						{
							GiveHealth(shooter, plugin.iMax, false, true);
						}
					}
					else if(plugin.iMax == -1)
					{
						if((sHealth + aHealth) < 100)
						{
							GiveHealth(shooter, sHealth + aHealth, false, false);
						}
						else
						{
							GiveHealth(shooter, sHealth + aHealth, false, true);
						}
					}

					if(cClass != 8)
					{
						if(plugin.bNotifications)
						{
							PrintHintText(shooter, "%t", "HP", aHealth);
						}
						else
						{
							PrintCenterText(shooter, "%t", "HP", aHealth);
						}
					}
				}
			}

			if(plugin.bCI)
			{
				if(IsValidCI(iEntity))
				{
					char cClass[128];
					GetEdictClassname(iEntity, cClass, sizeof(cClass));
					if(StrEqual(cClass, "infected"))
					{
						sHealth = GetClientHealth(shooter);

						if(plugin.bHS && bHeadShot)
						{
							aHealth = plugin.iCIHP + plugin.iHSHP;
						}
						else
						{
							aHealth = plugin.iCIHP;
						}

						if(plugin.iMax > 0)
						{
							if((sHealth + aHealth) < plugin.iMax)
							{
								GiveHealth(shooter, sHealth + aHealth, false, false);
							}
							else
							{
								GiveHealth(shooter, plugin.iMax, false, true);
							}
						}
						else if(plugin.iMax == -1)
						{
							if((sHealth + aHealth) < 100)
							{
								GiveHealth(shooter, sHealth + aHealth, false, false);
							}
							else
							{
								GiveHealth(shooter, sHealth + aHealth, false, true);
							}
						}

						if(plugin.bNotifications)
						{
							PrintHintText(shooter, "%t", "HP", aHealth);
						}
						else
						{
							PrintCenterText(shooter, "%t", "HP", aHealth);
						}
					}
				}
			}
		}
		else if(strcmp(name, "witch_killed") == 0)
		{
			if(plugin.bWitch)
			{
				int attacker = GetClientOfUserId(event.GetInt("userid"));
				if(IsValidSurv(attacker))
				{
					sHealth = GetClientHealth(attacker);
					if(sHealth < plugin.iMax && !L4D_IsPlayerIncapacitated(attacker))
					{
						GiveHealth(attacker, plugin.iMax, false, true);
					}
					else if(L4D_IsPlayerIncapacitated(attacker))
					{
						GiveHealth(attacker, plugin.iMax, true, true);
					}

					if(plugin.bNotifications)
					{
						CPrintToChatAll("%t", "WitchFinallyKilledBy", attacker);
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

stock void GiveHealth(int iClient, int iHealth, bool bIncadRes, bool bHigh100)
{
	if(bIncadRes && L4D_IsPlayerIncapacitated(iClient))
	{
		L4D_ReviveSurvivor(iClient);
	}

	if(bHigh100)
	{
		SetEntProp(iClient, Prop_Send, "m_iMaxHealth", iHealth);
		SetEntProp(iClient, Prop_Send, "m_iHealth", iHealth);
	}
	else
	{
		SetEntProp(iClient, Prop_Send, "m_iHealth", iHealth);
	}

	int iTempHealth = L4D_GetPlayerTempHealth(iClient);
	if(L4D_GetPlayerTempHealth(iClient) > 0 && (iTempHealth - iHealth) > 0)
	{
		L4D_SetPlayerTempHealthFloat(iClient, float(iTempHealth - iHealth));
	}
	else
	{
		L4D_SetPlayerTempHealthFloat(iClient, 0.0);
		if(plugin.bRemoveBW && L4D_IsPlayerOnThirdStrike(iClient))
		{
			L4D_SetPlayerThirdStrikeState(iClient, false);
			StopSound(iClient, SNDCHAN_STATIC, SOUND_HEARTBEAT);
		}

		if(plugin.bRemoveIncaps && L4D_GetPlayerReviveCount(iClient) > 0)
		{
			L4D_SetPlayerReviveCount(iClient, 0);
		}
	}
}

stock bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

stock bool IsValidSurv(int client)
{
	return IsValidClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
}

stock bool IsValidSI(int client)
{
	return IsValidClient(client) && GetClientTeam(client) == 3;
}

stock bool IsValidCI(int iCI)
{
	return iCI > 0 && iCI > MaxClients && iCI <= 2048 && IsValidEntity(iCI) && IsValidEdict(iCI);
}
