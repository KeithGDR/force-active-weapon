#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_DESCRIPTION "Force clients to use an active weapon either via commands or console variables."
#define PLUGIN_VERSION "1.0.1"

#include <sourcemod>
#include <sdktools>

ConVar cvar_Status;
ConVar cvar_ForceSlot;

int iForceWeapon[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "Force Active Weapon", 
	author = "Keith Warren (Shaders Allen)", 
	description = PLUGIN_DESCRIPTION, 
	version = PLUGIN_VERSION, 
	url = "http://www.shadersallen.com/"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	CreateConVar("sm_forceactiveweapon_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_SPONLY | FCVAR_DONTRECORD);
	cvar_Status = CreateConVar("sm_forceactiveweapon_status", "1", "Status of the plugin.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvar_ForceSlot = CreateConVar("sm_forceactiveweapon_forceslot", "0", "Slot to force all clients to use.\n0 = primary, 1 = secondary, 2 = melee, etc", FCVAR_NOTIFY, true, 0.0, true, 6.0);

	AutoExecConfig();
	
	RegAdminCmd("sm_forceactiveweapon", Command_ForceActiveWeapon, ADMFLAG_SLAY, "Set a clients active weapon.");
}

public Action Command_ForceActiveWeapon(int client, int args)
{
	if (!GetConVarBool(cvar_Status))
	{
		return Plugin_Handled;
	}

	if (args < 2)
	{
		char sCommand[32];
		GetCmdArg(0, sCommand, sizeof(sCommand));

		ReplyToCommand(client, "[SM] Usage: %s <target> <slot> (0 = primary, 1 = secondary, 2 = melee, etc)", sCommand);
		return Plugin_Handled;
	}

	char sTarget[64];
	GetCmdArg(1, sTarget, sizeof(sTarget));

	char sSlot[12];
	GetCmdArg(2, sSlot, sizeof(sSlot));
	int iSlot = StringToInt(sSlot);

	char sTargetName[MAX_TARGET_LENGTH];
	int iTargetList[MAXPLAYERS];
	bool tn_is_ml;

	int iTargetCount = ProcessTargetString(sTarget, client, iTargetList, sizeof(iTargetList), COMMAND_FILTER_ALIVE, sTargetName, sizeof(sTargetName), tn_is_ml);

	if (iTargetCount <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	for (int i = 0; i < iTargetCount; i++)
	{
		ForcePlayerActiveSlot(iTargetList[i], iSlot);
	}
	
	return Plugin_Handled;
}

void ForcePlayerActiveSlot(int client, int slot = 0, int admin = 0)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return;
	}
	
	if (slot < 0 || slot > 6)
	{
		slot = 0;
	}
	
	iForceWeapon[client] = slot;
	
	LogAction(admin, client, "\"%L\" forced active weapon slot of \"%L\" to %i.", admin, client, slot);
	ShowActivity(admin, "forced active weapon slot of %N to %i", client, slot);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (IsPlayerAlive(client) && iForceWeapon[client] > 0)
	{
		int setactive = GetPlayerWeaponSlot(client, iForceWeapon[client] - 1);
		
		if (IsValidEntity(setactive))
		{
			weapon = setactive;
			//Don't have to return plugin changed here, not sure why.
		}
	}
}

public void OnClientPutInServer(int client)
{
	iForceWeapon[client] = GetConVarInt(cvar_ForceSlot);
}

public void OnClientDisconnect(int client)
{
	iForceWeapon[client] = GetConVarInt(cvar_ForceSlot);
}