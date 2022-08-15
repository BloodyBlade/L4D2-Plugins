#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <adminmenu>
#include <colors>

#define PLUGIN_VERSION "1.03"

bool MuteStatus[MAXPLAYERS + 1][MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "Self-Mute",
	author = "Otokiru ,edit 93x, Accelerator(edit. by BloodyBlade)",
	description = "Self Mute Player Voice",
	version = PLUGIN_VERSION,
	url = "www.xose.net"
}

//====================================================================================================
//==== CREDITS: Otokiru (Idea+Source) // TF2MOTDBackpack (PlayerList Menu)
//====================================================================================================

public void OnPluginStart() 
{
	LoadTranslations("selfmute.phrases");
	CreateConVar("sm_selfmute_version", PLUGIN_VERSION, "Version of Self-Mute", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);

	AddCommandListener(say, "say");
	AddCommandListener(say, "say_team");
}

//====================================================================================================

public void OnClientPutInServer(int client)
{
	if (IsFakeClient(client)) return;

	float fClientTime = GetClientTime(client);
	for (int id = 1; id <= MaxClients; id++)
	{
		if (fClientTime <= 180.0)
		{
			MuteStatus[id][client] = false;
			MuteStatus[client][id] = false;
			continue;
		}
		if (id != client && IsClientInGame(id))
		{
			if (MuteStatus[id][client]) SetListenOverride(id, client, Listen_No);
			if (MuteStatus[client][id]) SetListenOverride(client, id, Listen_No);
		}
	}
}

public Action say(int i, const char[] command, int argc) 
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

public int MenuHandler_GeneralMuteMenu(Menu menu, MenuAction action, int client, int itemNum)
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

public Action selfMute(int client, int args)
{
	if(client)
	{
		if(args < 1)
		{
//			ReplyToCommand(client, "[SM] Use: !sm [playername]");
			DisplayMuteMenu(client);
			return Plugin_Handled;
		}

		char arg2[10], strTarget[32], strTargetName[MAX_TARGET_LENGTH];
		GetCmdArg(2, arg2, sizeof(arg2));
		GetCmdArg(1, strTarget, sizeof(strTarget)); 

		int TargetList[MAXPLAYERS], TargetCount; 
		bool TargetTranslate; 

		if ((TargetCount = ProcessTargetString(strTarget, client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_BOTS, 
		strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0) 
		{
			ReplyToTargetError(client, TargetCount); 
			return Plugin_Handled; 
		}

		for (int i = 0; i < TargetCount; i++) 
		{
			if (TargetList[i] > 0 && TargetList[i] != client && IsClientInGame(TargetList[i]))
				muteTargetedPlayer(client, TargetList[i]);
		}
	}
	return Plugin_Handled;
}

public Action DisplayMuteMenu(int client)
{
	Menu menu = new Menu(MenuHandler_MuteMenu);
	char DisplayMuteMenuTitle[32];
	Format(DisplayMuteMenuTitle, sizeof(DisplayMuteMenuTitle), "%T\n \n", "Choose a player to mute", client);
	menu.SetTitle(DisplayMuteMenuTitle);
	menu.ExitBackButton = true;

	AddTargetsToMenu2(menu, 0, COMMAND_FILTER_NO_BOTS);

	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_MuteMenu(Menu menu, MenuAction action, int param1, int param2)
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
			int target, userid = StringToInt(info);

			if ((target = GetClientOfUserId(userid)) == 0) CPrintToChat(param1, "%t", "[Self-Mute] Player no longer available");
			else muteTargetedPlayer(param1, target);
		}
	}
}

public void muteTargetedPlayer(int client, int target)
{
	SetListenOverride(client, target, Listen_No);
	CPrintToChat(client, "%t", "[Self-Mute] You have self-muted: %N", target);
	MuteStatus[client][target] = true;
}

//====================================================================================================

public Action selfUnmute(int client, int args)
{
	if(client)
	{
		if(args < 1) 
		{
//			ReplyToCommand(client, "[SM] Use: !su [playername]");
			DisplayUnMuteMenu(client);
			return Plugin_Handled;
		}

		char arg2[10], strTarget[32], strTargetName[MAX_TARGET_LENGTH];
		GetCmdArg(2, arg2, sizeof(arg2));
		GetCmdArg(1, strTarget, sizeof(strTarget));

		int TargetList[MAXPLAYERS], TargetCount; 
		bool TargetTranslate; 

		if ((TargetCount = ProcessTargetString(strTarget, client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_BOTS, 
		strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0) 
		{
			ReplyToTargetError(client, TargetCount); 
			return Plugin_Handled; 
		}

		for (int i = 0; i < TargetCount; i++) 
		{
			if(TargetList[i] > 0 && TargetList[i] != client && IsClientInGame(TargetList[i]))
				unMuteTargetedPlayer(client, TargetList[i]);
		}
	}
	return Plugin_Handled;
}

public Action DisplayUnMuteMenu(int client)
{
	Menu menu = new Menu(MenuHandler_UnMuteMenu);
	char DisplayUnMuteMenuTitle[32];
	Format(DisplayUnMuteMenuTitle, sizeof(DisplayUnMuteMenuTitle), "%T\n \n", "Choose a player to unmute:", client);
	menu.SetTitle(DisplayUnMuteMenuTitle);
	menu.ExitBackButton = true;

	AddTargetsToMenu2(menu, 0, COMMAND_FILTER_NO_BOTS);

	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_UnMuteMenu(Menu menu, MenuAction action, int param1, int param2)
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
			int target, userid = StringToInt(info);

			if ((target = GetClientOfUserId(userid)) == 0) CPrintToChat(param1, "[Self-Mute] Player no longer available");
			else unMuteTargetedPlayer(param1, target);
		}
	}
}

public void unMuteTargetedPlayer(int client, int target)
{
	SetListenOverride(client, target, Listen_Yes);
	CPrintToChat(client, "%t", "[Self-Mute] You have self-unmuted: %N", target);
	MuteStatus[client][target] = false;
}

//====================================================================================================

public Action checkmute(int client, int args)
{
	if (client) DisplayCheckMuteMenu(client);
	return Plugin_Handled;
}

public Action DisplayCheckMuteMenu(int client)
{
    Panel CheckMutePanel = CreatePanel();
    char nickNames[256];
    Format(nickNames, sizeof(nickNames), "%T\n \n", "List of self-muted:");
    CheckMutePanel.SetTitle(nickNames);
    
    for (int id = 1; id <= MaxClients; id++)
	{
		if (IsClientInGame(id) && !IsFakeClient(id))
		{
			if(GetListenOverride(client, id) == Listen_No)
			{
				Format(nickNames, sizeof(nickNames), " %N", id);
				CheckMutePanel.DrawText(nickNames);
			}
		}
	}

    CheckMutePanel.Send(client, MuteMenuHandler, 10);
    CheckMutePanel.Close();

    return Plugin_Handled;
}

public int MuteMenuHandler(Menu CheckMutePanel, MenuAction action, int client, int param2)
{
}
