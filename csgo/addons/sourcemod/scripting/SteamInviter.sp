#pragma semicolon 1

#include <sourcemod>
#include <steamcore>
#include <sdkhooks>

#define PLUGIN_URL "yash1441@yahoo.com"
#define PLUGIN_VERSION "1.6"
#define PLUGIN_NAME "Steam Inviter"
#define PLUGIN_AUTHOR "Simon"

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = "Invites players to add as friend and invite to group.",
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

public int OnSteamAccountLoggedIn()
{
	PrintToServer("Steam account logged in successfully.");
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(client)) return Plugin_Continue;
	if (IsSteamAccountLogged())
	{
		InviteGroup(client);
	}
	return Plugin_Continue;
}

public void InviteGroup(int client)
{
	char steamID64[32];
	if (GetClientAuthId(client, AuthId_SteamID64, steamID64, sizeof steamID64) == false)
	{
		PrintToServer("Can't get SteamID64 of %N.", client);
		return;
	}
	if (!GetConVarBool(AddGroup)) return;
	char steamGroup[65];
	GetConVarString(cvarGroupID, steamGroup, sizeof(steamGroup));
	if (StrEqual(steamGroup, "")) 
	{ 
		PrintToServer("Steam group is not configured.");
		return;
	}
	sources[client] = GetCmdReplySource();
	if(SteamCommunityGroupInvite(steamID64, steamGroup, client))
		PrintToServer("Invited %N to the Steam group.", client);
	else PrintToServer("Failed to invite %N to the Steam group. Not logged in.", client);
}

public int OnCommunityGroupInviteResult(const char[] invitee, const char[] group, int errorCode, any client)
{
	SetCmdReplySource(sources[client]);
	switch(errorCode)
	{
		case 0x00:	PrintToServer("General: No error, request successful.");
		case 0x01:	PrintToServer("General: Logged out, plugin will attempt to login.");
		case 0x02:	PrintToServer("General: Connection timed out.");
		case 0x03:	PrintToServer("General: Steam servers down.");
		case 0x20:	PrintToServer("Invite Error: Failed http group invite request.");
		case 0x21:	PrintToServer("Invite Error: Incorrect invitee or another error.");
		case 0x22:	PrintToServer("Invite Error: Incorrect Group ID or missing data.");
		case 0x23:	PrintToServer("Invite Error: (LEGACY, no longer used)");
		case 0x24:	PrintToServer("Invite Error: SteamCore account is not a member of the group or does not have permissions to invite.");
		case 0x25:	PrintToServer("Invite Error: Limited account. Only full Steam accounts can send Steam group invites");
		case 0x26:	PrintToServer("Invite Error: Unkown error. Check https://github.com/polvora/SteamCore/issues/6");
		case 0x27:	PrintToServer("Invite Error: Invitee has already received an invite or is already on the group.");
		case 0x28:	{
			PrintToServer("Invite Error: Invitee must be friends with the SteamCore account to receive an invite.");
			InviteFriend(client);
		}
		default:	PrintToServer("There was an error \x010x%02x while sending your invite :(", errorCode);
	}
}

public void InviteFriend(int client)
{
	char steamID64[32];
	if (GetClientAuthId(client, AuthId_SteamID64, steamID64, sizeof steamID64) == false)
	{
		PrintToServer("Can't get SteamID64 of %N.", client);
		return;
	}
	if (!GetConVarBool(AddFriend)) return;
	sources[client] = GetCmdReplySource();
	if (SteamCommunityAddFriend(steamID64, client))
		PrintToServer("Added %N as friend.", client);
	else PrintToServer("Failed to add %N as friend. Not logged in.", client);
}

public int OnCommunityAddFriendResult(const char[] friend, errorCode, any client)
{
	SetCmdReplySource(sources[client]);
	switch(errorCode)
	{
		case 0x00:	PrintToServer("General: No error, request successful.");
		case 0x01:	PrintToServer("General: Logged out, plugin will attempt to login.");
		case 0x02:	PrintToServer("General: Connection timed out.");
		case 0x03:	PrintToServer("General: Steam servers down.");
		case 0x30:	PrintToServer("Friend Add Error: Failed http friend request.");
		case 0x31:	PrintToServer("Friend Add Error: Invited account ignored the friend request.");
		case 0x32:	PrintToServer("Friend Add Error: Invited account has blocked the SteamCore account.");
		case 0x33:	PrintToServer("Friend Add Error: SteamCore account is limited. Only full Steam accounts can send friend requests.");
		default:	PrintToServer("There was an error \x010x%02x while sending your friend request :(", errorCode);
	}
}

stock bool IsValidClient(int client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}