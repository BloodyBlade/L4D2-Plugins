/**
 * ============================================================================
 *
 *  L4D2 Melee Damage Resistance
 *
 *  Description:
 *      Survivors (players and/or bots) who carry or equip a melee weapon
 *      receive a configurable percentage of damage resistance against ALL
 *      damage sources.
 *
 *  ConVars (auto-saved to cfg/sourcemod/l4d2_melee_resistance.cfg):
 *      l4d2_melee_resist_enabled       - Master on/off switch
 *      l4d2_melee_resist_amount        - Resistance percentage (0.0–1.0)
 *      l4d2_melee_resist_equipped_only - Only apply while melee is active
 *      l4d2_melee_resist_bots          - Apply to survivor bots
 *      l4d2_melee_resist_announce      - Chat hint when resistance activates
 *      l4d2_melee_resist_exclude_ff    - Exclude friendly-fire from reduction
 *
 *  Author  : BatoSaiX
 *  Version : 1.1.0
 *  Game    : Left 4 Dead 2
 *
 * ============================================================================
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

// ---------------------------------------------------------------------------
// Plugin metadata
// ---------------------------------------------------------------------------
#define PLUGIN_VERSION  "1.1.0"
#define PLUGIN_NAME     "L4D2 Melee Damage Resistance"
#define CVAR_FLAGS FCVAR_NOTIFY

public Plugin myinfo =
{
    name        = PLUGIN_NAME,
    author      = "BatoSaiX(Edit. by BloodyBlade)",
    description = "Survivors carrying a melee weapon gain damage resistance",
    version     = PLUGIN_VERSION,
    url         = ""
};

// ---------------------------------------------------------------------------
// ConVar handles
// ---------------------------------------------------------------------------
ConVar g_cvEnabled;           // Plugin master switch
ConVar g_cvResistAmount;      // Damage reduction factor  (0.0 – 1.0)
ConVar g_cvEquippedOnly;      // Require melee to be the active weapon
ConVar g_cvAffectBots;        // Apply to survivor bots
ConVar g_cvAnnounce;          // Notify player in chat when buff applies
ConVar g_cvExcludeFF;         // Skip friendly-fire damage
// ---------------------------------------------------------------------------
// Tracking: which clients have already received the "buff active" hint
// ---------------------------------------------------------------------------
bool g_bHooked, g_bAnnounced[MAXPLAYERS + 1], g_bAffectBots, g_bAnnounce, g_bEquippedOnly, g_bExcludeFF;
float g_fResistAmount;

// ---------------------------------------------------------------------------
// OnPluginStart
// ---------------------------------------------------------------------------
public void OnPluginStart()
{
	// ---- Version ConVar ----
	CreateConVar(
		"l4d2_melee_resist_version", PLUGIN_VERSION,
		PLUGIN_NAME ... " version",
		CVAR_FLAGS | FCVAR_DONTRECORD
	);

	// ---- Create ConVars ----
	g_cvEnabled = CreateConVar(
		"l4d2_melee_resist_enabled", "1",
		"Enable or disable the Melee Damage Resistance plugin.\n"
		... "(1 = On, 0 = Off)",
		CVAR_FLAGS,
		true, 0.0,
		true, 1.0
	);

	g_cvResistAmount = CreateConVar(
		"l4d2_melee_resist_amount", "0.30",
		"Fraction of incoming damage to negate when a survivor holds/carries\n"
		... "a melee weapon.  Range: 0.0 (no reduction) – 1.0 (immune).\n"
		... "Default: 0.30 (30%% damage resistance)",
		CVAR_FLAGS,
		true, 0.0,
		true, 1.0
	);

	g_cvEquippedOnly = CreateConVar(
		"l4d2_melee_resist_equipped_only", "1",
		"0 = Resistance applies whenever a melee is in the survivor's\n"
		... "    inventory (slot 1), even if not currently drawn.\n"
		... "1 = Resistance only applies while the melee weapon is the\n"
		... "    active (drawn) weapon.",
		CVAR_FLAGS,
		true, 0.0,
		true, 1.0
	);

	g_cvAffectBots = CreateConVar(
		"l4d2_melee_resist_bots", "1",
		"Apply damage resistance to AI survivor bots as well.\n"
		... "(1 = Yes, 0 = No)",
		CVAR_FLAGS,
		true, 0.0,
		true, 1.0
	);

	g_cvAnnounce = CreateConVar(
		"l4d2_melee_resist_announce", "1",
		"Print a one-time chat hint to the survivor the first time their\n"
		... "melee resistance activates each life.\n"
		... "(1 = Yes, 0 = No)",
		CVAR_FLAGS,
		true, 0.0,
		true, 1.0
	);

	g_cvExcludeFF = CreateConVar(
		"l4d2_melee_resist_exclude_ff", "0",
		"Exclude friendly-fire damage from the resistance reduction.\n"
		... "(1 = FF bypasses resistance, 0 = FF is also reduced)",
		CVAR_FLAGS,
		true, 0.0,
		true, 1.0
	);

	// ---- Auto-save config ----
	AutoExecConfig(true, "l4d2_melee_resistance");

	g_cvEnabled.AddChangeHook(OnConVarEnableChanged);
	g_cvResistAmount.AddChangeHook(OnConVarsChanged);
	g_cvEquippedOnly.AddChangeHook(OnConVarsChanged);
	g_cvAffectBots.AddChangeHook(OnConVarsChanged);
	g_cvAnnounce.AddChangeHook(OnConVarsChanged);
	g_cvExcludeFF.AddChangeHook(OnConVarsChanged);
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void OnConVarEnableChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	IsAllowed();
}

void OnConVarsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(convar == g_cvResistAmount)
	{
		g_fResistAmount = convar.FloatValue;
	}
	else if(convar == g_cvEquippedOnly)
	{
		g_bEquippedOnly = convar.BoolValue;
	}
	else if(convar == g_cvAffectBots)
	{
		g_bAffectBots = convar.BoolValue;
	}
	else if(convar == g_cvAnnounce)
	{
		g_bAnnounce = convar.BoolValue;
	}
	else if(convar == g_cvExcludeFF)
	{
		g_bExcludeFF = convar.BoolValue;
	}
}

void IsAllowed()
{
	bool bPluginOn = g_cvEnabled.BoolValue;
	if(!g_bHooked && bPluginOn)
	{
		g_bHooked = true;
		OnConVarsChanged(g_cvResistAmount, "", "");
		OnConVarsChanged(g_cvEquippedOnly, "", "");
		OnConVarsChanged(g_cvAffectBots, "", "");
		OnConVarsChanged(g_cvAnnounce, "", "");
		OnConVarsChanged(g_cvExcludeFF, "", "");
		HookEvent("player_spawn", OnPlayerSpawn);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i)) continue;
			SDKHook(i, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
		}
	}
	else if(g_bHooked && !bPluginOn)
	{
		g_bHooked = false;
		UnhookEvent("player_spawn", OnPlayerSpawn);
	}
}

// ---------------------------------------------------------------------------
// Client hooks
// ---------------------------------------------------------------------------
public void OnClientPutInServer(int client)
{
	if(g_bHooked && client > 0)
	{
		SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
	}
}

public void OnClientDisconnect(int client)
{
    g_bAnnounced[client] = false;
}

// Called each time a survivor spawns (resets the chat hint flag)
void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (IsValidSurvivor(client))
	{
        g_bAnnounced[client] = false;
	}
}

// ---------------------------------------------------------------------------
// Damage hook
// ---------------------------------------------------------------------------
Action Hook_OnTakeDamage(
    int     victim,
    int    &attacker,
    int    &inflictor,
    float  &damage,
    int    &damagetype)
{
    // ---- Master switch ----
    if (!g_bHooked)
        return Plugin_Continue;

    // ---- Survivors only ----
    if (!IsValidSurvivor(victim))
        return Plugin_Continue;

    // ---- Bot filter ----
    if (IsFakeClient(victim) && !g_bAffectBots)
        return Plugin_Continue;

    // ---- Friendly-fire exclusion ----
    if (g_bExcludeFF && IsValidSurvivor(attacker))
        return Plugin_Continue;

    // ---- Melee check ----
    if (!SurvivorHasMelee(victim))
        return Plugin_Continue;

    // ---- Apply resistance ----
    damage *= (1.0 - g_fResistAmount);

    // ---- One-time chat announcement (human players only) ----
    if (!IsFakeClient(victim) && g_bAnnounce && !g_bAnnounced[victim])
    {
        g_bAnnounced[victim] = true;
        PrintToChat(victim,
            "\x04[Melee Resist]\x01 Your melee weapon grants you \x05%.0f%%\x01 damage resistance!",
            g_fResistAmount * 100.0
        );
    }

    return Plugin_Changed;
}

// ---------------------------------------------------------------------------
// Helper – check if the survivor has (or is holding) a melee weapon
// ---------------------------------------------------------------------------
stock bool SurvivorHasMelee(int client)
{
    if (g_bEquippedOnly)
    {
        // Must be holding the melee right now
        return IsValidMeleeEntity(GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"));
    }
    else
    {
        // Melee is secondary slot (slot 1); pistols are also slot 1 but
        // have different classnames, so we just check the classname.
        return IsValidMeleeEntity(GetPlayerWeaponSlot(client, 1));
    }
}

// ---------------------------------------------------------------------------
// Helper – verify an entity is a melee weapon
// ---------------------------------------------------------------------------
stock bool IsValidMeleeEntity(int entity)
{
    if (entity == -1 || !IsValidEntity(entity))
        return false;

    char classname[64];
    GetEntityClassname(entity, classname, sizeof(classname));
    // Regular melee weapons use "weapon_melee".
    // The chainsaw is a special case — it uses its own classname "weapon_chainsaw".
    return (
        StrContains(classname, "weapon_melee",    false) != -1 ||
        StrContains(classname, "weapon_chainsaw", false) != -1
    );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
stock bool IsValidSurvivor(int client)
{
    return 
        client > 0 
		&& client <= MaxClients 
		&& IsClientInGame(client) 
        && IsPlayerAlive(client)
        && GetClientTeam(client) == 2
    ;
}
