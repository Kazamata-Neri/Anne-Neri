#pragma semicolon 1
//強制1.7以後的新語法
#pragma newdecls required
#include <sourcemod>
#include <dhooks>
#define NAME_RoundRespawn "CTerrorPlayer::RoundRespawn"
#define SIG_RoundRespawn_LINUX "@_ZN13CTerrorPlayer12RoundRespawnEv"
#define SIG_RoundRespawn_WINDOWS "\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\xE8\\x2A\\x2A\\x2A\\x2A\\x84\\x2A\\x75\\x2A\\x8B\\x2A\\xE8\\x2A\\x2A\\x2A\\x2A\\xC6\\x86"

#define NAME_SetHumanSpectator "SurvivorBot::SetHumanSpectator"
#define SIG_SetHumanSpectator_LINUX "@_ZN11SurvivorBot17SetHumanSpectatorEP13CTerrorPlayer"
#define SIG_SetHumanSpectator_WINDOWS "\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x83\\xBE\\x2A\\x2A\\x2A\\x2A\\x2A\\x7E\\x2A\\x32\\x2A\\x5E\\x5D\\xC2\\x2A\\x2A\\x8B\\x0D"

#define NAME_SetObserverTarget "CTerrorPlayer::SetObserverTarget"
#define SIG_SetObserverTarget_LINUX "@_ZN11SurvivorBot17SetHumanSpectatorEP13CTerrorPlayer"
#define SIG_SetObserverTarget_WINDOWS "\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x83\\xBE\\x2A\\x2A\\x2A\\x2A\\x2A\\x7E\\x2A\\x32\\x2A\\x5E\\x5D\\xC2\\x2A\\x2A\\x8B\\x0D"

#define NAME_SetModel "CBasePlayer::SetModel"
#define SIG_SetModel_LINUX "@_ZN11CBasePlayer8SetModelEPKc"
#define SIG_SetModel_WINDOWS "\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x56\\x57\\x50\\x8B\\x2A\\xE8\\x2A\\x2A\\x2A\\x2A\\x8B\\x3D"

#define NAME_GoAwayFromKeyboard "CTerrorPlayer::GoAwayFromKeyboard"
#define SIG_GoAwayFromKeyboard_LINUX "@_ZN13CTerrorPlayer18GoAwayFromKeyboardEv"
#define SIG_GoAwayFromKeyboard_WINDOWS "\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x53\\x56\\x57\\x8B\\xF1\\x8B\\x06\\x8B\\x90\\xC8\\x08\\x00\\x00"

#define NAME_GiveDefaultItems "CTerrorPlayer::GiveDefaultItems"
#define SIG_GiveDefaultItems_LINUX "@_ZN13CTerrorPlayer16GiveDefaultItemsEv"
#define SIG_GiveDefaultItems_WINDOWS "\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x50\\xE8\\x2A\\x2A\\x2A\\x2A\\x83\\x2A\\x2A\\x84\\x2A\\x0F\\x84\\x2A\\x2A\\x2A\\x2A\\xA1\\x2A\\x2A\\x2A\\x2A\\x8B\\x88"

#define TEAM_SPECTATOR	1
#define TEAM_SURVIVOR	2
#define TEAM_INFECTED   3
#define TEAM_PASSING	4

#define PLUGIN_VERSION	"1.0"
#define CVAR_FLAGS		FCVAR_NOTIFY

ConVar g_hSLimit, g_hgive0, g_hgive1, g_hgive2, g_hgive3, g_hgive4, g_hgive5;
ConVar g_haway, g_hdaze, g_hkick, g_hsset, g_hmaxs, g_hLimit, g_hTeam, g_hSteam, g_hBanId;

int g_iSurvivorBot;
int hgive0, hgive1, hgive2, hgive3, hgive4, hgive5;
int hdaze, hLimit;

Handle g_TimerSpecCheck = null;

bool g_bShouldFixAFK = false, g_bShouldIgnore = false, g_aSteamIDsFinaleVehicleLeaving;

char g_Models[MAXPLAYERS+1][128];

Handle hRoundRespawn, hSetHumanSpec, hSetObserverTarget, hGoAwayFromKeyboard;

bool l4d2_button[MAXPLAYERS+1];

int VariableSurvivor[MAXPLAYERS+1], numPrinted[MAXPLAYERS+1];
Handle ClientTimer_Index[MAXPLAYERS+1], ClientTimerDaze[MAXPLAYERS+1], CheckAFKTimer[MAXPLAYERS+1];

float LastEyeAngles [MAXPLAYERS+1][3], CurrEyeAngles [MAXPLAYERS+1][3];

Address g_pStatsCondition;
StringMap g_aSteamIDs;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	char GameName[64];
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrContains(GameName, "left4dead", false) == -1)
		return APLRes_Failure; 
	
	return APLRes_Success; 
}

