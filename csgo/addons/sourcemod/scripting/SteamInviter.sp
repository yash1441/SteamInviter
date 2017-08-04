#pragma semicolon 1

#include <sourcemod>
#include <steamcore>

#define PLUGIN_URL "yash1441@yahoo.com"
#define PLUGIN_VERSION "1.2"
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
		PrintToServer("Steam group is not configured.");
		return;
	}

	int id = GetSteamAccountID(client);
	char steamID64[32];
	if (GetClientAuthId(client, AuthId_SteamID64, steamID64, sizeof steamID64) == false)
	{
		PrintToServer("Can't get SteamID64 of %N.", client);
	}
	
	if(SteamAccountAddFriend(0, steamID64, callback2))
		PrintToServer("Added %N as friend.", id);
	else PrintToServer("Failed to add %N as friend.", id);
	
	sources[client] = GetCmdReplySource();
	
	if(SteamGroupInvite(0, steamID64, steamGroup, callback))
		PrintToServer("Invited %N to the Steam group.", id);
	else PrintToServer("Failed to invite %N to the Steam group.", id);
	
	return;				
}

public callback2(client, bool success, errorCode, any data)
{
	if (client != 0 && !IsClientInGame(client))
	{
		return;
	}
	if (success) PrintToServer("The friend invite has been sent.");
	else
	{
		PrintToServer("Error");
		switch(errorCode)
		{
			case 0x01:	PrintToServer("Server is busy with another task at this time, try again in a few seconds.");
			case 0x02:	PrintToServer("Session expired, retry to reconnect.");
			case 0x30:	PrintToServer("Failed http friend request.");
			case 0x31:	PrintToServer("Friend request not sent.");
			default:	PrintToServer("There was an error \x010x%02x while sending your friend request :(", errorCode);
		}
	}
}

public callback(client, bool success, errorCode, any data)
{
	if (client != 0 && !IsClientInGame(client))
	{
		return;
	}
	
	SetCmdReplySource(sources[client]);
	if (success) PrintToServer("The group invite has been sent.");
	else
	{
		PrintToServer("Error");
		switch(errorCode)
		{
			case 0x01:	PrintToServer("Server is busy with another task at this time, try again in a few seconds.");
			case 0x02:	PrintToServer("Session expired, retry to reconnect.");
			case 0x27:	PrintToServer("Target has already received an invite or is already on the group.");
			default:	PrintToServer("There was an error \x010x%02x while sending your invite :(", errorCode);
		}
	}
}
