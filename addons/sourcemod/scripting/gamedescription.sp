#pragma semicolon 1

// 头文件
#include <sourcemod>
#include <sdktools>
#include <SteamWorks>

public Plugin myinfo = 
{
	name 			= "Custom Game Description",
	author 			= "夜羽真白",
	description 	= "自定义显示游戏信息",
	version 		= "1.0.1.0",
	url 			= "https://steamcommunity.com/id/saku_ra/"
}

public void OnPluginStart()
{
	
}

public void OnGameFrame()
{
	SteamWorks_SetGameDescription("音理の快乐小屋");
}