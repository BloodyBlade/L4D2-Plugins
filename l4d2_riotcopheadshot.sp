#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define PLUGIN_VERSION "1.3"
#define CVAR_FLAGS FCVAR_NOTIFY

ConVar g_cvarEnable, g_cvarDebug, g_cvarRiotCopHeadShotEnable, g_cvarRiotCopBodyShotDivisor, g_cvarFallenHeadShotMultiplier, g_cvarRiotPenetrationDamage;
bool g_bEnabled = false, g_bDebug = false;
int g_iRiotCopHeadShot_HeadEnable = 0;
float g_fRiotCopHeadShot_BodyDivisor = 0.0, g_fFallenHeadMultiplier = 0.0, g_fPenetrationDamage = 0.0;

public Plugin myinfo = 
{
	name = "L4D2 Riot Cop Head Shot",
	author = "dcx2 | helped by Mr. Zero / McFlurry",
	description = "Kills riot cops instantly if you shoot them in the head, makes body shots hurt riot cops a little bit, multiplies damage to fallen and Jimmy Gibbs from head shots",
	version = PLUGIN_VERSION,
	url = "www.AlliedMods.net"
}

public void OnPluginStart()
{
	// cache my convars
	CreateConVar("sm_riotcopheadshot_ver", PLUGIN_VERSION, "L4D2 Riot Cop Head Shot plugin version", CVAR_FLAGS|FCVAR_DONTRECORD);
	g_cvarEnable = CreateConVar("sm_riotcopheadshot_enable", "1.0", "Enables this plugin.", CVAR_FLAGS);
	g_cvarRiotCopHeadShotEnable = CreateConVar("sm_riotcopheadshot_riotheadenable", "1.0", "0: disabled\n1: Head shots instantly kill riot cops\n2: Head shots do 1x damage", CVAR_FLAGS);
	g_cvarRiotCopBodyShotDivisor = CreateConVar("sm_riotcopheadshot_riotbodydivisor", "40.0", "How much to divide body shot damage by (0 will disable)", CVAR_FLAGS);
	g_cvarFallenHeadShotMultiplier = CreateConVar("sm_riotcopheadshot_fallenheadmultiplier", "12.0", "How much to multiply fallen head shots by (0 will disable)", CVAR_FLAGS);
	g_cvarRiotPenetrationDamage = CreateConVar("sm_riotcopheadshot_bodypenetrationdamage", "13.0", "How much damage penetrating weapons should do to the body of riot cops", CVAR_FLAGS);
	g_cvarDebug = CreateConVar("sm_riotcopheadshot_debug", "0.0", "Print debug output.", CVAR_FLAGS);

	AutoExecConfig(true, "L4D2RiotCopHeadShot");

	// be nice and listen for changes
	g_cvarEnable.AddChangeHook(OnRCHSEnableChanged);
	g_cvarRiotCopHeadShotEnable.AddChangeHook(OnRCHS_RCHeadChanged);
	g_cvarRiotCopBodyShotDivisor.AddChangeHook(OnRCHS_RCBodyChanged);
	g_cvarFallenHeadShotMultiplier.AddChangeHook(OnRCHS_FHeadChanged);
	g_cvarRiotPenetrationDamage.AddChangeHook(OnRCHS_RiotPenDamage);
	g_cvarDebug.AddChangeHook(OnRCHSDebugChanged);

	// get cvars after AutoExecConfig
	g_bEnabled = g_cvarEnable.BoolValue;
	g_iRiotCopHeadShot_HeadEnable = g_cvarRiotCopHeadShotEnable.IntValue;
	g_fRiotCopHeadShot_BodyDivisor = g_cvarRiotCopBodyShotDivisor.FloatValue;
	g_fFallenHeadMultiplier = g_cvarFallenHeadShotMultiplier.FloatValue;
	g_fPenetrationDamage = g_cvarRiotPenetrationDamage.FloatValue;
	g_bDebug = g_cvarDebug.BoolValue;

	if (g_bDebug)
	{
		HookEvent("infected_hurt", Event_InfectedHurt);
	}
}

void OnRCHSEnableChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	g_bEnabled = view_as<bool>(StringToInt(newVal));
}

void OnRCHSDebugChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	g_bDebug = view_as<bool>(StringToInt(newVal));
	bool oldDebug = view_as<bool>(StringToInt(oldVal));
	if (g_bDebug && !oldDebug)
	{
		HookEvent("infected_hurt", Event_InfectedHurt);
	}
	else if (oldDebug && !g_bDebug)
	{
		UnhookEvent("infected_hurt", Event_InfectedHurt);
	}
}

