/*=======================================================================================
	Plugin Info:

*	Name	:	Survivor Chat Select
*	Author	:	mi123645
*	Descrp	:	This plugin allows players to change their character or model
*	Link	:	https://forums.alliedmods.net/showthread.php?t=107121

*   Edits by:   DeathChaos25
*	Descrp	:	Compatibility with fakezoey plugin added
*   Link    :   https://forums.alliedmods.net/showthread.php?t=258189

*   Edits by:   Cookie
*	Descrp	:	Support for cookies added

*   Edits by:   Merudo
*	Descrp	:	Fixed bugs with misplaced weapon models after selecting a survivor & added admin menu support (!sm_admin)
*   Link    :   "https://forums.alliedmods.net/showthread.php?p=2399150#post2399150"

========================================================================================*/
#pragma semicolon 1
#pragma newdecls required
#define PLUGIN_VERSION "1.6.1"
#define PLUGIN_NAME "Survivor Chat Select"
#define PLUGIN_PREFIX 	"\x01[\x04SCS\x01]"

#include <sourcemod>  
#include <sdktools>
#include <clientprefs>
#include <adminmenu>
#include <colors>

TopMenu hTopMenu;

ConVar convarZoey, convarSpawn, convarAdminsOnly, convarCookies;

#define MODEL_BILL "models/survivors/survivor_namvet.mdl" 
#define MODEL_FRANCIS "models/survivors/survivor_biker.mdl" 
#define MODEL_LOUIS "models/survivors/survivor_manager.mdl" 
#define MODEL_ZOEY "models/survivors/survivor_teenangst.mdl" 

#define MODEL_NICK "models/survivors/survivor_gambler.mdl" 
#define MODEL_ROCHELLE "models/survivors/survivor_producer.mdl" 
#define MODEL_COACH "models/survivors/survivor_coach.mdl" 
#define MODEL_ELLIS "models/survivors/survivor_mechanic.mdl" 

#define     NICK     	0
#define     ROCHELLE    1
#define     COACH     	2
#define     ELLIS     	3
#define     BILL     	4
#define     ZOEY     	5
#define     FRANCIS     6
#define     LOUIS     	7

int    g_iSelectedClient[MAXPLAYERS + 1] = {0, ...};
static Cookie g_hClientID, g_hClientModel;
GlobalForward g_hForwardOnCharSelected;

public Plugin myinfo =  
{  
	name = PLUGIN_NAME,  
	author = "DeatChaos25, Mi123456 & Merudo",  
	description = "Select a survivor character by typing their name into the chat.",  
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2399163#post2399163"
} 

