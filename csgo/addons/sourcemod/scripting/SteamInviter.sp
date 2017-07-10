#pragma semicolon 1

#include <sourcemod>
#include <steamcore>

#define PLUGIN_URL "yash1441@yahoo.com"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_NAME "Steam Inviter"
#define PLUGIN_AUTHOR "Simon"

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = "Invites to Steam Group on connecting to server.",
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

Handle cvarGroupID = INVALID_HANDLE;
ReplySource sources[32];

public void OnPluginStart()
{
	CreateConVar("si_version", PLUGIN_VERSION, "Steam Inviter Version", FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	cvarGroupID = CreateConVar("si_steamgroupid", "", "Group id where people is going to be invited.", 0);
}

public void OnClientAuthorized(client)
{
	if (client > 0 && client < (MAXPLAYERS + 1))
	cmdInvite(client);
}

public cmdInvite(client)
{
	char steamGroup[65];
	GetConVarString(cvarGroupID, steamGroup, sizeof(steamGroup));
	if (StrEqual(steamGroup, "")) 
	{ 
		ReplyToCommand(client, "Steam group is not configured.");
		return;
	}

	int id = GetSteamAccountID(client);
	char steamID64[32];
	GetClientAuthId(client, AuthId_SteamID64, steamID64, sizeof steamID64);
	sources[client] = GetCmdReplySource();
	SteamGroupInvite(client, steamID64, steamGroup, callback);
	ReplyToCommand(client, "Invited %n to the Steam group.", id);
	
	return;				
}

public callback(client, bool success, errorCode, any data)
{
	if (client != 0 && !IsClientInGame(client)) return;
	
	SetCmdReplySource(sources[client]);
	if (success) ReplyToCommand(client, "The group invite has been sent.");
	else
	{
		switch(errorCode)
		{
			case 0x01:	ReplyToCommand(client, "Server is busy with another task at this time, try again in a few seconds.");
			case 0x02:	ReplyToCommand(client, "There was a timeout in your request, try again.");
			case 0x23:	ReplyToCommand(client, "Session expired, retry to reconnect.");
			case 0x27:	ReplyToCommand(client, "Target has already received an invite or is already on the group.");
			default:	ReplyToCommand(client, "There was an error \x010x%02x while sending your invite :(", errorCode);
		}
	}
}