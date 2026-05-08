#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>
//#include <smlib>

#define PLUGIN_VERSION	"2025-07-21"			//版本

ConVar g_hCvarInfectedTime;
ConVar g_hCvarInfectedLimit;
ConVar g_hCvarTankBhop;
ConVar g_hCvarWeapon;
ConVar hCvarCoop;

int CommonLimit; 
int CommonTime; 
int TankBhop;
int Weapon; 
int MaxPlayers;

//String:sBuffer[256];

public OnPluginStart()
{
	g_hCvarInfectedTime = FindConVar("versus_special_respawn_interval");
	g_hCvarInfectedLimit = FindConVar("l4d_infected_limit");
	g_hCvarTankBhop = FindConVar("ai_Tank_Bhop");
	g_hCvarWeapon = CreateConVar("ZonemodWeapon", "0", "", 0, false, 0.0, false, 0.0);

	HookConVarChange(g_hCvarInfectedTime, Cvar_InfectedTime);
	HookConVarChange(g_hCvarInfectedLimit, Cvar_InfectedLimit);
	HookConVarChange(g_hCvarTankBhop, CvarTankBhop);
	HookConVarChange(g_hCvarWeapon, CvarWeapon);

	CommonTime = GetConVarInt(g_hCvarInfectedTime);
	CommonLimit = GetConVarInt(g_hCvarInfectedLimit);
	TankBhop = GetConVarInt(g_hCvarTankBhop);
	Weapon = GetConVarInt(g_hCvarWeapon);

	hCvarCoop = CreateConVar("coopmode", "0");

	RegConsoleCmd("sm_xx",InfectedStatus);
	RegConsoleCmd("sm_zs", ZiSha);
	RegConsoleCmd("sm_kill", ZiSha);

	HookEvent("player_incapacitated_start",Incap_Event);
	HookEvent("player_incapacitated",Incap_Event);
	HookEvent("round_start", event_RoundStart);
	HookEvent("player_death", player_death);
}

public Action:player_death(Event event, const char[] name, bool dontBroadcast)
{
	if(IsTeamImmobilised())
	{
		SetConVarString(FindConVar("mp_gamemode"), "realism");
	}
	return Plugin_Continue;
}

public Action:ZiSha(int client, int args)
{
	ForcePlayerSuicide(client);
	if(IsTeamImmobilised())
	{
		SetConVarString(FindConVar("mp_gamemode"), "realism");
	}
	return Plugin_Handled;
}

public Incap_Event(Event event, const char[] name, bool dontBroadcast)
{
	new Incap = GetClientOfUserId(GetEventInt(event, "userid"));
	// 开启死门
	if(bool:GetConVarBool(hCvarCoop))
	{
		ForcePlayerSuicide(Incap);
	}
	if(IsTeamImmobilised())
	{
		SetConVarString(FindConVar("mp_gamemode"), "realism");
	}
}

//离开安全门重新加载插件（理论上不应该在此插件完成）
public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
	ReloadPlugins();
	return Plugin_Continue;
}

public Cvar_InfectedTime(ConVar cvar, const char[] oldValue, const char[] newValue) 
{
	CommonTime = g_hCvarInfectedTime.IntValue;
	ReloadPlugins();
}

public Cvar_InfectedLimit(ConVar cvar, const char[] oldValue, const char[] newValue) 
{
	CommonLimit = g_hCvarInfectedLimit.IntValue;
}

public CvarTankBhop(ConVar cvar, const char[] oldValue, const char[] newValue) 
{
	TankBhop = g_hCvarTankBhop.IntValue;
}

public CvarWeapon(ConVar cvar, const char[] oldValue, const char[] newValue) 
{
	Weapon = g_hCvarWeapon.IntValue;
	switch (Weapon)
	{
		case 0: ServerCommand("exec vote/weapon/Annehappy.cfg");
		case 1: ServerCommand("exec vote/weapon/zonemod.cfg");
		case 2: ServerCommand("exec vote/weapon/Neri.cfg");
	}
}

