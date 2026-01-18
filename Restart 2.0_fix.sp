#pragma semicolon 1
#pragma newdecls required

#define VERSION "2.0_fix"
#define CVAR_FLAGS FCVAR_NOTIFY|FCVAR_SPONLY

ConVar hRestartEnable, hRestartType;
bool bEnabled = false;
int iType = 0, iTime = 0;

public Plugin myinfo =
{
	name	= "Restart",
	author	= "Temlik & HolyHender",
	version	= VERSION
}

public void OnPluginStart()
{
	CreateConVar("restart_version", VERSION, "Restart plugin version", CVAR_FLAGS|FCVAR_DONTRECORD);
	hRestartEnable = CreateConVar("restart_enable", "1", "Enable/Disable plugin(0 = disable, 1 = enable)", CVAR_FLAGS);
	hRestartType = CreateConVar("restart_type", "0", "Type of restart method(0 = exit, 1 = quit, 2 = _restart)", CVAR_FLAGS);

	AutoExecConfig(true, "Restart");

	hRestartEnable.AddChangeHook(OnConVarsChanged);
	hRestartType.AddChangeHook(OnConVarsChanged);

	RegAdminCmd("sm_restart", Command_Restart, ADMFLAG_ROOT);
}

public void OnConfigsExecuted()
{
	OnConVarsChanged(null, "", "");
}

void OnConVarsChanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{
	bEnabled = hRestartEnable.BoolValue;
	iType = hRestartType.IntValue;
}

Action Command_Restart(int client, int args)
{
	if(bEnabled)
	{
		if(args < 1)
		{
			ReplyToCommand(client, "Usage: sm_restart <seconds>");
			return Plugin_Handled;
		}

		char val[8];
		GetCmdArg(1, val, sizeof(val));
		if((iTime = StringToInt(val)) > 0)
		{
			iTime += GetTime();
			CreateTimer(1.0, Timer_Restart, _, TIMER_REPEAT);
			Timer_Restart(null);
		}
		else
		{
			ReplyToCommand(client, "Value must be greater than zero.");
		}
	}
	return Plugin_Handled;
}

Action Timer_Restart(Handle timer)
{
	if(bEnabled)
	{
		int time = iTime - GetTime();
		if(time > 0)
		{
			PrintCenterTextAll("Рестарт через: %i сек.", time);
			return Plugin_Continue;
		}
		else
		{
			PrintCenterTextAll("Рестарт!");
			switch(iType)
			{
				case 0:
				{
					ServerCommand("exit");
				}
				case 1:
				{
					ServerCommand("quit");
				}
				case 2:
				{
					ServerCommand("_restart");
				}
			}
			return Plugin_Stop;
		}
	}
	else
	{
		return Plugin_Stop;
	}
}
