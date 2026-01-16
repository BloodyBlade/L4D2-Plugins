/************************************************************************************
*              Reference to edit and read this source code faster
*************************************************************************************
* Every string, integer, ConVar or whatever it is, will have one letter at the begining
* g_ meants that the function is Global, i refers to an integer, fl to floats, s to
* strings, cvar to ConVars, timer to Timers, vec to Vectors, b to Bool strings and
* h to any other needed handle.
* For example, g_bIsDeath mean it is global, is a boolean and according to the description
* or name, checks if a player is death. Thats something you should keep in mind if you are
* going to edit this plugin, or copy any function.
*
* You are free to copy any functions of this plugin without asking first, don't worry, 
* i won't even bother.
*
* Made this little guide, because when I just started, I tried to understand the plugins
* I read, but it was hard for a newbie on this. So, this reference is for those who try
* to start coding plugins,
*
* For Changelog or plugin information, please, go to the plugin's topic or contact me
* honorcode23...
*
*--------------------General Reference----------------------------------------------
*
* EH = [Extra Health] Means to survivor's bonus health per kills berserker feature.
* EIH = [Extra Infected Health] Means to infected's extra health on berserker feature
* ED = [Extra Damage]Means to infected's extra damage feature
* Ex = [Exclude] Refers to the words 'Exclude' or 'Excluded'
* FS = [Fire Shield] Refers to the Fire Shield feature
* LB = [Lethal Bite] Refers to the Lethal Bite feature
*
* i = [Integer] Refers to an integer value (1 - 345345, 544)
* fl = [Float] Refers to float values (3.5, 6.777, 34.43)
* b = [Bool] Refers to bool values (true - false)
* s = [String] refers to strings (hello - infected - any_word)
* cvar = [ConVar] Refers to a plugin convar or setting handle
* vec = [Vector] Float number with vector functions
* h = [Handle] Any custom handle needed by the plugin
* timer = [Timer] Timer handle
*
*************************************************************************************
*************************************************************************************/

//Includes
#pragma semicolon 1 //Who doesn't like semicolons? :)
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS FCVAR_NOTIFY
//Definitions
#define SOUND_START "ui/pickup_secret01.wav" //Sound heard by the client that begins berserker
#define SOUND_END "ui/pickup_misc42.wav" //Sound heard by the client when berserker ends
#define EFFECT_PARTICLE_SURVIVOR "fire_small_01" //Particle to show in a berserker player
#define EFFECT_PARTICLE_INFECTED "fire_small_03"
#define SOUND_NONE "music/the_endd/kalinX003DDDDD/OLODOSO.wav" //Anything so the console finds an error, and stop the enforced sounds.
#define SOUND_GUITAR "ui/pickup_guitarriff10.wav" //Sound heard by everyone when someone berserks
#define GETVERSION "1.6.8" //Plugin version

//**********************DEBUGGING OPTIONS AND OUTPUTS*******************************
#define RSDEBUG 0 //Faster swinging, reloading and shooting debug information.
#define BYDEBUG 0 //Berserker Yell debug information.
#define LBDEBUG 0 //Lethal bite debug information
#define FSDEBUG 0 //Fire shield debug information
#define NRDEBUG 0 //Nasty Revenge debug information
#define CTDEBUG 0 //Stats and counts debug information
#define EVTDEBUG 0 //Events information
#define ZKDEBUG 0 //Berserker debug information
#define CKDEBUG 0 //Safe timers and checkers debug information
#define BOODEBUG 0 //Boomer debug
#define CODEBUG 0 //Common Infected debug - Reason: Sometimes the event wont fire??
//***********************************************************************************

//Berserker Yell feature sound file paths.
#define YELLNICK_1 "player/survivor/voice/gambler/battlecry04.wav"
#define YELLNICK_2 "player/survivor/voice/gambler/battlecry01.wav"
#define YELLNICK_3 "player/survivor/voice/gambler/battlecry02.wav"
#define YELLRO_1 "player/survivor/voice/producer/battlecry01.wav"
#define YELLRO_2 "player/survivor/voice/producer/battlecry02.wav"
#define YELLRO_3 "player/survivor/voice/producer/hurrah11.wav"
#define YELLELLIS_1 "player/survivor/voice/mechanic/battlecry01.wav"
#define YELLELLIS_2 "player/survivor/voice/mechanic/battlecry03.wav"
#define YELLELLIS_3 "player/survivor/voice/mechanic/battlecry02.wav"
#define YELLCOACH_1 "player/survivor/voice/coach/battlecry09.wav"
#define YELLCOACH_2 "player/survivor/voice/coach/battlecry06.wav"
#define YELLCOACH_3 "player/survivor/voice/coach/battlecry04.wav"
#define YELLHUNTER_1 "player/hunter/voice/warn/hunter_warn_10.wav"
#define YELLHUNTER_2 "player/hunter/voice/warn/hunter_warn_14.wav"
#define YELLHUNTER_3 "player/hunter/voice/warn/hunter_warn_18.wav"
#define YELLSMOKER_1 "player/smoker/voice/warn/smoker_warn_01.wav"
#define YELLSMOKER_2 "player/smoker/voice/warn/smoker_warn_04.wav"
#define YELLSMOKER_3 "player/smoker/voice/warn/smoker_warn_05.wav"
#define YELLJOCKEY_1 "player/jockey/voice/warn/jockey_06.wav"
#define YELLJOCKEY_2 "player/jockey/voice/idle/jockey_lurk06.wav"
#define YELLJOCKEY_3 "player/jockey/voice/idle/jockey_lurk09"
#define YELLSPITTER_1 "player/spitter/voice/warn/spitter_warn_01.wav"
#define YELLSPITTER_2 "player/spitter/voice/warn/spitter_warn_02.wav"
#define YELLSPITTER_3 "player/spitter/voice/warn/spitter_warn_03.wav"
#define YELLBOOMER_1 "player/boomer/voice/action/male_zombie10_growl5.wav"
#define YELLBOOMER_2 "player/boomer/voice/action/male_zombie10_growl6.wav"
#define YELLBOOMER_3 "player/boomer/voice/alert/male_boomer_alert_05.wav"
#define YELLCHARGER_1 "player/charger/voice/warn/charger_warn_01.wav"
#define YELLCHARGER_2 "player/charger/voice/warn/charger_warn_02.wav"
#define YELLCHARGER_3 "player/charger/voice/warn/charger_warn_03.wav"
#define YELLBOOMETTE_1 "player/boomer/voice/action/female_zombie10_growl4.wav"
#define YELLBOOMETTE_2 "player/boomer/voice/action/female_zombie10_growl5.wav"
#define YELLBOOMETTE_3 "player/boomer/voice/action/female_zombie10_growl3.wav"
#define YELLTANK_1 "player/tank/voice/pain/tank_fire_01.wav"
#define YELLTANK_2 "player/tank/voice/pain/tank_fire_03.wav"
#define YELLTANK_3 "player/tank/voice/yell/tank_throw_04.wav"

//User messages
#define FFADE_IN            0x0001        // Just here so we don't pass 0 into the function
#define FFADE_OUT           0x0002        // Fade out (not in)
#define FFADE_MODULATE      0x0004        // Modulate (don't blend)
#define FFADE_STAYOUT       0x0008        // ignores the duration, stays faded out until new ScreenFade message received
#define FFADE_PURGE         0x0010        // Purges all other fades, replacing them with this one

//--------------------------------------------------------------------------------
//		 Global strings, convars, bools, integers, floats, vectors, etc          
//--------------------------------------------------------------------------------

//------------------------------Strings-------------------------------------------
char g_sBerserkMusic[PLATFORM_MAX_PATH]; //Path for the music file to play when berserker mode is running
char g_sKeyToBind[12]; //Key to bind to activate berserker. If set to nothing, +ZOOM will be taken instead, or, by !berserker command.

//------------------------------Integers------------------------------------------
int g_iTeam[MAXPLAYERS + 1] = {0, ...}; //Player team index
int g_iEffect[MAXPLAYERS + 1] = {0, ...}; //client effect entity id
int g_iZerkTime[MAXPLAYERS + 1] = {0, ...};

int g_iKillCount[MAXPLAYERS + 1] = {0, ...}; //Common infected kill count for survivors
int g_iKillCountExtra[MAXPLAYERS + 1] = {0, ...}; //Common infected kill count, under berserker for survivors (To grant additional health).
int g_iDamageCount[MAXPLAYERS + 1] = {0, ...}; //Damage count for infected. Based on the number of times the infected attacks a survivor.(Soon, based on the amount of damage)
int g_iWhoVomited[MAXPLAYERS + 1] = {0, ...}; //Who was the last who vomited a player

//---------------------------------Bools-------------------------------------------
bool g_bIsIncapacitated[MAXPLAYERS+1] = {false, ...}; //Is the player incapacitated?
bool g_bHasBerserker[MAXPLAYERS+1] = {false, ...}; //Is the player under berserker mode?
bool g_bBerserkerEnabled[MAXPLAYERS+1] = {false, ...}; //Is berserker ready to be used?
bool g_bHasFireBullets[MAXPLAYERS+1] = {false, ...}; //Has the player fire bullets?

//Exclude Extra Damage
bool g_bExBoomerED = false; //Are boomers excluded from extra damage?
bool g_bExTankED = false; //Are tanks excluded from extra damage?
bool g_bExChargerED = false; //Are Chargers excluded from extra damage?
bool g_bExSpitterED = false; //Are Spitters excluded from extra damage?
bool g_bExHunterED = false; //Are hunters excluded from extra damage?
bool g_bExJockeyED = false; //Are jockeys excluded from extra damage?
bool g_bExSmokerED = false; //Are smokers excluded from extra damage?

//Exclude Fire Shield
bool g_bExBoomerFS = false; //Are boomers excluded from fire shield?
bool g_bExTankFS = false; //Are tanks excluded from fire shield?
bool g_bExChargerFS = false; //Are Chargers excluded from fire shield?
bool g_bExSpitterFS = false; //Are Spitters excluded from fire shield?
bool g_bExHunterFS = false; //Are hunters excluded from fire shield?
bool g_bExJockeyFS = false; //Are jockeys excluded from fire shield?
bool g_bExSmokerFS = false; //Are smokers excluded from fire shield?

//Exclude Extra Health
bool g_bExBoomerEIH = false; //Are boomers excluded from extra health?
bool g_bExTankEIH = false; //Are tanks excluded from extra health?
bool g_bExChargerEIH = false; //Are Chargers excluded from extra health?
bool g_bExSpitterEIH = false; //Are Spitters excluded from extra health?
bool g_bExHunterEIH = false; //Are hunters excluded from extra health?
bool g_bExJockeyEIH = false; //Are jockeys excluded from extra health?
bool g_bExSmokerEIH = false; //Are smokers excluded from extra health?

//Exclude Lethal Bite
bool g_bExBoomerLB = false; //Are boomers excluded from lethal bite?
bool g_bExTankLB = false; //Are tanks excluded from lethal bite?
bool g_bExChargerLB = false; //Are Chargers excluded from lethal bite?
bool g_bExSpitterLB = false; //Are Spitters excluded from lethal bite?
bool g_bExHunterLB = false; //Are hunters excluded from lethal bite?
bool g_bExJockeyLB = false; //Are jockeys excluded from lethal bite?
bool g_bExSmokerLB = false; //Are smokers excluded from lethal bite?

//Exclude Berserker Yell
bool g_bExBoomerBY = false; //Are boomers excluded from berserker yell?
bool g_bExTankBY = false; //Are tanks excluded from berserker yell?
bool g_bExChargerBY = false; //Are Chargers excluded from berserker yell?
bool g_bExSpitterBY = false; //Are Spitters excluded from berserker yell?
bool g_bExHunterBY = false; //Are hunters excluded from berserker yell?
bool g_bExJockeyBY = false; //Are jockeys excluded from berserker yell?
bool g_bExSmokerBY = false; //Are smokers excluded from berserker yell?

//Exclude everything
bool g_bExALLBoomer = false; //Are boomers excluded from ALL features?
bool g_bExALLTank = false; //Are tanks excluded from ALL features?
bool g_bExALLCharger = false; //Are Chargers excluded from ALL features?
bool g_bExALLSpitter = false; //Are Spitters excluded from ALL features?
bool g_bExALLHunter = false; //Are hunters excluded from ALL features?
bool g_bExALLJockey = false; //Are jockeys excluded from ALL features?
bool g_bExALLSmoker = false; //Are smokers excluded from ALL features?

bool g_bIsPouncing[MAXPLAYERS+1] = {false, ...}; //Is the infected pouncing a survivor?
bool g_bIsChoking[MAXPLAYERS+1] = {false, ...}; //Is the infected choking a survivor?
bool g_bIsRiding[MAXPLAYERS+1] = {false, ...}; //Is the infected jockey-riding a survivor?

bool g_bFinaleEscape = false; // Is the rescue vehicle here?
bool g_bIsVomited[MAXPLAYERS+1] = {false, ...}; //Is the player vomited?
bool g_bLBActive[MAXPLAYERS+1] = {false, ...}; //Lethal bite active?
bool g_bDidYell[MAXPLAYERS+1] = {false, ...}; //Did yell?
bool g_bIsPummeling[MAXPLAYERS+1] = {false, ...}; //Is pummeling.

//-----------------------------ConVars------------------------------------

//Global
ConVar g_cvarInfectedDuration;
ConVar g_cvarPlayMusic;
ConVar g_cvarBindKey;
ConVar g_cvarCountMode;
ConVar g_cvarCountExpireTime;
ConVar g_cvarEffectType;
ConVar g_cvarKeyToBind;
ConVar g_cvarAutomaticStart;
ConVar g_cvarChangeColor;
ConVar g_cvarColor;
ConVar g_cvarMusicFile;
ConVar g_cvarDownloadMusic;
ConVar g_cvarEnableMusicShield;
ConVar g_cvarAdrenCheckTimer;
ConVar g_cvarAdrenCheckEnable;
ConVar g_cvarAllowZoomKey;
ConVar g_cvarYell;
ConVar g_cvarYellPower;
ConVar g_cvarYellRadius;
ConVar g_cvarYellLuck;
ConVar g_cvarAnnounceType;

//Survivor
ConVar g_cvarSurvivorEnable;
ConVar g_cvarSurvivorGoal;
ConVar g_cvarSurvivorSI;
ConVar g_cvarSurvivorSIGoal;
ConVar g_cvarEHEnabled;
ConVar g_cvarEHGoal;
ConVar g_cvarEHBonusAmount;
ConVar g_cvarEHSpecialInstant;
ConVar g_cvarEHSpecialBonusAmount;
ConVar g_cvarAdrenType;
ConVar g_cvarRefillWeapon;
ConVar g_cvarSpecialBullets;
ConVar g_cvarIncapImmunity;
ConVar g_cvarShovePenalty;
ConVar g_cvarInfiniteSpecialBullets;
ConVar g_cvarMeleeOnly;
ConVar g_cvarEnableImmunity;
ConVar g_cvarImmunityDuration;
ConVar g_cvarGiveLaserSight;
ConVar g_cvarFireWeaponsOnly;
ConVar g_cvarFasterReload;
ConVar g_cvarFasterShooting;
ConVar g_cvarFasterSwinging;
ConVar g_cvarNastyRevenge;
ConVar g_cvarNastyRevengeProb;
ConVar g_cvarNastyRevengeInfProb;
ConVar g_cvarYellSurvivor;
ConVar g_cvarYellFire;
ConVar g_cvarIncapRestrict;
ConVar g_cvarAdvEffectSurvivor;
ConVar g_cvarSurvivorDuration;
ConVar g_cvarConvertPermHealth;

//Infected
ConVar g_cvarInfectedEnable;
ConVar g_cvarInfectedGoal;
ConVar g_cvarInfectedCountType;
ConVar g_cvarAbilityImmunity = 	null;
ConVar g_cvarEDEnabled;
ConVar g_cvarEDMultiplier;
ConVar g_cvarEIHEnabled;
ConVar g_cvarEIHMultiplier;
ConVar g_cvarEDExInfected;
ConVar g_cvarExInfected;
ConVar g_cvarLBExInfected;
ConVar g_cvarEIHExInfected;
ConVar g_cvarFSExInfected;
ConVar g_cvarBYExInfected;
ConVar g_cvarEDEnableIncap;
ConVar g_cvarLethalBite;
ConVar g_cvarLethalBiteDmg;
ConVar g_cvarLethalBiteDur;
ConVar g_cvarLethalBiteFreq;
ConVar g_cvarFireShield;
ConVar g_cvarYellInfected;
ConVar g_cvarYellDead;
ConVar g_cvarAdvEffectInfected;
ConVar g_cvarBlindVomit;
ConVar g_cvarPummelSafe;

//Game ConVars

//--------------------------------OFFSETS----------------------------------------

static int g_flLagMovement = 0;
static int g_iShovePenalty = 0;
static int g_iAdrenSoundEffect = 0;

//------------------------------Timers------------------------------------------

Handle g_hAdrenCheckHandle[MAXPLAYERS + 1] = {null, ...}; //Adrenaline effects timer handle
Handle g_timerLethalBiteDur = null; //Lethal bite duration timer handle
Handle g_timerLethalBiteFreq = null; //Lethal bite frequency timer handle

//--------------------------Other Handles--------------------------------------
GameData g_hGameConf; //Game file path for signatures, adresses and offsets.
Handle sdkCallVomitPlayer = null; //SDKCall, vomit or puke players.
Handle sdkCallPushPlayer = null; //SDKCall, push survivors as if the attacker was a tank.
Handle sdkSetBuffer = null;
Handle sdkAdrenaline = null;
Handle sdkShove = null;
/****************************************************************************
*		Dusty1091 plugin source code - Adrenaline and Pills powerups plugin
*****************************************************************************/
//Used to track who has the weapon firing.
//Index goes up to 18, but each index has a value indicating a client index with
//DT so the plugin doesn't have to cycle a full 18 times per game frame
int g_iDTRegisterIndex[64] = {-1, ...};
//and this tracks how many have DT
int g_iDTRegisterCount = 0;
//this tracks the current active 'weapon id' in case the player changes guns
int g_iDTEntid[64] = {-1, ...};
//this tracks the engine time of the next attack for the weapon, after modification
//(modified interval + engine time)
float g_flDTNextTime[64] = {-1.0, ...};
/* ***************************************************************************/
//similar to Double Tap
int g_iMARegisterIndex[64] = {-1, ...};
//and this tracks how many have MA
int g_iMARegisterCount = 0;
//these are similar to those used by Double Tap
float g_flMANextTime[64] = {-1.0, ...};
int g_iMAEntid[64] = {-1, ...};
int g_iMAEntid_notmelee[64] = {-1, ...};
//this tracks the attack count, similar to twinSF
int g_iMAAttCount[64] = {-1, ...};
/* ***************************************************************************/
//Rates of the attacks
float g_flDT_rate = 0.0;
float g_fl_reload_rate = 0.0;
//Make sure we stop activity on map changes or we can get disconnects
bool g_bIsLoading = false;
/* ***************************************************************************/
//This keeps track of the default values for reload speeds for the different shotgun types
//NOTE: I got these values from tPoncho's own source
//NOTE: Pump and Chrome have identical values
const float g_fl_AutoS = 0.666666;
const float g_fl_AutoI = 0.4;
const float g_fl_AutoE = 0.675;
const float g_fl_SpasS = 0.5;
const float g_fl_SpasI = 0.375;
const float g_fl_SpasE = 0.699999;
const float g_fl_PumpS = 0.5;
const float g_fl_PumpI = 0.5;
const float g_fl_PumpE = 0.6;
/* ***************************************************************************/
//tracks if the game is L4D 2 (Support for L4D1 pending...)
bool g_bL4D2 = false;
/* ***************************************************************************/
//offsets
int g_iNextPAttO		= -1;
int g_iActiveWO			= -1;
int g_iShotStartDurO	= -1;
int g_iShotInsertDurO	= -1;
int g_iShotEndDurO		= -1;
int g_iPlayRateO		= -1;
int g_iShotRelStateO	= -1;
int g_iNextAttO			= -1;
int g_iTimeIdleO		= -1;
int g_iVMStartTimeO		= -1;
int g_iViewModelO		= -1;
int g_iNextSAttO		= -1;
int g_ActiveWeaponOffset;
/* ***************************************************************************/
//****************************************************************************

GlobalForward g_hForward_BerserkUse = null;

//Plugin Info
public Plugin myinfo = 
{
	name = "Berserker Mode",
	author = "honorcode23(Edit. by BloodyBlade)",
	description = "Enters on Berserker Mode after x amount of killed infected",
	version = GETVERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=127518"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if (engine == Engine_Left4Dead)
	{
		g_bL4D2 = false;
	}
	else if(engine == Engine_Left4Dead2)
	{
		g_bL4D2 = true;
	}
	else
	{
		strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead 2\" game");
		return APLRes_SilentFailure;
	}
	g_hForward_BerserkUse = new GlobalForward("OnBerserkerUsed", ET_Event, Param_Cell);
	return APLRes_Success;
}