public void OnPluginStart()
{
	l4d2_multislots_LoadGameCFG();
	RegAdminCmd("sm_addbot", AddBot, ADMFLAG_ROOT);
	RegAdminCmd("sm_addbot2", AddBot2, ADMFLAG_ROOT);
	g_hSLimit		= FindConVar("survivor_limit");
	g_hgive0		= CreateConVar("l4d2_multislots_Survivor_spawn0",				"1",		"启用给予玩家武器和物品? 0=禁用, 1=启用.", CVAR_FLAGS);
	g_hgive1		= CreateConVar("l4d2_multislots_Survivor_spawn1",				"1",		"启用给予主武器? 0=禁用, 1=启用(随机获得:冲锋枪,消音冲锋枪)(开局时都没有主武器则不给).", CVAR_FLAGS);
	g_hgive2		= CreateConVar("l4d2_multislots_Survivor_spawn2",				"1",		"启用给予副武器? 1=随机获得副武器(小手枪,马格南,斧头, 2=斧头).", CVAR_FLAGS);
	g_hgive3		= CreateConVar("l4d2_multislots_Survivor_spawn3",				"0",		"启用给予投掷武器? 0=禁用, 1=启用(随机获得:胆汁罐,燃烧瓶,土制炸弹).", CVAR_FLAGS);
	g_hgive4		= CreateConVar("l4d2_multislots_Survivor_spawn4",				"0",		"启用给予医疗物品? 0=禁用, 1=启用(随机获得:电击器,医疗包).", CVAR_FLAGS);
	g_hgive5		= CreateConVar("l4d2_multislots_Survivor_spawn5",				"0",		"启用给予急救物品? 0=禁用, 1=启用(随机获得:止痛药,肾上腺素).", CVAR_FLAGS);
	g_haway		= CreateConVar("l4d2_multislots_enabled_away",				"0",		"启用指令 !away 强制加入旁观者? 0=禁用, 1=启用(公共), 2=启用(只限管理员).", CVAR_FLAGS);
	g_hdaze		= CreateConVar("l4d2_multislots_enabled_away_daze",			"0",		"设置幸存者在复活门被营救或被电击器救活后多少秒无操作自动闲置? 0=禁用.", CVAR_FLAGS);
	g_hkick		= CreateConVar("l4d2_multislots_enabled_kick",				"0",		"启用指令 !kb 踢出所有电脑幸存者?(包括闲置玩家的电脑幸存者) 0=禁用, 1=启用.", CVAR_FLAGS);
	g_hLimit		= FindConVar("survivor_limit");
	g_hsset		= CreateConVar("l4d2_multislots_enabled_Sv_Sset",				"0",		"启用指令 !sset 设置服务器人数? 0=禁用(不影响设置最大人数), 1=启用.", CVAR_FLAGS);
	g_hmaxs		= FindConVar("survivor_limit");
	g_hTeam		= CreateConVar("l4d2_multislots_enabled_player_Team",			"0",		"启用玩家转换队伍提示? 0=禁用 1=启用.", CVAR_FLAGS);
	g_hSteam		= CreateConVar("l4d2_multislots_enabled_player_steamID",		"0",	"设置玩家手动离开游戏后禁止重新加入的时间/秒. 0=禁用.", CVAR_FLAGS);
	g_hBanId		= CreateConVar("l4d2_multislots_enabled_player_steamID_Ban",	"0",		"自动封禁被踢出的玩家多长时间/分钟. 0=禁用.", CVAR_FLAGS);
	
	g_hSLimit.Flags &= ~FCVAR_NOTIFY; //移除ConVar变动提示
	g_hSLimit.SetBounds(ConVarBound_Upper, true, 31.0);
	
	g_hSLimit.AddChangeHook(l4d2OtherConVarChanged);
	g_hgive0.AddChangeHook(l4d2OtherConVarChanged);
	g_hgive1.AddChangeHook(l4d2OtherConVarChanged);
	g_hgive2.AddChangeHook(l4d2OtherConVarChanged);
	g_hgive3.AddChangeHook(l4d2OtherConVarChanged);
	g_hgive4.AddChangeHook(l4d2OtherConVarChanged);
	g_hgive5.AddChangeHook(l4d2OtherConVarChanged);

	g_haway.AddChangeHook(l4d2OtherConVarChanged);
	g_hdaze.AddChangeHook(l4d2OtherConVarChanged);
	g_hkick.AddChangeHook(l4d2OtherConVarChanged);
	g_hLimit.AddChangeHook(l4d2OtherConVarChanged);
	g_hsset.AddChangeHook(l4d2OtherConVarChanged);
	g_hmaxs.AddChangeHook(l4d2OtherConVarChanged);
	g_hTeam.AddChangeHook(l4d2OtherConVarChanged);
	g_hSteam.AddChangeHook(l4d2OtherConVarChanged);
	g_hBanId.AddChangeHook(l4d2OtherConVarChanged);
	g_aSteamIDs = new StringMap();
}