public void OnPluginStart()  
{
	g_hForwardOnCharSelected = CreateGlobalForward("L4D2_OnCharSelected", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hClientID 	= new Cookie("Player_Character", "Player's default character ID.", CookieAccess_Protected);
	g_hClientModel  = new Cookie("Player_Model", "Player's default character model.", CookieAccess_Protected);

	RegConsoleCmd("sm_zoey", ZoeyUse, "Changes your survivor character into Zoey");  
	RegConsoleCmd("sm_nick", NickUse, "Changes your survivor character into Nick");  
	RegConsoleCmd("sm_ellis", EllisUse, "Changes your survivor character into Ellis");  
	RegConsoleCmd("sm_coach", CoachUse, "Changes your survivor character into Coach");  
	RegConsoleCmd("sm_rochelle", RochelleUse, "Changes your survivor character into Rochelle");  
	RegConsoleCmd("sm_bill", BillUse, "Changes your survivor character into Bill");  
	RegConsoleCmd("sm_francis", BikerUse, "Changes your survivor character into Francis");  
	RegConsoleCmd("sm_louis", LouisUse, "Changes your survivor character into Louis");  

	RegConsoleCmd("sm_z", ZoeyUse, "Changes your survivor character into Zoey");  
	RegConsoleCmd("sm_n", NickUse, "Changes your survivor character into Nick");  
	RegConsoleCmd("sm_e", EllisUse, "Changes your survivor character into Ellis");  
	RegConsoleCmd("sm_c", CoachUse, "Changes your survivor character into Coach");  
	RegConsoleCmd("sm_r", RochelleUse, "Changes your survivor character into Rochelle");  
	RegConsoleCmd("sm_b", BillUse, "Changes your survivor character into Bill");  
	RegConsoleCmd("sm_f", BikerUse, "Changes your survivor character into Francis");  
	RegConsoleCmd("sm_l", LouisUse, "Changes your survivor character into Louis");  

	RegAdminCmd("sm_csc", InitiateMenuAdmin, ADMFLAG_GENERIC, "Brings up a menu to select a client's character"); 
	RegConsoleCmd("sm_csm", ShowMenu, "Brings up a menu to select a client's character"); 
	RegConsoleCmd("sm_model", ShowMenu, "Brings up a menu to select a client's character"); 	

	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_bot_replace", Event_PlayerToBot, EventHookMode_Post);

	convarAdminsOnly = CreateConVar("l4d_csm_admins_only", "0","Changes access to the sm_csm command. 1 = Admin access only.", FCVAR_NOTIFY, true, 0.0, true, 1.0);		
	convarZoey 		 = CreateConVar("l4d_scs_zoey", "1", "Prop for Zoey. 0: Rochelle (windows), 1: Zoey (linux), 2: Nick (fakezoey)", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	convarSpawn		 = CreateConVar("l4d_scs_botschange", "0", "Change new bots to least prevalent survivor? 1:Enable, 0:Disable", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convarCookies	 = CreateConVar("l4d_scs_cookies", "1", "Store player's survivor? 1:Enable, 0:Disable", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	LoadTranslations("survivor_chat_select.phrases");
	AutoExecConfig(true, "l4dscs");

	/* Account for late loading */
	TopMenu topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null))
	{
		OnAdminMenuReady(topmenu);
	}
} 

// *********************************************************************************
// Character Select functions
// *********************************************************************************	

int GetZoeyProp()
{
	if 		(convarZoey.IntValue == 2) return NICK;			// For use with fakezoey for windows
	else if (convarZoey.IntValue == 1) return ZOEY;			// Linux only, or crashes the game
	else							   return ROCHELLE;		// For windows without fakezoey
}

Action ZoeyUse(int client, int args)  
{  
	if(!Capped(client)) SurvivorChange(client, GetZoeyProp(), MODEL_ZOEY, "Zoey");
	return Plugin_Handled;
}

Action NickUse(int client, int args)  
{
	if(!Capped(client)) SurvivorChange(client, NICK, MODEL_NICK, "Nick");
	return Plugin_Handled;
}

Action EllisUse(int client, int args)  
{
	if(!Capped(client)) SurvivorChange(client, ELLIS, MODEL_ELLIS, "Ellis");
	return Plugin_Handled;
}

Action CoachUse(int client, int args)  
{
	if(!Capped(client)) SurvivorChange(client, COACH, MODEL_COACH, "Coach");
	return Plugin_Handled;
}

Action RochelleUse(int client, int args)  
{  
	if(!Capped(client)) SurvivorChange(client, ROCHELLE, MODEL_ROCHELLE, "Rochelle");
	return Plugin_Handled;
}

Action BillUse(int client, int args)  
{  
	if(!Capped(client)) SurvivorChange(client, BILL, MODEL_BILL, "Bill");
	return Plugin_Handled;
}

Action BikerUse(int client, int args)  
{  
	if(!Capped(client)) SurvivorChange(client, FRANCIS, MODEL_FRANCIS, "Francis");
	return Plugin_Handled;
}

Action LouisUse(int client, int args)  
{  
	if(!Capped(client)) SurvivorChange(client, LOUIS, MODEL_LOUIS, "Louis");
	return Plugin_Handled;
}

// Function changes the survivor
void SurvivorChange(int client, int prop, char[] model,  char[] name, bool save = true)
{
	if(client < 1 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 2)
	{
		CPrintToChat(client, "%t", "YouMustBeInSurvivor");
		return;
	}

	if (IsFakeClient(client))  // if bot, change name
	{
		SetClientInfo(client, "name", name);
	}

	SetEntProp(client, Prop_Send, "m_survivorCharacter", prop);  
	SetEntityModel(client, model);
	ReEquipWeapons(client);

	if (convarCookies && save)
	{
		char sprop[2]; IntToString(prop, sprop, 2);
		g_hClientID.Set(client, sprop);
		g_hClientModel.Set(client, model);
		CPrintToChat(client, "%t", "YourDefaultCharacterIsNowSet", PLUGIN_PREFIX, name); 
	}
}	
	
public void OnMapStart() 
{     
	FindConVar("precache_all_survivors").SetInt(1); 

	if (!IsModelPrecached("models/survivors/survivor_teenangst.mdl"))	PrecacheModel("models/survivors/survivor_teenangst.mdl", false); 
	if (!IsModelPrecached("models/survivors/survivor_biker.mdl"))		PrecacheModel("models/survivors/survivor_biker.mdl", false); 
	if (!IsModelPrecached("models/survivors/survivor_manager.mdl"))		PrecacheModel("models/survivors/survivor_manager.mdl", false); 
	if (!IsModelPrecached("models/survivors/survivor_namvet.mdl"))		PrecacheModel("models/survivors/survivor_namvet.mdl", false); 
	if (!IsModelPrecached("models/survivors/survivor_gambler.mdl"))		PrecacheModel("models/survivors/survivor_gambler.mdl", false); 
	if (!IsModelPrecached("models/survivors/survivor_coach.mdl"))		PrecacheModel("models/survivors/survivor_coach.mdl", false); 
	if (!IsModelPrecached("models/survivors/survivor_mechanic.mdl"))    PrecacheModel("models/survivors/survivor_mechanic.mdl", false); 
	if (!IsModelPrecached("models/survivors/survivor_producer.mdl"))	PrecacheModel("models/survivors/survivor_producer.mdl", false); 
}

// *********************************************************************************
// Character Select menu
// *********************************************************************************	

/* This Admin Menu was taken from csm, all credits go to Mi123645 */ 
Action InitiateMenuAdmin(int client, int args)  
{
	if (client == 0)  
	{ 
		ReplyToCommand(client, "Menu is in-game only."); 
		return Plugin_Handled; 
	}

	char name[MAX_NAME_LENGTH], number[10];

	Menu menu = new Menu(ShowMenu2);
	menu.SetTitle("Select a client:"); 

	for (int i = 1; i <= MaxClients; i++) 
	{ 
		if (!IsClientInGame(i)) continue; 
		if (GetClientTeam(i) != 2) continue; 
		//if (i == client) continue; 

		Format(name, sizeof(name), "%N", i); 
		Format(number, sizeof(number), "%i", i); 
		menu.AddItem(number, name); 
	}

	menu.ExitButton = true; 
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

int ShowMenu2(Menu menu, MenuAction action, int client, int param2)  
{
	switch (action)  
	{
		case MenuAction_Select:  
		{
			char number[4]; 
			menu.GetItem(param2, number, sizeof(number)); 
			g_iSelectedClient[client] = StringToInt(number);
			ShowMenuAdmin(client, 0); 
		}
		case MenuAction_Cancel:
		{ 
			if (param2 == MenuCancel_ExitBack && hTopMenu != null)
			{
				hTopMenu.Display(client, TopMenuPosition_LastCategory);
			}			
		} 
		case MenuAction_End:  
		{
			delete menu;
		}
	}
	return 0;
}

Action ShowMenuAdmin(int client, int args)  
{
	if(client > 0 && args < 1)
	{
		char cMenuTitle[40], sMenuEntry[16]; 

		Menu menu = new Menu(CharMenuAdmin); 
		Format(cMenuTitle, sizeof(cMenuTitle), "%T\n \n", "ChooseACharacter", client);
		menu.SetTitle(cMenuTitle); 

		Format(sMenuEntry, sizeof(sMenuEntry), "%T", "Nick", client);
		menu.AddItem("0", sMenuEntry); 
		Format(sMenuEntry, sizeof(sMenuEntry), "%T", "Rochelle", client);
		menu.AddItem("1", sMenuEntry); 
		Format(sMenuEntry, sizeof(sMenuEntry), "%T", "Coach", client);
		menu.AddItem("2", sMenuEntry); 
		Format(sMenuEntry, sizeof(sMenuEntry), "%T", "Ellis", client);
		menu.AddItem("3", sMenuEntry);

		Format(sMenuEntry, sizeof(sMenuEntry), "%T", "Bill", client);
		menu.AddItem("4", sMenuEntry);     
		Format(sMenuEntry, sizeof(sMenuEntry), "%T", "Zoey", client);
		menu.AddItem("5", sMenuEntry); 
		Format(sMenuEntry, sizeof(sMenuEntry), "%T", "Francis", client);
		menu.AddItem("6", sMenuEntry); 
		Format(sMenuEntry, sizeof(sMenuEntry), "%T", "Louis", client);
		menu.AddItem("7", sMenuEntry); 

		menu.ExitButton = true; 
		menu.Display(client, MENU_TIME_FOREVER);
	}
	return Plugin_Handled;
}

int CharMenuAdmin(Menu menu, MenuAction action, int client, int param2)  
{
	switch (action)
	{
		case MenuAction_Select:  
		{
			char item[8]; 
			menu.GetItem(param2, item, sizeof(item)); 

			switch(StringToInt(item))
			{
				case NICK: SurvivorChange(g_iSelectedClient[client],          NICK, MODEL_NICK,    "Nick", false);     
				case ROCHELLE: SurvivorChange(g_iSelectedClient[client],      ROCHELLE, MODEL_ROCHELLE, "Rochelle", false);     
				case COACH: SurvivorChange(g_iSelectedClient[client],         COACH, MODEL_COACH,   "Coach", false);
				case ELLIS: SurvivorChange(g_iSelectedClient[client],         ELLIS, MODEL_ELLIS,   "Ellis", false); 
				case BILL: SurvivorChange(g_iSelectedClient[client],          BILL, MODEL_BILL,    "Bill", false);
				case ZOEY: SurvivorChange(g_iSelectedClient[client], GetZoeyProp(), MODEL_ZOEY,    "Zoey", false);  
				case FRANCIS: SurvivorChange(g_iSelectedClient[client],       FRANCIS, MODEL_FRANCIS, "Francis", false);
				case LOUIS: SurvivorChange(g_iSelectedClient[client],         LOUIS, MODEL_LOUIS,   "Louis", false);
			} 
		} 
		case MenuAction_Cancel: {}
		case MenuAction_End: delete menu; 
	}
	return 0;
}

Action ShowMenu(int client, int args) 
{
	if (client == 0) 
	{
		ReplyToCommand(client, "%t", "SCSMenuInGameOnly");
		return Plugin_Handled;
	}
	if (GetClientTeam(client) != 2)
	{
		ReplyToCommand(client, "%t", "OnlyAvailableToSurv");
		return Plugin_Handled;
	}
	if (!IsPlayerAlive(client)) 
	{
		ReplyToCommand(client, "%t", "YouMustBeAlive");
		return Plugin_Handled;
	}
	if (GetUserFlagBits(client) == 0 && convarAdminsOnly.BoolValue)
	{
		ReplyToCommand(client, "%t", "OnlyAvaliableToAdmins");
		return Plugin_Handled;
	}

	char cMenuTitle[40], sMenuEntry[16]; 
	Menu menu = new Menu(CharMenu);
	Format(cMenuTitle, sizeof(cMenuTitle), "%T\n \n", "ChooseACharacter", client);
	menu.SetTitle(cMenuTitle);

	Format(sMenuEntry, sizeof(sMenuEntry), "%T", "Nick", client);
	menu.AddItem("0", sMenuEntry); 
	Format(sMenuEntry, sizeof(sMenuEntry), "%T", "Rochelle", client);
	menu.AddItem("1", sMenuEntry); 
	Format(sMenuEntry, sizeof(sMenuEntry), "%T", "Coach", client);
	menu.AddItem("2", sMenuEntry); 
	Format(sMenuEntry, sizeof(sMenuEntry), "%T", "Ellis", client);
	menu.AddItem("3", sMenuEntry);

	Format(sMenuEntry, sizeof(sMenuEntry), "%T", "Bill", client);
	menu.AddItem("4", sMenuEntry);     
	Format(sMenuEntry, sizeof(sMenuEntry), "%T", "Zoey", client);
	menu.AddItem("5", sMenuEntry); 
	Format(sMenuEntry, sizeof(sMenuEntry), "%T", "Francis", client);
	menu.AddItem("6", sMenuEntry); 
	Format(sMenuEntry, sizeof(sMenuEntry), "%T", "Louis", client);
	menu.AddItem("7", sMenuEntry);

	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

int CharMenu(Menu menu, MenuAction action, int param1, int param2) 
{
	switch (action) 
	{
		case MenuAction_Select: 
		{
			char item[8];
			menu.GetItem(param2, item, sizeof(item));

			switch(StringToInt(item)) 
			{
				case NICK: NickUse(param1, NICK);
				case ROCHELLE: RochelleUse(param1, ROCHELLE);
				case COACH: CoachUse(param1, COACH);
				case ELLIS: EllisUse(param1, ELLIS);
				case BILL: BillUse(param1, BILL);
				case ZOEY: ZoeyUse(param1, ZOEY);
				case FRANCIS: BikerUse(param1, FRANCIS);
				case LOUIS: LouisUse(param1, LOUIS);
			}
		}
		case MenuAction_Cancel:
		{
		}
		case MenuAction_End: 
		{
			delete menu;
		}
	}
	return 0;
}

// *********************************************************************************
// Admin Menu entry
// *********************************************************************************

//// Added for admin menu
public void OnAdminMenuReady(Handle aTopMenu)
{
	TopMenu topmenu = TopMenu.FromHandle(aTopMenu);

	/* Block us from being called twice */
	if (topmenu == hTopMenu)
	{
		return;
	}
	
	/* Save the Handle */
	hTopMenu = topmenu;
	
	// Find player's menu ...
	TopMenuObject player_commands = hTopMenu.FindCategory(ADMINMENU_PLAYERCOMMANDS);

	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		hTopMenu.AddItem("Select player's survivor", InitiateMenuAdmin2, player_commands, "Select player's survivor", ADMFLAG_GENERIC);
	}
}

void InitiateMenuAdmin2(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int client, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "SelectPlayersSurvivor", client);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		InitiateMenuAdmin(client, 0);
	}
}

// *********************************************************************************
// Cookie loading
// *********************************************************************************

Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2 && convarCookies)
	{
		CreateTimer(0.3, Timer_LoadCookie, GetClientUserId(client));
	}
	return Plugin_Continue;
}

