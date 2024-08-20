#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <adminmenu>
#include <colors>

#define PLUGIN_VERSION "2.1"

int g_MuteList[MAXPLAYERS + 1][MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "Self-Mute",
	author = "Accelerator, Otokiru ,edit 93x(Edit. by BloodyBlade)",
	description = "Self Mute Player Voice",
	version = PLUGIN_VERSION,
	url = "www.xose.net"
}

//====================================================================================================
//==== CREDITS: Otokiru (Idea+Source) // TF2MOTDBackpack (PlayerList Menu)
//====================================================================================================

public void OnPluginStart() 
{	
	LoadTranslations("common.phrases");
	LoadTranslations("selfmute.phrases");
	CreateConVar("sm_selfmute_version", PLUGIN_VERSION, "Version of Self-Mute", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegConsoleCmd("sm_sm", selfMute, "Mute player by typing !selfmute [playername]");
	RegConsoleCmd("sm_selfmute", selfMute, "Mute player by typing !sm [playername]");
	RegConsoleCmd("sm_su", selfUnmute, "Unmute player by typing !su [playername]");
	RegConsoleCmd("sm_selfunmute", selfUnmute, "Unmute player by typing !selfunmute [playername]");
	RegConsoleCmd("sm_cm", checkmute, "Check who you have self-muted");
	RegConsoleCmd("sm_checkmute", checkmute, "Check who you have self-muted");

	AddCommandListener(say, "say");
	AddCommandListener(say, "say_team");
}

//====================================================================================================

public void OnClientAuthorized(int client, const char[] auth)
{
	if (!StrEqual(auth, "BOT"))
	{
		if (GetClientTime(client) > 10.0) return;
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		g_MuteList[client][i] = 0;
	}
}

public void OnClientPutInServer(int client)
{
	if (!IsFakeClient(client))
	{
		for (int id = 1; id <= MaxClients; id++)
		{
			if (id != client && g_MuteList[client][id] && IsClientConnected(id))
			{
				if (g_MuteList[client][id] == GetClientUserId(id)) SetListenOverride(client, id, Listen_No);
				else g_MuteList[client][id] = 0;
			}
		}
	}
}

Action say(int i, const char[] command, int argc) 
{  
    char csay[8];
    GetCmdArgString(csay, sizeof(csay));
    StripQuotes(csay);
    TrimString(csay);

    if(i > 0)
    {
        if ((strcmp(csay, "mute", false) == 0) || (strcmp(csay, "!mute", false) == 0))
            GeneralSelfMuteMenu(i, 0);
    	else if((strcmp(csay, "sm", false) == 0) || (strcmp(csay, "!sm", false) == 0))
    		DisplayMuteMenu(i);
    	else if((strcmp(csay, "unmute", false) == 0) || (strcmp(csay, "!unmute", false) == 0) || (strcmp(csay, "su", false) == 0) || (strcmp(csay, "!su", false) == 0))
    		DisplayUnMuteMenu(i);
    	else if ((strcmp(csay, "cm", false) == 0) || (strcmp(csay, "!cm", false) == 0))
    		DisplayCheckMuteMenu(i);
    }
}

stock Action GeneralSelfMuteMenu(int client, int args)
{
	Menu menu = new Menu(MenuHandler_GeneralMuteMenu);
	char MuteMenuTitle[32], Value[32];
	Format(MuteMenuTitle, sizeof(MuteMenuTitle), "%T\n \n", "Mute_menu", client);
	menu.SetTitle(MuteMenuTitle);
	Format(Value, sizeof(Value), "%T", "Mute_player", client);
	menu.AddItem("0", Value);
	Format(Value, sizeof(Value), "%T", "Unmute_player", client);
	menu.AddItem("1", Value);
	Format(Value, sizeof(Value), "%T", "Check_mute_players", client);
	menu.AddItem("2", Value);

	menu.ExitBackButton = true;

	menu.Display(client, 30);
}

int MenuHandler_GeneralMuteMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
            switch (itemNum)
            {
    			case 0: DisplayMuteMenu(client);
    			case 1: DisplayUnMuteMenu(client);
    			case 2: DisplayCheckMuteMenu(client);
            }
		}
	}
}

//====================================================================================================

