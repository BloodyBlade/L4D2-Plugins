#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.5"
#define PLUGIN_NAME "L4D2 Special Ammo"
#define CVAR_FLAGS FCVAR_NOTIFY|FCVAR_SPONLY

#define TEST_DEBUG 0
#define TEST_DEBUG_LOG 0

static int iSpecialAmmoAmount = 0, iKillCountLimitSetting = 0, SpecialAmmoUsed[MAXPLAYERS + 1] = {0, ...}, killcount[MAXPLAYERS + 1] = {0, ...};
static ConVar SpecialAmmoOn, SpecialAmmoAmount, KillCountLimitSetting, DumDumForce;
static bool HasDumDumAmmo[MAXPLAYERS + 1] = {false, ...}, NoDoubleEventFire = false, bHooked = false;
static float fDumDumForce = 0.0;

public Plugin myinfo =
{
	name = PLUGIN_NAME, 
	author = " AtomicStryker ", 
	description = " Dish out major damage with special ammo types ", 
	version = PLUGIN_VERSION, 
	url = "http://forums.alliedmods.net/showthread.php?t=114210"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	EngineVersion test = GetEngineVersion();
	if(test != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2 game.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{	
	CreateConVar("l4d2_specialammo_version", PLUGIN_VERSION, " The version of L4D Special Ammo running ", CVAR_FLAGS|FCVAR_DONTRECORD);
	SpecialAmmoOn = CreateConVar("l4d2_specialammo_on", "1", "Plugin on/off", CVAR_FLAGS);
	SpecialAmmoAmount = CreateConVar("l4d2_specialammo_amount", "100", "How much special ammo a player gets. (default 50)", CVAR_FLAGS);
	KillCountLimitSetting = CreateConVar("l4d2_specialammo_killcountsetting", "50", "How much Infected a Player has to shoot to win special ammo. (default 120)", CVAR_FLAGS);
	DumDumForce = CreateConVar("l4d2_specialammo_dumdumforce", "75.0", "How powerful the DumDum Kickback is. (default 75.0)", CVAR_FLAGS);

	SpecialAmmoOn.AddChangeHook(ConVarPluginOnChanged);
	SpecialAmmoAmount.AddChangeHook(ConVarsChanged);
	KillCountLimitSetting.AddChangeHook(ConVarsChanged);
	DumDumForce.AddChangeHook(ConVarsChanged);

	RegAdminCmd("sm_givespecialammo", GiveSpecialAmmo, ADMFLAG_KICK, " sm_givespecialammo <1, 2 or 3> ");

	AutoExecConfig(true, "l4d2_specialammo"); // an autoexec! ooooh shiny
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarPluginOnChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void ConVarsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	iSpecialAmmoAmount = SpecialAmmoAmount.IntValue;
	iKillCountLimitSetting = KillCountLimitSetting.IntValue;
	fDumDumForce = DumDumForce.FloatValue;
}

void IsAllowed()
{
	bool bPluginOn = SpecialAmmoOn.BoolValue;
	if(bPluginOn && !bHooked)
	{
		bHooked = true;
		ConVarsChanged(null, "", "");
		HookEvent("infected_hurt", AnInfectedGotHurt);
		HookEvent("player_hurt", APlayerGotHurt);
		HookEvent("weapon_fire", WeaponFired);
		HookEvent("bullet_impact", BulletImpact);
		HookEvent("infected_death", KillCountUpgrade);
		HookEvent("round_start", RoundStartEvent);
	}
	else if(!bPluginOn && bHooked)
	{
		bHooked = false;
		UnhookEvent("infected_hurt", AnInfectedGotHurt);
		UnhookEvent("player_hurt", APlayerGotHurt);
		UnhookEvent("weapon_fire", WeaponFired);
		UnhookEvent("bullet_impact", BulletImpact);
		UnhookEvent("infected_death", KillCountUpgrade);
		UnhookEvent("round_start", RoundStartEvent);
	}
}

Action RoundStartEvent(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		killcount[i] = 0;
		SpecialAmmoUsed[i] = 0;
		HasDumDumAmmo[i] = false;
	}
	return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	if(client > 0)
	{
		killcount[client] = 0;
		SpecialAmmoUsed[client] = 0;
		HasDumDumAmmo[client] = false;
	}
}

public void OnClientPutInServer(int client)
{
	if(client > 0)
	{
		killcount[client] = 0;
		SpecialAmmoUsed[client] = 0;
		HasDumDumAmmo[client] = false;
	}
}

Action WeaponFired(Event event, const char[] ename, bool dontBroadcast)
{
	// get client and used weapon
	int client = GetClientOfUserId(event.GetInt("userid"));
	char weapon[64];
	event.GetString("weapon", weapon, 64);
	
	if (client > 0 && HasDumDumAmmo[client] == true)
	{
		if (StrContains(weapon, "shotgun", false) == -1)SpecialAmmoUsed[client]++; // if not a shotgun, one round per shot.
		else SpecialAmmoUsed[client] = SpecialAmmoUsed[client] + 5; // Five times the special rounds usage for shotguns.
		
		int SpecialAmmoLeft = iSpecialAmmoAmount - SpecialAmmoUsed[client];
		if ((SpecialAmmoLeft % 10) == 0 && SpecialAmmoLeft > 0) // Display a center HUD message every round decimal value of leftover ammo (30, 20, 10...)
			PrintCenterText(client, "DumDum ammo rounds left: %d", SpecialAmmoLeft);

		if (SpecialAmmoUsed[client] >= iSpecialAmmoAmount) CreateTimer(0.3, OutOfAmmo, client); //to remove the toys
	}
	return Plugin_Continue;
}

Action APlayerGotHurt(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = event.GetInt("attacker");
	if (!attacker) return Plugin_Continue; // if hit by a zombie or anything, we dont care
	
	int client = GetClientOfUserId(attacker);
	if (!HasDumDumAmmo[client] || GetClientTeam(client) != 2)return Plugin_Continue;

	int InfClient = GetClientOfUserId(event.GetInt("userid"));
	if (GetClientTeam(InfClient) != 3) return Plugin_Continue; //no FF effects (or should we ;P )

	float FiringAngles[3], PushforceAngles[3], force = fDumDumForce;

	GetClientEyeAngles(client, FiringAngles);
	
	PushforceAngles[0] = Cosine(DegToRad(FiringAngles[1])) * force;
	PushforceAngles[1] = Cosine(DegToRad(FiringAngles[1])) * force;
	PushforceAngles[2] = Cosine(DegToRad(FiringAngles[0])) * force;
	
	float current[3], resulting[3];
	GetEntPropVector(InfClient, Prop_Data, "m_vecVelocity", current);
	
	resulting[0] = current[0] + PushforceAngles[0];
	resulting[1] = current[1] + PushforceAngles[1];
	resulting[2] = current[2] + PushforceAngles[2];
	
	TeleportEntity(InfClient, NULL_VECTOR, NULL_VECTOR, resulting);
	
	return Plugin_Continue;
}

Action AnInfectedGotHurt(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("attacker"));
	if (!HasDumDumAmmo[client] || GetClientTeam(client) != 2)return Plugin_Continue;
	
	int infectedentity = event.GetInt("entityid");
	
	float FiringAngles[3], PushforceAngles[3], force = fDumDumForce;

	GetClientEyeAngles(client, FiringAngles);
	
	PushforceAngles[0] = Cosine(DegToRad(FiringAngles[1])) * force;
	PushforceAngles[1] = Cosine(DegToRad(FiringAngles[1])) * force;
	PushforceAngles[2] = Cosine(DegToRad(FiringAngles[0])) * force;
	
	float current[3], resulting[3];
	GetEntPropVector(infectedentity, Prop_Data, "m_vecVelocity", current);

	resulting[0] = current[0] + PushforceAngles[0];
	resulting[1] = current[1] + PushforceAngles[1];
	resulting[2] = current[2] + PushforceAngles[2];
	
	TeleportEntity(infectedentity, NULL_VECTOR, NULL_VECTOR, resulting);
	
	return Plugin_Continue;
}