Action Timer_LoadCookie(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	char sID[2], sModel[64];

	if(client > 0 && IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2 && convarCookies)
	{
		if(AreClientCookiesCached(client))
		{
			g_hClientID.Get(client, sID, sizeof(sID));
			g_hClientModel.Get(client, sModel, sizeof(sModel));

			if(strlen(sID) && strlen(sModel))
			{
				SetEntProp(client, Prop_Send, "m_survivorCharacter", StringToInt(sID)); 
				SetEntityModel(client, sModel);
			}
		}
		else 
		{
			CPrintToChat(client, "%t", "CouldntLoadYourDefaultCharacter", PLUGIN_PREFIX);
		}
	}
	return Plugin_Stop;
}

// *********************************************************************************
// Bots spawn as survivor with fewest clones
// *********************************************************************************

char survivor_models[8][] = { MODEL_NICK, MODEL_ROCHELLE, MODEL_COACH, MODEL_ELLIS, MODEL_BILL,	MODEL_ZOEY,	MODEL_FRANCIS, MODEL_LOUIS };
char survivor_commands[8][] = { "sm_nick", "sm_rochelle", "sm_coach", "sm_ellis", "sm_bill", "sm_zoey", "sm_francis", "sm_louis"};

Action Event_PlayerToBot(Event event, char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(event.GetInt("player")), bot = GetClientOfUserId(event.GetInt("bot")); 

	// If bot replace bot (due to bot creation)
	if(player > 0 && GetClientTeam(player) == 2  && IsFakeClient(player) && convarSpawn.BoolValue) 
	{
		FakeClientCommand(bot, survivor_commands[GetFewestSurvivor(bot)]);
	}
	return Plugin_Continue;
}