public void OnPluginEnd()
{
	vStatsConditionPatch(false);
}

public void OnConfigsExecuted()
{
	l4d2_multislots_LoadGameCFG();
}

/// 初始化
public void l4d2_multislots_LoadGameCFG()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/l4d2_multislots.txt");
	
	//判断是否有文件
	if (FileExists(sPath))
	{
		GameData hGameData = new GameData("l4d2_multislots");
		if(hGameData == null) 
			SetFailState("Failed to load gamedata/l4d2_multislots.txt");
			
		StartPrepSDKCall(SDKCall_Player);
		if(PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::RoundRespawn") == false)
			SetFailState("Failed to find signature: CTerrorPlayer::RoundRespawn");
		else
		{
			hRoundRespawn = EndPrepSDKCall();
			if(hRoundRespawn == null)
				SetFailState("Failed to create SDKCall: CTerrorPlayer::RoundRespawn");
		}
		
		vRegisterStatsConditionPatch(hGameData);
		
		StartPrepSDKCall(SDKCall_Player);
		if(PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "SurvivorBot::SetHumanSpectator") == false)
			SetFailState("Failed to find signature: SurvivorBot::SetHumanSpectator");
		else
		{
			PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
			hSetHumanSpec = EndPrepSDKCall();
			if(hSetHumanSpec == null)
				SetFailState("Failed to create SDKCall: SurvivorBot::SetHumanSpectator");
		}

		StartPrepSDKCall(SDKCall_Player);
		if(PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTerrorPlayer::SetObserverTarget") == false)
			SetFailState("Failed to find offset: CTerrorPlayer::SetObserverTarget");
		else
		{
			PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
			hSetObserverTarget = EndPrepSDKCall();
			if(hSetObserverTarget == null)
				SetFailState("Failed to create SDKCall: CTerrorPlayer::SetObserverTarget");
		}
		StartPrepSDKCall(SDKCall_Player);
		if(PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::GoAwayFromKeyboard") == false)
			SetFailState("Failed to find signature: CTerrorPlayer::GoAwayFromKeyboard");
		else
		{
			PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
			hGoAwayFromKeyboard = EndPrepSDKCall();
			if(hGoAwayFromKeyboard == null)
				SetFailState("Failed to create SDKCall: CTerrorPlayer::GoAwayFromKeyboard");
		}
		
		vSetupDetours(hGameData);
		
		delete hGameData;
	}
	else
	{
		File hFile = OpenFile(sPath, "w", false);
	
		hFile.WriteLine("\"Games\"");
		hFile.WriteLine("{");

		hFile.WriteLine("	\"left4dead2\"");
		hFile.WriteLine("	{");
		
		hFile.WriteLine("		\"Functions\"");
		hFile.WriteLine("		{");
		
		hFile.WriteLine("			\"SurvivorBot::SetHumanSpectator\"");
		hFile.WriteLine("			{");
		hFile.WriteLine("				\"signature\"	\"SurvivorBot::SetHumanSpectator\"");
		hFile.WriteLine("				\"callconv\"	\"thiscall\"");
		hFile.WriteLine("				\"return\"	\"void\"");
		hFile.WriteLine("				\"this\"	\"entity\"");
		hFile.WriteLine("				\"arguments\"");
		hFile.WriteLine("				{");
		hFile.WriteLine("					\"AFKPlayer\"");
		hFile.WriteLine("					{");
		hFile.WriteLine("						\"type\"	\"cbaseentity\"");
		hFile.WriteLine("					}");
		hFile.WriteLine("				}");
		hFile.WriteLine("			}");
		
		hFile.WriteLine("			\"CTerrorPlayer::GoAwayFromKeyboard\"");
		hFile.WriteLine("			{");
		hFile.WriteLine("				\"signature\"	\"CTerrorPlayer::GoAwayFromKeyboard\"");
		hFile.WriteLine("				\"callconv\"	\"thiscall\"");
		hFile.WriteLine("				\"return\"	\"void\"");
		hFile.WriteLine("				\"this\"	\"entity\"");
		hFile.WriteLine("			}");
		
		hFile.WriteLine("			\"CBasePlayer::SetModel\"");
		hFile.WriteLine("			{");
		hFile.WriteLine("				\"signature\"	\"CBasePlayer::SetModel\"");
		hFile.WriteLine("				\"callconv\"	\"thiscall\"");
		hFile.WriteLine("				\"return\"	\"void\"");
		hFile.WriteLine("				\"this\"	\"entity\"");
		hFile.WriteLine("				\"arguments\"");
		hFile.WriteLine("				{");
		hFile.WriteLine("					\"modelname\"");
		hFile.WriteLine("					{");
		hFile.WriteLine("						\"type\"	\"charptr\"");
		hFile.WriteLine("					}");
		hFile.WriteLine("				}");
		hFile.WriteLine("			}");
		
		hFile.WriteLine("			\"CTerrorPlayer::GiveDefaultItems\"");
		hFile.WriteLine("			{");
		hFile.WriteLine("				\"signature\"	\"CTerrorPlayer::GiveDefaultItems\"");
		hFile.WriteLine("				\"callconv\"	\"thiscall\"");
		hFile.WriteLine("				\"return\"	\"void\"");
		hFile.WriteLine("				\"this\"	\"entity\"");
		hFile.WriteLine("			}");
		
		hFile.WriteLine("		}");
		
		hFile.WriteLine("		\"Addresses\"");
		hFile.WriteLine("		{");
		
		hFile.WriteLine("			\"CTerrorPlayer::RoundRespawn\"");
		hFile.WriteLine("			{");
		hFile.WriteLine("				\"linux\"");
		hFile.WriteLine("				{");
		hFile.WriteLine("					\"signature\"	\"CTerrorPlayer::RoundRespawn\"");
		hFile.WriteLine("				}");
		hFile.WriteLine("				\"windows\"");
		hFile.WriteLine("				{");
		hFile.WriteLine("					\"signature\"	\"CTerrorPlayer::RoundRespawn\"");
		hFile.WriteLine("				}");
		hFile.WriteLine("			}");
		
		hFile.WriteLine("		}");
		
		hFile.WriteLine("		\"Offsets\"");
		hFile.WriteLine("		{");
		
		hFile.WriteLine("			\"CTerrorPlayer::SetObserverTarget\"");
		hFile.WriteLine("			{");
		hFile.WriteLine("				\"linux\"	\"403\"");
		hFile.WriteLine("				\"windows\"	\"402\"");
		hFile.WriteLine("			}");
		
		hFile.WriteLine("			\"RoundRespawn_Offset\"");
		hFile.WriteLine("			{");
		hFile.WriteLine("				\"linux\"	\"25\"");
		hFile.WriteLine("				\"windows\"	\"15\"");
		hFile.WriteLine("			}");
		
		hFile.WriteLine("			\"RoundRespawn_Byte\"");
		hFile.WriteLine("			{");
		hFile.WriteLine("				\"linux\"	\"117\"");
		hFile.WriteLine("				\"windows\"	\"117\"");
		hFile.WriteLine("			}");
		
		hFile.WriteLine("		}");
		
		hFile.WriteLine("		\"Signatures\"");
		hFile.WriteLine("		{");
		
		hFile.WriteLine("			\"%s\"", NAME_RoundRespawn);
		hFile.WriteLine("			{");
		hFile.WriteLine("				\"library\"	\"server\"");
		hFile.WriteLine("				\"linux\"	\"%s\"", SIG_RoundRespawn_LINUX);
		hFile.WriteLine("				\"windows\"	\"%s\"", SIG_RoundRespawn_WINDOWS);
		hFile.WriteLine("			}");
		
		hFile.WriteLine("			\"%s\"", NAME_SetHumanSpectator);
		hFile.WriteLine("			{");
		hFile.WriteLine("				\"library\"	\"server\"");
		hFile.WriteLine("				\"linux\"	\"%s\"", SIG_SetHumanSpectator_LINUX);
		hFile.WriteLine("				\"windows\"	\"%s\"", SIG_SetObserverTarget_WINDOWS);
		hFile.WriteLine("			}");
		
		hFile.WriteLine("			\"%s\"", NAME_SetModel);
		hFile.WriteLine("			{");
		hFile.WriteLine("				\"library\"	\"server\"");
		hFile.WriteLine("				\"linux\"	\"%s\"", SIG_SetModel_LINUX);
		hFile.WriteLine("				\"windows\"	\"%s\"", SIG_SetModel_WINDOWS);
		hFile.WriteLine("			}");
		
		hFile.WriteLine("			\"%s\"", NAME_GoAwayFromKeyboard);
		hFile.WriteLine("			{");
		hFile.WriteLine("				\"library\"	\"server\"");
		hFile.WriteLine("				\"linux\"	\"%s\"", SIG_GoAwayFromKeyboard_LINUX);
		hFile.WriteLine("				\"windows\"	\"%s\"", SIG_GoAwayFromKeyboard_WINDOWS);
		hFile.WriteLine("			}");
		
		hFile.WriteLine("			\"%s\"", NAME_GiveDefaultItems);
		hFile.WriteLine("			{");
		hFile.WriteLine("				\"library\"	\"server\"");
		hFile.WriteLine("				\"linux\"	\"%s\"", SIG_GiveDefaultItems_LINUX);
		hFile.WriteLine("				\"windows\"	\"%s\"", SIG_GiveDefaultItems_WINDOWS);
		hFile.WriteLine("			}");
		
		hFile.WriteLine("		}");
		
		hFile.WriteLine("	}");
		hFile.WriteLine("}");
		
		FlushFile(hFile);
		delete hFile;
	}
}

void vRegisterStatsConditionPatch(GameData hGameData = null)
{
	int iOffset = hGameData.GetOffset("RoundRespawn_Offset");
	if(iOffset == -1)
		SetFailState("Failed to find offset: RoundRespawn_Offset");

	int iByteMatch = hGameData.GetOffset("RoundRespawn_Byte");
	if(iByteMatch == -1)
		SetFailState("Failed to find byte: RoundRespawn_Byte");

	g_pStatsCondition = hGameData.GetAddress("CTerrorPlayer::RoundRespawn");
	if(!g_pStatsCondition)
		SetFailState("Failed to find address: CTerrorPlayer::RoundRespawn");
	
	g_pStatsCondition += view_as<Address>(iOffset);
	
	int iByteOrigin = LoadFromAddress(g_pStatsCondition, NumberType_Int8);
	if(iByteOrigin != iByteMatch)
		SetFailState("Failed to load 'CTerrorPlayer::RoundRespawn', byte mis-match @ %d (0x%02X != 0x%02X)", iOffset, iByteOrigin, iByteMatch);
}

void vRoundRespawn(int client)
{
	vStatsConditionPatch(true);
	SDKCall(hRoundRespawn, client);
	vStatsConditionPatch(false);
}

void vStatsConditionPatch(bool bPatch)
{
	static bool bPatched;
	if(!bPatched && bPatch)
	{
		bPatched = true;
		StoreToAddress(g_pStatsCondition, 0x79, NumberType_Int8);
	}
	else if(bPatched && !bPatch)
	{
		bPatched = false;
		StoreToAddress(g_pStatsCondition, 0x75, NumberType_Int8);
	}
}

void vSetupDetours(GameData hGameData = null)
{
	DynamicDetour dDetour = DynamicDetour.FromConf(hGameData, "SurvivorBot::SetHumanSpectator");
	if(dDetour == null)
		SetFailState("Failed to find signature: SurvivorBot::SetHumanSpectator");
		
	if(!dDetour.Enable(Hook_Pre, OnSetHumanSpectatorPre))
		SetFailState("Failed to detour pre: SurvivorBot::SetHumanSpectator");

	dDetour = DynamicDetour.FromConf(hGameData, "CTerrorPlayer::GoAwayFromKeyboard");
	if(dDetour == null)
		SetFailState("Failed to find signature: CTerrorPlayer::GoAwayFromKeyboard");

	dDetour = DynamicDetour.FromConf(hGameData, "CBasePlayer::SetModel");
	if(dDetour == null)
		SetFailState("Failed to find signature: CBasePlayer::SetModel");
		
	if(!dDetour.Enable(Hook_Pre, mrePlayerSetModelPre))
		SetFailState("Failed to detour pre: CBasePlayer::SetModel");
		
	if(!dDetour.Enable(Hook_Post, mrePlayerSetModelPost))
		SetFailState("Failed to detour post: CBasePlayer::SetModel");
		
	dDetour = DynamicDetour.FromConf(hGameData, "CTerrorPlayer::GiveDefaultItems");
	if(dDetour == null)
		SetFailState("Failed to find signature: CTerrorPlayer::GiveDefaultItems");
		
	if(!dDetour.Enable(Hook_Post, mreGiveDefaultItemsPost))
		SetFailState("Failed to detour post: CTerrorPlayer::GiveDefaultItems");
}

public void OnMapStart()
{
	l4d2GetOtherCvars();
	//清除储存的全部玩家SteamID.
	if(g_aSteamIDsFinaleVehicleLeaving)
	{
		g_aSteamIDs.Clear();
		g_aSteamIDsFinaleVehicleLeaving = false;
	}
	
	SetConVarInt(FindConVar("sv_consistency"), 0);//关闭模型一致性检查? (普通战役服必备参数,建议保持关闭)   0=关闭  1=开启.
	SetConVarInt(FindConVar("z_spawn_flow_limit"), 50000);
	
	//修复女巫模型没预载而引起的游戏闪退,必备.
	if (!IsModelPrecached("models/infected/witch.mdl")) 				PrecacheModel("models/infected/witch.mdl", false);
	if (!IsModelPrecached("models/infected/witch_bride.mdl")) 			PrecacheModel("models/infected/witch_bride.mdl", false);
	
	//修复幸存者模型没预载而引起的游戏闪退,必备.
	if (!IsModelPrecached("models/survivors/survivor_teenangst.mdl"))	PrecacheModel("models/survivors/survivor_teenangst.mdl", false);
	if (!IsModelPrecached("models/survivors/survivor_biker.mdl"))		PrecacheModel("models/survivors/survivor_biker.mdl", false);
	if (!IsModelPrecached("models/survivors/survivor_manager.mdl"))	PrecacheModel("models/survivors/survivor_manager.mdl", false);
	if (!IsModelPrecached("models/survivors/survivor_namvet.mdl"))		PrecacheModel("models/survivors/survivor_namvet.mdl", false);
	if (!IsModelPrecached("models/survivors/survivor_gambler.mdl"))	PrecacheModel("models/survivors/survivor_gambler.mdl", false);
	if (!IsModelPrecached("models/survivors/survivor_coach.mdl"))		PrecacheModel("models/survivors/survivor_coach.mdl", false);
	if (!IsModelPrecached("models/survivors/survivor_mechanic.mdl"))	PrecacheModel("models/survivors/survivor_mechanic.mdl", false);
	if (!IsModelPrecached("models/survivors/survivor_producer.mdl"))	PrecacheModel("models/survivors/survivor_producer.mdl", false);
}

//地图结束.
public void OnMapEnd()
{
	StopTimers();
	l4d2_killtimer();
}

public void l4d2OtherConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	int a = StringToInt(newValue);
	int b = StringToInt(oldValue);
	if(a < b)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR)
			{
				vRemovePlayerWeapons(i);
				KickClient(i, "[提示] 指令踢出所有电脑幸存者");
			}
		}
	}
	l4d2GetOtherCvars();
}

