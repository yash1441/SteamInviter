#pragma semicolon 1

#include <sourcemod>
#include <steamcore>
#include <sdkhooks>

#define PLUGIN_URL "yash1441@yahoo.com"
#define PLUGIN_VERSION "1.5"
#define PLUGIN_NAME "Steam Inviter"
#define PLUGIN_AUTHOR "Simon"

bool FirstSpawn[MAXPLAYERS + 1] =  { false, ... };
bool SecondSpawn[MAXPLAYERS + 1] =  { false, ... };

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = "Invites players to add as friend and add to group.",
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

ConVar cvarGroupID;
ConVar AddFriend;
ConVar AddGroup;
ReplySource sources[32];

public void OnPluginStart()
{
	CreateConVar("si_version", PLUGIN_VERSION, "Steam Inviter Version", FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	cvarGroupID = CreateConVar("si_steamgroupid", "", "Group id where people are going to be invited.", 0);
	AddFriend = CreateConVar("si_friend_enable", "1", "Enable or Disable add as friend feature.", 0, true, 0.0, true, 1.0);
	AddGroup = CreateConVar("si_group_enable", "1", "Enable or Disable invite to group feature.", 0, true, 0.0, true, 1.0);
	if(!HookEventEx("player_spawn", OnPlayerSpawn))
		LogError("Failed to hook player_spawn.");
}

public void OnClientPostAdminCheck(client)
{
	if (IsValidClient(client))
	{
		FirstSpawn[client] = true;
		SecondSpawn[client] = false;
	}
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(client)) return Plugin_Continue;
	if(IsSteamCoreBusy())
	{
		PrintToServer("Steam Core is busy, couldn't invite to group.");
		return Plugin_Continue;
	}
	if (FirstSpawn[client])
	{
		InviteFriend(client);
		return Plugin_Continue;
	}
	if (SecondSpawn[client])
	{
		InviteGroup(client);
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

public void InviteFriend(int client)
{
	char steamID64[32];
	if (GetClientAuthId(client, AuthId_SteamID64, steamID64, sizeof steamID64) == false)
	{
		PrintToServer("Can't get SteamID64 of %N.", client);
		return;
	}
	FirstSpawn[client] = false;
	SecondSpawn[client] = true;
	if (!GetConVarBool(AddFriend)) return;
	sources[client] = GetCmdReplySource();
	if (SteamAccountAddFriend(0, steamID64, AddFriendCallback))
		PrintToServer("Added %N as friend.", client);
	else PrintToServer("Failed to add %N as friend.", client);
}

public void InviteGroup(int client)
{
	char steamID64[32];
	if (GetClientAuthId(client, AuthId_SteamID64, steamID64, sizeof steamID64) == false)
	{
		PrintToServer("Can't get SteamID64 of %N.", client);
		return;
	}
	SecondSpawn[client] = false;
	if (!GetConVarBool(AddGroup)) return;
	char steamGroup[65];
	GetConVarString(cvarGroupID, steamGroup, sizeof(steamGroup));
	if (StrEqual(steamGroup, "")) 
	{ 
		PrintToServer("Steam group is not configured.");
		return;
	}
	sources[client] = GetCmdReplySource();
	if(SteamGroupInvite(0, steamID64, steamGroup, AddGroupCallback))
		PrintToServer("Invited %N to the Steam group.", client);
	else PrintToServer("Failed to invite %N to the Steam group.", client);
}

public AddFriendCallback(int client, bool success, int errorCode, any data)
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

public AddGroupCallback(int client, bool success, int errorCode, any data)
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

stock bool IsValidClient(int client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}