#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS FCVAR_NOTIFY
#define PLUGIN_VERSION "1.0"

public Plugin myinfo = 
{
	name = "Admin Reserved Slot",
	author = "BloodyAngel",
	description = "Admin reserved slot",
	version = PLUGIN_VERSION,
	url = "http://bloodsiworld.ru"
}

ConVar ARSN, ARSKB;
bool bARSKB = false;
int iRS = 0, iMaxPlayers = 0;

public void OnPluginStart()
{
    CreateConVar("admin_reserved_slot_version", PLUGIN_VERSION, "Admin Reserved Slot plugin version", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
    (ARSN = CreateConVar("admin_reserved_slot_number",	"4", "The number of reserved slots.", CVAR_FLAGS, true,0.0, true, 32.0)).AddChangeHook(ConVarsChanged);
    (ARSKB = CreateConVar("admin_reserved_slot_punishment", "0", "0 = Kick, 1 = Ban.\n\"\" - all.", CVAR_FLAGS, true, 0.0, true, 1.0)).AddChangeHook(ConVarsChanged);

    AutoExecConfig(true, "AdminReservedSlots");
    LoadTranslations("reservedslots.phrases");
}

public void OnConfigsExecuted()
{
	ConVarsChanged(null, "", "");
}

void ConVarsChanged(ConVar convar, char[] oldValue, char[] newValue)
{
    iRS = ARSN.IntValue;
    bARSKB = ARSKB.BoolValue;
    iMaxPlayers = FindConVar("sv_maxplayers").IntValue;
}

public void OnClientPostAdminCheck(int iClient)
{
	if(!IsFakeClient(iClient))
	{
        int flags = GetUserFlagBits(iClient);
        if(GetClientCount() > (iMaxPlayers - iRS))
        {
            if(!(flags & ADMFLAG_ROOT || flags & ADMFLAG_RESERVATION) || !flags)
            {
                Punishment(iClient);
            }
        }
		else if (GetClientCount() > iMaxPlayers)
        {
            int iTarget = 0;
            iTarget = SelectKickClient(false);
            if (iTarget > 0)
            {
                Punishment(iClient);
            }
            else
            {
                iTarget = SelectKickClient(true);
                if (iTarget > 0)
                {
                    Punishment(iClient);
                }
            }
        }
	}
}

stock int SelectKickClient(bool bAllowAdmin)
{
    float highestValue, highestSpecValue, value;
    int highestValueId = 0, highestSpecValueId = 0, i = 1, iFlags = 0;
    bool specFound;
    while (i <= MaxClients)
    {
        if (IsClientConnected(i))
        {
            iFlags = GetUserFlagBits(i);
            if (!(iFlags & ADMFLAG_ROOT || iFlags & ADMFLAG_RESERVATION))
            {
                value = 0.0;
                if (IsClientInGame(i) && !IsFakeClient(i))
                {
                    value = GetClientAvgLatency(i, view_as<NetFlow>(0));
                    if (IsClientObserver(i))
                    {
                        specFound = true;
                        if (value > highestSpecValue)
                        {
                            highestSpecValue = value;
                            highestSpecValueId = i;
                        }
                    }
                }
                if (value >= highestValue)
                {
                    highestValue = value;
                    highestValueId = i;
                }
            }
            else if(bAllowAdmin)
            {
                if (IsClientInGame(i) && !IsFakeClient(i))
                {
                    if((iFlags & ADMFLAG_RESERVATION) && !(iFlags & ADMFLAG_ROOT))
                    {
                        highestSpecValueId = i;
                    }
                }
            }
            i++;
        }
        i++;
    }
    if (specFound)
    {
        return highestSpecValueId;
    }
    return highestValueId;
}

void Punishment(int iClient)
{
    if(bARSKB)
    {
        char m[100];
        FormatEx(m, 100, "%T", "Slot reserved", iClient);
        BanClient(iClient, 1, BANFLAG_AUTHID, "Admin Reserved Slot", m, "sm_addban");
    }
    else
    {
        KickClient(iClient, "%T", "Slot reserved", iClient);
    }
}