int GetFewestSurvivor(int clientignore = -1) 
{
	char Model[128];
	int Survivors[8];

	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client) == 2 && client != clientignore)
		{
			GetClientModel(client, Model, 128);
			for (int s = 0; s < 8; s++)
			{
				if (StrEqual(Model, survivor_models[s])) Survivors[s] = Survivors[s] + 1;
			}
		}
	}

	int minS = 1, min  = 9999;

	for (int s = 0; s < 8; s++)
	{
		if (Survivors[s] < min) 
		{
			minS = s;
			min  = Survivors[s];
		}
	}
	return minS;
}

// ------------------------------------------------------------------
// Save weapon details, remove weapon, create new weapons with exact same properties
// Needed otherwise there will be animation bugs after switching characters due to different weapon mount points
// ------------------------------------------------------------------
void ReEquipWeapons(int client)
{
	int i_Weapon = GetEntDataEnt2(client, FindSendPropInfo("CBasePlayer", "m_hActiveWeapon"));
	
	// Don't bother with the weapon fix if dead or unarmed
	if (!IsPlayerAlive(client) || !IsValidEdict(i_Weapon) || !IsValidEntity(i_Weapon))
		return;

	int iSlot0 = GetPlayerWeaponSlot(client, 0), iSlot1 = GetPlayerWeaponSlot(client, 1), 
		iSlot2 = GetPlayerWeaponSlot(client, 2), iSlot3 = GetPlayerWeaponSlot(client, 3), 
		iSlot4 = GetPlayerWeaponSlot(client, 4);

	char sWeapon[64];
	GetClientWeapon(client, sWeapon, sizeof(sWeapon));

	//  Protection against grenade duplication exploit (throwing grenade then quickly changing character)
	if (iSlot2 > 0 && strcmp(sWeapon, "weapon_vomitjar", true) && strcmp(sWeapon, "weapon_pipe_bomb", true) && strcmp(sWeapon, "weapon_molotov", true ))
	{
		GetEdictClassname(iSlot2, sWeapon, 64);
		DeletePlayerSlot(client, iSlot2);
		GivePlayerItem(client, sWeapon);
	}
	if (iSlot3 > 0)
	{
		GetEdictClassname(iSlot3, sWeapon, 64);
		DeletePlayerSlot(client, iSlot3);
		GivePlayerItem(client, sWeapon);
	}
	if (iSlot4 > 0)
	{
		GetEdictClassname(iSlot4, sWeapon, 64);
		DeletePlayerSlot(client, iSlot4);
		GivePlayerItem(client, sWeapon);
	}
	if (iSlot1 > 0) ReEquipSlot1(client, iSlot1);
	if (iSlot0 > 0) ReEquipSlot0(client, iSlot0);
}