void l4d2GetOtherCvars()
{
	g_hSLimit = FindConVar("survivor_limit");
	hgive0 = g_hgive0.IntValue;
	hgive1 = g_hgive1.IntValue;
	hgive2 = g_hgive2.IntValue;
	hgive3 = g_hgive3.IntValue;
	hgive4 = g_hgive4.IntValue;
	hgive5 = g_hgive5.IntValue;
	hdaze	= g_hdaze.IntValue;
	g_hSLimit.IntValue = hLimit = g_hLimit.IntValue;
	
}

public Action AddBot(int client, int args)
{
	CreateTimer(1.5, Timer_SpawnBot,_, TIMER_FLAG_NO_MAPCHANGE);
}
public Action AddBot2(int client, int args)
{
	CreateTimer(1.5, Timer_SpawnBot,_, TIMER_FLAG_NO_MAPCHANGE);
}
public Action Timer_SpawnBot(Handle timer, any client)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (TotalSurvivors() < hLimit)
		{
			vSpawnFakeSurvivorClient();
		}
	}
}
void l4d2_killtimer()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		delete CheckAFKTimer[i];
		delete ClientTimerDaze[i];
		delete ClientTimer_Index[i];
	}
}


//检测玩家是不是在发呆或按下某些按键.
public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if(!IsValidClientRunCmd(client))
		return Plugin_Continue;
		
	if(vel[0] != 0 || vel[1] != 0 || vel[2] != 0)
		l4d2_button[client] = false;
	else
	{
		if(buttons & IN_ATTACK || buttons & IN_JUMP || buttons & IN_DUCK 
		|| buttons & IN_USE || buttons & IN_ATTACK2 || buttons & IN_SCORE 
		|| buttons & IN_SPEED || buttons & IN_ZOOM || buttons & IN_RELOAD)
		{
			l4d2_button[client] = false;
			if(numPrinted[client] > 0)
				numPrinted[client] = 0;
			return Plugin_Continue;
		}
		l4d2_button[client] = true;
	}
	return Plugin_Continue;
}