Action OutOfAmmo(Handle hTimer, any client)
{
	if (!HasDumDumAmmo[client]) return Plugin_Stop;
	PrintToChat(client, "\x05You've run out of DumDum ammo.");
	HasDumDumAmmo[client] = false;
	SpecialAmmoUsed[client] = 0;
	return Plugin_Stop;
}

Action KillCountUpgrade(Event event, char[] ename, bool dontBroadcast)
{
	if (NoDoubleEventFire) return Plugin_Continue;
	
	int client = GetClientOfUserId(event.GetInt("attacker"));
	bool minigun = event.GetBool("minigun");
	bool blast = event.GetBool("blast");

	NoDoubleEventFire = true;

	if (client)
	{
		if (!minigun && !blast)
			killcount[client] += 1;
		else
		{
			NoDoubleEventFire = false;
			return Plugin_Continue;
		}
		
		DebugPrintToAll("Kill Count Upgrade %N, now %i", client, killcount[client]);
		
		if ((killcount[client] % 15) == 0)PrintCenterText(client, "Infected killed: %d", killcount[client]);
		
		if ((killcount[client] % iKillCountLimitSetting) == 0 && killcount[client] > 1)
		{
			if (IsClientInGame(client) && GetClientTeam(client) == 2)
			{
				char ammotype[64];
				int luck = GetRandomInt(1, 3); // wee randomness!!
				switch (luck)
				{
					case 1:
					{
						SetSpecialAmmoInPlayerGun(client, 0);
						HasDumDumAmmo[client] = false;
						SpecialAmmoUsed[client] = 0;
						ammotype = "Incendiary";
						CheatCommand(client, "upgrade_add", "INCENDIARY_AMMO");
						
						SetSpecialAmmoInPlayerGun(client, iSpecialAmmoAmount);
					}
					case 2:
					{
						SetSpecialAmmoInPlayerGun(client, 0);
						HasDumDumAmmo[client] = false;
						SpecialAmmoUsed[client] = 0;
						ammotype = "Explosive";
						CheatCommand(client, "upgrade_add", "EXPLOSIVE_AMMO");
						
						SetSpecialAmmoInPlayerGun(client, iSpecialAmmoAmount);
					}
					case 3:
					{
						HasDumDumAmmo[client] = true;
						SpecialAmmoUsed[client] = 0;
						ammotype = "DumDum";
					}
				}
				PrintToChatAll("\x04%N\x01 won %s ammo for killing %d Infected!", client, ammotype, killcount[client]);
			}
		}
	}
	
	NoDoubleEventFire = false;
	return Plugin_Continue;
}