// --------------------------------------
// Extra work to save/load ammo details
// --------------------------------------	
void ReEquipSlot0(int client, int iSlot0)
{
	Call_StartForward(g_hForwardOnCharSelected);
	Call_PushCell(client);
	Call_Finish();

	int iClip,iAmmo, iUpgrade, iUpAmmo;
	char sWeapon[64];

	GetEdictClassname(iSlot0, sWeapon, 64);

	iClip = GetEntProp(iSlot0, Prop_Send, "m_iClip1", 4);
	iAmmo = GetClientAmmo(client, sWeapon);
	iUpgrade = GetEntProp(iSlot0, Prop_Send, "m_upgradeBitVec", 4);
	iUpAmmo  = GetEntProp(iSlot0, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", 4);

	DeletePlayerSlot(client, iSlot0);
	GivePlayerItem(client, sWeapon);

	SetEntProp(iSlot0, Prop_Send, "m_iClip1", iClip, 4);
	SetClientAmmo(client, sWeapon, iAmmo);
	SetEntProp(iSlot0, Prop_Send, "m_upgradeBitVec", iUpgrade, 4);
	SetEntProp(iSlot0, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", iUpAmmo, 4);
}

// --------------------------------------
// Extra work to identify melee weapon, & save/load ammo details
// --------------------------------------
void ReEquipSlot1(int client, int iSlot1)
{
	char className[64], modelName[64], sWeapon[64];
	
	sWeapon[0] = '\0' ;
	int Ammo = -1, iSlot = -1;

	GetEdictClassname(iSlot1, className, sizeof(className));

	// Try to find weapon name without models
	if 		(!strcmp(className, "weapon_melee", true))   GetEntPropString(iSlot1, Prop_Data, "m_strMapSetScriptName", sWeapon, 64);
	else if (strcmp(className, "weapon_pistol", true))   GetEdictClassname(iSlot1, sWeapon, 64);
	
	// IF model checking is required
	if (sWeapon[0] == '\0')
	{
		GetEntPropString(iSlot1, Prop_Data, "m_ModelName", modelName, sizeof(modelName));

		if 		(StrContains(modelName, "v_pistolA.mdl",         true) != -1)	sWeapon = "weapon_pistol";
		else if (StrContains(modelName, "v_dual_pistolA.mdl",    true) != -1)	sWeapon = "dual_pistol";
		else if (StrContains(modelName, "v_desert_eagle.mdl",    true) != -1)	sWeapon = "weapon_pistol_magnum";
		else if (StrContains(modelName, "v_bat.mdl",             true) != -1)	sWeapon = "baseball_bat";
		else if (StrContains(modelName, "v_cricket_bat.mdl",     true) != -1)	sWeapon = "cricket_bat";
		else if (StrContains(modelName, "v_crowbar.mdl",         true) != -1)	sWeapon = "crowbar";
		else if (StrContains(modelName, "v_fireaxe.mdl",         true) != -1)	sWeapon = "fireaxe";
		else if (StrContains(modelName, "v_katana.mdl",          true) != -1)	sWeapon = "katana";
		else if (StrContains(modelName, "v_golfclub.mdl",        true) != -1)	sWeapon = "golfclub";
		else if (StrContains(modelName, "v_machete.mdl",         true) != -1)	sWeapon = "machete";
		else if (StrContains(modelName, "v_tonfa.mdl",           true) != -1)	sWeapon = "tonfa";
		else if (StrContains(modelName, "v_electric_guitar.mdl", true) != -1)	sWeapon = "electric_guitar";
		else if (StrContains(modelName, "v_frying_pan.mdl",      true) != -1)	sWeapon = "frying_pan";
		else if (StrContains(modelName, "v_knife_t.mdl",         true) != -1)	sWeapon = "knife";
		else if (StrContains(modelName, "v_chainsaw.mdl",        true) != -1)	sWeapon = "weapon_chainsaw";
		else if (StrContains(modelName, "v_riotshield.mdl",      true) != -1)	sWeapon = "alliance_shield";
		else if (StrContains(modelName, "v_fubar.mdl",           true) != -1)	sWeapon = "fubar";
		else if (StrContains(modelName, "v_paintrain.mdl",       true) != -1)	sWeapon = "nail_board";
		else if (StrContains(modelName, "v_sledgehammer.mdl",    true) != -1)	sWeapon = "sledgehammer";
		else if (StrContains(modelName, "v_pitchfork.mdl",       true) != -1)	sWeapon = "pitchfork";
		else if (StrContains(modelName, "v_shovel.mdl",    		 true) != -1)	sWeapon = "shovel";
	}

	// IF Weapon properly identified, save then delete then reequip
	if (sWeapon[0] != '\0')
	{
		// IF Weapon uses ammo, save it
		if (!strcmp(sWeapon, "dual_pistol", true) 
		||  !strcmp(sWeapon, "weapon_pistol", true)
		||  !strcmp(sWeapon, "weapon_pistol_magnum", true) 
		||  !strcmp(sWeapon, "weapon_chainsaw", true)
		)
		{
			Ammo = GetEntProp(iSlot1, Prop_Send, "m_iClip1", 4);
		}	

		DeletePlayerSlot(client, iSlot1);

		// Reequip weapon (special code for dual pistols)
		if (!strcmp(sWeapon, "dual_pistol", true))
		{
			GivePlayerItem(client, "weapon_pistol");
			GivePlayerItem(client, "weapon_pistol");
		}
		else
		{
			GivePlayerItem(client, sWeapon);
		}

		// Restore ammo
		if (Ammo >= 0)
		{
			iSlot = GetPlayerWeaponSlot(client, 1);
			if (iSlot > 0) SetEntProp(iSlot, Prop_Send, "m_iClip1", Ammo, 4);
		}
	}
}

void DeletePlayerSlot(int client, int weapon)
{		
	if(RemovePlayerItem(client, weapon))
	{
		AcceptEntityInput(weapon, "Kill");
	}
}

// *********************************************************************************
// Get/Set ammo
// *********************************************************************************

int GetClientAmmo(int client, char[] weapon)
{
	int weapon_offset = GetWeaponOffset(weapon), iAmmoOffset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
	return weapon_offset > 0 ? GetEntData(client, iAmmoOffset + weapon_offset) : 0;
}

void SetClientAmmo(int client, char[] weapon, int count)
{
	int weapon_offset = GetWeaponOffset(weapon), iAmmoOffset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
	if (weapon_offset > 0) SetEntData(client, iAmmoOffset + weapon_offset, count);
}

int GetWeaponOffset(char[] weapon)
{
	int weapon_offset;

	if (StrEqual(weapon, "weapon_rifle") || StrEqual(weapon, "weapon_rifle_sg552") || StrEqual(weapon, "weapon_rifle_desert") || StrEqual(weapon, "weapon_rifle_ak47"))
	{
		weapon_offset = 12;
	}
	else if (StrEqual(weapon, "weapon_rifle_m60"))
	{
		weapon_offset = 24;
	}
	else if (StrEqual(weapon, "weapon_smg") || StrEqual(weapon, "weapon_smg_silenced") || StrEqual(weapon, "weapon_smg_mp5"))
	{
		weapon_offset = 20;
	}
	else if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_shotgun_chrome"))
	{
		weapon_offset = 28;
	}
	else if (StrEqual(weapon, "weapon_autoshotgun") || StrEqual(weapon, "weapon_shotgun_spas"))
	{
		weapon_offset = 32;
	}
	else if (StrEqual(weapon, "weapon_hunting_rifle"))
	{
		weapon_offset = 36;
	}
	else if (StrEqual(weapon, "weapon_sniper_scout") || StrEqual(weapon, "weapon_sniper_military") || StrEqual(weapon, "weapon_sniper_awp"))
	{
		weapon_offset = 40;
	}
	else if (StrEqual(weapon, "weapon_grenade_launcher"))
	{
		weapon_offset = 68;
	}

	return weapon_offset;
}

bool Capped(const int client)
{
	if(GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0) return true; 
	else if(GetEntPropEnt(client, Prop_Send, "m_carryAttacker" ) > 0) return true; 
	else if(GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0) return true;
	else if(GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0) return true;
	else if(GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0) return true;
	return false;
}