bool IsValidClientRunCmd(int client)
{
	return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
}
public Action ClientSurvivorDaze(Handle timer, any client)
{
	if((client = GetClientOfUserId(client)))
	{
		if (!IsClientInGame(client))
			return Plugin_Continue;
		
		if (GetClientTeam(client) != 2 || !IsPlayerAlive(client))
		{
			VariableSurvivor[client] = 0;
			ClientTimerDaze[client] = null;
			return Plugin_Stop;
		}
		if (GetClientTeam(client) == 2)
		{
			VariableSurvivor[client]++;
			
			if (GazeMovement(client) && l4d2_button[client])
			{
				if (VariableSurvivor[client] >= hdaze) 
				{
					SDKCall(hGoAwayFromKeyboard, client);
					VariableSurvivor[client] = 0;
					ClientTimerDaze[client] = null;
					return Plugin_Stop;
				}
			}
			else
			{
				if (VariableSurvivor[client] == 1)
					return Plugin_Continue;
				
				VariableSurvivor[client] = 0;
				ClientTimerDaze[client] = null;
				return Plugin_Stop;
			}
		}
	}
	return Plugin_Continue;
}

//只是检测幸存者视线移动.
bool GazeMovement(int client)
{
	GetClientEyeAngles(client, CurrEyeAngles[client]);
	if (LastEyeAngles[client][0] == CurrEyeAngles[client][0] && LastEyeAngles[client][1] == CurrEyeAngles[client][1] && LastEyeAngles[client][2] == CurrEyeAngles[client][2])
	{
		return true;
	}
	else
	{
		LastEyeAngles[client] = CurrEyeAngles[client];
		return false;
	}
}