void BulletImpact(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0)
	{
		float Origin[3];
		Origin[0] = event.GetFloat("x");
		Origin[1] = event.GetFloat("y");
		Origin[2] = event.GetFloat("z");
		
		if (HasDumDumAmmo[client])
		{
			float Direction[3];
			Direction[0] = GetRandomFloat(-1.0, 1.0);
			Direction[1] = GetRandomFloat(-1.0, 1.0);
			Direction[2] = GetRandomFloat(-1.0, 1.0);
			
			TE_SetupSparks(Origin, Direction, 1, 3);
			TE_SendToAll();
		}
	}
}

Action GiveSpecialAmmo(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_givespecialammo <1, 2 or 3> for incendiary, explosive or dumdum ammo");
		return Plugin_Handled;
	}
	
	char setting[10], ammotype[64];
	GetCmdArg(1, setting, sizeof(setting));
	
	switch (StringToInt(setting))
	{
		case 1:
		{
			SetSpecialAmmoInPlayerGun(client, 0);
			HasDumDumAmmo[client] = false;
			SpecialAmmoUsed[client] = 0;
			ammotype = "Incendiary";
			CheatCommand(client, "upgrade_add", "INCENDIARY_AMMO");
			
			SetSpecialAmmoInPlayerGun(client, iSpecialAmmoAmount);
		}
		case 2:
		{
			SetSpecialAmmoInPlayerGun(client, 0);
			HasDumDumAmmo[client] = false;
			SpecialAmmoUsed[client] = 0;
			ammotype = "Explosive";
			CheatCommand(client, "upgrade_add", "EXPLOSIVE_AMMO");
			
			SetSpecialAmmoInPlayerGun(client, iSpecialAmmoAmount);
		}
		case 3:
		{
			HasDumDumAmmo[client] = true;
			SpecialAmmoUsed[client] = 0;
			ammotype = "DumDum";
		}
	}
	
	PrintToChatAll("\x04%N\x01 cheated himself some %s ammo", client, ammotype);
	return Plugin_Handled;
}

stock int GetSpecialAmmoInPlayerGun(int client) //returns the amount of special rounds in your gun
{
	if (client > 0)
	{
		int gunent = GetPlayerWeaponSlot(client, 0);
		if (IsValidEdict(gunent))
		{
			return GetEntProp(gunent, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", 1);
		}
		else return 0;
	}
	return 0;
}

stock void SetSpecialAmmoInPlayerGun(int client, int amount)
{
	if (client > 0)
	{
		if (HasPlayerShottie(client))
		{
			amount = amount / 5;
		}
		
		int gunent = GetPlayerWeaponSlot(client, 0);
		if (IsValidEdict(gunent) && amount > 0)
		{
			DataPack datapack;
			CreateDataTimer(0.2, SetGunSpecialAmmo, datapack, TIMER_DATA_HNDL_CLOSE);
			datapack.WriteCell(gunent);
			datapack.WriteCell(amount);
		}
	}
}

Action SetGunSpecialAmmo(Handle timer, DataPack hDataPack)
{
	hDataPack.Reset();
	int ent = hDataPack.ReadCell();
	int amount = hDataPack.ReadCell();
	DebugPrintToAll("Delayed ammo Setting in gun %i to %i", ent, amount);
	SetEntProp(ent, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", amount, 1);
	return Plugin_Stop;
}

stock bool HasPlayerShottie(int client)
{
	if (client > 0)
	{
		char weapon[64];
		int gunent = GetPlayerWeaponSlot(client, 0);
		if (IsValidEdict(gunent))
		{
			GetEdictClassname(gunent, weapon, sizeof(weapon));
			if (StrContains(weapon, "shotgun", false) != -1)
				return true;
		}
		return false;
	}
	return false;
}

stock void CheatCommand(int client, char[] command, char[] arguments = "")
{
	if(client > 0)
	{
		int userflags = GetUserFlagBits(client);
		SetUserFlagBits(client, ADMFLAG_ROOT);
		int flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "%s %s", command, arguments);
		SetCommandFlags(command, flags);
		SetUserFlagBits(client, userflags);
	}
}

stock void DebugPrintToAll(const char[] format, any ...)
{
	#if TEST_DEBUG	|| TEST_DEBUG_LOG
	char buffer[192];

	VFormat(buffer, sizeof(buffer), format, 2);
	
	#if TEST_DEBUG
	PrintToChatAll("[Specialammo] %s", buffer);
	PrintToConsole(0, "[Specialammo] %s", buffer);
	#endif
	
	LogMessage("%s", buffer);
	#else
	//suppress "format" never used warning
	if (format[0])
		return;
	else
		return;
	#endif
} 