public Action InfectedStatus(int Client, int args)
{ 
	//FormatTime(sBuffer, sizeof(sBuffer), "%Y/%m/%d");
	if(IsValidPlayer(Client, false))
	{
		if(TankBhop > 0)
		{
			if(Weapon == 0)
			{
				PrintToChatAll("\x03Tank连跳\x05[\x04开启\x05] \x03武器\x05[\x04Anne\x05] \x03特感\x05[\x04%i特%i秒\x05] \x03星空列车与白的旅行\x05[\x04%s\x05]",CommonLimit,CommonTime,PLUGIN_VERSION);
			}
			else if(Weapon == 1)
			{
				PrintToChatAll("\x03Tank连跳\x05[\x04开启\x05] \x03武器\x05[\x04Zone\x05] \x03特感\x05[\x04%i特%i秒\x05] \x03星空列车与白的旅行\x05[\x04%s\x05]",CommonLimit,CommonTime,PLUGIN_VERSION);
			}
			else if(Weapon == 2)
			{
				PrintToChatAll("\x03Tank连跳\x05[\x04开启\x05] \x03武器\x05[\x04Neri\x05] \x03特感\x05[\x04%i特%i秒\x05] \x03星空列车与白的旅行\x05[\x04%s\x05]",CommonLimit,CommonTime,PLUGIN_VERSION);
			}
		}
		else
		{
			if(Weapon == 0)
			{
				PrintToChatAll("\x03Tank连跳\x05[\x04关闭\x05] \x03武器\x05[\x04Anne\x05] \x03特感\x05[\x04%i特%i秒\x05] \x03星空列车与白的旅行\x05[\x04%s\x05]",CommonLimit,CommonTime,PLUGIN_VERSION);
			}
			else if(Weapon == 1)
			{
				PrintToChatAll("\x03Tank连跳\x05[\x04关闭\x05] \x03武器\x05[\x04Zone\x05] \x03特感\x05[\x04%i特%i秒\x05] \x03星空列车与白的旅行\x05[\x04%s\x05]",CommonLimit,CommonTime,PLUGIN_VERSION);
			}
			else if(Weapon == 2)
			{
				PrintToChatAll("\x03Tank连跳\x05[\x04关闭\x05] \x03武器\x05[\x04Neri\x05] \x03特感\x05[\x04%i特%i秒\x05] \x03星空列车与白的旅行\x05[\x04%s\x05]",CommonLimit,CommonTime,PLUGIN_VERSION);
			}
		}
	}
	if(GetConVarInt(FindConVar("ReturnBlood"))>0)
		PrintToChatAll("\x03回血\x05[\x04开启\x05]");
	return Plugin_Handled;
}

public event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	//FormatTime(sBuffer, sizeof(sBuffer), "%Y/%m/%d");
	if(TankBhop > 0)
	{
		if(Weapon == 0)
		{
			PrintToChatAll("\x03Tank连跳\x05[\x04开启\x05] \x03武器\x05[\x04Anne\x05] \x03特感\x05[\x04%i特%i秒\x05] \x03星空列车与白的旅行\x05[\x04%s\x05]",CommonLimit,CommonTime,PLUGIN_VERSION);
		}
		else if(Weapon == 1)
		{
			PrintToChatAll("\x03Tank连跳\x05[\x04开启\x05] \x03武器\x05[\x04Zone\x05] \x03特感\x05[\x04%i特%i秒\x05] \x03星空列车与白的旅行\x05[\x04%s\x05]",CommonLimit,CommonTime,PLUGIN_VERSION);
		}
		else if(Weapon == 2)
		{
			PrintToChatAll("\x03Tank连跳\x05[\x04开启\x05] \x03武器\x05[\x04Neri\x05] \x03特感\x05[\x04%i特%i秒\x05] \x03星空列车与白的旅行\x05[\x04%s\x05]",CommonLimit,CommonTime,PLUGIN_VERSION);
		}
	}
	else
	{
		if(Weapon == 0)
		{
			PrintToChatAll("\x03Tank连跳\x05[\x04关闭\x05] \x03武器\x05[\x04Anne\x05] \x03特感\x05[\x04%i特%i秒\x05] \x03星空列车与白的旅行\x05[\x04%s\x05]",CommonLimit,CommonTime,PLUGIN_VERSION);
		}
		else if(Weapon == 1)
		{
			PrintToChatAll("\x03Tank连跳\x05[\x04关闭\x05] \x03武器\x05[\x04Zone\x05] \x03特感\x05[\x04%i特%i秒\x05] \x03星空列车与白的旅行\x05[\x04%s\x05]",CommonLimit,CommonTime,PLUGIN_VERSION);
		}
		else if(Weapon == 2)
		{
			PrintToChatAll("\x03Tank连跳\x05[\x04关闭\x05] \x03武器\x05[\x04Neri\x05] \x03特感\x05[\x04%i特%i秒\x05] \x03星空列车与白的旅行\x05[\x04%s\x05]",CommonLimit,CommonTime,PLUGIN_VERSION);
		}
	}
	if(GetConVarInt(FindConVar("ReturnBlood"))>0)
		PrintToChatAll("\x03回血\x05[\x04开启\x05]");
}