void OnRCHS_RCHeadChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	g_iRiotCopHeadShot_HeadEnable = StringToInt(newVal);
}

void OnRCHS_RCBodyChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	g_fRiotCopHeadShot_BodyDivisor = StringToFloat(newVal);
}

void OnRCHS_FHeadChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	g_fFallenHeadMultiplier = StringToFloat(newVal);
}

void OnRCHS_RiotPenDamage(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	g_fPenetrationDamage = StringToFloat(newVal);
}

// Listen for when infected are created, then listen to them spawn
public void OnEntityCreated(int entity, const char[] classname)
{
	if (entity <= 0 || entity > 2048) return;

	if (StrEqual(classname, "infected") || StrEqual(classname, "witch"))
	{
		SDKHook(entity, SDKHook_SpawnPost, RiotCop_SpawnPost);
	}
}

// Model name does not exist until after the uncommon is spawned
void RiotCop_SpawnPost(int entity)
{
	if (isRiotCop(entity))
	{
		SDKHook(entity, SDKHook_TraceAttack, RiotCop_TraceAttack);
		if (g_bDebug)	PrintToChatAll("Hooked riot cop for head shot");
	}
	else if (isFallenSurvivor(entity))
	{
		SDKHook(entity, SDKHook_TraceAttack, Fallen_TraceAttack);
		if (g_bDebug)	PrintToChatAll("Hooked fallen survivor for head shot");
	}
	else if (isJimmyGibbs(entity))
	{
		SDKHook(entity, SDKHook_TraceAttack, Fallen_TraceAttack);
		if (g_bDebug)	PrintToChatAll("Hooked Jimmy Gibbs for head shot");
	}
	
	if (g_bDebug)
	{
		// if debugging listen to OTD from all infected
		SDKHook(entity, SDKHook_OnTakeDamage, RiotCopOnTakeDamage);
		SDKHook(entity, SDKHook_TraceAttack, RiotCop_TraceAttack);
	}
}

// Based on code from Mr. Zero
// TODO: DealDamage instead of SDKHooks_TakeDamage?  TakeDamage seems unstable sometimes...
Action RiotCop_TraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if (g_bDebug) PrintToChatAll("RCTA: %d %d %d %f %x %x %d %d", victim, attacker, inflictor, damage, damagetype, ammotype, hitbox, hitgroup);

	if (!g_bEnabled || !IsValidEntity(victim) || !isValidSurvivor(attacker)) return Plugin_Continue;

	float newDamage = 0.0;

	if (g_iRiotCopHeadShot_HeadEnable > 0 && hitgroup == 1) 
	{
		newDamage = damage;	// default head shot damage, some guns may require multiple shots
		if (g_iRiotCopHeadShot_HeadEnable < 2 && newDamage < 50.0)
		{
//			newDamage = 50.0;
			// It seems that sometimes SDKHooks_TakeDamage causes a crash if it kills a riot cop?  Switching to BecomeRagdoll...
			AcceptEntityInput(victim, "BecomeRagdoll");
			if (g_bDebug) PrintToChatAll("TA: Riot cop ragdolled (before %f, after %f) (%x %x %x)", damage, newDamage, damagetype, ammotype, hitbox);
			return Plugin_Continue;
		}
		if (g_bDebug) PrintToChatAll("TA: Riot cop head shot (before %f, after %f) (%x %x %x)", damage, newDamage, damagetype, ammotype, hitbox);
	}
	else if (g_fRiotCopHeadShot_BodyDivisor > 0.9)
	{
		if (ammotype == 2 || ammotype == 9 || ammotype == 10)
		{
			// Penetrating weapons should do more damage to the body
			newDamage = g_fPenetrationDamage;				
		}
		else
		{
			newDamage = damage / g_fRiotCopHeadShot_BodyDivisor;		
		}
		if (g_bDebug) PrintToChatAll("TA: Riot cop body shot (before %f, after %f) (%x %x %x)", damage, newDamage, damagetype, ammotype, hitbox);
	}
	
	// Do not return Plugin_Changed, because this would then affect body shots from the back
	// Instead just do TakeDamage
	
	if (newDamage > 0.0) SDKHooks_TakeDamage(victim, 0, attacker, newDamage);

	//PrintToServer("RCTA Post");
	return Plugin_Continue;
}  