public void OnPluginStart()
{	
	//-------------------------------------------------------------------------
	//						Config ConVars and commands
	//------------------------------------------------------------------------

	//Global
	CreateConVar("l4d2_berserk_mode_version", GETVERSION, "Version of Berserker Mode Plugin", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
	g_cvarCountMode = CreateConVar("l4d2_berserk_mode_count_mode", "1", "How should the kill or damage count work?(0 = Timed, 1 = Not timed)", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarCountExpireTime = CreateConVar("l4d2_berserk_mode_count_expire_time", "30", "How much time must pass between kills or attacks to reset counts?", CVAR_FLAGS);
	g_cvarInfectedDuration = CreateConVar("l4d2_berserk_mode_infected_duration", "30", "Amount of time to berserk for infected", CVAR_FLAGS);
	g_cvarSurvivorDuration = CreateConVar("l4d2_berserk_mode_survivor_duration", "45", "Amout of time to berserker for survivors", CVAR_FLAGS);
	g_cvarAutomaticStart = CreateConVar("l4d2_berserk_mode_auto", "0", "Should the Berserk Mode toggle ON by itself? (Automatic?)", CVAR_FLAGS, true, 0.0, true, 1.0); 
	g_cvarPlayMusic = CreateConVar("l4d2_berserk_mode_play_music", "1", "Should the plugin play music when the players are under Berserker Mode?", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarSurvivorEnable = CreateConVar("l4d2_berserk_mode_enable_survivor", "1", "Enable Berserker On survivors?", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarInfectedEnable = CreateConVar("l4d2_berserk_mode_enable_infected", "1", "Enable Berserker On infected?", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarChangeColor = CreateConVar("l4d2_berserk_mode_change_color", "1", "Should the plugin change a special color on players with berserker?", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarColor = CreateConVar("l4d2_berserk_mode_color", "1", "What color should the players have on berserker? (1 = RED, 2 = BLUE, 3 = GREEN, 4 = BLACK, 5 = TRANSPARENT)", CVAR_FLAGS, true, 1.0, true, 5.0);
	g_cvarMusicFile = CreateConVar("l4d2_berserk_mode_music_file", "music/tank/onebadtank.wav", "Which music should be played on berserker mode?");
	g_cvarDownloadMusic = CreateConVar("l4d2_berserk_mode_music_custom", "0", "Is the music sound file a non-standard one? If it is, it will be forced to be downloaded", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarKeyToBind = CreateConVar("l4d2_berserk_mode_binding_key", "1", "Which key should the plugin bind for berserker? 1 = IN_ZOOM, 2 = IN_RELOAD. Default is ZOOM key", CVAR_FLAGS);
	g_cvarBindKey = CreateConVar("l4d2_berserk_mode_bind_key", "1", "Should the plugin bind the specified key for berserker?", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarEnableMusicShield  = CreateConVar("l4d2_berserk_mode_esthetic_shield", "1", "Should the plugin avoid playing the music if it is anoying? (On finale escapes, tanks on play, etc)", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarAdrenCheckEnable = CreateConVar("l4d2_berserk_mode_adren_safeguard", "1", "Should we activate the Adrenaline Safe Guard for sound? (Prevents glitches)", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarAdrenCheckTimer = CreateConVar("l4d2_berserk_mode_adren_safeguard_time", "20", "How long should the Adrenaline Safe Guard wait to check and fix sound?");
	g_cvarAllowZoomKey = CreateConVar("l4d2_berserk_mode_bind_zoom_key", "0", "Allow the +ZOOM (Mouse wheel) to be the default berserker key?", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarYell = CreateConVar("l4d2_berserk_mode_yell", "1", "Allow the berserker mode 'Yell' feature. (Shove enemies at berserker start", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarYellPower = CreateConVar("l4d2_berserk_mode_yell_power", "250", "Power of the shove of the Berserker mode 'Yell' feature", CVAR_FLAGS);
	g_cvarYellRadius = CreateConVar("l4d2_berserk_mode_yell_radius", "350", "Radius that the yell shoves enemies", CVAR_FLAGS);
	g_cvarYellLuck = CreateConVar("l4d2_berserk_mode_yell_luck", "2", "Chance of getting the Berserker Yell power (If set to 2, the probability will be of 50%, 3 = 33%, 4 = 25% 5= 20%)", CVAR_FLAGS, true, 1.0);
	g_cvarAnnounceType = CreateConVar("l4d2_berserk_mode_announce", "2", "How should the plugin tell the players that the Berserker Mode is ready to be used? (0: DONT ANNOUNCE |1:CHAT| 2:HINT TEXT | 3:CENTER HINT TEXT | 4:INSTRUCTOR HINT)", CVAR_FLAGS, true, 0.0, true, 4.0);

	//Survivor Options
	g_cvarSurvivorGoal = CreateConVar("l4d2_berserk_mode_goal", "20", "Amount of common infected needed to berserk on survivors", CVAR_FLAGS);
	g_cvarMeleeOnly = CreateConVar("l4d2_berserk_mode_melee_only", "0", "Only Melee kills are valid kills? 0 = Disable, 1 = Enable", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarFireWeaponsOnly = CreateConVar("l4d2_berserk_mode_bullet_only", "0", "Only Bullet based kills are valid kills? (Explosives and melee excluded) 0 Disable, 1 = Enable", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarEHEnabled = CreateConVar("l4d2_berserk_mode_health", "1", "While in berserker mode, should the player get health after specific amount of common infected killed?", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarEHGoal = CreateConVar("l4d2_berserk_mode_health_goal", "5", "Amount of infected killed on berserker to get health", CVAR_FLAGS);
	g_cvarEHBonusAmount = CreateConVar("l4d2_berserk_mode_health_amount", "3", "Amount of health given when a certain amount of infected is killed on berserker", CVAR_FLAGS);
	g_cvarEHSpecialInstant = CreateConVar("l4d2_berserk_mode_health_special", "1", "Instant health on special infected kill under Berserker Mode", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarEHSpecialBonusAmount = CreateConVar("l4d2_berserk_mode_health_amount_special", "2", "Amount of health given when an special infected is killed on berserker mode", CVAR_FLAGS);
	g_cvarAdrenType = CreateConVar("l4d2_berserk_mode_give_shot_mode", "2", "Should the plugin give adrenaline, or add its effects by itself? 0 = Disable, 1 = Give Shot, 2 = Effects", CVAR_FLAGS, true, 0.0, true, 2.0);
	g_cvarRefillWeapon = CreateConVar("l4d2_berserk_mode_refill_weapon", "1", "Should the plugin refill players weapons on berserker?", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarSpecialBullets = CreateConVar("l4d2_berserk_mode_give_special_bullets", "1", "Should the plugin give fire bullets or nothing to the player on berserker? (Nothing = 0, Fire bullets = 1)", CVAR_FLAGS, true, 0.0, true, 2.0);
	g_cvarIncapImmunity = CreateConVar("l4d2_berserk_mode_incap_inmu", "1", "Should the plugin give inmunity if the player gets incapacitated on berserker?", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarShovePenalty = CreateConVar("l4d2_berserk_mode_shove_penalty", "1", "Disable shoving penalty during berserker? (Will not affect other plugins with this function)", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarEffectType = CreateConVar("l4d2_berserk_mode_animation_type", "0", "What kind of screen effect should we use for berserker? 0 = None, 1 = Fire, 2 = Adrenaline style 3 = Both (May cause low performance)", CVAR_FLAGS, true, 0.0, true, 3.0);
	g_cvarInfiniteSpecialBullets = CreateConVar("l4d2_berserk_mode_infinite_special_bullets", "1", "Should the fire or ice bullets be infinite?", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarEnableImmunity = CreateConVar("l4d2_berserk_mode_god_mode", "1", "Should we give god mode to survivors during Berserker?", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarImmunityDuration = CreateConVar("l4d2_berserk_mode_god_mode_time", "5.0", "How long should the God Mode last?", CVAR_FLAGS);
	g_cvarGiveLaserSight = CreateConVar("l4d2_berserk_mode_give_laser", "1", "Should the plugin give a laser on berserker?", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarFasterReload = CreateConVar("l4d2_berserk_mode_faster_reloading", "1", "Should the players reload faster on berserker?", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarNastyRevenge = CreateConVar("l4d2_berserk_mode_nasty_revenge", "1", "Should the plugin enable Nasty Revenge feature?", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarNastyRevengeProb = CreateConVar("l4d2_berserk_mode_nasty_revenge_chance", "2", "Chance to blind the infected team? (If set to 2, the probability will be of 50%, 3 = 33%, 4 = 25%)", CVAR_FLAGS);
	g_cvarNastyRevengeInfProb = CreateConVar("l4d2_berserk_mode_nasty_revenge_single_chance", "2", "Chance of a single infected to get blind? (If set to 2, the probability will be of 50%, 3 = 33%, 4 = 25%)", CVAR_FLAGS);
	g_cvarFasterShooting = CreateConVar("l4d2_berserk_mode_faster_shooting", "1", "Should the players shoot faster on berserker?", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarFasterSwinging = CreateConVar("l4d2_berserk_mode_faster_swinging", "1", "Should the players swing their melee weapons faster on berserker?", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarYellSurvivor = CreateConVar("l4d2_berserk_mode_yell_survivor", "1", "Allow Berserker Yell feature on survivor players?", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarYellFire = CreateConVar("l4d2_berserk_mode_yell_ignite", "1", "Should the survivors that got the berserker yell feature, burn any infected that hits him?", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarIncapRestrict = CreateConVar("l4d2_berserk_mode_restrict_incapacitated", "1", "Allow or restrict player from using berserker if they are incapacitated? (1: Allow 0: Dont)", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarAdvEffectSurvivor = CreateConVar("l4d2_berserk_mode_effect_advanced_survivor", "1", "Enable the advanced game effect on berserker survivors? (Might cause low performance)", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarSurvivorSI = CreateConVar("l4d2_berserk_mode_special_infected_kill_count", "0", "Should the Special Infected be counted for berserker too?", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarSurvivorSIGoal = CreateConVar("l4d2_berserk_mode_special_infected_kill_bonus", "3", "How much berserker points should the survivor get if the kills a Special Infected? (Note: Berserker Infected raise the count for one more point. CVAR+1)", CVAR_FLAGS);
	g_cvarConvertPermHealth = CreateConVar("l4d2_berserk_mode_convert_permhealth", "1", "Should the survivor's temporary health be converted into permanent health upon berserker usage?", CVAR_FLAGS, true, 0.0, true, 1.0);

	//Infected Options
	g_cvarInfectedGoal = CreateConVar("l4d2_berserk_mode_infected_goal", "200", "Amount of times an infected attacks a survivor to berserker", CVAR_FLAGS);
	g_cvarEDEnabled = CreateConVar("l4d2_berserk_mode_extra_damage", "1", "Should the plugin give extra damage for infected on berserker?", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarAbilityImmunity = CreateConVar("l4d2_berserk_mode_atack_inmu", "1", "Hunters, Smokers and Jockeys, can't be killed during their special ability, they must be shoved(On Berserker)", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarEDMultiplier = CreateConVar("l4d2_berserk_mode_extra_damage_amount", "0.5", "Multiplier for extra infected damage (1.0 = Double)", CVAR_FLAGS);
	g_cvarEIHEnabled = CreateConVar("l4d2_berserk_mode_extra_health", "1", "Should the plugin give extra health for infected on berserker?", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarEIHMultiplier = CreateConVar("l4d2_berserk_mode_extra_health_amount", "3.0", "Multiplier for extra infected health (2.0 = Double)", CVAR_FLAGS);
	g_cvarEDEnableIncap = CreateConVar("l4d2_berserk_mode_extra_damage_incap", "0", "Should the double damage feature of the infected, be applied to incapacitated survivors?", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarEDExInfected = CreateConVar("l4d2_berserk_mode_extra_damage_exclude", "none", "Infected classes excluded from extra damage feature separated by comas. (spitter, hunter, charger, tank, jockey, smoker, boomer)", CVAR_FLAGS);
	g_cvarExInfected = CreateConVar("l4d2_berserk_mode_exclude_infected", "tank", "Infected classes excluded from ALL berserker features separated by comas. (spitter, hunter, charger, tank, jockey, smoker, boomer)", CVAR_FLAGS);
	g_cvarEIHExInfected = CreateConVar("l4d2_berserk_mode_extra_health_exclude", "none", "Infected classes excluded from extra health feature separated by comas.(spitter, hunter, charger, tank, jockey, smoker, boomer)", CVAR_FLAGS);
	g_cvarLethalBite = CreateConVar("l4d2_berserk_mode_lethal_bite", "0", "Should the plugin enable Lethal Bite feature? (Keeps inflicting damage after a hit, only if the hit was made during berserker)", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarLethalBiteDmg = CreateConVar("l4d2_berserk_mode_lethal_bite_damage", "1", "Damage done by the Lethal Bite feature", CVAR_FLAGS);
	g_cvarLethalBiteDur = CreateConVar("l4d2_berserk_mode_lethal_bite_duration", "5.0", "How long should the Lethal Bite effect last on the survivor?", CVAR_FLAGS);
	g_cvarLethalBiteFreq = CreateConVar("l4d2_berserk_mode_lethal_bite_frequency", "1.0", "How often should the Lethal Bite effect hurt a survivor (1.0 = each second)", CVAR_FLAGS);
	g_cvarFireShield = CreateConVar("l4d2_berserk_mode_fire_shield", "1", "Should the plugin block berserker infected from being ignited? (Fire Shield)", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarLBExInfected = CreateConVar("l4d2_berserk_mode_lethal_bite_exclude", "none", "Infected classes excluded from Lethal Bite feature separated by comas.(spitter, hunter, charger, tank, jockey, smoker, boomer)", CVAR_FLAGS);
	g_cvarFSExInfected = CreateConVar("l4d2_berserk_mode_fire_shield_exclude", "none", "Infected classes excluded from Fire Shield feature separated by comas.(spitter, hunter, charger, tank, jockey, smoker, boomer)", CVAR_FLAGS);
	g_cvarBYExInfected = CreateConVar("l4d2_berserk_mode_yell_exclude", "none", "Infected classes excluded from Berserker Yell feature separated by comas.(spitter, hunter, charger, tank, jockey, smoker, boomer)", CVAR_FLAGS);
	g_cvarYellInfected = CreateConVar("l4d2_berserk_mode_yell_infected", "1", "Allow Berserker Yell feature on infected players?", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarYellDead = CreateConVar("l4d2_berserk_mode_yell_ondead", "1", "Allow Berserker Yell if a berserker infected dies?", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarAdvEffectInfected = CreateConVar("l4d2_berserk_mode_effect_advanced_infected", "1", "Enable the advanced game effect on berserker infected? (Might cause low performance)", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarInfectedCountType = CreateConVar("l4d2_berserk_mode_infected_count_type", "0", "On what should be the infected count based? (1: Times attacked | 0: Damage dealt)", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarBlindVomit = CreateConVar("l4d2_berserk_mode_blind_vomit", "1", "Blind (with half black screen) a player if a berserk boomer vomits on him (1:Allow | 0:Dont)", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvarPummelSafe = CreateConVar("l4d2_berserk_mode_pummel_safe", "1", "Chargers that are pummeling a survivor can't be killed with melee weapons (1:Allow | 0:Dont)", CVAR_FLAGS, true, 0.0, true, 1.0);

	//Commands
	RegConsoleCmd("sm_berserker", CmdBerserker, "Toggle Berserker if it is enabled, or show current progress if it isn't");
	RegConsoleCmd("sm_zerkhelp", CmdZerkHelp, "Show Berserker Mode help in console");

	//These are development related and will be deleted in the future
	RegAdminCmd("sm_forcezerk", CmdForceZerk, ADMFLAG_SLAY, "Forces berserk on yourself");
	RegAdminCmd("sm_forcegod", CmdForceGod, ADMFLAG_SLAY, "For test of some godmode properties");
	RegAdminCmd("sm_forcegod0", CmdForceGodOff, ADMFLAG_SLAY, "Disables forced god");
	RegAdminCmd("sm_forcezerkon", CmdForceZerkOn, ADMFLAG_SLAY, "Forces berserker on everybody");
	RegAdminCmd("sm_zerkon", CmdEnableZerk, ADMFLAG_SLAY, "Enables Berserker On You");
	RegAdminCmd("sm_debugreport", CmdDebugReport, ADMFLAG_SLAY, "Debug report");
	RegAdminCmd("sm_incapme", CmdIncapMe, ADMFLAG_SLAY, "Incap yourself");
	RegAdminCmd("sm_lbme", CmdLethBiteMe, ADMFLAG_SLAY, "Hurts you with lethal bite");
	RegAdminCmd("sm_yell", CmdYell, ADMFLAG_SLAY, "You will yell with this command");
	RegAdminCmd("sm_zerkbile", CmdZerkBile, ADMFLAG_SLAY, "Zerk bile");

	//Create Config File
	AutoExecConfig(true, "l4d2_berserk_mode");

	//Get music File
	g_cvarMusicFile.GetString(g_sBerserkMusic, sizeof(g_sBerserkMusic));
	if(g_cvarDownloadMusic.BoolValue)
	{
		//File will be forced to be downloaded, only if it doesn't overwrite a previus one.
		char musicpath[256];
		Format(musicpath, sizeof(musicpath), "sound/%s", g_sBerserkMusic);
		AddFileToDownloadsTable(musicpath);
	}

	//************************HOOK EVENT CALLS***********************************

	//Hooking global events
	HookEvent("round_end", OnRoundEnd); //When a round ends, called before OnMapEnd
	HookEvent("round_start_post_nav", OnRoundStart); //When a round starts, seems to be called before OnMapStart
	#if CTDEBUG
	PrintToServer("[PLUGIN] Hooked global events");
	#endif

	HookEvent("jockey_ride", OnJockeyRideStart); //Anytime a jockey rides a survivor
	HookEvent("lunge_pounce", OnHunterPounceStart); //Everytime a hunter pounces a survivor
	HookEvent("choke_start", OnSmokerChokeStart); //When smoker starts choking. This is also called when the survivor gets stuck for a few seconds.
	HookEvent("jockey_ride_end", OnJockeyRideEnd); //When the jockey ride ends
	HookEvent("pounce_stopped", OnHunterPounceEnd); //When the hunter pounce ends
	HookEvent("choke_start", OnSmokerChokeEnd); //When the smoke choke ends. Tongue broke
	HookEvent("player_hurt", OnPlayerHurt); //When a player is hurt
	HookEvent("player_shoved", OnPlayerShoved); //When a player gets shoved

	HookEvent("charger_pummel_start", OnPummelStart);
	HookEvent("charger_pummel_end", OnPummelEnd);
	#if CTDEBUG
	PrintToServer("[PLUGIN] Hooked Infected events");
	#endif

	HookEvent("player_death", OnPlayerDeath); //When a player is killed or simply dies
	HookEvent("player_incapacitated", OnPlayerIncap); //When a player gets incapacitated
	HookEvent("weapon_reload", OnWeaponReload); //When a player reload its weapon
	HookEvent("infected_hurt", OnCommonHurt); //When a common infected or witch is hurt
	HookEvent("weapon_fire", OnWeaponFire); //When a weapon is fired
	#if CTDEBUG
	PrintToServer("[PLUGIN] Hooked Survivor events");
	#endif

	//CHECKS
	HookEvent("player_incapacitated_start", OnPlayerPreIncap); //Right before player gets incapacitated, last chance to read its living info.
	HookEvent("finale_escape_start", OnFinaleEscapeStart); //Finale escape started (Vehicle is almost ready)
	HookEvent("tank_spawn", OnTankSpawned); //Tank spawned in game
	HookEvent("tank_killed", OnTankKilled); //Tank got killed
	HookEvent("adrenaline_used", OnAdrenalineUsed); //Everytime someone uses an adrenaline shot
	HookEvent("player_now_it", OnVomited); //When a players gets vomited by boomer or hit by boomer's explosion
	HookEvent("player_no_longer_it", OnVomitCleaned); //When the player is not blidn anymore, and doesn't atrack the horde
	HookEvent("tank_frustrated", OnTankFrustrated); //When a tank is frustrated
	HookEvent("player_bot_replace", OnBotReplacePlayer); //A bot takes over an existing player
	HookEvent("bot_player_replace", OnPlayerReplaceBot); //A player takes over an existing bot

	//********************Prepare fufute SDKCalls*******************************

	g_hGameConf = new GameData("l4d2_bm_sig");
	if(g_hGameConf == null)
	{
		SetFailState("Couldn't find the offsets file. Please, check that it is installed correctly.");
	}

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "CTerrorPlayer_OnHitByVomitJar");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	sdkCallVomitPlayer = EndPrepSDKCall();

	if(sdkCallVomitPlayer == null)
	{
		SetFailState("Unable to find the 'CTerrorPlayer_OnHitByVomitJar' signature, check the file version!");
	}

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "CTerrorPlayer_Fling");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	sdkCallPushPlayer = EndPrepSDKCall();
	if(sdkCallPushPlayer == null)
	{
		SetFailState("Unable to find the 'CTerrorPlayer_Fling' signature, check the file version!");
	}

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "CTerrorPlayer_SetHealthBuffer");
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	sdkSetBuffer = EndPrepSDKCall();
	if(sdkSetBuffer == null)
	{
		SetFailState("Unable to find the 'setbuffer' signature, check the file version!");
	}

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "CTerrorPlayer_OnAdrenalineUsed");
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	sdkAdrenaline = EndPrepSDKCall();
	if(sdkAdrenaline == null)
	{
		SetFailState("Unable to find the 'adrenaline' signature, check the file version!");
	}

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "CTerrorPlayer_OnShovedBySurvivor");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	sdkShove = EndPrepSDKCall();
	if(sdkShove == null)
	{
		SetFailState("Unable to find the 'shove' signature, check the file version!");
	}

	delete g_hGameConf;

	//*************************************************************************

	//**********************************Dusty's plugins
	//get offsets
	g_iNextPAttO		=	FindSendPropInfo("CBaseCombatWeapon","m_flNextPrimaryAttack");
	g_iActiveWO			=	FindSendPropInfo("CBaseCombatCharacter","m_hActiveWeapon");
	g_iShotStartDurO	=	FindSendPropInfo("CBaseShotgun","m_reloadStartDuration");
	g_iShotInsertDurO	=	FindSendPropInfo("CBaseShotgun","m_reloadInsertDuration");
	g_iShotEndDurO		=	FindSendPropInfo("CBaseShotgun","m_reloadEndDuration");
	g_iPlayRateO		=	FindSendPropInfo("CBaseCombatWeapon","m_flPlaybackRate");
	g_iShotRelStateO	=	FindSendPropInfo("CBaseShotgun","m_reloadState");
	g_iNextAttO			=	FindSendPropInfo("CTerrorPlayer","m_flNextAttack");
	g_iTimeIdleO		=	FindSendPropInfo("CTerrorGun","m_flTimeWeaponIdle");
	g_iVMStartTimeO		=	FindSendPropInfo("CTerrorViewModel","m_flLayerStartTime");
	g_iViewModelO		=	FindSendPropInfo("CTerrorPlayer","m_hViewModel");

	g_ActiveWeaponOffset = FindSendPropInfo("CBasePlayer", "m_hActiveWeapon");
	g_iNextSAttO		=	FindSendPropInfo("CBaseCombatWeapon","m_flNextSecondaryAttack");
	g_bIsLoading = true;
	g_fl_reload_rate = 0.5714;
	g_flDT_rate = 0.6667;
}

public void OnMapStart()
{
	//Get music File
	g_cvarMusicFile.GetString(g_sBerserkMusic, sizeof(g_sBerserkMusic));
	if(g_cvarDownloadMusic.BoolValue)
	{
		//File will be forced to be downloaded, only if it doesn't overwrite a previus one.
		char musicpath[256];
		Format(musicpath, sizeof(musicpath), "sound/%s", g_sBerserkMusic);
		AddFileToDownloadsTable(musicpath);
	}
	
	//Begin berserker stats
	RunBerserkCount();
	
	//Precache Sounds
	PrecacheSoundSmart(SOUND_START);
	PrecacheSoundSmart(SOUND_END);
	PrecacheSoundSmart(g_sBerserkMusic);
	PrecacheSoundSmart(YELLNICK_1);
	PrecacheSoundSmart(YELLNICK_2);
	PrecacheSoundSmart(YELLNICK_3);
	PrecacheSoundSmart(YELLRO_1);
	PrecacheSoundSmart(YELLRO_2);
	PrecacheSoundSmart(YELLRO_3);
	PrecacheSoundSmart(YELLELLIS_1);
	PrecacheSoundSmart(YELLELLIS_2);
	PrecacheSoundSmart(YELLELLIS_3);
	PrecacheSoundSmart(YELLCOACH_1);
	PrecacheSoundSmart(YELLCOACH_2);
	PrecacheSoundSmart(YELLCOACH_3);
	PrecacheSoundSmart(YELLHUNTER_1);
	PrecacheSoundSmart(YELLHUNTER_2);
	PrecacheSoundSmart(YELLHUNTER_3);
	PrecacheSoundSmart(YELLSMOKER_1);
	PrecacheSoundSmart(YELLSMOKER_2);
	PrecacheSoundSmart(YELLSMOKER_3);
	PrecacheSoundSmart(YELLJOCKEY_1);
	PrecacheSoundSmart(YELLJOCKEY_2);
	PrecacheSoundSmart(YELLJOCKEY_3);
	PrecacheSoundSmart(YELLSPITTER_1);
	PrecacheSoundSmart(YELLSPITTER_2);
	PrecacheSoundSmart(YELLSPITTER_3);
	PrecacheSoundSmart(YELLBOOMER_1);
	PrecacheSoundSmart(YELLBOOMER_2);
	PrecacheSoundSmart(YELLBOOMER_3);
	PrecacheSoundSmart(YELLCHARGER_1);
	PrecacheSoundSmart(YELLCHARGER_2);
	PrecacheSoundSmart(YELLCHARGER_3);
	PrecacheSoundSmart(YELLBOOMETTE_1);
	PrecacheSoundSmart(YELLBOOMETTE_2);
	PrecacheSoundSmart(YELLBOOMETTE_3);
	PrecacheSoundSmart(YELLTANK_1);
	PrecacheSoundSmart(YELLTANK_2);
	PrecacheSoundSmart(YELLTANK_3);
	
	PrecacheParticle(EFFECT_PARTICLE_SURVIVOR);
	PrecacheParticle(EFFECT_PARTICLE_INFECTED);

	#if CTDEBUG
	PrintToServer("[PLUGIN]Sounds have been precached");
	#endif
	
	//Server is not loading anymore
	g_bIsLoading = false;
}

stock void PrecacheSoundSmart(char[] sSound)
{
	PrecacheSound(sSound);
}

public void OnGameFrame()
{
	//Check all players
	for(int i = 1; i <= MaxClients; i++)
	{
		//If the selected client was 0 or wasn't in game, discart
		//Checks: Is a survivor, is alive, is in game, has berserker running and the required convar is enabled
		if(i > 0 && IsValidEntity(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2 && IsClientInGame(i) && g_bHasBerserker[i] && g_cvarShovePenalty.BoolValue)
		{
			//If the player is pressing the right click of the mouse, proceed
			if(GetClientButtons(i) & IN_ATTACK2)
			{
				//This will reset the penalty, so it doesnt even get applied.
				SetEntData(i, g_iShovePenalty, 0, 4);
				#if ZKDEBUG
				PrintToConsole(i, "[PLUGIN]Shove fatige disabled");
				#endif
			}
		}
	}
	
	//If server is not processing data or is loading, do nothing. This prevent lag or crashes.
	if (!IsServerProcessing() || g_bIsLoading)
	{
		return;
	}
	else
	{
		MA_OnGameFrame();
		DT_OnGameFrame();
	}
}

//When a client is putted in the server (joins)
public void OnClientPutInServer(int client)
{
	if(client > 0)
	{
		//Rebuild MA and DT registry.
		RebuildAll();
	}
}

//When a client is disconnected from the server
public void OnClientDisconnect(int client)
{
	RebuildAll();
	if(client > 0)
	{
		g_iKillCount[client] = false;
		g_iZerkTime[client] = g_cvarInfectedDuration.IntValue;
		g_iKillCountExtra[client] = false;
		g_iDamageCount[client] = false;
		g_bHasBerserker[client] = false;
		g_bBerserkerEnabled[client] = false;
		g_bIsRiding[client] = false;
		g_bIsPouncing[client] = false;
		g_bIsChoking[client] = false;
		g_bIsIncapacitated[client] = false;
		g_bIsVomited[client] = false;
		g_bIsPummeling[client] = false;
		g_iWhoVomited[client] = 0;
	}
}

//When a map ends
public void OnMapEnd()
{
	//Obviously, an escape is not proceeding
	g_bFinaleEscape = false;
	ResetBerserkCount();
	#if CTDEBUG
	PrintToServer("[PLUGIN]Counts and controls have been resetted");
	#endif
	ClearAll();
	g_bIsLoading = true;
	for(int i = 1; i <=MaxClients ; i++)
	{
		g_hAdrenCheckHandle[i] = null;
	}
}

//When a round begins
void OnRoundStart(Event hEvent, char[] event_name, bool dontBroadcast)
{
	CheckRestrictedClasses();
	PrecacheSound(g_sBerserkMusic);
	//Server is not loading anymore
	g_bIsLoading = false;
	
	//Clear MA and DT registry
	ClearAll();
	
	//Begin berserker stats
	RunBerserkCount();
	#if EVTDEBUG
	PrintToChatAll("\x04[Event]\x01 Round Started!");
	#endif
}

//When a round ends, do the same as OnMapEnd
void OnRoundEnd(Event hEvent, char[] event_name, bool dontBroadcast)
{
	ClearAll();
	ResetBerserkCount();
	g_bFinaleEscape = false;
	#if EVTDEBUG
	PrintToServer("[PLUGIN]Counts and controls have been resetted");
	#endif
	ClearAll();
	g_bIsLoading = true;
}

//Add Lethal bite to yourself
Action CmdLethBiteMe(int client, int args)
{
    if(g_timerLethalBiteDur != null)
    {
        delete g_timerLethalBiteDur;
    }
    if(g_timerLethalBiteFreq != null)
    {
        delete g_timerLethalBiteFreq;
    }
    DoLethalBite(client, client, g_cvarLethalBiteDmg.IntValue, g_cvarLethalBiteDur.FloatValue, g_cvarLethalBiteFreq.FloatValue);
    return Plugin_Handled;
}

//Yell
Action CmdYell(int client, int args)
{
    Yell(client);
    return Plugin_Handled;
}

Action CmdZerkBile(int client, int args)
{
    SDKCall(sdkCallVomitPlayer, client, client, true);
    ToggleBlackScreen(client);
    return Plugin_Handled;
}

//Force berserk mode on the yourself command
Action CmdForceZerk(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("Cannot use this command trough the server console");
		return Plugin_Handled;
	}
	BeginBerserkerMode(client);
	#if ZKDEBUG
	PrintToServer("[PLUGIN]%s forced berserker on himself", client);
	PrintToChat(client, "[PLUGIN]You forced berserker on yourself!");
	#endif
    return Plugin_Handled;
}

//Will force berserker mode on everybody
Action CmdForceZerkOn(int client, int args)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(i > 0 && IsValidEntity(i) && IsClientInGame(i))
		{
			BeginBerserkerMode(i);
		}
	}
	#if ZKDEBUG
	PrintToServer("[PLUGIN]%s forced berserker on all players", client);
	PrintToChatAll("[PLUGIN]An admin forced berserker on everybody!");
	#endif
    return Plugin_Handled;
}

//Will force God Mode in yourself
Action CmdForceGod(int client, int args)
{
	if(client == 0)
	{
		return Plugin_Handled;
	}
	SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
	#if ZKDEBUG
	PrintToServer("[PLUGIN]%s forced god mode on himself", client);
	PrintToChat(client, "[PLUGIN]You forced berserker on yourself");
	#endif
    return Plugin_Handled;
}

//Force berserk mode to be ready
Action CmdEnableZerk(int client, int args)
{
    //Allow the use of the berserker and notify the player about it
    g_bBerserkerEnabled[client] = true;
    Announce(client);
    DataPack pack;
    CreateDataTimer(0.1, DisplayHint, pack, TIMER_FLAG_NO_MAPCHANGE);
    pack.WriteCell(client);
    pack.WriteString("Berserker is ready!");
    pack.WriteString("sm_berserker");
    #if ZKDEBUG
    char sName[256];
    GetClientName(client, sName, sizeof(sName));
    PrintToServer("[PLUGIN]%s forced berserker to be ready on himself", sName);
    PrintToChat(client, "[PLUGIN]You forced berserker to be ready on yourself");
    #endif
    return Plugin_Handled;
}

//Retrieve any godmode feature of the player
Action CmdForceGodOff(int client, int args)
{
	if(client == 0)
	{
		return Plugin_Handled;
	}
	SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
	#if ZKDEBUG
	PrintToServer("[PLUGIN]%s retrieved god mode from himself", client);
	PrintToChat(client, "[PLUGIN]You retrieved god mode from yourself");
	#endif
    return Plugin_Handled;
}

//BETA function - Prints essential debugging information for developers.
Action CmdDebugReport(int client, int args)
{
    char weapon[256], godmode[30], exinfectedED[256];
    int entity = GetEntDataEnt2(client, FindSendPropInfo("CTerrorPlayer", "m_hActiveWeapon"));
    g_cvarEDExInfected.GetString(exinfectedED, sizeof(exinfectedED));
    if( StrContains( exinfectedED, "boomer" ) != -1) 
    {
        g_bExBoomerED = true;
    }
    else
    {
        g_bExBoomerED = false;
    }
    if( StrContains( exinfectedED, "spitter" ) != -1)
    {
        g_bExSpitterED = true;
    }
    else
    {
        g_bExSpitterED = false;
    }
    if( StrContains( exinfectedED, "hunter" ) != -1)
    {
        g_bExHunterED = true;
    }
    else
    {
        g_bExHunterED = false;
    }
    if( StrContains( exinfectedED, "jockey" ) != -1) 
    {
        g_bExJockeyED = true;
    }
    else
    {
        g_bExJockeyED = false;
    }
    if( StrContains( exinfectedED, "charger" ) != -1) 
    {
        g_bExChargerED = true;
    }
    else
    {
        g_bExChargerED = false;
    }
    if( StrContains( exinfectedED, "smoker" ) != -1) 
    {
        g_bExSmokerED = true;
    }
    else
    {
        g_bExSmokerED = false;
    }
    if( StrContains( exinfectedED, "tank" ) != -1) 
    {
        g_bExTankED = true;
    }
    else
    {
        g_bExTankED = false;
    }
        
    if(GetEntProp(client, Prop_Data, "m_takedamage") == 2)
    {
        Format(godmode, sizeof(godmode), "Disabled");
    }
    if(GetEntProp(client, Prop_Data, "m_takedamage") == 0)
    {
        Format(godmode, sizeof(godmode), "Enabled");
    }
    GetEntityNetClass(entity, weapon, sizeof(weapon));
    PrintToChat(client, "***************************************************************");
    PrintToChat(client, "***************************************************************");
    PrintToChat(client, "\x03Debug report begin");
    PrintToChat(client, "\x03Yellow = Game related ||| White = Plugin related");
    PrintToChat(client, "***************************************************************");
    PrintToChat(client, "***************************************************************");
    PrintToChat(client, "Kill Count: %i", g_iKillCount[client]);
    PrintToChat(client, "Damage Count: %i", g_iDamageCount[client]);
    PrintToChat(client, "Berserker Running: %b", g_bHasBerserker[client]);
    PrintToChat(client, "Berserker Enabled: %b", g_bBerserkerEnabled[client]);
    PrintToChat(client, "Server Loading: %b", g_bIsLoading);
    PrintToChat(client, "ServerProcessing: %b", IsServerProcessing());
    PrintToChat(client, "\x04Team: %i", g_iTeam[client]);
    PrintToChat(client, "\x04Client Index: %i", client);
    PrintToChat(client, "\x04Speed: %f", g_flLagMovement);
    PrintToChat(client, "\x04Adrenaline is: %i", GetEntProp(client, Prop_Send, "m_bAdrenalineActive"));
    PrintToChat(client, "\x04Adrenaline sound value: %f", GetEntPropFloat(client, Prop_Send, "m_fNVAdrenaline"));
    PrintToChat(client, "\x04God Mode: %s", godmode);
    PrintToChat(client, "\x04Weapon : %s", weapon);
    PrintToChat(client, "\x04Zombie Class Index: %i", GetEntProp(client, Prop_Send, "m_zombieClass"));
    PrintToChat(client, "***************************************************************");
    PrintToChat(client, "***************************************************************");
    PrintToChat(client, "\x03Debug report end");
    PrintToChat(client, "***************************************************************");
    PrintToChat(client, "***************************************************************");
    return Plugin_Handled;
}

//Accessed by they specified key, by +ZOOM key or by chat typing.
Action CmdBerserker(int client, int args)
{		
	//If client index is equal to 0 (world), abort
	if(!client
	|| !IsValidEntity(client)
	|| !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	g_iTeam[client] = GetClientTeam(client);
	//If the player is no running berserker, and it is also ready to be activated, begin it.
	if(!g_bHasBerserker[client] && g_bBerserkerEnabled[client] && IsValidEntity(client) && IsPlayerAlive(client) && !IsRestrictedALL(client) && (!g_cvarIncapRestrict.BoolValue && !view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated")) || g_cvarIncapRestrict.BoolValue))
	{
		BeginBerserkerMode(client);
		#if ZKDEBUG
		char sName[256];
		GetClientName(client, sName, sizeof(sName));
		PrintToServer("[PLUGIN]%s began berserker mode by command", sName);
		PrintToChat(client, "[PLUGIN]You began berserker mode by command");
		#endif
	}
	//If not, proceed to print chat information
	else
	{
		if(!g_bHasBerserker[client] && g_bBerserkerEnabled[client] && !IsPlayerAlive(client))
		{
			PrintToChat(client, "\x04You cannot use berserker mode while death!");
			return Plugin_Handled;
		}
		
		//If the player is restricted
		if(IsPlayerAlive(client) && !g_bHasBerserker[client] && !g_bBerserkerEnabled[client] && IsRestrictedALL(client))
		{
			PrintToChat(client, "\x04You cannot use berserker mode with this infected");
			return Plugin_Handled;
		}
		
		//If the player was already under berserk mode...
		if(g_bHasBerserker[client])
		{
			PrintToChat(client, "\x04You are already on berserker mode!!!");
			return Plugin_Handled;
		}
		if(!g_cvarIncapRestrict.BoolValue && view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated")))
		{
			PrintToChat(client, "\x04You cannot use berserker mode while incapacitated!");
			return Plugin_Handled;
		}
		//If the berserker is not ready for the player...
		else
		{
			int count = 0;
			int goal = 0;
			
			//Identify if the player is an infected or a survivor.
			if(g_iTeam[client] == 2)
			{
				count = g_iKillCount[client];
				goal = g_cvarSurvivorGoal.IntValue;
			}
			else if(g_iTeam[client] == 3)
			{
				count = g_iDamageCount[client];
				goal = g_cvarInfectedGoal.IntValue;
			}
			
			//Print to players chat his progress.
			
			PrintToChat(client, "\x04Berserker - \x01 Charging [%i/%i]", count, goal);
			#if ZKDEBUG
			char name[256];
			GetClientName(client, name, sizeof(name));
			PrintToServer("[PLUGIN]%s tried to use berserker, but failed", name);
			PrintToChat(client, "[PLUGIN]You failed to begin berserker. REASON: Goal not reached");
			#endif
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}

//Start Berserk Stats
public void RunBerserkCount()
{
	g_flLagMovement = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
	g_iShovePenalty = FindSendPropInfo("CTerrorPlayer", "m_iShovePenalty");
	g_iAdrenSoundEffect = FindSendPropInfo("CTerrorPlayer", "m_fNVAdrenaline");
	for(int i = 1; i <= MaxClients; i++)
	{
		g_iZerkTime[i] = g_cvarInfectedDuration.IntValue;
	}
	#if CTDEBUG
	PrintToServer("[PLUGIN] Got needed offsets and properties");
	#endif
}

public void ResetBerserkCount()
{
	#if CTDEBUG
	PrintToServer("[PLUGIN] Resetted needed offsets and properties");
	#endif
	g_bFinaleEscape = false;
	for(int i = 1; i <= MaxClients; i++)
	{
		//Reset berserker stats and required bools for everyone
		g_iKillCount[i] = 0;
		g_iZerkTime[i] = g_cvarInfectedDuration.IntValue;
		g_iKillCountExtra[i] = 0;
		g_iDamageCount[i] = 0;
		g_bHasBerserker[i] = false;
		g_bBerserkerEnabled[i] = false;
		g_bIsRiding[i] = false;
		g_bIsPouncing[i] = false;
		g_bIsChoking[i] = false;
		g_bIsIncapacitated[i] = false;
		g_bIsVomited[i] = false;
		g_bIsPummeling[i] = false;
		g_iWhoVomited[i] = 0;
	}
}

//Fire and ice bullet related...
void OnCommonHurt(Event hEvent, char[] event_name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(hEvent.GetInt("attacker"));
	int infected = hEvent.GetInt("entityid");
	if(attacker == 0)
	{
		return;
	}
	g_iTeam[attacker] = GetClientTeam(attacker);
	if(g_iTeam[attacker] == 2)
	{
		if(g_bHasBerserker[attacker] && g_bHasFireBullets[attacker] && !IsFakeClient(attacker) && IsClientInGame(attacker))
		{
			g_iKillCountExtra[attacker]++;
			CreateTimer(0.1, IgniteInf, infected, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

Action IgniteInf(Handle timer, any entity)
{
    if(entity > 0 && IsValidEntity(entity))
    {
        IgniteEntity(entity, 20.0);
    }
    return Plugin_Stop;
}

//Infected count based on damage dealt
void OnPlayerHurt(Event hEvent, char[] sEventName, bool bDontBroadcast)
{
	int iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"));
	int iVictim = GetClientOfUserId(hEvent.GetInt("userid"));
	int iDamage = hEvent.GetInt("dmg_health");
	int iEntityId = hEvent.GetInt("attackerentid");
	int iDamageType = hEvent.GetInt("type");
	
	if(iAttacker == 0) //If the attacker is the world or not a client.
	{
		#if CTDEBUG
		PrintToChatAll("WORLD ATTACKED %N", iVictim);
		#endif
		//Filter: 
		if(iEntityId > 0 && IsValidEntity(iEntityId) && iVictim > 0 && IsValidEntity(iVictim) && IsClientInGame(iVictim))
		{
			#if CTDEBUG
			PrintToChatAll("WORLD ATTACKED AND IS > 0", iVictim);
			#endif
			g_iTeam[iVictim] = GetClientTeam(iVictim);
			if(g_iTeam[iVictim] != 2)
			{
				return;
			}
			char class[64];
			GetEdictClassname(iEntityId, class, sizeof(class));
			if(StrEqual(class, "infected"))
			{
				if(g_bIsVomited[iVictim])
				{
					int iRealAttacker = g_iWhoVomited[iVictim];
					if(iRealAttacker > 0 && IsValidEntity(iRealAttacker) && IsClientInGame(iRealAttacker) && !IsFakeClient(iRealAttacker) && GetClientTeam(iRealAttacker) == 3)
					{
						g_iDamageCount[iRealAttacker] += 1;
						if(!g_cvarCountMode.BoolValue)
						{
							if(g_iDamageCount[iRealAttacker] <= 1)
							{
								CreateTimer(g_cvarCountExpireTime.FloatValue, ResetKillCount, iRealAttacker, TIMER_FLAG_NO_MAPCHANGE);
							}
						}
						
						if(g_iDamageCount[iRealAttacker] >= g_cvarInfectedGoal.IntValue)
						{
							g_iDamageCount[iRealAttacker] = 0;
							g_bBerserkerEnabled[iRealAttacker] = true;
							Announce(iRealAttacker);
							#if CTDEBUG
							PrintToChat(iRealAttacker, "[PLUGIN] Goal reached, enabling berserker");
							#endif
						}
					}
				}
				else if(g_bHasBerserker[iVictim] && g_bDidYell[iVictim])
				{
					IgniteEntity(iEntityId, 20.0);
					#if BYDEBUG
					PrintToConsole(iVictim, "An infected (%i) hurt you and you had yelled. Ignited.", iEntityId);
					#endif
				}
			}
		}
	}
	else //Otherwise...
	{
		if(!IsValidEntity(iAttacker)
		|| !IsClientInGame(iAttacker)
		|| IsFakeClient(iAttacker))
		{
			#if CTDEBUG
			PrintToChat(iAttacker, "\x04Not valid");
			#endif
			return;
		}
		#if CTDEBUG
		PrintToChat(iAttacker, "\x04You are a valid attacker");
		#endif
		g_iTeam[iAttacker] = GetClientTeam(iAttacker);
		if(g_cvarSurvivorEnable.BoolValue && g_iTeam[iAttacker] == 2)
		{
			#if CTDEBUG
			PrintToChat(iAttacker, "\x04You are a survivor and the Zerk For Survivors is enabled");
			#endif
			if(GetClientTeam(iVictim) == 3)
			{
				if(g_cvarYellFire.BoolValue && g_bHasBerserker[iAttacker] && g_bHasFireBullets[iAttacker])
				{
					CreateTimer(0.1, IgniteInf, iVictim, TIMER_FLAG_NO_MAPCHANGE);
				}
				
				if(g_cvarPummelSafe.BoolValue && GetEntProp(iVictim, Prop_Send, "m_zombieClass") == 6 && g_bHasBerserker[iVictim] && g_bIsPummeling[iVictim])
				{
					char sWeapon[256];
					GetClientWeapon(iAttacker, sWeapon, sizeof(sWeapon));
					if(StrContains(sWeapon, "weapon_melee") >= 0)
					{
						int iTotal = GetClientHealth(iVictim) + iDamage;
						SetEntityHealth(iVictim, iTotal);
					}
				}
			}
		}
		else if(g_cvarInfectedEnable.BoolValue && g_iTeam[iAttacker] == 3)
		{
			#if CTDEBUG
			PrintToChat(iAttacker, "\x04You are an infected nad the zerk is also enabled");
			#endif
			if(GetClientTeam(iVictim) == 2)
			{
				#if CTDEBUG
				PrintToChat(iAttacker, "\x04Victim is an attacker");
				#endif
				if(!g_bHasBerserker[iAttacker] && !g_bBerserkerEnabled[iAttacker])
				{
					#if CTDEBUG
					PrintToChat(iAttacker, "\x04You don't have any zerk");
					#endif
					if(g_cvarInfectedCountType.BoolValue)
					{
						g_iDamageCount[iAttacker] += 1;
					}
					else
					{
						g_iDamageCount[iAttacker] += iDamage;
					}
					#if CTDEBUG
					PrintToChat(iAttacker, "[PLUGIN] Damage count raised");
					#endif
					if(!g_cvarCountMode.BoolValue)
					{
						if(g_iDamageCount[iAttacker] <= 1)
						{
							CreateTimer(g_cvarCountExpireTime.FloatValue, ResetKillCount, iAttacker, TIMER_FLAG_NO_MAPCHANGE);
						}
					}
					
					if(g_iDamageCount[iAttacker] >= g_cvarInfectedGoal.IntValue)
					{
						g_iDamageCount[iAttacker] = 0;
						g_bBerserkerEnabled[iAttacker] = true;
						Announce(iAttacker);
						#if CTDEBUG
						PrintToChat(iAttacker, "[PLUGIN] Goal reached, enabling berserker");
						#endif
					}
				}
				else if(g_bHasBerserker[iAttacker])
				{
					int iIncapState = GetEntProp(iVictim, Prop_Send, "m_isIncapacitated");
					if(iIncapState == 0 || (iIncapState == 1 && g_cvarEDEnableIncap.BoolValue && !g_bHasBerserker[iVictim]))
					{						
						if(g_cvarEDEnabled.BoolValue && !IsRestrictedED(iAttacker))
						{
							int iPostHealth = GetClientHealth(iVictim);
							float flBonusDamage = g_cvarEDMultiplier.FloatValue;
							float flNewDamage = iDamage*flBonusDamage;
							float flTotal = iPostHealth-flNewDamage;
							int iTotal = RoundToFloor(flTotal);
							#if CTDEBUG
							int prevhealth = iPostHealth+iDamage;
							PrintToChat(iAttacker, "[INFECTED] Original target health: %i", prevhealth);
							PrintToChat(iAttacker, "[INFECTED] Original iDamage dealt: %i", iDamage);
							PrintToChat(iAttacker, "[INFECTED] New iDamage dealt: %i", RoundToNearest(iDamage+iDamage*flBonusDamage));
							PrintToChat(iAttacker, "[INFECTED] Final target health: %i", RoundToNearest(flTotal));
							#endif
							if(iTotal <= 0 && !view_as<bool>(GetEntProp(iVictim, Prop_Send, "m_isIncapacitated")))
							{
								//If the damage is GENERIC, skip, as it could create unnecesary loops.
								if(iDamageType != 0)
								{
									IncapSurvivor(iVictim, iAttacker);
								}
								#if CTDEBUG
								PrintToChat(iAttacker, "[INFECTED] Final health was below 0, incapacitating");
								#endif
							}
							else if(iTotal <= 0 && view_as<bool>(GetEntProp(iVictim, Prop_Send, "m_isIncapacitated")))
							{
								SetEntityHealth(iVictim, 0);
								#if CTDEBUG
								PrintToChat(iAttacker, "[INFECTED] Final health was below 0 and was already incapacitated, killing");
								#endif
							}
							else
							{
								SetEntityHealth(iVictim, iTotal);
							}
						}
						//LETHAL BITE related!
						if(g_cvarLethalBite.BoolValue && !IsRestrictedLB(iAttacker) && !g_bLBActive[iAttacker])
						{
							DoLethalBite(iVictim, iAttacker, g_cvarLethalBiteDmg.IntValue, g_cvarLethalBiteDur.FloatValue, g_cvarLethalBiteFreq.FloatValue);
						}

						if(g_cvarFireShield.BoolValue && !IsRestrictedFS(iVictim))
						{
							if(iDamageType == 8 || iDamageType == 2056)
							{
								ExtinguishEntity(iVictim);
								#if FSDEBUG
								PrintToChat(iVictim, "[FIRE SHIELD] Activated!, Extinguishing you!");
								#endif
							}
						}
					}
				}
			}
		}
	}
}


void OnPummelStart(Event hEvent, char[] event_name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(hEvent.GetInt("userid"));
	g_bIsPummeling[attacker] = true;
	#if EVTDEBUG
	int victim = GetClientOfUserId(hEvent.GetInt("victim"));
	char vname[256], aname[256];
	GetClientName(victim, vname, sizeof(vname));
	GetClientName(attacker, aname, sizeof(aname));
	PrintToChatAll("\x04[Event]\x01 Player %s(%i) is pummeling %s(%i)", aname, attacker, vname, victim);
	#endif
}

void OnPummelEnd(Event hEvent, char[] event_name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(hEvent.GetInt("userid"));
	g_bIsPummeling[attacker] = false;
	#if EVTDEBUG
	int victim = GetClientOfUserId(hEvent.GetInt("victim"));
	char vname[256], aname[256];
	GetClientName(victim, vname, sizeof(vname));
	GetClientName(attacker, aname, sizeof(aname));
	PrintToChatAll("\x04[Event]\x01 Player %s(%i) is not pummeling %s(%i) anymore", aname, attacker, vname, victim);
	#endif
}

/*Special infected abilities during Berserker*/
//Jockey ride start
Action OnJockeyRideStart(Event hEvent, char[] event_name, bool dontBroadcast)
{
	#if EVTDEBUG
	PrintToChatAll("\x04[Event]\x01 Jockey ride started");
	#endif
	if(!g_cvarAbilityImmunity.BoolValue)
	{
		return Plugin_Continue;
	}
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	if(client == 0)
	{
		return Plugin_Continue;
	}
	g_iTeam[client] = GetClientTeam(client);
	g_bIsRiding[client] = true;
	if(g_iTeam[client] == 3 && !IsFakeClient(client) && IsClientInGame(client))
	{
		if(g_bHasBerserker[client])
		{
			if(GetEntProp(client, Prop_Data, "m_takedamage") != 0)
			{
				SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
				CreateTimer(1.0, CheckInfectedZerk, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
				#if ZKDEBUG
				PrintToChat(client, "\x04[ZERK DEBUG]\x01Gave you immunity during ride");
				#endif
			}
		}
	}
    return Plugin_Continue;
}

//Pounce Start
Action OnHunterPounceStart(Event hEvent, char[] event_name, bool dontBroadcast)
{
	#if EVTDEBUG
	PrintToChatAll("\x04[Event]\x01 Hunter Pounce started");
	#endif
	if(!g_cvarAbilityImmunity.BoolValue)
	{
		return Plugin_Continue;
	}
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	if(client == 0)
	{
		return Plugin_Continue;
	}
	g_iTeam[client] = GetClientTeam(client);
	g_bIsPouncing[client] = true;
	if(g_iTeam[client] == 3 && !IsFakeClient(client) && IsClientInGame(client))
	{
		if(g_bHasBerserker[client])
		{
			if(GetEntProp(client, Prop_Data, "m_takedamage") != 0)
			{
				SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
				CreateTimer(1.0, CheckInfectedZerk, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
				#if ZKDEBUG
				PrintToChat(client, "\x04[ZERK DEBUG]\x01Gave you immunity during pounce");
				#endif
			}
		}
	}
    return Plugin_Continue;
}

//Cancel god mode if players get shoved
Action OnPlayerShoved(Event hEvent, char[] event_name, bool dontBroadcast)
{
    if(!g_cvarAbilityImmunity.BoolValue)
    {
        return Plugin_Continue;
    }

    int client = GetClientOfUserId(hEvent.GetInt("userid"));
    if(client == 0)
    {
        return Plugin_Continue;
    }
    g_iTeam[client] = GetClientTeam(client);
    if(g_iTeam[client] == 3)
    {
        #if EVTDEBUG
        PrintToChatAll("\x04[Event]\x01 Infected got shoved");
        #endif
        g_bIsRiding[client] = false;
        g_bIsPouncing[client] = false;
        g_bIsChoking[client] = false;
    }
    return Plugin_Continue;
}

//Choke Start
Action OnSmokerChokeStart(Event hEvent, char[] event_name, bool dontBroadcast)
{
	#if EVTDEBUG
	PrintToChatAll("\x04[Event]\x01 Smoker choke started");
	#endif
	if(!g_cvarAbilityImmunity.BoolValue)
	{
		return Plugin_Continue;
	}

	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	if(client == 0)
	{
		return Plugin_Continue;
	}
	g_iTeam[client] = GetClientTeam(client);
	g_bIsChoking[client] = true;
	if(g_iTeam[client] == 3 && !IsFakeClient(client) && IsClientInGame(client))
	{
		if(g_bHasBerserker[client])
		{
			if(GetEntProp(client, Prop_Data, "m_takedamage") != 0)
			{
				SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
				CreateTimer(1.0, CheckInfectedZerk, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
				#if ZKDEBUG
				PrintToChat(client, "\x04[ZERK DEBUG]\x01Gave you immunity during choke");
				#endif
			}
		}
	}
    return Plugin_Continue;
}

//Jockey Ride Over
Action OnJockeyRideEnd(Event hEvent, char[] event_name, bool dontBroadcast)
{
    #if EVTDEBUG
    PrintToChatAll("\x04[Event]\x01 Jockey ride is now over");
    #endif
    if(!g_cvarAbilityImmunity.BoolValue)
    {
        return Plugin_Continue;
    }

    for(int i = 1; i <= MaxClients; i++)
    {
        if(i == 0)
        {
            return Plugin_Continue;
        }

        if(g_iTeam[i] == 3)
        {
            g_bIsRiding[i] = false;
        }
    }
    return Plugin_Continue;
}

//Hunter Pounce Over
Action OnHunterPounceEnd(Event hEvent, char[] event_name, bool dontBroadcast)
{
    #if EVTDEBUG
    PrintToChatAll("\x04[Event]\x01 Hunter Pounce is now over");
    #endif
    if(!g_cvarAbilityImmunity.BoolValue)
    {
        return Plugin_Continue;
    }

    for(int i = 1; i <= MaxClients; i++)
    {
        if(i == 0)
        {
            return Plugin_Continue;
        }
 
        if(g_iTeam[i] == 3)
        {
            g_bIsPouncing[i] = false;
        }
    }
    return Plugin_Continue;
}

//Smoker Choke Over
Action OnSmokerChokeEnd(Event hEvent, char[] event_name, bool dontBroadcast)
{
    #if EVTDEBUG
    PrintToChatAll("\x04[Event]\x01 Smoker Choke is now over");
    #endif
    if(!g_cvarAbilityImmunity.BoolValue)
    {
        return Plugin_Continue;
    }

    for(int i = 1; i <= MaxClients; i++)
    {
        if(i == 0)
        {
            return Plugin_Continue;
        }

        if(g_iTeam[i] == 3)
        {
            g_bIsChoking[i] = false;
        }
    }
    return Plugin_Continue;
}

//God mode during incap
Action OnPlayerIncap(Event hEvent, char[] event_name, bool dontBroadcast)
{
    int client = GetClientOfUserId(hEvent.GetInt("userid"));
    if(client != 0)
    {
        g_iTeam[client] = GetClientTeam(client);
    }
    if(g_iTeam[client] == 2)
    {
        if(g_bHasBerserker[client] && g_cvarIncapImmunity.BoolValue)
        {
            if(GetEntProp(client, Prop_Data, "m_takedamage") != 0)
            {
                SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
                CreateTimer(0.1, CheckZerk, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
                #if ZKDEBUG
                PrintToChat(client, "\x04[ZERK DEBUG]\x01Gave you immunity during incapacitation");
                #endif
            }
        }
    }
    return Plugin_Continue;
}

//Tank Spawned
Action OnTankSpawned(Event hEvent, char[] event_name, bool dontBroadcast)
{
    #if EVTDEBUG
    PrintToChatAll("\x04[Event] \x01A Tank was spawned [Tank Count: %i]", GetTankCount());
    #endif
    return Plugin_Continue;
}

//Tanks is frustrated
Action OnTankFrustrated(Event hEvent, char[] event_name, bool dontBroadcast)
{
    #if EVTDEBUG
    PrintToChatAll("\x04[Event] \x01Tank Frustrated!!!");
    #endif
    return Plugin_Continue;
}

//Tank Killed
Action OnTankKilled(Event hEvent, char[] event_name, bool dontBroadcast)
{
    #if EVTDEBUG
    PrintToChatAll("\x04[Event] \x01Tank Killed [Tank Count: %i]", GetTankCount());
    #endif
    return Plugin_Continue;
}

//Bot replaces a player
Action OnBotReplacePlayer(Event hEvent, char[] event_name, bool dontBroadcast)
{
    #if EVTDEBUG
    int botuserid = hEvent.GetInt("bot");
    int bot = GetClientOfUserId(botuserid);
    int client = GetClientOfUserId(hEvent.GetInt("player"));
    char sName[256];
    GetClientName(client, sName, sizeof(sName));
    PrintToChatAll("\x04[Event] \x01A bot(id:%i)(index: %i) just replaced %s", botuserid, bot, sName);
    #endif
    return Plugin_Continue;
}

Action OnPlayerReplaceBot(Event hEvent, char[] event_name, bool dontBroadcast)
{
    #if EVTDEBUG
    int botuserid = hEvent.GetInt("bot");
    int bot = GetClientOfUserId(botuserid);
    int client = GetClientOfUserId(hEvent.GetInt("player"));
    char sName[256];
    GetClientName(client, sName, sizeof(sName));
    PrintToChatAll("\x04[Event] \x01%s replaced a bot(id:%i)(index: %i)", sName, botuserid, bot);
    #endif
    return Plugin_Continue;
}

//When a finale escape starts
Action OnFinaleEscapeStart(Event hEvent, char[] event_name, bool dontBroadcast)
{
    g_bFinaleEscape = true;
    #if EVTDEBUG
    PrintToChatAll("\x04[Event]\x01Finale escape has began");
    #endif
    return Plugin_Continue;
}

//On vomited by boomer or hit by boomer's explosion
Action OnVomited(Event hEvent, char[] event_name, bool dontBroadcast)
{
    int client = GetClientOfUserId(hEvent.GetInt("userid"));
    int attacker = GetClientOfUserId(hEvent.GetInt("attacker"));
    #if EVTDEBUG
    char sName[MAX_NAME_LENGTH+1];
    GetClientName(client, sName, sizeof(sName));
    PrintToChatAll("\x04[Event]\x01 %s got vomited", sName);
    #endif

    g_iWhoVomited[client] = attacker;
    if(!g_bIsVomited[client])
    {
        #if NRDEBUG
        PrintToChatAll("[NASTY REVENGE] Player wasnt vomited, setting as he is now...");
        #endif
        g_bIsVomited[client] = true;
        g_iTeam[client] = GetClientTeam(client);
        if(g_cvarNastyRevenge.BoolValue && g_bHasBerserker[client] && g_iTeam[client] == 2)
        {
            #if NRDEBUG
            PrintToChatAll("[NASTY REVENGE] Enabled and player with berserker detected, try chances");
            #endif
            DoNastyRevenge();
        }
    }
    if(g_bHasBerserker[attacker] && g_cvarBlindVomit.BoolValue)
    {
        ToggleBlackScreen(client);
    }
    return Plugin_Continue;
}

Action OnVomitCleaned(Event hEvent, char[] event_name, bool dontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	g_bIsVomited[client] = false;
	RetrieveBlackScreen(client);
	#if EVTDEBUG
	char sName[MAX_NAME_LENGTH+1];
	GetClientName(client, sName, sizeof(sName));
	PrintToChatAll("\x04[Event]\x01 %s is no longer vomited", sName);
	#endif
    return Plugin_Continue;
}

//On adrenaline shot used - SAFE GUARD
Action OnAdrenalineUsed(Event hEvent, char[] event_name, bool dontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	if(g_cvarAdrenCheckEnable.BoolValue)
	{
		if(g_hAdrenCheckHandle[client] != null)
		{
			delete g_hAdrenCheckHandle[client];
		}
		
		g_hAdrenCheckHandle[client] = CreateTimer(g_cvarAdrenCheckTimer.FloatValue, timerAdrenCheck, client, TIMER_FLAG_NO_MAPCHANGE);
		#if CKDEBUG
		PrintToChat(client, "\x02[SAFE GUARD]\x01 Safe guard activated");
		#endif
	}
	
	#if EVTDEBUG
	char sName[MAX_NAME_LENGTH+1];
	GetClientName(client, sName, sizeof(sName));
	PrintToChatAll("\x04[Event]\x01Adrenaline used by %s", sName);
	#endif
    return Plugin_Continue;
}

//Adrenaline safe guard for sounds - SAFE GUARD
Action timerAdrenCheck(Handle timer, any client)
{	
    //Checks: Is not world or console, is a valid entity, is inside the game, belongs to survivors
    if(client == 0 || !IsValidEntity(client) || !IsClientInGame(client) || g_iTeam[client] != 2)
    {
        #if CKDEBUG
        PrintToChatAll("[SAFE GUARD] The last valid client id (%i) didn't pass the filters, canceling...", userid);
        #endif
        g_hAdrenCheckHandle[client] = null;
        return Plugin_Stop;
    }

    //Check: Berserker enabled, in case the berserker was enabled or was applied, cancel adrenaline use and refire timer.
    if(g_bHasBerserker[client])
    {
        if(g_hAdrenCheckHandle[client] != null)
        {
            g_hAdrenCheckHandle[client] = null;
        }
        
        g_hAdrenCheckHandle[client] = CreateTimer(1.5, timerAdrenCheck, client, TIMER_FLAG_NO_MAPCHANGE);
        #if CKDEBUG
        PrintToChat(client, "\x02[SAFE GUARD]\x01 User has berserker active, wait for re-check");
        #endif
        return Plugin_Stop;
    }
    //If the player has no berserker, delete adrenaline effects, in case they remain active
    else
    {
        if(client > 0 && IsValidEntity(client) && IsClientInGame(client))
        {
            SetEntPropFloat(client, Prop_Send, "m_fNVAdrenaline", 0.0);
            SetEntDataFloat(client, g_iAdrenSoundEffect, 0.0, true);
            #if CKDEBUG
            PrintToChat(client, "\x02[SAFE GUARD]\x01 Time has expired, retrieving adrenaline sound effect");
            #endif
            g_hAdrenCheckHandle[client] = null;
            return Plugin_Stop;
        }
    }
    return Plugin_Continue;
}

//Get the last valid weapon if it was enforced
Action OnPlayerPreIncap(Event hEvent, char[] event_name, bool dontBroadcast)
{
    #if EVTDEBUG
    PrintToChatAll("\x04[Event]\x01Player Pre Incapacitation");
    #endif
    return Plugin_Continue;
}

//On Weapon Reload
Action OnWeaponReload(Event hEvent, char[] event_name, bool dontBroadcast)
{
    int client = GetClientOfUserId(hEvent.GetInt("userid"));
    if(client != 0)
    {
        g_iTeam[client] = GetClientTeam(client);
    }

    if(g_bHasBerserker[client] && g_iTeam[client] == 2 && g_cvarFasterReload.BoolValue)
    {
        AdrenReload(client);
    }
    return Plugin_Continue;
}

//On Weapon Fire
Action OnWeaponFire(Event hEvent, char[] event_name, bool dontBroadcast)
{
    int client = GetClientOfUserId(hEvent.GetInt("userid"));
    if(client == 0)
    {
        return Plugin_Continue;
    }
    return Plugin_Continue;
}

//On Player death or Special infected killed
void OnPlayerDeath (Event hEvent, char[] event_name, bool dontBroadcast)
{
    RebuildAll();

    //Get Needed Data
    int iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"));
    int iVictim = GetClientOfUserId(hEvent.GetInt("userid"));

    if(iVictim == 0)
    {
        LogDebug("A player died and the victim id was null, probably common kill");
        int iEntity = hEvent.GetInt("entityid");
        LogDebug("The entity id is: %i", iEntity);
        if(iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
        {
            LogDebug("The entity that dies is valid, proceed to get the class");
            char class[128];
            GetEdictClassname(iEntity, class, sizeof(class));
            if(StrEqual(class, "infected"))
            {
                LogDebug("The entity is a common infected, proceed");
                int iDmgType = hEvent.GetInt("type");
                char sWeapon[128];
                hEvent.GetString("weapon", sWeapon, sizeof(sWeapon));
                LogDebug("Sending Input: OnCommonKilled with params: %i - %i - %s - %i", iAttacker, iEntity, sWeapon, iDmgType);
                OnCommonKilled(iAttacker, sWeapon, iDmgType);
            }
            else
            {
                LogDebug("The entity is not a common infected");
            }
        }
        else
        {
            LogDebug("World died, or the entity was invalid");
        }
    }

    if(iAttacker > 0 && iVictim > 0)
    {
        if(!IsValidEntity(iAttacker)
        || !IsClientInGame(iAttacker))
        {
            return;
        }
        g_iTeam[iAttacker] = GetClientTeam(iAttacker);
        if(g_iTeam[iAttacker] == 2)
        {
            g_iTeam[iVictim] = GetClientTeam(iVictim);
            if(g_iTeam[iVictim] == 3)
            {
                if(!g_bHasBerserker[iAttacker])
                {
                    char weapon[256];
                    hEvent.GetString("weapon", weapon, sizeof(weapon));
                    if(g_cvarSurvivorSI.BoolValue)
                    {
                        //Only melee kills are valid
                        if(g_cvarMeleeOnly.BoolValue && !g_cvarFireWeaponsOnly.BoolValue)
                        {
                            //Is the weapon a valid melee weapon net class?
                            if(StrContains(weapon, "melee") >= 0 || StrContains(weapon, "chainsaw") >= 0)
                            {
                                if(g_bHasBerserker[iVictim])
                                {
                                    g_iKillCount[iAttacker] += g_cvarSurvivorSIGoal.IntValue + 1;
                                }
                                else
                                {
                                    g_iKillCount[iAttacker] += g_cvarSurvivorSIGoal.IntValue;
                                }
                            }
                        }
                        else if(!g_cvarMeleeOnly.BoolValue && g_cvarFireWeaponsOnly.BoolValue)
                        {
                            if(IsValidFireWeaponName(weapon))
                            {
                                if(g_bHasBerserker[iVictim])
                                {
                                    g_iKillCount[iAttacker] += g_cvarSurvivorSIGoal.IntValue + 1;
                                }
                                else
                                {
                                    g_iKillCount[iAttacker] += g_cvarSurvivorSIGoal.IntValue;
                                }
                            }
                        }
                        else if(g_cvarMeleeOnly.BoolValue && g_cvarFireWeaponsOnly.BoolValue)
                        {
                            if(StrContains(weapon, "melee") >= 0 || StrContains(weapon, "chainsaw") >= 0 || IsValidFireWeaponName(weapon))
                            {
                                if(g_bHasBerserker[iVictim])
                                {
                                    g_iKillCount[iAttacker] += g_cvarSurvivorSIGoal.IntValue + 1;
                                }
                                else
                                {
                                    g_iKillCount[iAttacker] += g_cvarSurvivorSIGoal.IntValue;
                                }
                            }
                        }
                        else if(!g_cvarMeleeOnly.BoolValue && !g_cvarFireWeaponsOnly.BoolValue)
                        {
                            if(g_bHasBerserker[iVictim])
                            {
                                g_iKillCount[iAttacker] += g_cvarSurvivorSIGoal.IntValue + 1;
                            }
                            else
                            {
                                g_iKillCount[iAttacker] += g_cvarSurvivorSIGoal.IntValue;
                            }
                        }
                        if(!g_cvarCountMode.BoolValue)
                        {
                            if(g_iKillCount[iAttacker] <= 1)
                            {
                                CreateTimer(g_cvarCountExpireTime.FloatValue, ResetKillCount, iAttacker, TIMER_FLAG_NO_MAPCHANGE);
                            }
                        }
                        if(g_iKillCount[iAttacker] >= g_cvarSurvivorGoal.IntValue)
                        {
                            if(g_cvarAutomaticStart.BoolValue)
                            {
                                g_iKillCount[iAttacker] = 0;
                                g_bBerserkerEnabled[iAttacker] = true;
                                BeginBerserkerMode(iAttacker);
                            }
                            else
                            {
                                g_iKillCount[iAttacker] = 0;
                                g_bBerserkerEnabled[iAttacker] = true;
                                Announce(iAttacker);
                                DataPack pack;
                                CreateDataTimer(0.1, DisplayHint, pack, TIMER_FLAG_NO_MAPCHANGE);
                                pack.WriteCell(iAttacker);
                                pack.WriteString("Berserker is ready!");
                                pack.WriteString("sm_berserker");
                            }
                        }
                    }
                }
                else
                {
                    if(g_cvarEHSpecialInstant.BoolValue)
                    {
                        if(g_bHasBerserker[iAttacker])
                        {
                            int health = GetClientHealth(iAttacker);
                            if( health > 0 && health < 100)
                            {
                                int total = health + g_cvarEHSpecialBonusAmount.IntValue;
                                if(total > 100)
                                {
                                    total = 100;
                                }
                                SetEntityHealth(iAttacker, total);
                                #if ZKDEBUG
                                PrintToChat(iAttacker, "\x04[ZERK DEBUG]\x01Your health is now %i", total);
                                #endif
                            }
                        }
                    }
                }
                if(g_bHasBerserker[iVictim] && g_cvarYellDead.BoolValue)
                {
                    Yell(iVictim);
                }
            }
        }
    }
}

//On common infected killed
stock void OnCommonKilled(int attacker, char[] weapon, int type)
{
	//@damage type: 8 is equal to recent fire and 2056 refers to an idle fire. Any of them are fire weapons
	LogDebug("[COMMON DEBUG] Common Infected Killed Input Received");

	if(attacker <= 0
	|| !IsValidEntity(attacker)
	|| !IsClientInGame(attacker)
	|| !IsPlayerAlive(attacker)
	|| GetClientTeam(attacker) != 2)
	{
		LogDebug("[COMMON DEBUG] The attacker didnt pass the filters");
		return;
	}

	//Give Health On Berserker
	if(g_bHasBerserker[attacker])
	{
		LogDebug("[COMMON DEBUG] The attacker has berserker active, raise health");
		if(g_cvarEHEnabled.BoolValue)
		{
			g_iKillCountExtra[attacker]+= 1;
			if(g_iKillCountExtra[attacker] >= g_cvarEHGoal.IntValue)
			{
				g_iKillCountExtra[attacker] = 0;
				int health = (GetClientHealth(attacker));
				if( health > 0 && health < 100)
				{
					int total = health + g_cvarEHBonusAmount.IntValue;
					if(total > 100)
					{
						total = 100;
					}
					SetEntityHealth(attacker, total);
					
					#if ZKDEBUG
					PrintToChat(attacker, "\x04[ZERK DEBUG]\x01Your health is now %i", total);
					#endif
				}
			}
		}
		LogDebug("[COMMON DEBUG] Done raising health...");
	}

	g_iTeam[attacker] = GetClientTeam(attacker);

	if(!IsFakeClient(attacker) && !g_bHasBerserker[attacker] && !g_bBerserkerEnabled[attacker] && g_iTeam[attacker] == 2 && g_cvarSurvivorEnable.BoolValue)
	{
		if(!g_cvarIncapRestrict.BoolValue && view_as<bool>(GetEntProp(attacker, Prop_Send, "m_isIncapacitated")))
		{
			LogDebug("[COMMON DEBUG] The attacker was incapacitated and count is disabled for this instance");
			return;
		}
		
		//Only melee kills are valid
		if(g_cvarMeleeOnly.BoolValue && !g_cvarFireWeaponsOnly.BoolValue)
		{
			//Was the damage caused by "world" ? (Molotov, pipe bomb)
			if(StrEqual(weapon, "melee"))
			{
				g_iKillCount[attacker] +=1;
			}
		}
		//Only bullet based kills are valid(Rifles, pistols, snipers, shotguns, etc)
		else if(!g_cvarMeleeOnly.BoolValue && g_cvarFireWeaponsOnly.BoolValue)
		{
			if(!StrEqual(weapon, "melee") && type != 8 && type != 2056)
			{
				g_iKillCount[attacker] +=1;
			}
		}
		//Everything excepting world damage is valid
		else if(g_cvarMeleeOnly.BoolValue && g_cvarFireWeaponsOnly.BoolValue)
		{
			if(type != 8 && type != 2056)
			{
				g_iKillCount[attacker] +=1;
			}
		}
		//Anything is valid
		else if(!g_cvarMeleeOnly.BoolValue && !g_cvarFireWeaponsOnly.BoolValue)
		{
			g_iKillCount[attacker] +=1;
		}
		
		if(!g_cvarCountMode.BoolValue)
		{
			if(g_iKillCount[attacker] <= 1)
			{
				CreateTimer(g_cvarCountExpireTime.FloatValue, ResetKillCount, attacker, TIMER_FLAG_NO_MAPCHANGE);
			}
		}

		if(g_iKillCount[attacker] >= g_cvarSurvivorGoal.IntValue)
		{
			if(g_cvarAutomaticStart.BoolValue)
			{
				g_iKillCount[attacker] = 0;
				g_bBerserkerEnabled[attacker] = true;
				BeginBerserkerMode(attacker);
			}
			else
			{
				g_iKillCount[attacker] = 0;
				g_bBerserkerEnabled[attacker] = true;
				Announce(attacker);
				DataPack pack;
				CreateDataTimer(0.1, DisplayHint, pack, TIMER_FLAG_NO_MAPCHANGE);
				pack.WriteCell(attacker);
				pack.WriteString("Berserker is ready!");
				pack.WriteString("sm_berserker");
			}
		}
	}
	LogDebug("[COMMON DEBUG] Function Call Normal End :: Success / Fail ignored!");
}

//Toggle Berserker
void BeginBerserkerMode(int client)
{
	Forward_BerserkerUsed(client);
	g_iTeam[client] = GetClientTeam(client);
	//If the berserker yell feature is enabled, yell...
	if(g_cvarYell.BoolValue && !IsRestrictedBY(client))
	{
		switch(GetRandomInt(1, g_cvarYellLuck.IntValue))
		{
			case 1:
			{
				if(GetClientTeam(client) == 2 && g_cvarYellSurvivor.BoolValue || GetClientTeam(client) == 3 && g_cvarYellInfected.BoolValue)
				{
					Yell(client);
					g_bDidYell[client] = true;
					#if BYDEBUG
					PrintToConsole(client, "Yelling...");
					#endif
				}
			}
		}
	}
	//Survivors
	g_iTeam[client] = GetClientTeam(client);
	if((g_iTeam[client] == 2) && (IsClientInGame(client)) && (IsPlayerAlive(client)))
	{
		g_iZerkTime[client] = g_cvarSurvivorDuration.IntValue;
		PrintToChat(client, "\x04You are now under berserker mode!");
		g_bHasBerserker[client] = true;
		g_bBerserkerEnabled[client] = false;
		float vec[3];
		
		if(g_cvarAdvEffectSurvivor.BoolValue)
		{
			ShowEffect(client);
		}

		if(g_cvarAdrenType.IntValue == 1)
		{
			CheatCommand(client, "give", "adrenaline");
			#if ZKDEBUG
			PrintToChat(client, "\x04[ZERK DEBUG] \x01Gave you an adrenaline shot");
			#endif
		}
		else if(g_cvarAdrenType.IntValue == 2)
		{
			SDKCall(sdkAdrenaline, client, 15.0);
		}

		if(g_cvarConvertPermHealth.BoolValue)
		{
			int TempHealth = GetClientTempHealth(client);
			if(TempHealth > 0)
			{
				int PermHealth = GetClientHealth(client);
				int total = PermHealth + TempHealth;
				if(total > 100)
				{
					total = 100;
				}
				RemoveTempHealth(client);
				SetEntityHealth(client, total);
			}
		}
		if(g_cvarEffectType.IntValue == 2 || g_cvarEffectType.IntValue == 3)
		{
			//SetEntProp(client, Prop_Send, "m_bAdrenalineActive", 1);
			//CreateTimer(5.0, AdrenTimer, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
		if(g_cvarRefillWeapon.BoolValue)
		{
			CheatCommand(client, "give",  "ammo");
			#if ZKDEBUG
			PrintToChat(client, "\x04[ZERK DEBUG] \x01Refilled your weapon");
			#endif
		}
		
		if(g_cvarSpecialBullets.BoolValue)
		{
			if(!g_cvarInfiniteSpecialBullets.BoolValue)
			{
				CheatCommand(client, "upgrade_add", "incendiary_ammo");
			}
			else
			{
				g_bHasFireBullets[client] = true;
			}

			#if ZKDEBUG
			PrintToChat(client, "\x04[ZERK DEBUG] \x01Gave you fire bullets");
			#endif
		}
		EmitAmbientSound(SOUND_GUITAR, vec, client, SNDLEVEL_GUNFIRE);
		
		if(g_cvarChangeColor.BoolValue)
		{
			switch(g_cvarColor.IntValue)
            {
                case 1: //RED
                {
                    SetEntityRenderColor(client, 189, 9, 13, 235);
                }
                case 2: //BLUE
                {
                    SetEntityRenderColor(client, 34, 22, 173, 235);
                }
                case 3: //GREEN
                {
                    SetEntityRenderColor(client, 34, 120, 24, 235);
                }
                case 4: //BLACK
                {
                    SetEntityRenderColor(client, 0, 0, 0, 235);
                }
                case 5: //INVISIBLE
                {
                    SetEntityRenderColor(client, 255, 255, 255, 0);
                }
            }
		}
		
		#if ZKDEBUG
		PrintToChat(client, "\x04[ZERK DEBUG] \x01Custom color applied");
		#endif
		
		ClientCommand(client, "play %s", SOUND_START);
		#if ZKDEBUG
		PrintToChat(client, "\x04[ZERK DEBUG] \x01 Initial sound played");
		#endif
		
		if(g_cvarPlayMusic.BoolValue)
		{
			CreateTimer(1.2, SoundTimer, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		//God Mode for 3.0 seconds
		if(GetEntProp(client, Prop_Data, "m_takedamage") != 0)
		{
			if(g_cvarEnableImmunity.BoolValue)
			{
				SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
				CreateTimer(g_cvarImmunityDuration.FloatValue, NoDamageTimer, client, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		#if ZKDEBUG
		PrintToChat(client, "\x04[ZERK DEBUG] \x01 Gave initial immunity");
		#endif
		
		//Increased Speed
		SetEntDataFloat(client, g_flLagMovement, 1.2, true);
		#if ZKDEBUG
		PrintToChat(client, "\x04[ZERK DEBUG] \x01Increased your speed");
		#endif
		if(g_cvarEffectType.IntValue == 1 || g_cvarEffectType.IntValue == 3)
		{
			IgniteEntity(client, g_cvarSurvivorDuration.FloatValue);
		}
		#if ZKDEBUG
		PrintToChat(client, "\x04[ZERK DEBUG] \x01Screen effect is being shown");
		#endif
		if(g_cvarGiveLaserSight.BoolValue)
		{
			CheatCommand(client, "upgrade_add", "laser_sight");
			CreateTimer(g_cvarSurvivorDuration.FloatValue, LaserOff, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		CreateTimer(1.0, BerserkEnd, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		//Color SAFE-GUARD
		CreateTimer(g_cvarSurvivorDuration.FloatValue + 5.0, timerRestoreColor, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	//Infected
	else if((g_iTeam[client] == 3) && (IsClientInGame(client)) && !view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated")) && (IsPlayerAlive(client)))
	{
		if(g_cvarAdvEffectInfected.BoolValue)
		{
			ShowEffect(client);
		}
		g_iZerkTime[client] = g_cvarInfectedDuration.IntValue;
		//Announces that berserker is ON
		PrintToChat(client, "\x04 You are now under berserker mode!");
		
		//Controls, declarations, variables, etc
		g_bHasBerserker[client] = true;
		g_bBerserkerEnabled[client] = false;
		float vec[3];
		
		//Sound that will be heard by everyone, from the player casting berserker
		EmitAmbientSound(SOUND_GUITAR, vec, client, SNDLEVEL_GUNFIRE);
		
		//Sets red color for the player
		SetEntityRenderColor(client, 189, 9, 13, 235);
		#if ZKDEBUG
		PrintToChat(client, "\x04[ZERK DEBUG]\x01Custom color has been set for you");
		#endif
		
		//Starts berserker music, if enabled on the config file
		ClientCommand(client, "play %s", SOUND_START);
		#if ZKDEBUG
		PrintToChat(client, "\x04[ZERK DEBUG]\x01Playing specified music");
		#endif
		
		if(g_cvarPlayMusic.BoolValue)
		{
			CreateTimer(1.2, SoundTimer, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		
		//[DISABLED] Attempt to give temporal health, which failed. This function is useless, but wasn't deleted for other reasons
		//Extra infected health
		if(g_cvarEIHEnabled.BoolValue && !IsRestrictedEIH(client))
		{
			int health = GetClientHealth(client);
			float dmgbonus = g_cvarEIHMultiplier.FloatValue;
			float total = health * dmgbonus;
			int inttotal = RoundToFloor(total);
			SetEntityHealth(client, inttotal);
		}
		
		//Increases Speed
		SetEntDataFloat(client, g_flLagMovement, 1.2, true);
		#if ZKDEBUG
		PrintToChat(client, "\x04[ZERK DEBUG]\x01Increased your speed");
		#endif
		
		//Create timer to disable berserker later
		CreateTimer(1.0, BerserkEnd, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		//Color SAFE-GUARD
		CreateTimer(g_cvarInfectedDuration.FloatValue + 5.0, timerRestoreColor, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	RebuildAll();
}

//Play Music On Berserker
Action SoundTimer(Handle timer, any client)
{
    if(!IsClientInGame(client) || !IsValidEntity(client)) return Plugin_Stop;

    //Starts music
    if(g_cvarEnableMusicShield.BoolValue && GetTankCount() == 0 && !g_bFinaleEscape)
    {
        ClientCommand(client, "play %s", g_sBerserkMusic);
    }
    else if(!g_cvarEnableMusicShield.BoolValue)
    {
        ClientCommand(client, "play %s", g_sBerserkMusic);
    }
    #if ZKDEBUG
    PrintToChat(client, "\x04[ZERK DEBUG]\x01Music has started");
    #endif
    //Creates timer to disable the music later
    CreateTimer(1.0, STOPSOUND, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    return Plugin_Stop;
}

//Stops Music
Action STOPSOUND(Handle timer, any client)
{
	if(g_bIsLoading)
	{
		if(client > 0 && IsValidEntity(client) && IsClientInGame(client) && !IsFakeClient(client))
		{
			//To avoid disable errors on music, apply the command multiple times
			ClientCommand(client, "play %s", SOUND_NONE);
			ClientCommand(client, "play %s", SOUND_NONE);
			ClientCommand(client, "play %s", SOUND_NONE);
			ClientCommand(client, "play %s", SOUND_NONE);
			ClientCommand(client, "play %s", SOUND_NONE);
			ClientCommand(client, "play %s", SOUND_NONE);
			
			//Set default color
			SetEntityRenderColor(client, 255, 255, 255, 255);
			#if ZKDEBUG
			PrintToChat(client, "\x04[ZERK DEBUG]\x01 Music is over");
			#endif
			ClientCommand(client, "play %s", SOUND_NONE);
			#if ZKDEBUG
			PrintToChat(client, "\x04[ZERK DEBUG] \x01Returned to the default color");
			#endif
			//Stop music and announce that the berserker is over
			PrintToChat(client, "\x04Berserker mode is over");
			ClientCommand(client, "play %s", SOUND_NONE);
			ClientCommand(client, "play %s", SOUND_NONE);
			ClientCommand(client, "play %s", SOUND_END);
			StopSound(client, SNDCHAN_AUTO, g_sBerserkMusic);
		}
		return Plugin_Stop;
	}
	else if(!client
	|| !IsValidEntity(client)
	|| !IsClientInGame(client))
	{
		return Plugin_Stop;
	}
	
	if(!g_bHasBerserker[client])
	{
		//To avoid disable errors on music, apply the command multiple times
		ClientCommand(client, "play %s", SOUND_NONE);
		ClientCommand(client, "play %s", SOUND_NONE);
		ClientCommand(client, "play %s", SOUND_NONE);
		ClientCommand(client, "play %s", SOUND_NONE);
		ClientCommand(client, "play %s", SOUND_NONE);
		ClientCommand(client, "play %s", SOUND_NONE);
		
		//Set default color
		SetEntityRenderColor(client, 255, 255, 255, 255);
		#if ZKDEBUG
		PrintToChat(client, "\x04[ZERK DEBUG]\x01 Music is over");
		#endif
		ClientCommand(client, "play %s", SOUND_NONE);
		#if ZKDEBUG
		PrintToChat(client, "\x04[ZERK DEBUG] \x01Returned to the default color");
		#endif
		//Stop music and announce that the berserker is over
		PrintToChat(client, "\x04Berserker mode is over");
		ClientCommand(client, "play %s", SOUND_NONE);
		ClientCommand(client, "play %s", SOUND_NONE);
		ClientCommand(client, "play %s", SOUND_END);
		StopSound(client, SNDCHAN_AUTO, g_sBerserkMusic);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

//Remove God Mode
Action NoDamageTimer(Handle timer, any client)
{
    //Retrieves temporal god mode
    SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
    return Plugin_Stop;
}

//Remove laser
Action LaserOff(Handle timer, any client)
{
    if(!IsClientInGame(client) || !IsValidEntity(client)) return Plugin_Stop;
    //Retrieves the laser
    CheatCommand(client, "upgrade_remove", "laser_sight");
    return Plugin_Stop;
}

//End Berserker
Action BerserkEnd(Handle timer, any client)
{
	if(g_bIsLoading
	|| !client
	|| !IsValidEntity(client)
	|| !IsClientInGame(client))
	{
		g_bDidYell[client] = false;
		//Sets speed to default (Normal)
		if(client > 0 && IsValidEntity(client) && IsClientInGame(client))
		{
			SetEntDataFloat(client, g_flLagMovement, 1.0, true);
		}
		#if ZKDEBUG
		PrintToChat(client, "\x04[ZERK DEBUG] \x01Returned to normal speed");
		#endif
		//Set berserker control to 0 (OFF)
		g_bHasBerserker[client] = false;
		g_bHasFireBullets[client] = false;
		g_iZerkTime[client] = g_cvarInfectedDuration.IntValue;
		RebuildAll();
		#if ZKDEBUG
		PrintToChat(client, "\x04[ZERK DEBUG] \x01Berserker mode is over!");
		#endif
		return Plugin_Stop;
	}
	if(IsRestrictedALL(client))
	{
		g_bDidYell[client] = false;
		//Sets speed to default (Normal)
		if(client > 0 && IsValidEntity(client) && IsClientInGame(client))
		{
			SetEntDataFloat(client, g_flLagMovement, 1.0, true);
			#if ZKDEBUG
			PrintToChat(client, "\x04[ZERK DEBUG] \x01Returned to normal speed");
			#endif
		}
		//Set berserker control to 0 (OFF)
		g_bHasBerserker[client] = false;
		g_bHasFireBullets[client] = false;
		g_iZerkTime[client] = g_cvarInfectedDuration.IntValue;
		RebuildAll();
		#if ZKDEBUG
		PrintToChat(client, "\x04[ZERK DEBUG] \x01Berserker mode is over!");
		#endif
		PrintToChat(client, "\x04Berserker Mode is disabled with this infected, stopping");
		return Plugin_Stop;
	}
	if(g_iTeam[client] == 3 && (!IsPlayerAlive(client) || GetEntProp(client, Prop_Send, "m_isGhost") == 1))
	{
		PrintHintText(client, "The berserker mode is paused, take your time to spawn!");
		return Plugin_Continue;
	}
	g_iZerkTime[client]--;
	if(g_iZerkTime[client] <= 0)
	{
		g_bDidYell[client] = false;
		//Sets speed to default (Normal)
		SetEntDataFloat(client, g_flLagMovement, 1.0, true);
		#if ZKDEBUG
		PrintToChat(client, "\x04[ZERK DEBUG] \x01Returned to normal speed");
		#endif
		//Set berserker control to 0 (OFF)
		g_bHasBerserker[client] = false;
		g_bHasFireBullets[client] = false;
		g_iZerkTime[client] = g_cvarInfectedDuration.IntValue;
		RebuildAll();
		#if ZKDEBUG
		PrintToChat(client, "\x04[ZERK DEBUG] \x01Berserker mode is over!");
		#endif
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

//Timers and checkers for god mode and other functions

//Timer - Survivor Incapacitation god mode checker
Action CheckZerk(Handle timer, any client)
{
	//Is the player under berserker mode? If no, retrieve god mode
	if(!g_bHasBerserker[client] && client > 0 && IsValidEntity(client) && IsClientInGame(client))
	{		
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		#if ZKDEBUG
		PrintToChat(client, "\x04[ZERK DEBUG] \x01Incapacitation immunity is no longer being applied");
		#endif
		return Plugin_Stop;
	}
	
	//If yes, continue checking
	return Plugin_Continue;
}

//Timer - Infected god mode checker (Will check if the berserker is disabled to remove godmode
Action CheckInfectedZerk(Handle timer, any client)
{
	//Is the player under berserker mode AND is using his special ability? If No, remove god mode
	if(client > 0 && IsValidEntity(client) && IsClientInGame(client) && ((!g_bHasBerserker[client]) || ((!g_bIsRiding[client]) && (!g_bIsPouncing[client]) && (!g_bIsChoking[client]))))
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		#if ZKDEBUG
		PrintToChat(client, "\x04[ZERK DEBUG] \x01Immunity during special ability ended");
		#endif
		return Plugin_Stop;
	}
	
	//If yes, continue checking
	return Plugin_Continue;
}

//Timer - Will reset the kill count in case the goal isnt reached in time
Action ResetKillCount(Handle timer, any client)
{
    g_iKillCount[client] = 0;
    return Plugin_Stop;
}

//Timer - Will set the default color again in case it has not come back yet
Action timerRestoreColor(Handle timer, any client)
{
    if(client > 0 && IsValidEntity(client) && IsClientInGame(client) && GetClientTeam(client) != 1 && IsPlayerAlive(client))
    {
        SetEntityRenderColor(client, 255, 255, 255, 255);
        SetEntityRenderColor(client, 255, 255, 255, 255);
        SetEntityRenderColor(client, 255, 255, 255, 255);
        SetEntityRenderColor(client, 255, 255, 255, 255);
        SetEntityRenderColor(client, 255, 255, 255, 255);
        DispatchKeyValue(client, "color", "255 255 255 255");
        DispatchKeyValue(client, "color", "255 255 255 255");
        DispatchKeyValue(client, "color", "255 255 255 255");
        SetEntityRenderColor(client, 255, 255, 255, 255);
    }
    return Plugin_Stop;
}
//Zoom button used (Default)
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
    //If the admin doesnt want this to be the default key, then dont even bother on doing anything.
    if(!g_cvarBindKey.BoolValue || (!g_cvarAllowZoomKey.BoolValue && g_cvarKeyToBind.IntValue == 1) || !g_cvarKeyToBind.BoolValue)
    {
        return Plugin_Continue;
    }

    //If client index is equal to 0 (world), abort
    if(client == 0)
    {
        return Plugin_Continue;
    }

    //If the player is no running berserker, and it is also ready to be activated, begin it.
    if((((buttons & IN_ZOOM) && g_cvarKeyToBind.IntValue == 1) || ((buttons & IN_RELOAD) && g_cvarKeyToBind.IntValue == 2)) && !g_bHasBerserker[client] && g_bBerserkerEnabled[client] &&!IsRestrictedALL(client) && (!g_cvarIncapRestrict.BoolValue && !view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated")) || g_cvarIncapRestrict.BoolValue))
    {
        BeginBerserkerMode(client);
        #if CTDEBUG
        PrintToServer("[PLUGIN]%s began berserker mode by command", client);
        PrintToChat(client, "[PLUGIN]You began berserker mode by command");
        #endif
    }
    //If not, proceed to print chat information
    else
    {
        //If the player is restricted
        if((buttons & IN_ZOOM) && !g_bHasBerserker[client] && !g_bBerserkerEnabled[client] && IsRestrictedALL(client))
        {
            return Plugin_Continue;
        }
        
        //If the player was already under berserk mode...
        if((buttons & IN_ZOOM) && g_bHasBerserker[client])
        {
            return Plugin_Continue;
        }
        if(!g_cvarIncapRestrict.BoolValue && view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated")))
        {
            return Plugin_Continue;
        }
        //If the berserker is not ready for the player...
        else if((buttons & IN_ZOOM) && !g_bBerserkerEnabled[client])
        {			
            #if CTDEBUG
            char name[256];
            GetClientName(client, name, sizeof(name));
            PrintToServer("[PLUGIN]%s tried to use berserker, but failed", name);
            PrintToChat(client, "[PLUGIN]You failed to begin berserker. REASON: Goal not reached");
            #endif
            return Plugin_Continue;
        }
    }
    return Plugin_Continue;
}

//Displaying the instructor Hint
Action DisplayHint(Handle timer, DataPack pack)
{
    char  msg[256], bind[16], msgphrase[256];
    pack.Reset();
    int client = GetClientOfUserId(pack.ReadCell());
    if(!client || !IsValidEntity(client) || !IsClientInGame(client))
    {
        return Plugin_Stop;
    }
    pack.ReadString(msg, sizeof(msg));
    pack.ReadString(bind, sizeof(bind));

    int HintEntity;
    char name[32];
    HintEntity = CreateEntityByName("env_instructor_hint");
    FormatEx(name, sizeof(name), "TRIH%d", client);
    DispatchKeyValue(client, "targetname", name);
    DispatchKeyValue(HintEntity, "hint_target", name);

    DispatchKeyValue(HintEntity, "hint_range", "0.01");
    DispatchKeyValue(HintEntity, "hint_color", "255 255 255");
    DispatchKeyValue(HintEntity, "hint_caption", msgphrase);
    DispatchKeyValue(HintEntity, "hint_icon_onscreen", "use_binding");
    DispatchKeyValue(HintEntity, "hint_binding", bind);
    DispatchKeyValue(HintEntity, "hint_timeout", "6.0");
    ClientCommand(client, "gameinstructor_enable 1");
    DispatchSpawn(HintEntity);
    AcceptEntityInput(HintEntity, "ShowHint");
    CreateTimer(6.0, DisableInstructor, client, TIMER_FLAG_NO_MAPCHANGE);
    return Plugin_Stop;
}

//Disable instructor
Action DisableInstructor(Handle timer, any client)
{
    ClientCommand(client, "gameinstructor_enable 0");
    return Plugin_Stop;
}

//Disable Berserker on some circunstances

//Using commands that need sv_cheats 1 on them.
void CheatCommand(int client, const char[] command, const char[] arguments)
{
	if (!client) return;
	if (!IsClientInGame(client)) return;
	if (!IsValidEntity(client)) return;
	int admindata = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	int flags = GetCommandFlags (command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, admindata);
}

//Is valid bullet based?
stock bool IsValidBulletBased(char[] weapon)
{
	return StrEqual(weapon, "CAutoShotgun") || StrEqual(weapon, "CSniperRifle") || StrEqual(weapon, "CPistol") || StrEqual(weapon, "CMagnumPistol") || StrEqual(weapon, "CAssaultRifle") || StrEqual(weapon, "CRifle_Desert") || StrEqual(weapon, "CSubMachinegun") || StrEqual(weapon, "CSNG_Silenced") || StrEqual(weapon, "CSniper_Military") || StrEqual(weapon, "CRifle_AK47") || StrEqual(weapon, "CRifle_SG552") || StrEqual(weapon, "CShotgun_Chrome") || StrEqual(weapon, "CShotgun_SPAS") || StrEqual(weapon, "CPumpShotgun") || StrEqual(weapon, "CSMG_MP5") || StrEqual(weapon, "CSniper_AWP") || StrEqual(weapon, "CSniper_Scout");
}

//This code belongs to Dusty1029, from here until it is specified, the code was made by him, and have no credits for it!
//On the start of a reload
void AdrenReload(int client)
{
    if (GetClientTeam(client) == 2)
    {
        #if RSDEBUG
        PrintToChatAll("\x03Client \x01%i\x03; start of reload detected",client );
        #endif
        int iEntid = GetEntDataEnt2(client, g_iActiveWO);
        if (IsValidEntity(iEntid)==false) return;

        char stClass[32];
        GetEntityNetClass(iEntid,stClass,32);

        //for non-shotguns
        if (StrContains(stClass,"shotgun",false) == -1)
        {
            MagStart(iEntid, client);
            return;
        }
        //shotguns are a bit trickier since the game tracks per shell inserted
        //and there's TWO different shotguns with different values...
        else if (StrContains(stClass,"autoshotgun",false) != -1)
        {
            //create a pack to send clientid and gunid through to the timer
            DataPack hPack;
            CreateDataTimer(0.1,Timer_AutoshotgunStart,hPack, TIMER_FLAG_NO_MAPCHANGE);
            hPack.WriteCell(client);
            hPack.WriteCell(iEntid);
            return;
        }
        else if (StrContains(stClass,"shotgun_spas",false) != -1)
        {
            //similar to the autoshotgun, create a pack to send
            DataPack hPack;
            CreateDataTimer(0.1,Timer_SpasShotgunStart,hPack, TIMER_FLAG_NO_MAPCHANGE);
            hPack.WriteCell(client);
            hPack.WriteCell(iEntid);
            return;
        }
        else if (StrContains(stClass,"pumpshotgun",false) != -1 || StrContains(stClass,"shotgun_chrome",false) != -1)
        {
            DataPack hPack;
            CreateDataTimer(0.1,Timer_PumpshotgunStart,hPack, TIMER_FLAG_NO_MAPCHANGE);
            hPack.WriteCell(client);
            hPack.WriteCell(iEntid);
            return;
        }
    }
}
// ////////////////////////////////////////////////////////////////////////////
//called for mag loaders
void MagStart(int iEntid, int client)
{
	if(client > 0)
	{
		#if RSDEBUG
		PrintToChatAll("\x05-magazine loader detected,\x03 gametime \x01%f", GetGameTime());
		#endif
		float flGameTime = GetGameTime();
		float flNextTime_ret = GetEntDataFloat(iEntid,g_iNextPAttO);
		#if RSDEBUG
		PrintToChatAll("\x03- pre, gametime \x01%f\x03, retrieved nextattack\x01 %i %f\x03, retrieved time idle \x01%i %f",
			flGameTime,
			g_iNextAttO,
			GetEntDataFloat(client,g_iNextAttO),
			g_iTimeIdleO,
			GetEntDataFloat(iEntid,g_iTimeIdleO)
			);
		#endif

		//this is a calculation of when the next primary attack will be after applying reload values
		//NOTE: at this point, only calculate the interval itself, without the actual game engine time factored in
		
		float flNextTime_calc = ( flNextTime_ret - flGameTime ) * g_fl_reload_rate ;
		
		//we change the playback rate of the gun, just so the player can "see" the gun reloading faster
		
		SetEntDataFloat(iEntid, g_iPlayRateO, 1.0/g_fl_reload_rate, true);
		
		//create a timer to reset the playrate after time equal to the modified attack interval
		
		CreateTimer( flNextTime_calc, Timer_MagEnd, iEntid, TIMER_FLAG_NO_MAPCHANGE);
		
		//experiment to remove double-playback bug
		DataPack hPack;
		//now we create the timer that will prevent the annoying double playback
		if ( (flNextTime_calc - 0.4) > 0 )
		{
			CreateDataTimer(flNextTime_calc - 0.4, Timer_MagEnd2, hPack, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			CreateDataTimer(flNextTime_calc, Timer_MagEnd2, hPack, TIMER_FLAG_NO_MAPCHANGE);
		}
		hPack.WriteCell(client);
		//this calculates the equivalent time for the reload to end
		float flStartTime_calc = flGameTime - ( flNextTime_ret - flGameTime ) * ( 1 - g_fl_reload_rate ) ;
		hPack.WriteFloat(flStartTime_calc);
		//and finally we set the end reload time into the gun so the player can actually shoot with it at the end
		flNextTime_calc += flGameTime;
		SetEntDataFloat(iEntid, g_iTimeIdleO, flNextTime_calc, true);
		SetEntDataFloat(iEntid, g_iNextPAttO, flNextTime_calc, true);
		SetEntDataFloat(client, g_iNextAttO, flNextTime_calc, true);
		#if RSDEBUG
		PrintToChatAll("\x03- post, calculated nextattack \x01%f\x03, gametime \x01%f\x03, retrieved nextattack\x01 %i %f\x03, retrieved time idle \x01%i %f",
			flNextTime_calc,
			flGameTime,
			g_iNextAttO,
			GetEntDataFloat(client,g_iNextAttO),
			g_iTimeIdleO,
			GetEntDataFloat(iEntid,g_iTimeIdleO)
			);
		#endif
	}
}

//called for autoshotguns
Action Timer_AutoshotgunStart (Handle timer, DataPack hPack)
{
	timer = null;
	if (IsServerProcessing()==false)
		return Plugin_Stop;

	hPack.Reset();
	int iCid = hPack.ReadCell();
	int iEntid = hPack.ReadCell();

	if (iCid <= 0
		|| iEntid <= 0
		|| IsValidEntity(iCid)==false
		|| IsValidEntity(iEntid)==false
		|| IsClientInGame(iCid)==false)
		return Plugin_Stop;

	#if RSDEBUG
	PrintToChatAll("\x03-autoshotgun detected, iEntid \x01%i\x03, startO \x01%i\x03, insertO \x01%i\x03, endO \x01%i",
		iEntid,
		g_iShotStartDurO,
		g_iShotInsertDurO,
		g_iShotEndDurO
		);
	PrintToChatAll("\x03- pre mod, start \x01%f\x03, insert \x01%f\x03, end \x01%f",
		g_fl_AutoS,
		0.4,
		g_fl_AutoE
		);
	#endif
		
	//then we set the new times in the gun
	SetEntDataFloat(iEntid,	g_iShotStartDurO,	g_fl_AutoS*g_fl_reload_rate,	true);
	SetEntDataFloat(iEntid,	g_iShotInsertDurO,	0.4*g_fl_reload_rate,	true);
	SetEntDataFloat(iEntid,	g_iShotEndDurO,		g_fl_AutoE*g_fl_reload_rate,	true);

	//we change the playback rate of the gun just so the player can "see" the gun reloading faster
	SetEntDataFloat(iEntid, g_iPlayRateO, 1.0/g_fl_reload_rate, true);

	//and then call a timer to periodically check whether the gun is still reloading or not to reset the animation
	//but first check the reload state; if it's 2, then it needs a pump/cock before it can shoot again, and thus needs more time
	if (g_bL4D2)
	{
		CreateDataTimer(0.3, Timer_ShotgunEnd, hPack, TIMER_REPEAT |TIMER_FLAG_NO_MAPCHANGE);
	}

	hPack.WriteCell(iCid);
	hPack.WriteCell(iEntid);

	#if RSDEBUG
	PrintToChatAll("\x03- after mod, start \x01%f\x03, insert \x01%f\x03, end \x01%f",
		g_fl_AutoS,
		0.4,
		g_fl_AutoE
		);
	#endif

	return Plugin_Stop;
}

Action Timer_SpasShotgunStart (Handle timer, DataPack hPack)
{
	timer = null;
	if (IsServerProcessing()==false)
		return Plugin_Stop;

	ResetPack(hPack);
	int iCid = hPack.ReadCell();
	int iEntid = hPack.ReadCell();

	if (iCid <= 0
		|| iEntid <= 0
		|| IsValidEntity(iCid)==false
		|| IsValidEntity(iEntid)==false
		|| IsClientInGame(iCid)==false)
		return Plugin_Stop;

	#if RSDEBUG
	PrintToChatAll("\x03-autoshotgun detected, iEntid \x01%i\x03, startO \x01%i\x03, insertO \x01%i\x03, endO \x01%i",
		iEntid,
		g_iShotStartDurO,
		g_iShotInsertDurO,
		g_iShotEndDurO
		);
	PrintToChatAll("\x03- pre mod, start \x01%f\x03, insert \x01%f\x03, end \x01%f",
		g_fl_SpasS,
		g_fl_SpasI,
		0.699999
		);
	#endif
		
	//then we set the new times in the gun
	SetEntDataFloat(iEntid,	g_iShotStartDurO,	g_fl_SpasS*g_fl_reload_rate,	true);
	SetEntDataFloat(iEntid,	g_iShotInsertDurO,	g_fl_SpasI*g_fl_reload_rate,	true);
	SetEntDataFloat(iEntid,	g_iShotEndDurO,		0.699999*g_fl_reload_rate,	true);

	//we change the playback rate of the gun just so the player can "see" the gun reloading faster
	SetEntDataFloat(iEntid, g_iPlayRateO, 1.0/g_fl_reload_rate, true);

	//and then call a timer to periodically check whether the gun is still reloading or not to reset the animation
	//but first check the reload state; if it's 2, then it needs a pump/cock before it can shoot again, and thus needs more time
	CreateDataTimer(0.3, Timer_ShotgunEnd, hPack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	hPack.WriteCell(iCid);
	hPack.WriteCell(iEntid);

	#if RSDEBUG
	PrintToChatAll("\x03- after mod, start \x01%f\x03, insert \x01%f\x03, end \x01%f",
		g_fl_SpasS,
		g_fl_SpasI,
		0.699999
		);
	#endif

	return Plugin_Stop;
}

//called for pump/chrome shotguns
Action Timer_PumpshotgunStart (Handle timer, DataPack hPack)
{
	timer = null;
	if (IsServerProcessing()==false)
		return Plugin_Stop;

	hPack.Reset();
	int iCid = hPack.ReadCell();
	int iEntid = hPack.ReadCell();

	if (iCid <= 0
		|| iEntid <= 0
		|| IsValidEntity(iCid)==false
		|| IsValidEntity(iEntid)==false
		|| IsClientInGame(iCid)==false)
		return Plugin_Stop;

	#if RSDEBUG
	PrintToChatAll("\x03-pumpshotgun detected, iEntid \x01%i\x03, startO \x01%i\x03, insertO \x01%i\x03, endO \x01%i",
		iEntid,
		g_iShotStartDurO,
		g_iShotInsertDurO,
		g_iShotEndDurO
		);
	PrintToChatAll("\x03- pre mod, start \x01%f\x03, insert \x01%f\x03, end \x01%f",
		g_fl_PumpS,
		g_fl_PumpI,
		g_fl_PumpE
		);
	#endif

	//then we set the new times in the gun
	SetEntDataFloat(iEntid,	g_iShotStartDurO,	g_fl_PumpS*g_fl_reload_rate,	true);
	SetEntDataFloat(iEntid,	g_iShotInsertDurO,	g_fl_PumpI*g_fl_reload_rate,	true);
	SetEntDataFloat(iEntid,	g_iShotEndDurO,		g_fl_PumpE*g_fl_reload_rate,	true);

	//we change the playback rate of the gun just so the player can "see" the gun reloading faster
	SetEntDataFloat(iEntid, g_iPlayRateO, 1.0/g_fl_reload_rate, true);

	//and then call a timer to periodically check whether the gun is still reloading or not to reset the animation
	if (g_bL4D2)
		CreateDataTimer(0.3, Timer_ShotgunEnd, hPack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

	hPack.WriteCell(iCid);
	hPack.WriteCell(iEntid);

	#if RSDEBUG
	PrintToChatAll("\x03- after mod, start \x01%f\x03, insert \x01%f\x03, end \x01%f",
		g_fl_PumpS,
		g_fl_PumpI,
		g_fl_PumpE
		);
	#endif

	return Plugin_Stop;
}
// ////////////////////////////////////////////////////////////////////////////
//this resets the playback rate on non-shotguns
Action Timer_MagEnd (Handle timer, any iEntid)
{
	timer = null;
	if (IsServerProcessing()==false)
		return Plugin_Stop;

	#if RSDEBUG
	PrintToChatAll("\x03Reset playback, magazine loader");
	#endif

	if (iEntid <= 0 || IsValidEntity(iEntid)==false)
		return Plugin_Stop;

	SetEntDataFloat(iEntid, g_iPlayRateO, 1.0, true);

	return Plugin_Stop;
}

Action Timer_MagEnd2(Handle timer, DataPack hPack)
{
	timer = null;
	if (IsServerProcessing() == false)
	{
		return Plugin_Stop;
	}

	#if RSDEBUG
	PrintToChatAll("\x03Reset playback, magazine loader");
	#endif

	hPack.Reset();
	int iCid = hPack.ReadCell();
	float flStartTime_calc = hPack.ReadFloat();

	if (iCid <= 0 || IsValidEntity(iCid) == false || IsClientInGame(iCid) == false)
		return Plugin_Stop;

	//experimental, remove annoying double-playback
	int iVMid = GetEntDataEnt2(iCid, g_iViewModelO);
	SetEntDataFloat(iVMid, g_iVMStartTimeO, flStartTime_calc, true);

	#if RSDEBUG
	PrintToChatAll("\x03- end mag loader, icid \x01%i\x03 starttime \x01%f\x03 gametime \x01%f", iCid, flStartTime_calc, GetGameTime());
	#endif

	return Plugin_Stop;
}

Action Timer_ShotgunEnd(Handle timer, DataPack hPack)
{
	#if RSDEBUG
	PrintToChatAll("\x03-autoshotgun tick");
	#endif

	hPack.Reset();
	int iCid = hPack.ReadCell();
	int iEntid = hPack.ReadCell();

	if (IsServerProcessing()==false
		|| iCid <= 0
		|| iEntid <= 0
		|| IsValidEntity(iCid)==false
		|| IsValidEntity(iEntid)==false
		|| IsClientInGame(iCid)==false)
	{
		timer = null;
		return Plugin_Stop;
	}

	if (GetEntData(iEntid,g_iShotRelStateO)==0)
	{
		#if RSDEBUG
		PrintToChatAll("\x03-shotgun end reload detected");
		#endif

		SetEntDataFloat(iEntid, g_iPlayRateO, 1.0, true);

		//new iCid=GetEntPropEnt(iEntid,Prop_Data,"m_hOwner");
		float flTime = GetGameTime() + 0.2;
		SetEntDataFloat(iCid,	g_iNextAttO,	flTime,	true);
		SetEntDataFloat(iEntid,	g_iTimeIdleO,	flTime,	true);
		SetEntDataFloat(iEntid,	g_iNextPAttO,	flTime,	true);

		timer = null;
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

void RebuildAll()
{
	MA_Rebuild();
	DT_Rebuild();
}

void ClearAll()
{
	MA_Clear();
	DT_Clear();
}
// ////////////////////////////////////////////////////////////////////////////
//called whenever the registry needs to be rebuilt to cull any players who have left or died, etc.
//resets survivor's speeds and reassigns speed boost
//(called on: player death, player disconnect, adrenaline popped, adrenaline ended, -> change teams, convar change)
void MA_Rebuild()
{
	//clears all DT-related vars
	MA_Clear();
	//if the server's not running or is in the middle of loading, stop
	if (IsServerProcessing()==false)
		return;
	#if RSDEBUG
	PrintToChatAll("\x03Rebuilding melee registry");
	#endif
	for (int iI = 1 ; iI <= MaxClients ; iI++)
	{
		if (IsClientInGame(iI)==true && IsPlayerAlive(iI)==true && GetClientTeam(iI)==2 && g_bHasBerserker[iI])
		{
			g_iMARegisterCount++;
			g_iMARegisterIndex[g_iMARegisterCount]=iI;
			#if RSDEBUG
			PrintToChatAll("\x03-registering \x01%i",iI);
			#endif
		}
	}
}

//called to clear out registry and reset movement speeds
//(called on: round start, round end, map end)
void MA_Clear()
{
	g_iMARegisterCount=0;
	#if RSDEBUG
	PrintToChatAll("\x03Clearing melee registry");
	#endif
	for (int iI = 1 ; iI <= MaxClients ; iI++)
	{
		g_iMARegisterIndex[iI]= -1;
	}
}
// ////////////////////////////////////////////////////////////////////////////
//called whenever the registry needs to be rebuilt to cull any players who have left or died, etc.
//(called on: player death, player disconnect, closet rescue, change teams)
void DT_Rebuild()
{
	//clears all DT-related vars
	DT_Clear();

	//if the server's not running or is in the middle of loading, stop
	if (IsServerProcessing() == false)
		return;

	#if RSDEBUG
	PrintToChatAll("\x03Rebuilding weapon firing registry");
	#endif
	for (int iI = 1 ; iI <= MaxClients ; iI++)
	{
		if (IsClientInGame(iI) == true && IsPlayerAlive(iI) == true && GetClientTeam(iI) == 2 && g_bHasBerserker[iI])
		{
			g_iDTRegisterCount++;
			g_iDTRegisterIndex[g_iDTRegisterCount]=iI;
			#if RSDEBUG
			PrintToChatAll("\x03-registering \x01%i",iI);
			#endif
		}
	}
}

//called to clear out DT registry
//(called on: round start, round end, map end)
void DT_Clear()
{
	g_iDTRegisterCount=0;
	#if RSDEBUG
	PrintToChatAll("\x03Clearing weapon firing registry");
	#endif
	for (int iI = 1 ; iI <= MaxClients ; iI++)
	{
		g_iDTRegisterIndex[iI]= -1;
		g_iDTEntid[iI] = -1;
		g_flDTNextTime[iI]= -1.0;
	}
}
/* ***************************************************************************/
//Since this is called EVERY game frame, we need to be careful not to run too many functions
//kinda hard, though, considering how many things we have to check for =.=
void MA_OnGameFrame()
{
	// if plugin is disabled, don't bother
	if (!g_cvarFasterSwinging.BoolValue)
		return;
	// or if no one has MA, don't bother either
	if (g_iMARegisterCount==0)
		return;

	int iCid;
	//this tracks the player's ability id
	int iEntid;
	//this tracks the calculated next attack
	float flNextTime_calc;
	//this, on the other hand, tracks the current next attack
	float flNextTime_ret;
	//and this tracks the game time
	float flGameTime = GetGameTime();

	//theoretically, to get on the MA registry, all the necessary checks would have already
	//been run, so we don't bother with any checks here
	for (int iI = 1; iI <= g_iMARegisterCount; iI++)
	{
		if(!g_bHasBerserker[iI])
		{
			continue;
		}
		//PRE-CHECKS 1: RETRIEVE VARS
		//---------------------------
		iCid = g_iMARegisterIndex[iI];
		//stop on this client when the next client id is null
		if (iCid <= 0) continue;
		if(!IsClientInGame(iCid)) continue;
		if(!IsClientConnected(iCid)) continue; 
		if (!IsPlayerAlive(iCid)) continue;
		if(GetClientTeam(iCid) != 2) continue;
		iEntid = GetEntDataEnt2(iCid,g_ActiveWeaponOffset);
		//if the retrieved gun id is -1, then...
		//wtf mate? just move on
		if (iEntid == -1) continue;
		//and here is the retrieved next attack time
		flNextTime_ret = GetEntDataFloat(iEntid,g_iNextPAttO);

		//CHECK 1: IS PLAYER USING A KNOWN NON-MELEE WEAPON?
		//--------------------------------------------------
		//as the title states... to conserve processing power,
		//if the player's holding a gun for a prolonged time
		//then we want to be able to track that kind of state
		//and not bother with any checks
		//checks: weapon is non-melee weapon
		//actions: do nothing
		if (iEntid == g_iMAEntid_notmelee[iCid])
		{
			// PrintToChatAll("\x03Client \x01%i\x03; non melee weapon, ignoring",iCid );
			continue;
		}

		//CHECK 1.5: THE PLAYER HASN'T SWUNG HIS WEAPON FOR A WHILE
		//---------------------------------------------------------
		//in this case, if the player made 1 swing of his 2 strikes, and then paused long enough, 
		//we should reset his strike count so his next attack will allow him to strike twice
		//checks: is the delay between attacks greater than 1.5s?
		//actions: set attack count to 0, and CONTINUE CHECKS
		if (g_iMAEntid[iCid] == iEntid
				&& g_iMAAttCount[iCid]!=0
				&& (flGameTime - flNextTime_ret) > 1.0)
		{
			#if RSDEBUG
			PrintToChatAll("\x03Client \x01%i\x03; hasn't swung weapon",iCid );
			#endif
			g_iMAAttCount[iCid]=0;
		}

		//CHECK 2: BEFORE ADJUSTED ATT IS MADE
		//------------------------------------
		//since this will probably be the case most of the time, we run this first
		//checks: weapon is unchanged; time of shot has not passed
		//actions: do nothing
		if (g_iMAEntid[iCid] == iEntid
				&& g_flMANextTime[iCid]>=flNextTime_ret)
		{
			// PrintToChatAll("\x03DT client \x01%i\x03; before shot made",iCid );
			continue;
		}

		//CHECK 3: AFTER ADJUSTED ATT IS MADE
		//------------------------------------
		//at this point, either a gun was swapped, or the attack time needs to be adjusted
		//checks: stored gun id same as retrieved gun id,
		//        and retrieved next attack time is after stored value
		//actions: adjusts next attack time
		if (g_iMAEntid[iCid] == iEntid
				&& g_flMANextTime[iCid] < flNextTime_ret)
		{
			//----RSDEBUG----
			//PrintToChatAll("\x03DT after adjusted shot\n-pre, client \x01%i\x03; entid \x01%i\x03; enginetime\x01 %f\x03; NextTime_orig \x01 %f\x03; interval \x01%f",iCid,iEntid,flGameTime,flNextTime_ret, flNextTime_ret-flGameTime );

			//this is a calculation of when the next primary attack will be after applying double tap values
			//flNextTime_calc = ( flNextTime_ret - flGameTime ) * g_flMA_attrate + flGameTime;
			flNextTime_calc = flGameTime + 0.45 ;
			// flNextTime_calc = flGameTime + melee_speed[iCid] ;

			//then we store the value
			g_flMANextTime[iCid] = flNextTime_calc;

			//and finally adjust the value in the gun
			SetEntDataFloat(iEntid, g_iNextPAttO, flNextTime_calc, true);

			#if RSDEBUG
			PrintToChatAll("\x03-post, NextTime_calc \x01 %f\x03; new interval \x01%f",GetEntDataFloat(iEntid,g_iNextPAttO), GetEntDataFloat(iEntid,g_iNextPAttO)-flGameTime );
			#endif

			continue;
		}

		//CHECK 4: CHECK THE WEAPON
		//-------------------------
		//lastly, at this point we need to check if we are, in fact, using a melee weapon =P
		//we check if the current weapon is the same one stored in memory; if it is, move on;
		//otherwise, check if it's a melee weapon - if it is, store and continue; else, continue.
		//checks: if the active weapon is a melee weapon
		//actions: store the weapon's entid into either
		//         the known-melee or known-non-melee variable

		#if RSDEBUG
		PrintToChatAll("\x03DT client \x01%i\x03; weapon switch inferred",iCid );
		#endif

		//check if the weapon is a melee
		char stName[32];
		GetEntityNetClass(iEntid,stName,32);
		if (StrEqual(stName,"CTerrorMeleeWeapon",false)==true)
		{
			//if yes, then store in known-melee var
			g_iMAEntid[iCid]=iEntid;
			g_flMANextTime[iCid]=flNextTime_ret;
			continue;
		}
		else
		{
			//if no, then store in known-non-melee var
			g_iMAEntid_notmelee[iCid]=iEntid;
			continue;
		}
	}
}
// ////////////////////////////////////////////////////////////////////////////
void DT_OnGameFrame()
{
	// if plugin is disabled, don't bother
	if (!g_cvarFasterShooting.BoolValue)
		return;
	// or if no one has DT, don't bother either
	if (g_iDTRegisterCount==0)
		return;

	//this tracks the player's id, just to make life less painful...
	int iCid;
	//this tracks the player's gun id since we adjust numbers on the gun, not the player
	int iEntid;
	//this tracks the calculated next attack
	float flNextTime_calc;
	//this, on the other hand, tracks the current next attack
	float flNextTime_ret;
	//and this tracks next melee attack times
	float flNextTime2_ret;
	//and this tracks the game time
	float flGameTime = GetGameTime();

	//theoretically, to get on the DT registry all the necessary checks would have already
	//been run, so we don't bother with any checks here
	for (int iI = 1; iI <= g_iDTRegisterCount; iI++)
	{
		if(!g_bHasBerserker[iI])
		{
			continue;
		}
		//PRE-CHECKS: RETRIEVE VARS
		//-------------------------
		iCid = g_iDTRegisterIndex[iI];
		//stop on this client when the next client id is null
		if (iCid <= 0) return;
		//skip this client if they're disabled
		//if (g_iPState[iCid]==1) continue;

		//we have to adjust numbers on the gun, not the player so we get the active weapon id here
		iEntid = GetEntDataEnt2(iCid, g_iActiveWO);
		//if the retrieved gun id is -1, then...
		//wtf mate? just move on
		if (iEntid == -1) continue;
		//and here is the retrieved next attack time
		flNextTime_ret = GetEntDataFloat(iEntid,g_iNextPAttO);
		//and for retrieved next melee time
		flNextTime2_ret = GetEntDataFloat(iEntid,g_iNextSAttO);

		//RSDEBUG

		//CHECK 1: BEFORE ADJUSTED SHOT IS MADE
		//------------------------------------
		//since this will probably be the case most of the time, we run this first
		//checks: gun is unchanged; time of shot has not passed
		//actions: nothing
		if (g_iDTEntid[iCid]==iEntid
			&& g_flDTNextTime[iCid]>=flNextTime_ret)
		{
			//----RSDEBUG----
			//PrintToChatAll("\x03DT client \x01%i\x03; before shot made",iCid );
			continue;
		}

		//CHECK 2: INFER IF MELEEING
		//--------------------------
		//since we don't want to shorten the interval incurred after swinging, we try to guess when
		//a melee attack is made
		//checks: if melee attack time > engine time
		//actions: nothing
		if (flNextTime2_ret > flGameTime)
		{
			//----RSDEBUG----
			//PrintToChatAll("\x03DT client \x01%i\x03; melee attack inferred",iCid );
			continue;
		}

		//CHECK 3: AFTER ADJUSTED SHOT IS MADE
		//------------------------------------
		//at this point, either a gun was swapped, or the attack time needs to be adjusted
		//checks: stored gun id same as retrieved gun id, and retrieved next attack time is after stored value
		if (g_iDTEntid[iCid] == iEntid && g_flDTNextTime[iCid] < flNextTime_ret)
		{
			#if RSDEBUG
			PrintToChatAll("\x03DT after adjusted shot\n-pre, client \x01%i\x03; entid \x01%i\x03; enginetime\x01 %f\x03; NextTime_orig \x01 %f\x03; interval \x01%f",iCid,iEntid,flGameTime,flNextTime_ret, flNextTime_ret-flGameTime );
			#endif
			//this is a calculation of when the next primary attack
			//will be after applying double tap values
			flNextTime_calc = ( flNextTime_ret - flGameTime ) * g_flDT_rate + flGameTime;

			//then we store the value
			g_flDTNextTime[iCid] = flNextTime_calc;

			//and finally adjust the value in the gun
			SetEntDataFloat(iEntid, g_iNextPAttO, flNextTime_calc, true);

			#if RSDEBUG
			PrintToChatAll("\x03-post, NextTime_calc \x01 %f\x03; new interval \x01%f",GetEntDataFloat(iEntid,g_iNextPAttO), GetEntDataFloat(iEntid,g_iNextPAttO)-flGameTime );
			#endif
			continue;
		}

		//CHECK 4: ON WEAPON SWITCH
		//-------------------------
		//at this point, the only reason DT hasn't fired should be that the weapon had switched
		//checks: retrieved gun id doesn't match stored id or stored id is null
		//actions: updates stored gun id and sets stored next attack time to retrieved value
		if (g_iDTEntid[iCid] != iEntid)
		{
			#if RSDEBUG
			PrintToChatAll("\x03DT client \x01%i\x03; weapon switch inferred",iCid );
			#endif
			//now we update the stored vars
			g_iDTEntid[iCid]=iEntid;
			g_flDTNextTime[iCid]=flNextTime_ret;
			continue;
		}
		#if RSDEBUG
		PrintToChatAll("\x03DT client \x01%i\x03; reached end of checklist...",iCid );
		#endif
	}
}

//********************************************End of Dusty's code********************************

bool IsRestrictedED(int client)
{
	char weapon[256];
	int entity = GetEntDataEnt2(client, FindSendPropInfo("CTerrorPlayer", "m_hActiveWeapon"));
	if(entity <= 0 || !IsValidEntity(entity))
	{
		return false;
	}
	GetEntityNetClass(entity, weapon, sizeof(weapon));
	
	if(g_bExBoomerED && StrEqual(weapon, "CBoomerClaw"))
	{
		return true;
	}
	
	if(g_bExSpitterED && StrEqual(weapon, "CSpitterClaw"))
	{
		return true;
	}
	
	if(g_bExHunterED && StrEqual(weapon, "CHunterClaw"))
	{
		return true;
	}
	
	if(g_bExSmokerED && StrEqual(weapon, "CSmokerClaw"))
	{
		return true;
	}
	
	if(g_bExJockeyED && StrEqual(weapon, "CJockeyClaw"))
	{
		return true;
	}
	
	if(g_bExChargerED && StrEqual(weapon, "CChargerClaw"))
	{
		return true;
	}
	
	if(g_bExTankED && StrEqual(weapon, "CTankClaw"))
	{
		return true;
	}
	
	return false;
}

bool IsRestrictedLB(int client)
{
	char weapon[256]; 
	int entity = GetEntDataEnt2(client, FindSendPropInfo("CTerrorPlayer", "m_hActiveWeapon"));
	if(entity <= 0 || !IsValidEntity(entity))
	{
		return false;
	}
	GetEntityNetClass(entity, weapon, sizeof(weapon));
	
	if(g_bExBoomerLB && StrEqual(weapon, "CBoomerClaw"))
	{
		return true;
	}
	
	if(g_bExSpitterLB && StrEqual(weapon, "CSpitterClaw"))
	{
		return true;
	}
	
	if(g_bExHunterLB && StrEqual(weapon, "CHunterClaw"))
	{
		return true;
	}
	
	if(g_bExSmokerLB && StrEqual(weapon, "CSmokerClaw"))
	{
		return true;
	}
	
	if(g_bExJockeyLB && StrEqual(weapon, "CJockeyClaw"))
	{
		return true;
	}
	
	if(g_bExChargerLB && StrEqual(weapon, "CChargerClaw"))
	{
		return true;
	}
	
	if(g_bExTankLB && StrEqual(weapon, "CTankClaw"))
	{
		return true;
	}
	
	return false;
}

bool IsRestrictedEIH(int client)
{
	char weapon[256]; 
	int entity = GetEntDataEnt2(client, FindSendPropInfo("CTerrorPlayer", "m_hActiveWeapon"));
	if(entity <= 0 || !IsValidEntity(entity))
	{
		return false;
	}
	GetEntityNetClass(entity, weapon, sizeof(weapon));
	
	if(g_bExBoomerEIH && StrEqual(weapon, "CBoomerClaw"))
	{
		return true;
	}
	
	if(g_bExSpitterEIH && StrEqual(weapon, "CSpitterClaw"))
	{
		return true;
	}
	
	if(g_bExHunterEIH && StrEqual(weapon, "CHunterClaw"))
	{
		return true;
	}
	
	if(g_bExSmokerEIH && StrEqual(weapon, "CSmokerClaw"))
	{
		return true;
	}
	
	if(g_bExJockeyEIH && StrEqual(weapon, "CJockeyClaw"))
	{
		return true;
	}
	
	if(g_bExChargerEIH && StrEqual(weapon, "CChargerClaw"))
	{
		return true;
	}
	
	if(g_bExTankEIH && StrEqual(weapon, "CTankClaw"))
	{
		return true;
	}
	
	return false;
}

bool IsRestrictedFS(int client)
{
	char weapon[256]; 
	int entity = GetEntDataEnt2(client, FindSendPropInfo("CTerrorPlayer", "m_hActiveWeapon"));
	if(entity <= 0 || !IsValidEntity(entity))
	{
		return false;
	}
	GetEntityNetClass(entity, weapon, sizeof(weapon));
	
	if(g_bExBoomerFS && StrEqual(weapon, "CBoomerClaw"))
	{
		return true;
	}
	
	if(g_bExSpitterFS && StrEqual(weapon, "CSpitterClaw"))
	{
		return true;
	}
	
	if(g_bExHunterFS && StrEqual(weapon, "CHunterClaw"))
	{
		return true;
	}
	
	if(g_bExSmokerFS && StrEqual(weapon, "CSmokerClaw"))
	{
		return true;
	}
	
	if(g_bExJockeyFS && StrEqual(weapon, "CJockeyClaw"))
	{
		return true;
	}
	
	if(g_bExChargerFS && StrEqual(weapon, "CChargerClaw"))
	{
		return true;
	}
	
	if(g_bExTankFS && StrEqual(weapon, "CTankClaw"))
	{
		return true;
	}
	
	return false;
}

bool IsRestrictedBY(int client)
{
	char weapon[256]; 
	int entity = GetEntDataEnt2(client, FindSendPropInfo("CTerrorPlayer", "m_hActiveWeapon"));
	if(entity <= 0 || !IsValidEntity(entity))
	{
		return false;
	}
	GetEntityNetClass(entity, weapon, sizeof(weapon));
	
	if(g_bExBoomerBY && StrEqual(weapon, "CBoomerClaw"))
	{
		return true;
	}
	
	if(g_bExSpitterBY && StrEqual(weapon, "CSpitterClaw"))
	{
		return true;
	}
	
	if(g_bExHunterBY && StrEqual(weapon, "CHunterClaw"))
	{
		return true;
	}
	
	if(g_bExSmokerBY && StrEqual(weapon, "CSmokerClaw"))
	{
		return true;
	}
	
	if(g_bExJockeyBY && StrEqual(weapon, "CJockeyClaw"))
	{
		return true;
	}
	
	if(g_bExChargerBY && StrEqual(weapon, "CChargerClaw"))
	{
		return true;
	}
	
	if(g_bExTankBY && StrEqual(weapon, "CTankClaw"))
	{
		return true;
	}
	
	return false;
}

bool IsRestrictedALL(int client)
{
    char weapon[256]; 
    if(!IsValidEntity(client))
    {
        return false;
    }
    int entity = GetEntDataEnt2(client, FindSendPropInfo("CTerrorPlayer", "m_hActiveWeapon"));
    if(entity <= 0 || !IsValidEntity(entity))
    {
        return false;
    }
    GetEntityNetClass(entity, weapon, sizeof(weapon));

    if(g_bExALLBoomer && StrEqual(weapon, "CBoomerClaw"))
    {
        return true;
    }

    if(g_bExALLSpitter && StrEqual(weapon, "CSpitterClaw"))
    {
        return true;
    }

    if(g_bExALLHunter && StrEqual(weapon, "CHunterClaw"))
    {
        return true;
    }

    if(g_bExALLSmoker && StrEqual(weapon, "CSmokerClaw"))
    {
        return true;
    }

    if(g_bExALLJockey && StrEqual(weapon, "CJockeyClaw"))
    {
        return true;
    }

    if(g_bExALLCharger && StrEqual(weapon, "CChargerClaw"))
    {
        return true;
    }

    if(g_bExALLTank && StrEqual(weapon, "CTankClaw"))
    {
        return true;
    }

    return false;
}
	
	
void CheckRestrictedClasses()
{
	char ExInfectedHandle[256];
	//EXTRA DAMAGE-------------------------------------------------
	g_cvarEDExInfected.GetString(ExInfectedHandle, sizeof(ExInfectedHandle));
	
	if(StrContains(ExInfectedHandle, "boomer") != -1) 
	{
		g_bExBoomerED = true;
	}
	else
	{
		g_bExBoomerED = false;
	}
	if(StrContains(ExInfectedHandle, "spitter") != -1)
	{
		g_bExSpitterED = true;
	}
	else
	{
		g_bExSpitterED = false;
	}
	if(StrContains( ExInfectedHandle, "hunter" ) != -1)
	{
		g_bExHunterED = true;
	}
	else
	{
		g_bExHunterED = false;
	}
	if( StrContains( ExInfectedHandle, "jockey" ) != -1) 
	{
		g_bExJockeyED = true;
	}
	else
	{
		g_bExJockeyED = false;
	}
	if( StrContains( ExInfectedHandle, "charger" ) != -1) 
	{
		g_bExChargerED = true;
	}
	else
	{
		g_bExChargerED = false;
	}
	if( StrContains( ExInfectedHandle, "smoker" ) != -1) 
	{
		g_bExSmokerED = true;
	}
	else
	{
		g_bExSmokerED = false;
	}
	if( StrContains( ExInfectedHandle, "tank" ) != -1) 
	{
		g_bExTankED = true;
	}
	else
	{
		g_bExTankED = false;
	}
	//LETHAL BITE-------------------------------------------------
	g_cvarLBExInfected.GetString(ExInfectedHandle, sizeof(ExInfectedHandle));
	
	if( StrContains( ExInfectedHandle, "boomer" ) != -1) 
	{
		g_bExBoomerLB = true;
	}
	else
	{
		g_bExBoomerLB = false;
	}
	if( StrContains( ExInfectedHandle, "spitter" ) != -1)
	{
		g_bExSpitterLB = true;
	}
	else
	{
		g_bExSpitterLB = false;
	}
	if( StrContains( ExInfectedHandle, "hunter" ) != -1)
	{
		g_bExHunterLB = true;
	}
	else
	{
		g_bExHunterLB = false;
	}
	if( StrContains( ExInfectedHandle, "jockey" ) != -1) 
	{
		g_bExJockeyLB = true;
	}
	else
	{
		g_bExJockeyLB = false;
	}
	if( StrContains( ExInfectedHandle, "charger" ) != -1) 
	{
		g_bExChargerLB = true;
	}
	else
	{
		g_bExChargerLB = false;
	}
	if( StrContains( ExInfectedHandle, "smoker" ) != -1) 
	{
		g_bExSmokerLB = true;
	}
	else
	{
		g_bExSmokerLB = false;
	}
	if( StrContains( ExInfectedHandle, "tank" ) != -1) 
	{
		g_bExTankLB = true;
	}
	else
	{
		g_bExTankLB = false;
	}
	
	//EXTRA HEALTH-------------------------------------------------
	g_cvarEIHExInfected.GetString(ExInfectedHandle, sizeof(ExInfectedHandle));
	
	if( StrContains( ExInfectedHandle, "boomer" ) != -1) 
	{
		g_bExBoomerEIH = true;
	}
	else
	{
		g_bExBoomerEIH = false;
	}
	if( StrContains( ExInfectedHandle, "spitter" ) != -1)
	{
		g_bExSpitterEIH = true;
	}
	else
	{
		g_bExSpitterEIH = false;
	}
	if( StrContains( ExInfectedHandle, "hunter" ) != -1)
	{
		g_bExHunterEIH = true;
	}
	else
	{
		g_bExHunterEIH = false;
	}
	if( StrContains( ExInfectedHandle, "jockey" ) != -1) 
	{
		g_bExJockeyEIH = true;
	}
	else
	{
		g_bExJockeyEIH = false;
	}
	if( StrContains( ExInfectedHandle, "charger" ) != -1) 
	{
		g_bExChargerEIH = true;
	}
	else
	{
		g_bExChargerEIH = false;
	}
	if( StrContains( ExInfectedHandle, "smoker" ) != -1) 
	{
		g_bExSmokerEIH = true;
	}
	else
	{
		g_bExSmokerEIH = false;
	}
	if( StrContains( ExInfectedHandle, "tank" ) != -1) 
	{
		g_bExTankEIH = true;
	}
	else
	{
		g_bExTankEIH = false;
	}
	
	//FIRE SHIELD-------------------------------------------------
	g_cvarFSExInfected.GetString(ExInfectedHandle, sizeof(ExInfectedHandle));
	
	if( StrContains( ExInfectedHandle, "boomer" ) != -1) 
	{
		g_bExBoomerFS = true;
	}
	else
	{
		g_bExBoomerFS = false;
	}
	if( StrContains( ExInfectedHandle, "spitter" ) != -1)
	{
		g_bExSpitterFS = true;
	}
	else
	{
		g_bExSpitterFS = false;
	}
	if( StrContains( ExInfectedHandle, "hunter" ) != -1)
	{
		g_bExHunterFS = true;
	}
	else
	{
		g_bExHunterFS = false;
	}
	if( StrContains( ExInfectedHandle, "jockey" ) != -1) 
	{
		g_bExJockeyFS = true;
	}
	else
	{
		g_bExJockeyFS = false;
	}
	if( StrContains( ExInfectedHandle, "charger" ) != -1) 
	{
		g_bExChargerFS = true;
	}
	else
	{
		g_bExChargerFS = false;
	}
	if( StrContains( ExInfectedHandle, "smoker" ) != -1) 
	{
		g_bExSmokerFS = true;
	}
	else
	{
		g_bExSmokerFS = false;
	}
	if( StrContains( ExInfectedHandle, "tank" ) != -1) 
	{
		g_bExTankFS = true;
	}
	else
	{
		g_bExTankFS = false;
	}
	
	//BERSERKER YELL-------------------------------------------------
	g_cvarBYExInfected.GetString(ExInfectedHandle, sizeof(ExInfectedHandle));
	
	if( StrContains( ExInfectedHandle, "boomer" ) != -1) 
	{
		g_bExBoomerBY = true;
	}
	else
	{
		g_bExBoomerBY = false;
	}
	if( StrContains( ExInfectedHandle, "spitter" ) != -1)
	{
		g_bExSpitterBY = true;
	}
	else
	{
		g_bExSpitterBY = false;
	}
	if( StrContains( ExInfectedHandle, "hunter" ) != -1)
	{
		g_bExHunterBY = true;
	}
	else
	{
		g_bExHunterBY = false;
	}
	if( StrContains( ExInfectedHandle, "jockey" ) != -1) 
	{
		g_bExJockeyBY = true;
	}
	else
	{
		g_bExJockeyBY = false;
	}
	if( StrContains( ExInfectedHandle, "charger" ) != -1) 
	{
		g_bExChargerBY = true;
	}
	else
	{
		g_bExChargerBY = false;
	}
	if( StrContains( ExInfectedHandle, "smoker" ) != -1) 
	{
		g_bExSmokerBY = true;
	}
	else
	{
		g_bExSmokerBY = false;
	}
	if( StrContains( ExInfectedHandle, "tank" ) != -1) 
	{
		g_bExTankBY = true;
	}
	else
	{
		g_bExTankBY = false;
	}
	
	//ALL FEATURES-----------------------------------------------
	g_cvarExInfected.GetString(ExInfectedHandle, sizeof(ExInfectedHandle));
	
	if( StrContains( ExInfectedHandle, "boomer" ) != -1) 
	{
		g_bExALLBoomer = true;
	}
	else
	{
		g_bExALLBoomer = false;
	}
	if( StrContains( ExInfectedHandle, "spitter" ) != -1)
	{
		g_bExALLSpitter = true;
	}
	else
	{
		g_bExALLSpitter = false;
	}
	if( StrContains( ExInfectedHandle, "hunter" ) != -1)
	{
		g_bExALLHunter = true;
	}
	else
	{
		g_bExALLHunter = false;
	}
	if( StrContains( ExInfectedHandle, "jockey" ) != -1) 
	{
		g_bExALLJockey = true;
	}
	else
	{
		g_bExALLJockey = false;
	}
	if( StrContains( ExInfectedHandle, "charger" ) != -1) 
	{
		g_bExALLCharger = true;
	}
	else
	{
		g_bExALLCharger = false;
	}
	if( StrContains( ExInfectedHandle, "smoker" ) != -1) 
	{
		g_bExALLSmoker = true;
	}
	else
	{
		g_bExALLSmoker = false;
	}
	if( StrContains( ExInfectedHandle, "tank" ) != -1) 
	{
		g_bExALLTank = true;
	}
	else
	{
		g_bExALLTank = false;
	}
}

//Dev command
Action CmdIncapMe(int client, int args)
{
    IncapSurvivor(client, client);
    return Plugin_Handled;
}

//Force incapacitation
stock void IncapSurvivor(int client, int attacker)
{
	if(IsValidEntity(client))
	{
		char sUser[256];
		IntToString(GetClientUserId(client)+25, sUser, sizeof(sUser));
		int iDmgEntity = CreateEntityByName("point_hurt");
		SetEntityHealth(client, 1);
		DispatchKeyValue(client, "targetname", sUser);
		DispatchKeyValue(iDmgEntity, "DamageTarget", sUser);
		DispatchKeyValue(iDmgEntity, "Damage", "1000");
		DispatchSpawn(iDmgEntity);
		AcceptEntityInput(iDmgEntity, "Hurt", attacker);
		AcceptEntityInput(iDmgEntity, "Kill");
	}
}

void DoNastyRevenge()
{
    int vcount = 0;
    switch(GetRandomInt(1, g_cvarNastyRevengeProb.IntValue))
    {
        case 1:
        {
            #if NRDEBUG
            PrintToChatAll("[NASTY REVENGE] Chance succeed, applying vomit!");
            #endif
            for(int i = 1; i <= MaxClients; i++)
            {
                //If the selected client was 0 or wasn't in game, discart
                if(i == 0 || !IsClientInGame(i))
                {
                    continue;
                }
                g_iTeam[i] = GetClientTeam(i);
                
                //Checks: Is a infected, is alive, is in game, has berserker running.
                if(g_iTeam[i] == 3 && IsPlayerAlive(i) && IsClientInGame(i) && !g_bHasBerserker[i])
                {
                    switch(GetRandomInt(1, g_cvarNastyRevengeInfProb.IntValue))
                    {
                        case 1:
                        {
                            SDKCall(sdkCallVomitPlayer, i, i, true);
                            #if NRDEBUG
                            PrintToChat(i, "[NASTY REVENGE] Your chance is 1, vomiting you!");
                            #endif
                            vcount++;
                        }
                    }
                }
            }
            #if NRDEBUG
            PrintToChatAll("[NASTY REVENGE] Vomited %i players as revenge", vcount);
            #endif
            vcount = 0;
        }
    }
    #if NRDEBUG
    PrintToChatAll("[NASTY REVENGE] Vomited %i players as revenge", vcount);
    #endif
    vcount = 0;
    }

    stock void DoLethalBite(int victim, int attacker, int damage, float duration, float frequency)
    {
    #if LBDEBUG
    PrintToChatAll("[LETHAL BITE] Lethal bite request detected");
    #endif
    if(attacker == 0)
    {
        #if LBDEBUG
        PrintToChatAll("[LETHAL BITE] Player got hurt by world, doing nothing");
        #endif
        return;
    }
    #if LBDEBUG
    char sName[256];
    GetClientName(victim, sName, sizeof(sName));
    PrintToChatAll("[LETHAL BITE] Created duration timer for %s (%i)", sName, victim);
    #endif
    g_timerLethalBiteDur = CreateTimer(duration, timerLethalBiteDuration, victim, TIMER_FLAG_NO_MAPCHANGE);
    g_bLBActive[victim] = true;

    DataPack pack2;
    g_timerLethalBiteFreq = CreateDataTimer(frequency, timerLethalBiteFrequency, pack2, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    pack2.WriteCell(victim);
    pack2.WriteCell(damage);

    #if LBDEBUG
    GetClientName(victim, sName, sizeof(sName));
    PrintToChatAll("[LETHAL BITE] Created frequency timer for %s(%i)", sName, victim);
    #endif
}

Action timerLethalBiteDuration(Handle timer, any victim)
{
    #if LBDEBUG
    char sName[256];
    GetClientName(victim, sName, sizeof(sName));
    PrintToChatAll("[LETHAL BITE] Lethal bite expired for %s(%i)", sName, victim);
    #endif
    g_bLBActive[victim] = false;
    g_timerLethalBiteDur = null;
    return Plugin_Stop;
}

Action timerLethalBiteFrequency(Handle timer, DataPack pack2)
{
	pack2.Reset();
	int client = pack2.ReadCell();
	int damage = pack2.ReadCell();
	char sDamage[256];
	char sUser[256];
	if(!g_bLBActive[client])
	{
		g_timerLethalBiteFreq = null;
		return Plugin_Stop;
	}
	
	if(client > 0 && IsValidEntity(client))
	{
		IntToString(damage, sDamage, sizeof(sDamage));
		int userid = GetClientUserId(client);
		IntToString(userid+25, sUser, sizeof(sUser));
		int iDmgEntity = CreateEntityByName("point_hurt");
		DispatchKeyValue(client, "targetname", sUser);
		DispatchKeyValue(iDmgEntity, "DamageTarget", sUser);
		DispatchKeyValue(iDmgEntity, "Damage", sDamage);
		DispatchKeyValue(iDmgEntity, "DamageType", "0");
		DispatchSpawn(iDmgEntity);
		AcceptEntityInput(iDmgEntity, "Hurt", client);
		#if LBDEBUG
		PrintToConsole(client, "[LETHAL BITE] Hurting you");
		#endif
		RemoveEdict(iDmgEntity);
	}
	return Plugin_Continue;
}

int GetTankCount()
{
	int count = 0;
	for(int i = 1 ; i<=MaxClients ; i++)
	{
		if(i > 0 && IsClientConnected(i) && IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 3)
		{
			char weapon[128];
			int entity = GetEntDataEnt2(i, FindSendPropInfo("CTerrorPlayer", "m_hActiveWeapon"));
			if(entity > 0 && IsValidEntity(entity))
			{
				GetEntityNetClass(entity, weapon, sizeof(weapon));
			}
			if(StrEqual(weapon, "CTankClaw"))
			{
				count++;
			}
		}
	}
	return count;
}

stock void Yell(int client)
{
	EmitYell(client);
	float flMaxDistance = g_cvarYellRadius.FloatValue;
	float power = g_cvarYellPower.FloatValue;
	//Get the client's userid for debuggin info
	int tcount = 0;
	#if BYDEBUG
	int userid = GetClientUserId(client);
	PrintToConsole(client, "Getting position from this client[Index :%i | User Id: %i]", client, userid);
	#endif
	
	//Declare the client's position and the target position as floats.
	float pos[3], tpos[3], traceVec[3], resultingFling[3], currentVelVec[3];
	
	//Get the client's position and store it on the declared variable.
	GetClientAbsOrigin(client, pos);
	#if BYDEBUG
	PrintToConsole(client, "Position for (%i) is: %f, %f, %f", userid, pos[0], pos[1], pos[2]);
	#endif
	
	//If the client is an infected
	if(GetClientTeam(client) == 3)
	{
		//Find any possible colliding clients.
		for(int i = 1; i <= MaxClients; i++)
		{
			if(i == 0 || !IsValidEntity(i) || !IsClientInGame(i) || !IsPlayerAlive(i))
			{
				continue;
			}
			if(GetClientTeam(client) == GetClientTeam(i))
			{
				continue;
			}
			tcount++;
			GetEntPropVector(i, Prop_Data, "m_vecOrigin", tpos);
			
			if(GetVectorDistance(pos, tpos) <= flMaxDistance)
			{
				MakeVectorFromPoints(pos, tpos, traceVec);				// draw a line from car to Survivor
				GetVectorAngles(traceVec, resultingFling);							// get the angles of that line
				
				resultingFling[0] = Cosine(DegToRad(resultingFling[1])) * power;	// use trigonometric magic
				resultingFling[1] = Sine(DegToRad(resultingFling[1])) * power;
				resultingFling[2] = power;
				
				GetEntPropVector(i, Prop_Data, "m_vecVelocity", currentVelVec);		// add whatever the Survivor had before
				resultingFling[0] += currentVelVec[0];
				resultingFling[1] += currentVelVec[1];
				resultingFling[2] += currentVelVec[2];
				
				FlingPlayer(i, resultingFling, i);
			}
		}
	}
	
	if(GetClientTeam(client) == 2)
	{
		power += 300.0;
		//Find any possible colliding clients.
		for(int i = 1; i <= MaxClients; i++)
		{
			if(i == 0 || !IsValidEntity(i) || !IsClientInGame(i) || !IsPlayerAlive(i))
			{
				continue;
			}
			if(GetClientTeam(client) == GetClientTeam(i))
			{
				continue;
			}
			GetEntPropVector(i, Prop_Data, "m_vecOrigin", tpos);
			
			if(GetVectorDistance(pos, tpos) <= flMaxDistance)
			{
				MakeVectorFromPoints(pos, tpos, traceVec);				// draw a line from car to Survivor
				GetVectorAngles(traceVec, resultingFling);							// get the angles of that line
				
				resultingFling[0] = Cosine(DegToRad(resultingFling[1])) * power;	// use trigonometric magic
				resultingFling[1] = Sine(DegToRad(resultingFling[1])) * power;
				resultingFling[2] = power;
				
				GetEntPropVector(i, Prop_Data, "m_vecVelocity", currentVelVec);		// add whatever the Survivor had before
				resultingFling[0] += currentVelVec[0];
				resultingFling[1] += currentVelVec[1];
				resultingFling[2] += currentVelVec[2];
				
				TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, resultingFling);
				SDKCall(sdkShove, i, client, resultingFling);
				IgniteEntity(i, 8.0, true);
			}
		}
		char class[32];
		GetClientAbsOrigin(client, pos);
		for(int i = MaxClients+1; i < GetMaxEntities(); i++)
		{
			if(IsValidEntity(i) && IsValidEdict(i))
			{
				GetEdictClassname(i, class,sizeof(class));
				if(StrEqual(class, "infected") || StrEqual(class, "witch"))
				{
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", tpos);
					if(GetVectorDistance(pos, tpos) <= flMaxDistance)
					{
						IgniteEntity(i, 5.0, true);
					}
				}
			}
		}
	}
	#if BYDEBUG
	if(tcount > 0)
		PrintToConsole(client, "Targets found: %i", tcount);
	else
		PrintToConsole(client, "No targets matched");
	#endif
	tcount = 0;
}

stock void EmitYell(int client)
{
	char model[256];
	GetClientModel(client, model, sizeof(model));
	
	//Survivor - Nick
	if(StrEqual(model, "models/survivors/survivor_gambler.mdl"))
	{
		switch(GetRandomInt(1,3))
		{
			case 1:
			EmitSoundToAll(YELLNICK_1, client);
			case 2:
			EmitSoundToAll(YELLNICK_2, client);
			case 3:
			EmitSoundToAll(YELLNICK_3, client);
		}
	}
	
	//Survivor - Rochelle
	if(StrEqual(model, "models/survivors/survivor_producer.mdl"))
	{
		switch(GetRandomInt(1,3))
		{
			case 1:
			EmitSoundToAll(YELLRO_1, client);
			case 2:
			EmitSoundToAll(YELLRO_2, client);
			case 3:
			EmitSoundToAll(YELLRO_3, client);
		}
	}
	
	//Survivor - Ellis
	if(StrEqual(model, "models/survivors/survivor_mechanic.mdl"))
	{
		switch(GetRandomInt(1,3))
		{
			case 1:
			EmitSoundToAll(YELLELLIS_1, client);
			case 2:
			EmitSoundToAll(YELLELLIS_2, client);
			case 3:
			EmitSoundToAll(YELLELLIS_3, client);
		}
	}
	
	//Survivor - Coach
	if(StrEqual(model, "models/survivors/survivor_coach.mdl"))
	{
		switch(GetRandomInt(1,3))
		{
			case 1:
			EmitSoundToAll(YELLCOACH_1, client);
			case 2:
			EmitSoundToAll(YELLCOACH_2, client);
			case 3:
			EmitSoundToAll(YELLCOACH_3, client);
		}
	}
	
	//Infected - Hunter
	if(StrEqual(model, "models/infected/hunter.mdl"))
	{
		switch(GetRandomInt(1,3))
		{
			case 1:
			EmitSoundToAll(YELLHUNTER_1, client);
			case 2:
			EmitSoundToAll(YELLHUNTER_2, client);
			case 3:
			EmitSoundToAll(YELLHUNTER_3, client);
		}
	}
	
	//Infected - Smoker
	if(StrEqual(model, "models/infected/smoker.mdl"))
	{
		switch(GetRandomInt(1,3))
		{
			case 1:
			EmitSoundToAll(YELLSMOKER_1, client);
			case 2:
			EmitSoundToAll(YELLSMOKER_2, client);
			case 3:
			EmitSoundToAll(YELLSMOKER_3, client);
		}
	}
	
	//Infected - Spitter
	if(StrEqual(model, "models/infected/spitter.mdl"))
	{
		switch(GetRandomInt(1,3))
		{
			case 1:
			EmitSoundToAll(YELLSPITTER_1, client);
			case 2:
			EmitSoundToAll(YELLSPITTER_2, client);
			case 3:
			EmitSoundToAll(YELLSPITTER_3, client);
		}
	}
	
	//Infected - Jockey
	if(StrEqual(model, "models/infected/jockey.mdl"))
	{
		switch(GetRandomInt(1,3))
		{
			case 1:
			EmitSoundToAll(YELLJOCKEY_1, client);
			case 2:
			EmitSoundToAll(YELLJOCKEY_2, client);
			case 3:
			EmitSoundToAll(YELLJOCKEY_3, client);
		}
	}
	
	//Infected - Charger
	if(StrEqual(model, "models/infected/charger.mdl"))
	{
		switch(GetRandomInt(1,3))
		{
			case 1:
			EmitSoundToAll(YELLCHARGER_1, client);
			case 2:
			EmitSoundToAll(YELLCHARGER_2, client);
			case 3:
			EmitSoundToAll(YELLCHARGER_3, client);
		}
	}
	
	//Infected - Male boomer 
	if(StrEqual(model, "models/infected/boomer.mdl"))
	{
		switch(GetRandomInt(1,3))
		{
			case 1:
			EmitSoundToAll(YELLBOOMER_1, client);
			case 2:
			EmitSoundToAll(YELLBOOMER_2, client);
			case 3:
			EmitSoundToAll(YELLBOOMER_3, client);
		}
	}
	
	//Infected - Female boomer
	if(StrEqual(model, "models/infected/boomette.mdl"))
	{
		switch(GetRandomInt(1,3))
		{
			case 1:
			EmitSoundToAll(YELLBOOMETTE_1, client);
			case 2:
			EmitSoundToAll(YELLBOOMETTE_2, client);
			case 3:
			EmitSoundToAll(YELLBOOMETTE_3, client);
		}
	}
	
	//Infected - Tank
	if(StrEqual(model, "models/infected/tank.mdl"))
	{
		switch(GetRandomInt(1,3))
		{
			case 1:
			EmitSoundToAll(YELLTANK_1, client);
			case 2:
			EmitSoundToAll(YELLTANK_2, client);
			case 3:
			EmitSoundToAll(YELLTANK_3, client);
		}
	}
	#if BYDEBUG
	PrintToChat(client, "ROAAAARRRR!");
	#endif
}

stock void FlingPlayer(int target, float vector[3], int attacker, float stunTime = 3.0)
{
	SDKCall(sdkCallPushPlayer, target, vector, 96, attacker, stunTime);
}

void Announce(int client)
{
	char sUser[32], sMessage[256];
	switch(g_cvarAnnounceType.IntValue)
	{
		case 1:
		{
			PrintToChat(client, "\x04Berserker mode is ready! Press the '%s' key to activate it!", g_sKeyToBind);
		}
		case 2:
		{
			PrintHintText(client, "Berserker mode is ready! Press the '%s' key to activate it!", g_sKeyToBind);
		}
		case 3:
		{
			PrintCenterText(client, "Berserker mode is ready! Press the '%s' key to activate it!", g_sKeyToBind);
		}
		case 4:
		{
			IntToString(GetClientUserId(client)+25, sUser, sizeof(sUser));
			Format(sMessage, sizeof(sMessage), "Berserker mode is ready! Press the '%s' key to activate it!", g_sKeyToBind);
			int instructor  = CreateEntityByName("env_instructor_hint");
			DispatchKeyValue(client, "targetname", sUser);
			DispatchKeyValue(instructor, "hint_static", "1");
			DispatchKeyValue(instructor, "hint_color", "255 255 255");
			DispatchKeyValue(instructor, "hint_caption", sMessage);
			DispatchKeyValue(instructor, "hint_icon_onscreen", "icon_alert");
			DispatchKeyValue(instructor, "hint_timeout", "10");
			
			ClientCommand(client, "gameinstructor_enable 1");
			DispatchSpawn(instructor);
			char content[32];
			Format(content, sizeof(content), "ShowHint %s", sUser);
			AcceptEntityInput(instructor, "ShowHint", client);
			
			CreateTimer(10.0, timerEndHint, instructor, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

Action timerEndHint(Handle timer, any entity)
{
    if(IsValidEntity(entity))
    {
        AcceptEntityInput(entity, "Kill");
    }
    return Plugin_Stop;
}

void ShowEffect(int client)
{
    //Userid for targetting
    int userid = GetClientUserId(client);
    float pos[3];
    char sName[64], sTargetName[64];
    g_iEffect[client] = CreateEntityByName("info_particle_system");
    int Particle = g_iEffect[client];

    GetClientAbsOrigin(client, pos);
    TeleportEntity(Particle, pos, NULL_VECTOR, NULL_VECTOR);

    Format(sName, sizeof(sName), "%d", userid+25);
    DispatchKeyValue(client, "targetname", sName);
    GetEntPropString(client, Prop_Data, "m_iName", sName, sizeof(sName));

    Format(sTargetName, sizeof(sTargetName), "%d", userid+1000);

    DispatchKeyValue(Particle, "targetname", sTargetName);
    DispatchKeyValue(Particle, "parentname", sName);
    if(GetClientTeam(client) == 2)
    {
        DispatchKeyValue(Particle, "effect_name", EFFECT_PARTICLE_SURVIVOR);
    }
    else if(GetClientTeam(client) == 3)
    {
        DispatchKeyValue(Particle, "effect_name", EFFECT_PARTICLE_INFECTED);
    }

    DispatchSpawn(Particle);

    DispatchSpawn(Particle);

    //Parent:		
    SetVariantString(sName);
    AcceptEntityInput(Particle, "SetParent", Particle, Particle);
    ActivateEntity(Particle);
    AcceptEntityInput(Particle, "start");

    CreateTimer(1.0, timerEndEffect, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

Action timerEndEffect(Handle timer, any client)
{
	if(!g_bHasBerserker[client])
	{
		if(IsValidEntity(g_iEffect[client]))
		{
			RemoveEdict(g_iEffect[client]);
		}
		return Plugin_Stop;
	}
	if(!IsPlayerAlive(client) || GetEntProp(client, Prop_Send, "m_isGhost") == 1)
	{
		AcceptEntityInput(g_iEffect[client], "Stop");
		return Plugin_Continue;
	}
	AcceptEntityInput(g_iEffect[client], "Start");
	return Plugin_Continue;
}

stock void PrecacheParticle(char[] ParticleName)
{
	int Particle = CreateEntityByName("info_particle_system");
	if(IsValidEntity(Particle) && IsValidEdict(Particle))
	{
		DispatchKeyValue(Particle, "effect_name", ParticleName);
		DispatchSpawn(Particle);
		ActivateEntity(Particle);
		AcceptEntityInput(Particle, "start");
		CreateTimer(0.3, timerRemovePrecacheParticle, Particle, TIMER_FLAG_NO_MAPCHANGE);
	}
}

Action timerRemovePrecacheParticle(Handle timer, any Particle)
{
    if(IsValidEntity(Particle) && IsValidEdict(Particle))
    {
        AcceptEntityInput(Particle, "Kill");
    }
    return Plugin_Stop;
}

stock void ToggleBlackScreen(int client)
{
	if(client <= 0 || !IsValidEntity(client) || !IsClientInGame(client))
	{
		return;
	}
	Handle hFadeClient = StartMessageOne("Fade", client);
	BfWriteShort(hFadeClient,12);	// FIXED 16 bit, with SCREENFADE_FRACBITS fractional, seconds duration
	BfWriteShort(hFadeClient,0);		// FIXED 16 bit, with SCREENFADE_FRACBITS fractional, seconds duration until reset (fade & hold)
	BfWriteShort(hFadeClient,(FFADE_PURGE|FFADE_OUT|FFADE_STAYOUT)); // fade type (in / out)
	BfWriteByte(hFadeClient,0);	// fade red
	BfWriteByte(hFadeClient,0);	// fade green
	BfWriteByte(hFadeClient,0);	// fade blue
	BfWriteByte(hFadeClient, 180);	// fade alpha
	EndMessage();
	CreateTimer(12.0, timerEndBlackScreen, client, TIMER_FLAG_NO_MAPCHANGE);
}

Action timerEndBlackScreen(Handle timer, any client)
{
    RetrieveBlackScreen(client);
    return Plugin_Stop;
}

stock void RetrieveBlackScreen(int client)
{
	if(client <= 0 || !IsValidEntity(client) || !IsClientInGame(client))
	{
		return;
	}
	Handle hFadeClient = StartMessageOne("Fade", client);
	BfWriteShort(hFadeClient,12);	// FIXED 16 bit, with SCREENFADE_FRACBITS fractional, seconds duration
	BfWriteShort(hFadeClient,0);		// FIXED 16 bit, with SCREENFADE_FRACBITS fractional, seconds duration until reset (fade & hold)
	BfWriteShort(hFadeClient,(FFADE_PURGE|FFADE_IN|FFADE_STAYOUT)); // fade type (in / out)
	BfWriteByte(hFadeClient,0);	// fade red
	BfWriteByte(hFadeClient,0);	// fade green
	BfWriteByte(hFadeClient,0);	// fade blue
	BfWriteByte(hFadeClient, 180);	// fade alpha
	EndMessage();
}

/** Panel help to tell about all the berserker features **/
Action CmdZerkHelp(int client, int args)
{
	if(!client)
	{
		PrintToServer("This command can only be used in-game");
		return Plugin_Handled;
	}
	DisplayZerkHelpMenu(client);
	return Plugin_Handled;
}

stock void DisplayZerkHelpMenu(int client)
{
	Menu menu = new Menu(MenuHandler_ZerkHelp);
	menu.AddItem("what is it", "What is Berserker Mode?");
	menu.AddItem("how works", "How does it work?");
	menu.AddItem("features", "What are the features?");
	menu.ExitButton = true;
	menu.SetTitle("Berserker Help");
	menu.Display(client, MENU_TIME_FOREVER);
}

int MenuHandler_ZerkHelp(Menu menu, MenuAction action, int param1, int param2)
{
    switch(action)
    {
        case MenuAction_Select:
        {
            char menucmd[256];
            menu.GetItem(param2, menucmd, sizeof(menucmd));
            if(StrEqual(menucmd, "what is it"))
            {
                PrintToChat(param1, "\x04Berserker Mode is a special state where both survivors and infected are granted with special features");
                DisplayZerkHelpMenu(param1);
                return 0;
            }
            else if(StrEqual(menucmd, "how works"))
            {
                PrintToChat(param1, "\x04As a survivor, hunt down common infected to gain it. As an infected, damage survivors for it!");
                DisplayZerkHelpMenu(param1);
                return 0;
            }
            else if(StrEqual(menucmd, "features"))
            {
                DisplayFeaturesMenu(param1);
                return 0;
            }
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
    return 0;
}

stock void DisplayFeaturesMenu(int client)
{
	Menu menu = new Menu(MenuHandler_Features);
	menu.AddItem("common", "Common features");
	menu.AddItem("infected", "Infected features");
	menu.AddItem("survivor", "Survivor features");
	menu.ExitBackButton = true;
	menu.SetTitle("Berserker Features");
	menu.Display(client, MENU_TIME_FOREVER);
}

int MenuHandler_Features(Menu menu, MenuAction action, int param1, int param2)
{
    switch(action)
    {
        case MenuAction_Select:
        {
            char menucmd[256];
            menu.GetItem(param2, menucmd, sizeof(menucmd));
            if(StrEqual(menucmd, "common"))
            {
                DisplayCommonMenu(param1);
                return 0;
            }
            else if(StrEqual(menucmd, "infected"))
            {
                DisplayInfectedMenu(param1);
                return 0;
            }
            else if(StrEqual(menucmd, "survivor"))
            {
                DisplaySurvivorMenu(param1);
                return 0;
            }
        }
        case MenuAction_Cancel:
        {
            if(param2 == MenuCancel_ExitBack)
            {
                DisplayZerkHelpMenu(param1);
            }
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
    return 0;
}

stock void DisplayCommonMenu(int client)
{
	Menu menu = new Menu(MenuHandler_FeaturesCommon);
	menu.AddItem("speed", "Increased Speed");
	menu.AddItem("color", "Colored Skin");
	menu.AddItem("fire", "Fire effect");
	menu.ExitBackButton = true;
	menu.SetTitle("Common Features");
	menu.Display(client, MENU_TIME_FOREVER);
}

stock void DisplayInfectedMenu(int client)
{
	Menu menu = new Menu(MenuHandler_FeaturesInfected);
	menu.AddItem("damage", "Bonus Damage");
	menu.AddItem("ability", "Special Ability Shield");
	menu.AddItem("health", "Bonus Health");
	menu.AddItem("bite", "Lethal Bite");
	menu.AddItem("fire", "Fire Shield");
	menu.AddItem("yell", "Berserker Yell");
	menu.AddItem("bile", "Black Bile");
	menu.AddItem("pummel", "Pummel Safety");
	menu.AddItem("fatal", "Fatal Hit");
	menu.ExitBackButton = true;
	menu.SetTitle("Common Features");
	menu.Display(client, MENU_TIME_FOREVER);
}

stock void DisplaySurvivorMenu(int client)
{
	Menu menu = new Menu(MenuHandler_FeaturesSurvivor);
	menu.AddItem("items", "Give Items");
	menu.AddItem("fire", "On fire");
	menu.AddItem("incap", "Incap Shield");
	menu.AddItem("reward", "Health Reward");
	menu.AddItem("shove", "Shoving Expert");
	menu.AddItem("laser", "Laser King");
	menu.AddItem("2f4y", "Too fast for you");
	menu.AddItem("nasty", "Nasty Revenge");
	menu.AddItem("yell", "Berserker Yell");
	menu.AddItem("convert", "Health Convertion");
	menu.ExitBackButton = true;
	menu.SetTitle("Common Features");
	menu.Display(client, MENU_TIME_FOREVER);
}

int MenuHandler_FeaturesCommon(Menu menu, MenuAction action, int param1, int param2)
{
    switch(action)
    {
        case MenuAction_Select:
        {
            char menucmd[256];
            GetMenuItem(menu, param2, menucmd, sizeof(menucmd));
            if(StrEqual(menucmd, "speed"))
            {
                PrintToChat(param1, "\x04Both survivors and infected will get a speed boost under berserker");
                DisplayCommonMenu(param1);
            }
            else if(StrEqual(menucmd, "color"))
            {
                PrintToChat(param1, "\x04Both survivors and infected get colored with a special color on berserker");
                DisplayCommonMenu(param1);
            }
            else if(StrEqual(menucmd, "fire"))
            {
                PrintToChat(param1, "\x04Berserker Players get a fire effect on their feet");
                DisplayCommonMenu(param1);
            }
        }
        case MenuAction_Cancel:
        {
            if(param2 == MenuCancel_ExitBack)
            {
                DisplayFeaturesMenu(param1);
            }
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
    return 0;
}

int MenuHandler_FeaturesInfected(Menu menu, MenuAction action, int param1, int param2)
{
    switch(action)
    {
        case MenuAction_Select:
        {
            char menucmd[256];
            GetMenuItem(menu, param2, menucmd, sizeof(menucmd));
            if(StrEqual(menucmd, "damage"))
            {
                PrintToChat(param1, "\x04Infected deal extra damage during berserker");
                DisplayInfectedMenu(param1);
            }
            else if(StrEqual(menucmd, "ability"))
            {
                PrintToChat(param1, "\x04Hunters, Jockeys and Smokers can't be killed during their special ability. They must be shoved first");
                DisplayInfectedMenu(param1);
            }
            else if(StrEqual(menucmd, "health"))
            {
                PrintToChat(param1, "\x04Bonus Health upon berserker usage");
                DisplayInfectedMenu(param1);
            }
            else if(StrEqual(menucmd, "bite"))
            {
                PrintToChat(param1, "\x04Keeps inflicting damage after a single hit");
                DisplayInfectedMenu(param1);
            }
            else if(StrEqual(menucmd, "fire"))
            {
                PrintToChat(param1, "\x04Infected players on berserker mode cannot be ignited");
                DisplayInfectedMenu(param1);
            }
            else if(StrEqual(menucmd, "yell"))
            {
                PrintToChat(param1, "\x04When an infected player on berserker dies, he will make one last yell which will stun survivors around");
                DisplayInfectedMenu(param1);
            }
            else if(StrEqual(menucmd, "bile"))
            {
                PrintToChat(param1, "\x04When a survivor gets vomited by a berserker Boomer, his screen will become black");
                DisplayInfectedMenu(param1);
            }
            else if(StrEqual(menucmd, "health"))
            {
                PrintToChat(param1, "\x04Chargers cant be killed with melee weapons when they are pummeling and are under berserker");
                DisplayInfectedMenu(param1);
            }
            else if(StrEqual(menucmd, "fatal"))
            {
                PrintToChat(param1, "\x04If an infected hits a bleeding (Temporal Health) survivor, he will get incapacitated inmediatly.");
                DisplayInfectedMenu(param1);
            }
        }
        case MenuAction_Cancel:
        {
            if(param2 == MenuCancel_ExitBack)
            {
                DisplayFeaturesMenu(param1);
            }
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
    return 0;
}

int MenuHandler_FeaturesSurvivor(Menu menu, MenuAction action, int param1, int param2)
{
    switch(action)
    {
        case MenuAction_Select:
        {
            char menucmd[256];
            GetMenuItem(menu, param2, menucmd, sizeof(menucmd));
            if(StrEqual(menucmd, "items"))
            {
                PrintToChat(param1, "\x04The survivor gets one adrenaline shot and his weapon gets refilled on Berserker");
                DisplaySurvivorMenu(param1);
            }
            else if(StrEqual(menucmd, "fire"))
            {
                PrintToChat(param1, "\x04Survivors under berserker mode will ignite any infected if they hurt them");
                DisplaySurvivorMenu(param1);
            }
            else if(StrEqual(menucmd, "incap"))
            {
                PrintToChat(param1, "\x04Survivors get damage immunity during incapacitation");
                DisplaySurvivorMenu(param1);
            }
            else if(StrEqual(menucmd, "reward"))
            {
                PrintToChat(param1, "\x04Survivors get health from killing common infected");
                DisplaySurvivorMenu(param1);
            }
            else if(StrEqual(menucmd, "shove"))
            {
                PrintToChat(param1, "\x04Survivors dont get tired of shoving during berserker");
                DisplaySurvivorMenu(param1);
            }
            else if(StrEqual(menucmd, "laser"))
            {
                PrintToChat(param1, "\x04The survivor gets laser sights using berserker");
                DisplaySurvivorMenu(param1);
            }
            else if(StrEqual(menucmd, "2f4y"))
            {
                PrintToChat(param1, "\x04Faster reloading, firing and melee swinging during berserker");
                DisplaySurvivorMenu(param1);
            }
            else if(StrEqual(menucmd, "nasty"))
            {
                PrintToChat(param1, "\x04When a boomer vomits a berserker survivor, all the special infected will be biled too as a revenge");
                DisplaySurvivorMenu(param1);
            }
            else if(StrEqual(menucmd, "yell"))
            {
                PrintToChat(param1, "\x04When the berserker mode start, the survivor might yell. If a survivor yells all infected will be ignited if they hit him.");
                DisplaySurvivorMenu(param1);
            }
            else if(StrEqual(menucmd, "convert"))
            {
                PrintToChat(param1, "\x04Temporary health will be converted into permanent health upon berserker usage");
                DisplaySurvivorMenu(param1);
            }
        }
        case MenuAction_Cancel:
        {
            if(param2 == MenuCancel_ExitBack)
            {
                DisplayFeaturesMenu(param1);
            }
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
    return 0;
}

stock bool IsValidFireWeaponName(char[] sWeapon)
{
	if(StrContains(sWeapon, "grenade_launcher") >= 0)
	{
		return true;
	}
	else if(StrContains(sWeapon, "pistol") >= 0)
	{
		return true;
	}
	else if(StrContains(sWeapon, "rifle") >= 0)
	{
		return true;
	}
	else if(StrContains(sWeapon, "shotgun") >= 0)
	{
		return true;
	}
	else if(StrContains(sWeapon, "smg") >= 0)
	{
		return true;
	}
	else if(StrContains(sWeapon, "sniper") >= 0)
	{
		return true;
	}
	return false;
}

stock void LogDebug(any ...)
{
	#if (CODEBUG || RSDEBUG || BYDEBUG || LBDEBUG || FSDEBUG || NRDEBUG || CTDEBUG || EVTDEBUG || ZKDEBUG || CKDEBUG || BOODEBUG)
	char buffer[512];
	VFormat(buffer, sizeof(buffer), format, 2);
	char FileName[256], String:sTime[256];
	BuildPath(Path_SM, FileName, sizeof(FileName), "logs/berserker_debug.log", sTime);
	File file = OpenFile(FileName, "a+");
	FormatTime(sTime, sizeof(sTime), "%b %d |%H:%M:%S| %Y");
	file.WriteLine("%s: %s", sTime, buffer);
	PrintToServer("[BERSERKER DEBUG INFORMATION]: %s", buffer);
	file.Flush();
	delete file;
	#endif
}

stock int GetClientTempHealth(int client)
{
	//First filter -> Must be a valid client, successfully in-game and not an spectator (The dont have health).
    if(!client
    || !IsValidEntity(client)
    || !IsClientInGame(client)
	|| !IsPlayerAlive(client)
    || IsClientObserver(client)
	|| GetClientTeam(client) != 2)
    {
        return -1;
    }
    
    //First, we get the amount of temporal health the client has
    float buffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
    //We declare the permanent and temporal health variables
    float TempHealth;
    //In case the buffer is 0 or less, we set the temporal health as 0, because the client has not used any pills or adrenaline yet
    if(buffer <= 0.0)
    {
        TempHealth = 0.0;
    }
    //In case it is higher than 0, we proceed to calculate the temporl health
    else
    {
        //This is the difference between the time we used the temporal item, and the current time
        float difference = GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
        //We get the decay rate from this convar (Note: Adrenaline uses this value)
        float decay = FindConVar("pain_pills_decay_rate").FloatValue;
        //This is a constant we create to determine the amount of health. This is the amount of time it has to pass
        //before 1 Temporal HP is consumed.
        float constant = 1.0/decay;
        //Then we do the calcs
        TempHealth = buffer - (difference / constant);
    }
    
    //If the temporal health resulted less than 0, then it is just 0.
    if(TempHealth < 0.0)
    {
        TempHealth = 0.0;
    }
    
    //Return the value
    return RoundToFloor(TempHealth);
}

stock void RemoveTempHealth(int client)
{
	if(!client
    || !IsValidEntity(client)
    || !IsClientInGame(client)
	|| !IsPlayerAlive(client)
    || IsClientObserver(client)
	|| GetClientTeam(client) != 2)
    {
        return;
    }
	SDKCall(sdkSetBuffer, client, 0.0);
}

public int Forward_BerserkerUsed(int client)
{
	bool result;
	Call_StartForward(g_hForward_BerserkUse);
	Call_PushCell(client);
	Call_Finish(view_as<int>(result));
	return result;
}