Action selfMute(int client, int args)
{
	if(client == 0)
	{
		PrintToChat(client, "[SM] Cannot use command from RCON");
		return Plugin_Handled;
	}

	if(args < 1) 
	{
//		ReplyToCommand(client, "[SM] Use: !sm [playername]");
		DisplayMuteMenu(client);
		return Plugin_Handled;
	}

	char strTarget[32], strTargetName[MAX_TARGET_LENGTH];
	int TargetList[MAXPLAYERS], TargetCount; 
	bool TargetTranslate; 
	GetCmdArg(1, strTarget, sizeof(strTarget));

	if ((TargetCount = ProcessTargetString(strTarget, client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_BOTS,  strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0) 
	{
		ReplyToTargetError(client, TargetCount); 
		return Plugin_Handled; 
	}

	for (int i = 0; i < TargetCount; i++) 
	{ 
		if (TargetList[i] > 0 && TargetList[i] != client && IsClientInGame(TargetList[i])) 
		{
			muteTargetedPlayer(client, TargetList[i]);
		}
	}
	return Plugin_Handled;
}

void DisplayMuteMenu(int client)
{
	Menu menu = new Menu(MenuHandler_MuteMenu);
	char DisplayMuteMenuTitle[32];
	Format(DisplayMuteMenuTitle, sizeof(DisplayMuteMenuTitle), "%T\n \n", "Choose a player to mute", client);
	menu.SetTitle(DisplayMuteMenuTitle);
	AddTargetsToMenu2(menu, 0, COMMAND_FILTER_NO_BOTS);
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int MenuHandler_MuteMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			int target = GetClientOfUserId(StringToInt(info));
			if (target > 0) muteTargetedPlayer(param1, target);
			else CPrintToChat(param1, "%t", "[Self-Mute] Player no longer available");
		}
	}
	return 0;
}

void muteTargetedPlayer(int client, int target)
{
	SetListenOverride(client, target, Listen_No);
	CPrintToChat(client, "%t", "[Self-Mute] You have self-muted: %N", target);
	g_MuteList[client][target] = GetClientUserId(target);
}

//====================================================================================================

Action selfUnmute(int client, int args)
{
	if(client == 0)
	{
		PrintToChat(client, "[SM] Cannot use command from RCON");
		return Plugin_Handled;
	}

	if(args < 1) 
	{
//		ReplyToCommand(client, "[SM] Use: !su [playername]");
		DisplayUnMuteMenu(client);
		return Plugin_Handled;
	}

	char strTarget[32], strTargetName[MAX_TARGET_LENGTH];
	int TargetList[MAXPLAYERS], TargetCount;
	bool TargetTranslate;	
	GetCmdArg(1, strTarget, sizeof(strTarget));

	if ((TargetCount = ProcessTargetString(strTarget, client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_BOTS, 
	strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0) 
	{
		ReplyToTargetError(client, TargetCount); 
		return Plugin_Handled; 
	}

	for (int i = 0; i < TargetCount; i++) 
	{ 
		if(TargetList[i] > 0 && TargetList[i] != client && IsClientInGame(TargetList[i]))
		{
			unMuteTargetedPlayer(client, TargetList[i]);
		}
	}
	return Plugin_Handled;
}

void DisplayUnMuteMenu(int client)
{
	Menu menu = new Menu(MenuHandler_UnMuteMenu);
	char DisplayUnMuteMenuTitle[32];
	Format(DisplayUnMuteMenuTitle, sizeof(DisplayUnMuteMenuTitle), "%T\n \n", "Choose a player to unmute:", client);
	menu.SetTitle(DisplayUnMuteMenuTitle);
	AddTargetsToMenu2(menu, 0, COMMAND_FILTER_NO_BOTS);
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int MenuHandler_UnMuteMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			int target = GetClientOfUserId(StringToInt(info));
			if (target > 0) unMuteTargetedPlayer(param1, target);
			else PrintToChat(param1, "[SM] Player no longer available");
		}
	}
	return 0;
}

void unMuteTargetedPlayer(int client, int target)
{
	SetListenOverride(client, target, Listen_Default);
	CPrintToChat(client, "%t", "[Self-Mute] You have self-unmuted: %N", target);
	g_MuteList[client][target] = 0;
}

//====================================================================================================

Action checkmute(int client, int args)
{
	if (client) DisplayCheckMuteMenu(client);
	return Plugin_Handled;
}

Action DisplayCheckMuteMenu(int client)
{
	Panel CheckMutePanel = new Panel();
	char nickNames[256];
	bool firstNick = true;
	Format(nickNames, sizeof(nickNames), "%T\n \n", "List of self-muted:");
	CheckMutePanel.SetTitle(nickNames);
	strcopy(nickNames, sizeof(nickNames), "No players found.");

	for (int id = 1; id <= MaxClients; id++)
	{
		if (IsClientInGame(id) && !IsFakeClient(id))
		{
			if(GetListenOverride(client, id) == Listen_No)
			{
				if(firstNick)
				{
					firstNick = false;
					FormatEx(nickNames, sizeof(nickNames), "%N", id);
				}
				else Format(nickNames, sizeof(nickNames), "%s, %N", nickNames, id);
				CheckMutePanel.DrawText(nickNames);
			}
		}
	}

	CheckMutePanel.Send(client, MuteMenuHandler, 10);
	CheckMutePanel.Close();

	return Plugin_Handled;
}

int MuteMenuHandler(Menu CheckMutePanel, MenuAction action, int client, int param2)
{
}
