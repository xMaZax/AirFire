#pragma semicolon 0
#include sourcemod
#pragma newdecls required

#define PLUGIN_VERSION 	"1.1"

public Plugin myinfo =
{
	name		= "[CS:GO] Clients AirFire",
	author		= "wAries",
	description	= "...",
	version		= PLUGIN_VERSION,
	url			= "whyaries.ru"
};

#define HookCvar(%0,%1) %0(FindConVar(%1), NULL_STRING, NULL_STRING)

int g_Flags;

char szWeapons[1024];

char g_Cvars[][] =
{
    "dd_flag", "dd_weapons", "dd_style"
};

enum dStyle
{
    dNs = 0,
    dDD
};

dStyle dCur;

bool iPermission[MAXPLAYERS+1];

ConVar cvNs;

public void OnPluginStart()
{
    HookEvent("weapon_fire", OnFireClient);

    CreateConVar(g_Cvars[0], "z", "Permission flag").AddChangeHook(OnFlagChanged);
    CreateConVar(g_Cvars[1], "weapon_awp;weapon_ssg08", "Weapons name per ';'").AddChangeHook(OnWeaponsChanged);
    CreateConVar(g_Cvars[2], "0", "Style: 0 - airFire & dd \n1 - Only dropdown", _, true, 0.0, true, 1.0).AddChangeHook(OnStyleChanged);

    AutoExecConfig(true, "airFire");

    cvNs = FindConVar("weapon_accuracy_nospread");
    cvNs.Flags &= ~FCVAR_REPLICATED;
}

public void OnFlagChanged(ConVar cv, const char[] oldV, const char[] newV)
{
    char szFlag[4];
    cv.GetString(szFlag, sizeof(szFlag));
    
    g_Flags = (szFlag[0]) ? ReadFlagString(szFlag) : 0;
}

public void OnWeaponsChanged(ConVar cv, const char[] oldV, const char[] newV)
{
    cv.GetString(szWeapons, sizeof(szWeapons));
}

public void OnStyleChanged(ConVar cv, const char[] oldV, const char[] newV)
{
    dCur = view_as<dStyle>(cv.IntValue);
}

public void OnMapStart()
{
    HookCvar(OnFlagChanged, g_Cvars[0]);
    HookCvar(OnWeaponsChanged, g_Cvars[1]);
    HookCvar(OnStyleChanged, g_Cvars[2]);

    cvNs.BoolValue = false;
}

public void OnClientPutInServer(int iClient)
{
    iPermission[iClient] = false;
}

public void OnClientPostAdminCheck(int iClient)
{
    if(IsFakeClient(iClient) || IsClientSourceTV(iClient))
        return;
    
    int iFlags = GetUserFlagBits(iClient);
    if(g_Flags != 0 && !(iFlags & g_Flags))
        return;
    
    iPermission[iClient] = true;
}

bool rePlicated[MAXPLAYERS+1];

public void OnFireClient(Event ev, const char[] szName, bool IsSilent)
{
    int iClient = GetClientOfUserId(ev.GetInt("userid"));
    if(!iClient || iClient > MaxClients || !iPermission[iClient] || !rePlicated[iClient])
        return;
    
    cvNs.BoolValue = true;
    RequestFrame(OnFired, !true); 
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int& cmdnum, int &tickcount, int &seed, int mouse[2])
{
    if(!client || IsFakeClient(client) || !iPermission[client])
        return Plugin_Continue;

    static char szWeapon[32];
    GetClientWeapon(client, szWeapon, sizeof(szWeapon));

    if(StrContains(szWeapons, szWeapon) == -1 || GetEntityFlags(client) & FL_ONGROUND || (dCur == dDD && GetSpeed(client) > 50.0))
    {
        if(rePlicated[client])
            ChangeValue(client, "0");

        rePlicated[client] = false;
        return Plugin_Continue;
    }

    ChangeValue(client, "1");
    rePlicated[client] = true;

    return Plugin_Continue;
}

void ChangeValue(int iClient, const char[] sTatus)
{
    cvNs.ReplicateToClient(iClient, sTatus);
}

public void OnFired(any data)
{
    cvNs.BoolValue = data;
}

float GetSpeed(int client)
{
	float vel[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vel);
	return SquareRoot(vel[0] * vel[0] + vel[1] * vel[1]);
}