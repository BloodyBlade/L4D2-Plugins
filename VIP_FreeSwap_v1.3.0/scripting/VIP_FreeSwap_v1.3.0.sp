#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <vip_core>

bool g_bAccess[MAXPLAYERS + 1] = {false, ...};

public Plugin myinfo =  
{ 
	name = "[TolikCorporation][VIP] SwapTeam",
	version = "1.3.0"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_swap", Command_Swap);
	RegConsoleCmd("sm_tm", Command_Swap);
	RegConsoleCmd("sm_spec", Command_Spec);
	RegConsoleCmd("sm_sp", Command_Spec);
	AddCommandListener(Command_JoinTeam, "jointeam");
}

public void OnClientPostAdminCheck(int client)
{
	if(client > 0 && !IsFakeClient(client))
	{
		g_bAccess[client] = view_as<bool>(GetUserFlagBits(client) & ADMFLAG_ROOT);
	}
}

public void VIP_OnVIPClientLoaded(int iClient)
{
	if(iClient > 0)
	{
		g_bAccess[iClient] = true;
	}
}

public void VIP_OnVIPClientRemoved(int iClient, const char[] szReason, int iAdmin)
{
	if(iClient > 0)
	{
		g_bAccess[iClient] = false;
	}
}

Action Command_Swap(int client, int args)
{
	if (client > 0 && g_bAccess[client])
	{
		switch (GetClientTeam(client))
		{
			case 2:
			{
				ChangeClientTeam(client, 3);
				PrintToChat(client,"\x01\04[VIP] \x05[Смена команды] \x01Вы успешно сменили команду! [\x03T \x05> \x03CT\x01]");
			}
			case 3:
			{
				ChangeClientTeam(client, 2);
				PrintToChat(client,"\x01\04[VIP] \x05[Смена команды] \x01Вы успешно сменили команду! [\x03CT \x05> \x03T\x01]");
			}
			default:
			{
				if (GetRandomInt(2, 3) == 2)
				{
					ChangeClientTeam(client, 2);
					PrintToChat(client,"\x01\04[VIP] \x05[Смена команды] \x01Вы успешно сменили команду на случайную! [\x03SPEC \x05> \x03T\x01]");
				}
				else
				{
					ChangeClientTeam(client, 3);
					PrintToChat(client,"\x01\04[VIP] \x05[Смена команды] \x01Вы успешно сменили команду на случайную! [\x03SPEC \x05> \x03CT\x01]");
				}
			}
		}
	}
	else if (client > 0)
	{
		PrintToChat(client,"\x01\04[VIP] \x05[Смена команды] \x01Недостаточно полномочий!");
	}
	return Plugin_Handled;
}

Action Command_Spec(int client, int args)
{
	if (client > 0 && g_bAccess[client])
	{
		if (GetClientTeam(client) != 1)
		{
			ChangeClientTeam(client, 1);
			PrintToChat(client,"\x04[VIP] \x05[Смена команды] \x01Вы успешно перешли в \x03Наблюдатели\x01!");
		}
		else
		{
			PrintToChat(client,"\x04[VIP] \x05[Смена команды] \x01Вы итак находитесь в \x03Наблюдателях\x01!");
		}
	}
	else if (client > 0)
	{
		PrintToChat(client,"\x04[VIP] \x05[Смена команды] \x01Недостаточно полномочий!");
	}
	return Plugin_Handled;
}

Action Command_JoinTeam(int client, char[] command, int args)
{
	if (client > 0 && g_bAccess[client])
	{
		GetCmdArg(1, command, 3);
		ChangeClientTeam(client, StringToInt(command));
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
