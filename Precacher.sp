#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_NOTIFY

ConVar Model_Precacher_Enabled, L4D_SurvivorsEnabled, L4D2_SurvivorsEnabled, WeaponsEnabled, M60_Gl_Enabled;
ConVar MeleeWeaponsEnabled, CSS_WeaponsEnabled, HealthEnabled, InfectedEnabled, CommonInfectedEnabled;
ConVar ThrowEnabled, AmmoPacksEnabled, MiscEnabled;

public Plugin myinfo =
{
	name = "Model Precacher",
	author = "Jonny(edit. by BS/IW)",
	description = "Precaches models.",
	version = PLUGIN_VERSION,
	url = ""
}

public void OnPluginStart()
{
	RegAdminCmd("sm_precacheall", Command_PrecacheAllModels, ADMFLAG_ROOT);
	CreateConVar("Model_Precacher_version", PLUGIN_VERSION, "Version of the Model Precacher plugin.", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
	Model_Precacher_Enabled	= CreateConVar ("model_precacher_enabled",    	"1",  "Model Precacher Enabled",         	CVAR_FLAGS);
	L4D_SurvivorsEnabled	= CreateConVar ("precache_l4d_survivors",    	"1",  "Precaching L4D Survivors",         	CVAR_FLAGS);
	L4D2_SurvivorsEnabled  	= CreateConVar ("precache_l4d2_survivors",   	"1",  "Precaching L4D2 Survivors",        	CVAR_FLAGS);
	WeaponsEnabled        	= CreateConVar ("precache_weapon",           	"1",  "Precaching Weapons",               	CVAR_FLAGS);
	M60_Gl_Enabled          = CreateConVar ("precache_m60_gl",              "1",  "Precaching M60, Grenade Launcher", 	CVAR_FLAGS);
	MeleeWeaponsEnabled   	= CreateConVar ("precache_melee_weapons",    	"1",  "Precaching Melee Weapons",         	CVAR_FLAGS);
	CSS_WeaponsEnabled	    = CreateConVar ("precache_css_weapons",      	"1",  "Precaching Css Weapons",           	CVAR_FLAGS);
	HealthEnabled	    	= CreateConVar ("precache_health",         		"1",  "Precaching Health",                	CVAR_FLAGS);
	InfectedEnabled	    	= CreateConVar ("precache_infected",         	"1",  "Precaching Infected",              	CVAR_FLAGS);
	CommonInfectedEnabled	= CreateConVar ("precache_common_infected",  	"1",  "Precaching Common Infected",       	CVAR_FLAGS);
	ThrowEnabled	    	= CreateConVar ("precache_throw",         		"1",  "Precaching Health",                	CVAR_FLAGS);
	AmmoPacksEnabled	    = CreateConVar ("precache_ammo_packs",         	"1",  "Precaching Infected",              	CVAR_FLAGS);
	MiscEnabled				= CreateConVar ("precache_misc",  				"1",  "Precaching Common Infected",       	CVAR_FLAGS);
	AutoExecConfig(true, "Model_Precacher");		
}

public void OnMapStart()
{
    if(Model_Precacher_Enabled)
    {
        if(L4D_SurvivorsEnabled) Precache_l4d_Survivors();
    	if(L4D2_SurvivorsEnabled) Precache_l4d2_Survivors();
    	if(WeaponsEnabled) PrecacheWeapons();
    	if(M60_Gl_Enabled) Precache_M60_Gl();
    	if(MeleeWeaponsEnabled) PrecacheMeleeWeapons();
    	if(CSS_WeaponsEnabled) Precache_CSS_Weapons();
    	if(HealthEnabled) PrecacheHealth();
    	if(InfectedEnabled) PrecacheInfected();
    	if(CommonInfectedEnabled) PrecacheCommonInfected();
    	if(ThrowEnabled) PrecacheThrowWeapons();
    	if(AmmoPacksEnabled) PrecacheAmmoPacks();
    	if(MiscEnabled) PrecacheMisc();
    }
}

public Action Command_PrecacheAllModels(int client, int args)
{
	PrecacheAllItems();
}

void PrecacheAllItems()
{
	Precache_l4d_Survivors();
	Precache_l4d2_Survivors();
	PrecacheWeapons();
	Precache_M60_Gl();
	PrecacheMeleeWeapons();
	Precache_CSS_Weapons();
	PrecacheHealth();
	PrecacheInfected();
	PrecacheCommonInfected();
	PrecacheThrowWeapons();
	PrecacheAmmoPacks();
	PrecacheMisc();
}

void CheckPrecacheModel(const char[] Model)
{
	if (!IsModelPrecached(Model))
	{
		PrecacheModel(Model);
	}
}

void Precache_l4d_Survivors()
{
	CheckPrecacheModel("models/survivors/survivor_teenangst.mdl");
	CheckPrecacheModel("models/survivors/survivor_biker.mdl");
	CheckPrecacheModel("models/survivors/survivor_manager.mdl");
	CheckPrecacheModel("models/survivors/survivor_namvet.mdl");
}

void Precache_l4d2_Survivors()
{
	CheckPrecacheModel("models/survivors/survivor_coach.mdl");
	CheckPrecacheModel("models/survivors/survivor_gambler.mdl");
	CheckPrecacheModel("models/survivors/survivor_mechanic.mdl");
	CheckPrecacheModel("models/survivors/survivor_producer.mdl");
}

void PrecacheWeapons()
{
	CheckPrecacheModel("models/v_models/v_pistola.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_pistol_a.mdl");
	CheckPrecacheModel("models/v_models/v_dual_pistola.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_pistol_b.mdl");
	CheckPrecacheModel("models/v_models/v_desert_eagle.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_desert_eagle.mdl");
	CheckPrecacheModel("models/v_models/v_shotgun_chrome.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_shotgun.mdl");
	CheckPrecacheModel("models/v_models/v_pumpshotgun.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_pumpshotgun_a.mdl");	
	CheckPrecacheModel("models/v_models/v_autoshotgun.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_autoshot_m4super.mdl");
	CheckPrecacheModel("models/v_models/v_shotgun_spas.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_shotgun_spas.mdl");
	CheckPrecacheModel("models/v_models/v_smg.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_smg_uzi.mdl");
	CheckPrecacheModel("models/v_models/v_silenced_smg.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_smg_a.mdl");
	CheckPrecacheModel("models/v_models/v_desert_rifle.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_desert_rifle.mdl");
	CheckPrecacheModel("models/v_models/v_rifle.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_rifle_m16a2.mdl");
	CheckPrecacheModel("models/v_models/v_rifle_ak47.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_rifle_ak47.mdl");
	CheckPrecacheModel("models/v_models/v_huntingrifle.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_sniper_mini14.mdl");
	CheckPrecacheModel("models/v_models/v_sniper_military.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_sniper_military.mdl");
}

void Precache_M60_Gl()
{
	CheckPrecacheModel("models/v_models/v_m60.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_m60.mdl");
	CheckPrecacheModel("models/v_models/v_grenade_launcher.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_grenade_launcher.mdl");
}

void PrecacheMeleeWeapons()
{
	CheckPrecacheModel("models/weapons/melee/v_golfclub.mdl");
	CheckPrecacheModel("models/weapons/melee/w_golfclub.mdl");
	CheckPrecacheModel("models/weapons/melee/v_bat.mdl");
	CheckPrecacheModel("models/weapons/melee/w_bat.mdl");
	CheckPrecacheModel("models/weapons/melee/v_riotshield.mdl");
	CheckPrecacheModel("models/weapons/melee/w_riotshield.mdl");
	CheckPrecacheModel("models/weapons/melee/v_tonfa.mdl");
	CheckPrecacheModel("models/weapons/melee/w_tonfa.mdl");
	CheckPrecacheModel("models/weapons/melee/v_cricket_bat.mdl");
	CheckPrecacheModel("models/weapons/melee/w_cricket_bat.mdl");
	CheckPrecacheModel("models/weapons/melee/v_crowbar.mdl");
	CheckPrecacheModel("models/weapons/melee/w_crowbar.mdl");	
	CheckPrecacheModel("models/weapons/melee/v_chainsaw.mdl");
	CheckPrecacheModel("models/weapons/melee/w_chainsaw.mdl");
	CheckPrecacheModel("models/weapons/melee/v_electric_guitar.mdl");
	CheckPrecacheModel("models/weapons/melee/w_electric_guitar.mdl");
	CheckPrecacheModel("models/weapons/melee/v_fireaxe.mdl");
	CheckPrecacheModel("models/weapons/melee/w_fireaxe.mdl");
	CheckPrecacheModel("models/weapons/melee/v_frying_pan.mdl");	
	CheckPrecacheModel("models/weapons/melee/w_frying_pan.mdl");
	CheckPrecacheModel("models/weapons/melee/v_katana.mdl");
	CheckPrecacheModel("models/weapons/melee/w_katana.mdl");
	CheckPrecacheModel("models/weapons/melee/v_machete.mdl");
	CheckPrecacheModel("models/weapons/melee/w_machete.mdl");
	CheckPrecacheModel("models/weapons/melee/w_shovel.mdl");
	CheckPrecacheModel("models/weapons/melee/v_shovel.mdl");
	CheckPrecacheModel("models/weapons/melee/w_pitchfork.mdl");
	CheckPrecacheModel("models/weapons/melee/v_pitchfork.mdl");
}

void Precache_CSS_Weapons()
{
	CheckPrecacheModel("models/v_models/v_rif_sg552.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_rifle_sg552.mdl");
	CheckPrecacheModel("models/v_models/v_snip_awp.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_sniper_awp.mdl");
	CheckPrecacheModel("models/v_models/v_snip_scout .mdl");
	CheckPrecacheModel("models/w_models/weapons/w_sniper_scout.mdl");
	CheckPrecacheModel("models/v_models/v_smg_mp5.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_smg_mp5.mdl");
	CheckPrecacheModel("models/v_models/v_knife_t.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_knife_t.mdl");
}

void PrecacheHealth()
{
	CheckPrecacheModel("models/v_models/v_medkit.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_eq_Medkit.mdl");
	CheckPrecacheModel("models/v_models/v_defibrillator.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_eq_defibrillator.mdl");
	CheckPrecacheModel("models/v_models/v_painpills.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_eq_painpills.mdl");
	CheckPrecacheModel("models/v_models/v_adrenaline.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_eq_adrenaline.mdl");
}

void PrecacheInfected()
{
	CheckPrecacheModel("models/infected/hulk.mdl");
	CheckPrecacheModel("models/infected/hulk_dlc3.mdl");
	CheckPrecacheModel("models/infected/witch.mdl");
	CheckPrecacheModel("models/infected/witch_bride.mdl");
	CheckPrecacheModel("models/infected/boomette.mdl");
	CheckPrecacheModel("models/infected/limbs/exploded_boomette.mdl");
}

void PrecacheCommonInfected()
{
	CheckPrecacheModel("models/infected/common_male_ceda.mdl");
	CheckPrecacheModel("models/infected/common_male_clown.mdl");
	CheckPrecacheModel("models/infected/common_male_fallen_survivor.mdl");
	CheckPrecacheModel("models/infected/common_male_jimmy.mdl");
	CheckPrecacheModel("models/infected/common_male_mud.mdl");
	CheckPrecacheModel("models/infected/common_male_riot.mdl");
	CheckPrecacheModel("models/infected/common_male_roadcrew.mdl");
	CheckPrecacheModel("models/infected/common_male_dressShirt_jeans.mdl");
	CheckPrecacheModel("models/infected/common_female_tankTop_jeans.mdl");
	CheckPrecacheModel("models/infected/common_female_tshirt_skirt.mdl.mdl");
}

void PrecacheThrowWeapons()
{
	CheckPrecacheModel("models/v_models/v_pipebomb.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_eq_pipebomb.mdl");
	CheckPrecacheModel("models/v_models/v_molotov.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_eq_molotov.mdl");
	CheckPrecacheModel("models/v_models/v_bile_flask.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_eq_bile_flask.mdl");
}

void PrecacheAmmoPacks()
{
	CheckPrecacheModel("models/v_models/v_explosive_ammopack.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_eq_explosive_ammopack.mdl");
	CheckPrecacheModel("models/v_models/v_incendiary_ammopack.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_eq_incendiary_ammopack.mdl");
}

void PrecacheMisc()
{
	CheckPrecacheModel("models/props_junk/explosive_box001.mdl");
	CheckPrecacheModel("models/props_junk/gascan001a.mdl");
	CheckPrecacheModel("models/props_equipment/oxygentank01.mdl");
	CheckPrecacheModel("models/props_junk/propanecanister001a.mdl");
}