public OnClientPutInServer(int Client)
{
	//FormatTime(sBuffer, sizeof(sBuffer), "%Y/%m/%d");
	if (IsValidPlayer(Client, false))
	{
		MaxPlayers ++ ;
		if(MaxPlayers >= 3)
		{
			L4D_LobbyUnreserve();
			ServerCommand("sm_cvar sv_allow_lobby_connect_only 0");
		}
		if(TankBhop > 0)
		{
			if(Weapon == 0)
			{
				PrintToChatAll("\x03Tank连跳\x05[\x04开启\x05] \x03武器\x05[\x04Anne\x05] \x03特感\x05[\x04%i特%i秒\x05] \x03星空列车与白的旅行\x05[\x04%s\x05]",CommonLimit,CommonTime,PLUGIN_VERSION);
			}
			else if(Weapon == 1)
			{
				PrintToChatAll("\x03Tank连跳\x05[\x04开启\x05] \x03武器\x05[\x04Zone\x05] \x03特感\x05[\x04%i特%i秒\x05] \x03星空列车与白的旅行\x05[\x04%s\x05]",CommonLimit,CommonTime,PLUGIN_VERSION);
			}
			else if(Weapon == 2)
			{
				PrintToChatAll("\x03Tank连跳\x05[\x04开启\x05] \x03武器\x05[\x04Neri\x05] \x03特感\x05[\x04%i特%i秒\x05] \x03星空列车与白的旅行\x05[\x04%s\x05]",CommonLimit,CommonTime,PLUGIN_VERSION);
			}
		}
		else
		{
			if(Weapon == 0)
			{
				PrintToChatAll("\x03Tank连跳\x05[\x04关闭\x05] \x03武器\x05[\x04Anne\x05] \x03特感\x05[\x04%i特%i秒\x05] \x03星空列车与白的旅行\x05[\x04%s\x05]",CommonLimit,CommonTime,PLUGIN_VERSION);
			}
			else if(Weapon == 1)
			{
				PrintToChatAll("\x03Tank连跳\x05[\x04关闭\x05] \x03武器\x05[\x04Zone\x05] \x03特感\x05[\x04%i特%i秒\x05] \x03星空列车与白的旅行\x05[\x04%s\x05]",CommonLimit,CommonTime,PLUGIN_VERSION);
			}
			else if(Weapon == 2)
			{
				PrintToChatAll("\x03Tank连跳\x05[\x04关闭\x05] \x03武器\x05[\x04Neri\x05] \x03特感\x05[\x04%i特%i秒\x05] \x03星空列车与白的旅行\x05[\x04%s\x05]",CommonLimit,CommonTime,PLUGIN_VERSION);
			}
		}
		if(GetConVarInt(FindConVar("ReturnBlood"))>0)
			PrintToChatAll("\x03回血\x05[\x04开启\x05]");
	}
}

stock bool:IsValidPlayer(int Client, bool AllowBot = true, bool AllowDeath = true)
{
	if (Client < 1 || Client > MaxClients)
		return false;
	if (!IsClientConnected(Client) || !IsClientInGame(Client))
		return false;
	if (!AllowBot)
	{
		if (IsFakeClient(Client))
			return false;
	}

	if (!AllowDeath)
	{
		if (!IsPlayerAlive(Client))
			return false;
	}	
	return true;
}

ReloadPlugins()
{
	ServerCommand("sm plugins load_unlock");
	ServerCommand("sm plugins reload optional/infected_control_77.smx");
	ServerCommand("sm plugins reload optional/infected_control_1128.smx");
	ServerCommand("sm plugins reload optional/Alone_sea.smx");
	ServerCommand("sm plugins load_lock");
	ServerCommand("sm_startspawn");

}

bool:IsTeamImmobilised() {
	//Check if there is still an upright survivor
	bool bIsTeamImmobilised = true;
	for (int client = 1; client < MaxClients; client++)
	{
		// If a survivor is found to be alive and neither pinned nor incapacitated
		// team is not immobilised.
		if (Survivor(client) && IsPlayerAlive(client) ) 
		{		
			if (!Incapacitated(client) ) 
			{		
				bIsTeamImmobilised = false;				
			} 
		}
	}
	return bIsTeamImmobilised;
}

bool Survivor(i)
{
    return i > 0 && i <= MaxClients && IsClientInGame(i) && GetClientTeam(i) == 2;
}

bool Incapacitated(client)
{
	bool bIsIncapped = false;
	if (Survivor(client))
	{
		if (GetEntProp(client, Prop_Send, "m_isIncapacitated") > 0) bIsIncapped = true;
		if (!IsPlayerAlive(client)) bIsIncapped = true;
	}
	return bIsIncapped;
}