//给予玩家武器或物品.
public MRESReturn mreGiveDefaultItemsPost(int pThis)
{
	if(!hgive0)
		return MRES_Ignored;

	if(!IsClientInGame(pThis) || GetClientTeam(pThis) != TEAM_SURVIVOR || !IsPlayerAlive(pThis))
		return MRES_Ignored;

	vGiveDefaultItems(pThis);
	return MRES_Ignored;
}

void vGiveDefaultItems(int client)
{
	vRemovePlayerWeapons(client);

	if(!hgive0)
		BypassAndExecuteCommand(client, "give", "pistol");//给予一把小手枪.
	else if(vGiveWeaponCount())//当前没有任何幸存者有主武器.
	{
		switch(hgive2)
		{
			case 1:
				l4d2_GiveWeapon_pistol_2(client);
			case 2:
				BypassAndExecuteCommand(client, "give", "fireaxe");//斧头.
		}
	}
	else
		vGivePresetPrimary(client);
}

bool vGiveWeaponCount()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClientGive(i))
		{
			int weapon = GetPlayerWeaponSlot(i, 0);
			
			if(weapon > 0)
				return false;
		}
	}
	return true;
}

bool IsValidClientGive(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

void vGivePresetPrimary(int client)
{
	switch(hgive2)
	{
		case 1:
			l4d2_GiveWeapon_pistol_2(client);
		case 2:
			BypassAndExecuteCommand(client, "give", "fireaxe");//斧头.
	}
	switch(hgive3)
	{
		case 1:
			l4d2_GiveWeapon_pistol_3(client);
	}
	switch(hgive4)
	{
		case 1:
			l4d2_GiveWeapon_pistol_4(client);
	}
	switch(hgive5)
	{
		case 1:
			l4d2_GiveWeapon_pistol_5(client);
	}
	switch(hgive1)
	{
		case 1:
			l4d2_GiveWeapon_pistol_1(client);
	}
}
void StopTimers()
{
	delete g_TimerSpecCheck;
}

void BypassAndExecuteCommand(int client, char[] strCommand, char[] strParam1)
{
	int flags = GetCommandFlags(strCommand);
	SetCommandFlags(strCommand, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", strCommand, strParam1);
	SetCommandFlags(strCommand, flags);
}

int TotalSurvivors()
{
	int intt = 0;
	for (int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && (GetClientTeam(i) == TEAM_SURVIVOR))
				intt++;
	return intt;
}

bool vSpawnFakeSurvivorClient()
{
	int client = CreateFakeClient("FakeClient");
	if(client == 0)
		return;

	ChangeClientTeam(client, TEAM_SURVIVOR);

	if(DispatchKeyValue(client, "classname", "SurvivorBot") == false)
		return;

	if(DispatchSpawn(client) == false)
		return;

	//如果创建的电脑幸存者是死亡的则复活.
	if(!IsAlive(client))
		vRoundRespawn(client);
		
	if(hgive0 != 0 && hgive0 == 1)
	{
		vRemovePlayerWeapons(client);
		vGiveDefaultItems(client);
	}
	
	//创建电脑幸存者后传送.
	TeleportClient(client);
	KickClient(client, "[提示] 自动踢出电脑.");
}

//随机传送新加入的幸存者到其他幸存者身边.
void TeleportClient(int client)
{
	int iTarget = GetTeleportTarget(client);
	
	if(iTarget != -1)
	{
		//传送时强制蹲下防止卡住.
		ForceCrouch(client);
		
		float vPos[3];
		GetClientAbsOrigin(iTarget, vPos);
		TeleportEntity(client, vPos, NULL_VECTOR, NULL_VECTOR);
	}
}

int GetTeleportTarget(int client)
{
	int iNormal, iIncap, iHanging;
	int[] iNormalSurvivors = new int[MaxClients];
	int[] iIncapSurvivors = new int[MaxClients];
	int[] iHangingSurvivors = new int[MaxClients];
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(i != client && IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsAlive(i))
		{
			if(GetEntProp(i, Prop_Send, "m_isIncapacitated") > 0)
			{
				if(GetEntProp(i, Prop_Send, "m_isHangingFromLedge") > 0)
					iHangingSurvivors[iHanging++] = i;
				else
					iIncapSurvivors[iIncap++] = i;
			}
			else
				iNormalSurvivors[iNormal++] = i;
		}
	}
	return (iNormal == 0) ? (iIncap == 0 ? (iHanging == 0 ? -1 : iHangingSurvivors[GetRandomInt(0, iHanging - 1)]) : iIncapSurvivors[GetRandomInt(0, iIncap - 1)]) :iNormalSurvivors[GetRandomInt(0, iNormal - 1)];
}

void ForceCrouch(int client)
{
	SetEntProp(client, Prop_Send, "m_bDucked", 1);
	SetEntProp(client, Prop_Send, "m_fFlags", GetEntProp(client, Prop_Send, "m_fFlags") | FL_DUCKING);
}

//排除死亡的
bool IsAlive(int client)
{
	if(!GetEntProp(client, Prop_Send, "m_lifeState"))
		return true;
	return false;
}

void l4d2_GiveWeapon_pistol_2(int client)
{
	switch(GetRandomInt(0,2))
	{
		case 0:
			BypassAndExecuteCommand(client, "give", "fireaxe");//斧头.
		case 1:
			BypassAndExecuteCommand(client, "give", "pistol");//小手枪
		case 2:
			BypassAndExecuteCommand(client, "give", "pistol_magnum");//马格南
	}
}

void l4d2_GiveWeapon_pistol_3(int client)
{
	switch(GetRandomInt(0,2))
	{
		case 0:
			BypassAndExecuteCommand(client, "give", "pipe_bomb");//土制炸弹
		case 1:
			BypassAndExecuteCommand(client, "give", "molotov ");//燃烧瓶
		case 2:
			BypassAndExecuteCommand(client, "give", "vomitjar");//胆汁
	}
}

void l4d2_GiveWeapon_pistol_4(int client)
{
	switch(GetRandomInt(0,1))
	{
		case 0:
			BypassAndExecuteCommand(client, "give", "first_aid_kit");//医疗包
		case 1:
			BypassAndExecuteCommand(client, "give", "defibrillator");//电击器
	}
}

void l4d2_GiveWeapon_pistol_5(int client)
{
	switch(GetRandomInt(0,1))
	{
		case 0:
			BypassAndExecuteCommand(client, "give", "adrenaline");//肾上腺素
		case 1:
			BypassAndExecuteCommand(client, "give", "pain_pills");//止痛药
	}
}

void l4d2_GiveWeapon_pistol_1(int client)
{
	switch(GetRandomInt(0,1))
	{
		case 0:
			BypassAndExecuteCommand(client, "give", "smg");//冲锋枪
		case 1:
			BypassAndExecuteCommand(client, "give", "smg_silenced");//消声器冲锋枪
	}	
}

void vRemovePlayerWeapons(int client)
{
	int iWeapon;
	for(int i; i < 5; i++)
	{
		iWeapon = GetPlayerWeaponSlot(client, i);
		if(iWeapon > MaxClients && IsValidEntity(iWeapon))
		{
			if(RemovePlayerItem(client, iWeapon))
				RemoveEdict(iWeapon);
		}
	}
}
//幸存者身份修复.
// 1.7
//[L4D1/2] Survivor Identity Fix for 5+ Survivors
//https://forums.alliedmods.net/showthread.php?p=2403731#post2403731
// ------------------------------------------------------------------------
//  Stores the client of each survivor each time it is changed
//  Needed because when Event_PlayerToBot fires, it's hunter model instead
// ------------------------------------------------------------------------
public MRESReturn mrePlayerSetModelPre(int pThis, DHookParam hParams)
{ } // We need this pre hook even though it's empty, or else the post hook will crash the game.

public MRESReturn mrePlayerSetModelPost(int pThis, DHookParam hParams)
{
	if(pThis < 1 || pThis > MaxClients || !IsClientInGame(pThis))
		return MRES_Ignored;
		
	if(GetClientTeam(pThis) != TEAM_SURVIVOR)
	{
		g_Models[pThis][0] = '\0';
		return MRES_Ignored;
	}
	
	char model[128];
	hParams.GetString(1, model, sizeof(model));
	if (StrContains(model, "survivors", false) >= 0)
		strcopy(g_Models[pThis], 128, model);
	
	return MRES_Ignored;
}


//Only thing we need is the bot single threaded logic means we use the call order
public void OnEntityCreated(int entity, const char[] classname)
{
	if(!g_bShouldFixAFK)
		return;
	
	if(classname[0] != 's' || !StrEqual(classname, "survivor_bot", false))
		return;
	
	g_iSurvivorBot = entity;
}

public MRESReturn OnSetHumanSpectatorPre(int pThis, Handle hParams)
{
	if(g_bShouldIgnore)
		return MRES_Ignored;
	
	if(!g_bShouldFixAFK)
		return MRES_Ignored;
	
	if(g_iSurvivorBot < 1)
		return MRES_Ignored;
	
	return MRES_Supercede;
}