Action Fallen_TraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	// A multiplier of 1.0 will disable this feature
	if (g_bEnabled && isValidSurvivor(attacker) && IsValidEntity(victim) && hitgroup == 1 && g_fFallenHeadMultiplier > 1.0) 
	{
		float newDamage = damage * g_fFallenHeadMultiplier;

		// Jimmy Gibbs has even more health, and penetrating bullets kill him in one shot to the body
		// So penetrating bullets to the head will also kill him in one shot
		if (isJimmyGibbs(victim) && (ammotype == 2 || ammotype == 9 || ammotype == 10) && newDamage < 3000.0)
		{
			newDamage = 3000.0;
		}
		
		if (g_bDebug)
		{
			if (isFallenSurvivor(victim))	PrintToChatAll("TA: Fallen head shot (before %f, after %f)", damage, newDamage);
			else if (isJimmyGibbs(victim))	PrintToChatAll("TA: Jimmy Gibbs head shot (before %f, after %f)", damage, newDamage);
		}
		
		damage = newDamage;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}  

// If debugging,  listen to IH (it will hear witches, while OTD will not)
Action Event_InfectedHurt(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bDebug)
	{
		int entityid = event.GetInt("entityid");
		if (isRiotCop(entityid)) PrintToChatAll("IH: Hit riot cop in the %d for %d damage (%d remaining)", event.GetInt("hitgroup"), event.GetInt("amount"), GetEntProp(entityid, Prop_Data, "m_iHealth"));
		else if (isFallenSurvivor(entityid)) PrintToChatAll("IH: Hit fallen survivor in the %d for %d damage (%d remaining)", event.GetInt("hitgroup"), event.GetInt("amount"), GetEntProp(entityid, Prop_Data, "m_iHealth"));
		else if (isJimmyGibbs(entityid)) PrintToChatAll("IH: Hit Jimmy Gibbs in the %d for %d damage (%d remaining)", event.GetInt("hitgroup"), event.GetInt("amount"), GetEntProp(entityid, Prop_Data, "m_iHealth"));
		else PrintToChatAll("IH: Hit infected in the %d for %d damage (%d remaining)", event.GetInt("hitgroup"), event.GetInt("amount"), GetEntProp(entityid, Prop_Data, "m_iHealth"));
	}
	return Plugin_Continue;
}

// OTD has access to different debugging data
Action RiotCopOnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (g_bDebug)
	{
		char victimName[MAX_TARGET_LENGTH] = "Unconnected", attackerName[MAX_TARGET_LENGTH] = "Unconnected", inflictorName[32] = "Invalid", weaponName[32] = "Invalid";
		
		if (victim > 0 && victim <= MaxClients)
		{
			if (IsClientConnected(victim))
			{
				GetClientName(victim, victimName, sizeof(victimName));
			}
		}
		else if (IsValidEntity(victim))
		{
			GetEntityClassname(victim, victimName, sizeof(victimName));
		}
		
		if (attacker > 0 && attacker <= MaxClients)
		{
			if (IsClientConnected(attacker))
			{
				GetClientName(attacker, attackerName, sizeof(attackerName));
			}
		}
		else if (IsValidEntity(attacker))
		{
			GetEntityClassname(attacker, attackerName, sizeof(attackerName));
		}
		
		if (inflictor > 0 && IsValidEntity(inflictor))
		{
			GetEntityClassname(inflictor, inflictorName, sizeof(inflictorName));
		}

		if (weapon > 0 && IsValidEntity(weapon))
		{
			GetEntityClassname(weapon, weaponName, sizeof(weaponName));
		}
		
		PrintToChatAll("OTD: %s hit %s with %s / %s / %x for %f", attackerName, victimName, weaponName, inflictorName, damagetype, damage);
	}
	return Plugin_Continue;
}

stock bool isValidSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
}

stock bool isRiotCop(int entity)
{
	if (entity <= 0 || entity > 2048 || !IsValidEntity(entity)) return false;
	char model[128];
	GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
	return StrContains(model, "riot") != -1; // Common is a riot uncommon
}

stock bool isFallenSurvivor(int entity)
{
	if (entity <= 0 || entity > 2048 || !IsValidEntity(entity)) return false;
	char model[128];
	GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
	return StrContains(model, "fallen") != -1; // Common is a fallen uncommon
}

stock bool isJimmyGibbs(int entity)
{
	if (entity <= 0 || entity > 2048 || !IsValidEntity(entity)) return false;
	char model[128];
	GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
	return StrContains(model, "jimmy") != -1; // Common is a Jimmy Gibbs
}
