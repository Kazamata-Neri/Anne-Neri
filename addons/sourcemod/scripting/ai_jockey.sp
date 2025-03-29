#pragma semicolon 1
#pragma newdecls required

// 头文件
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include "treeutil\treeutil.sp"

#define CVAR_FLAG FCVAR_NOTIFY
#define BACK_JUMP_DIST 70.0
#define FREEZE_MAX_TIME 0.5
#define SHOVE_INTERVAL 1.0
#define DEBUG_ALL 0

enum AimType
{
	AimEye,
	AimBody,
	AimChest
};
enum
{
	ACTION_FROZEN,
	ACTION_JUMP_BACK,
	ACTION_JUMP_HIGH,
	ACTION_COUNT
};

public Plugin myinfo = 
{
	name 			= "Ai_Jockey 2.0 版本",
	author 			= "Breezy，High Cookie，Standalone，Newteee，cravenge，Harry，Sorallll，PaimonQwQ，夜羽真白",
	description 	= "觉得Ai猴子太弱了？ Try this！",
	version 		= "2022/12/16",
	url 			= "https://steamcommunity.com/id/saku_ra/"
}

// ConVars
ConVar g_hBhopSpeed, g_hStartHopDistance, g_hJockeyStumbleRadius,
		g_hSpecialJumpRange, g_hSpecialJumpAngle, g_hSpecialJumpChance, g_hActionChance, g_hAllowInterControl, g_hBackVision;
// Ints
int g_iState[MAXPLAYERS + 1][8], g_iActionArray[ACTION_COUNT];
// Float
float g_fShovedTime[MAXPLAYERS + 1] = {0.0}, g_fNoActionTime[MAXPLAYERS + 1][2], g_fPlayerShovedTime[MAXPLAYERS + 1] = {0.0};
// Bools
bool
	g_bHasBeenShoved[MAXPLAYERS + 1],
	g_bCanAttackPinned[MAXPLAYERS + 1] = { false },
	g_bCanBackVision[MAXPLAYERS + 1] = { false };
// StringMap
StringMap interControlMap = null;

public void OnPluginStart()
{
	g_hBhopSpeed = CreateConVar("ai_JockeyBhopSpeed", "80.0", "Jockey 连跳的速度", CVAR_FLAG, true, 0.0);
	g_hStartHopDistance = CreateConVar("ai_JockeyStartHopDistance", "99999", "Jockey 距离生还者多少距离开始主动连跳", CVAR_FLAG, true, 0.0);
	g_hJockeyStumbleRadius = CreateConVar("ai_JockeyStumbleRadius", "50", "Jockey 骑到人后会对多少范围内的生还者产生硬直效果", CVAR_FLAG, true, 0.0);
	// 骗推设置
	g_hSpecialJumpRange = CreateConVar("ai_JockeySpecialJumpRange", "250", "Jockey 距离生还者多少距离开始骗推", CVAR_FLAG, true, 0.0);
	g_hSpecialJumpAngle = CreateConVar("ai_JockeySpecialJumpAngle", "60", "当目标正在看着 Jockey 并与其处于这个角度之内，Jockey 会尝试骗推", CVAR_FLAG, true, 0.0, true, 180.0);
	g_hSpecialJumpChance = CreateConVar("ai_JockeySpecialJumpChance", "50", "Jockey 有多少概率执行骗推", CVAR_FLAG, true, 0.0, true, 100.0);
	g_hActionChance = CreateConVar("ai_jockeyNoActionChance", "80,0,20", "Jockey 执行以下行为的概率（冻结行动 [时间 0 - FREEZE_MAX_TIME 秒随机]，向后跳，高跳）逗号分割", CVAR_FLAG, true, 0.0, true, 100.0);
	g_hAllowInterControl = CreateConVar("ai_JockeyAllowInterControl", "0", "Jockey 优先找被这些特感控制的生还者，抢控或补控（不想要这个功能可以设置为 0）", CVAR_FLAG);
	g_hBackVision = CreateConVar("ai_JockeyBackVision", "0", "Jockey 在空中时将会以这个概率向当前视角反方向看", CVAR_FLAG, true, 0.0, true, 100.0);
	// HookEvent
	HookEvent("player_spawn", evt_PlayerSpawn, EventHookMode_Pre);
	HookEvent("player_shoved", evt_PlayerShoved, EventHookMode_Pre);
	HookEvent("player_jump", evt_PlayerJump, EventHookMode_Pre);
	HookEvent("jockey_ride", evt_JockeyRide);
	// AddChangeHook
	g_hActionChance.AddChangeHook(GetActionPercent_Cvars);
	g_hAllowInterControl.AddChangeHook(GetInterControl_Cvars);
	// GetActionPercent
	getActionPercent();
	// BuildStringMap
	interControlMap = new StringMap();
	// GetInterControlInfected
	getInterControlInfected();
}
public void OnPluginEnd()
{
	delete interControlMap;
}

void GetActionPercent_Cvars(ConVar convar, const char[] oldValue, const char[] newValue) { getActionPercent(); }
void GetInterControl_Cvars(ConVar convar, const char[] oldValue, const char[] newValue) { getInterControlInfected(); }

public Action OnPlayerRunCmd(int jockey, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (!IsAiJockey(jockey) || !IsPlayerAlive(jockey)) { return Plugin_Continue; }
	float fSpeed[3] = {0.0}, fCurrentSpeed = 0.0, fJockeyPos[3] = {0.0};
	GetEntPropVector(jockey, Prop_Data, "m_vecVelocity", fSpeed);
	fCurrentSpeed = SquareRoot(Pow(fSpeed[0], 2.0) + Pow(fSpeed[1], 2.0));
	GetClientAbsOrigin(jockey, fJockeyPos);
	// 获取jockey状态
	int iFlags = GetEntityFlags(jockey), iTarget = g_bCanAttackPinned[jockey] ? GetClientAimTarget(jockey, true) : GetClosetMobileSurvivor(jockey);
	bool bHasSight = view_as<bool>(GetEntProp(jockey, Prop_Send, "m_hasVisibleThreats"));
	// 在梯子上，禁止跳与蹲
	if (GetEntityMoveType(jockey) & MOVETYPE_LADDER)
	{
		buttons &= ~IN_JUMP;
		buttons &= ~IN_DUCK;
		return Plugin_Changed;
	}
	if (!IsValidSurvivor(iTarget) || !IsPlayerAlive(iTarget) || g_bHasBeenShoved[jockey]) { return Plugin_Continue; }
	// 当前 Jockey 有效，目标有效，进行其他操作
	float fTargetPos[3] = {0.0}, fDistance = NearestSurvivorDistance(jockey);
	GetClientAbsOrigin(iTarget, fTargetPos);
	// 当前速度不大于 130.0 或距离大于 StartHopDistance，不进行操作
	if (fCurrentSpeed <= 130.0 || fDistance > g_hStartHopDistance.FloatValue) { return Plugin_Continue; }
	if (iFlags & FL_ONGROUND)
	{
		if (g_bCanBackVision[jockey]) { g_bCanBackVision[jockey] = false; }
		// Jockey 距离目标的距离小于 g_hSpecialJumpRange.FloatValue
		if (bHasSight && fDistance <= g_hSpecialJumpRange.FloatValue)
		{
			// 如果目标没有正在看着 Jockey，则直接骑乘
			if (!IsTargetWatchingAttacker(jockey, iTarget, g_hSpecialJumpAngle.IntValue))
			{
				#if DEBUG_ALL
					PrintToConsoleAll("[Ai-Jockey]：目标没有看着生还者，直接进行攻击");
				#endif
				buttons |= IN_ATTACK;
				SetState(jockey, 0, IN_ATTACK);
				return Plugin_Changed;
			}
			// 如果目标正在看着 Jockey 而且正在两次推之间，直接骑乘
			if (GetGameTime() - g_fPlayerShovedTime[iTarget] < SHOVE_INTERVAL)
			{
				#if DEBUG_ALL
					PrintToConsoleAll("[Ai-Jockey]：目标：%N 正在推的 cd 内，直接进行攻击", iTarget);
				#endif
				buttons |= IN_ATTACK;
				float subtractVec[3] = {0.0}, eyeAngleVec[3] = {0.0};
				SubtractVectors(fTargetPos, fJockeyPos, subtractVec);
				NormalizeVector(subtractVec, subtractVec);
				GetVectorAngles(subtractVec, eyeAngleVec);
				ScaleVector(subtractVec, g_hBhopSpeed.FloatValue * 2.5);
				TeleportEntity(jockey, NULL_VECTOR, eyeAngleVec, subtractVec);
				SetState(jockey, 0, IN_ATTACK);
				return Plugin_Changed;
			}
			// 如果目标正在看着 Jockey 没有在两次推之间，尝试骗推
			if (getRandomIntInRange(0, 100) <= g_hSpecialJumpChance.IntValue && fDistance >= BACK_JUMP_DIST && (GetState(jockey, 0) & IN_JUMP))
			{
				int actionPercent = getRandomIntInRange(0, 100);
				// 概率冻结 Jockey，Jockey 解冻后仍然在地上，无需设置状态为 IN_ATTACK，进行其他操作
				if (actionPercent <= g_iActionArray[ACTION_FROZEN]
					&& g_fNoActionTime[jockey][0] == 0.0)
				{
					g_fNoActionTime[jockey][0] = GetGameTime();
					g_fNoActionTime[jockey][1] = getRandomFloatInRange(0.0, FREEZE_MAX_TIME);
					SetEntityMoveType(jockey, MOVETYPE_NONE);
					CreateTimer(g_fNoActionTime[jockey][1], setMoveTypeToCustomHandler, jockey);
					#if DEBUG_ALL
						PrintToConsoleAll("[Ai-Jockey]：目前概率：%d，冻结 Jockey：%.2f 秒，时间戳：%.2f", actionPercent, g_fNoActionTime[jockey][1], GetGameTime());
					#endif
				}
				else if (actionPercent > g_iActionArray[ACTION_FROZEN] 
					&& actionPercent <= g_iActionArray[ACTION_JUMP_BACK]
					&& (fDistance > 0.0 && fDistance <= g_hSpecialJumpRange.FloatValue))
				{
					// 距离大于 BACK_JUMP_DIST 且小于 250，Jockey 向后跳
					float subtractVec[3] = {0.0};
					SubtractVectors(fTargetPos, fJockeyPos, subtractVec);
					NegateVector(subtractVec);
					NormalizeVector(subtractVec, subtractVec);
					ScaleVector(subtractVec, g_hBhopSpeed.FloatValue * 2.5);
					buttons |= IN_JUMP;
					TeleportEntity(jockey, NULL_VECTOR, NULL_VECTOR, subtractVec);
					SetState(jockey, 0, IN_ATTACK);
					#if DEBUG_ALL
						PrintToConsoleAll("[Ai-Jockey]：目前概率：%d，Jockey 向后跳", actionPercent);
					#endif
				}
				else if (actionPercent > g_iActionArray[ACTION_JUMP_BACK] 
					&& actionPercent <= g_iActionArray[ACTION_JUMP_HIGH])
				{
					// 高跳
					angles[0] = getRandomFloatInRange(45.0, 60.0) * -1.0;
					TeleportEntity(jockey, NULL_VECTOR, angles, NULL_VECTOR);
					buttons |= IN_ATTACK;
					SetState(jockey, 0, IN_ATTACK);
					#if DEBUG_ALL
						PrintToConsoleAll("[Ai-Jockey]：目前概率：%d，Jockey 高跳，角度：%.2f", actionPercent, angles[0]);
					#endif
				}
				return Plugin_Changed;
			}
		}
		else
		{
			if (/*!g_bCanAttackPinned[jockey] && */Do_Bhop(jockey, buttons))
			{
				SetState(jockey, 0, IN_JUMP);
				return Plugin_Changed;
			}
		}
	}
	else
	{
		buttons &= ~IN_JUMP;
		buttons &= ~IN_ATTACK;
		if (GetState(jockey, 0) & IN_ATTACK && g_hBackVision.IntValue > 0 && getRandomIntInRange(0, 100) <= g_hBackVision.IntValue)
		{
			#if DEBUG_ALL
				PrintToConsoleAll("[Ai-Jockey]：获取到的概率在 g_hBackVision 之内，jockey 在空中允许向后看");
			#endif
			g_bCanBackVision[jockey] = true;
			SetState(jockey, 0, IN_JUMP);
		}
		else if (GetState(jockey, 0) & IN_ATTACK) { SetState(jockey, 0, IN_JUMP); }
		// 距离 <= 2 * g_hSpecialJumpRange.FloatValue 时，概率跳的时候向后看
		if (fDistance <= g_hSpecialJumpRange.FloatValue * 2.0 && g_bCanBackVision[jockey])
		{
			float subtractVec[3] = {0.0}, eyeAngleVec[3] = {0.0};
			SubtractVectors(fTargetPos, fJockeyPos, subtractVec);
			NegateVector(subtractVec);
			NormalizeVector(subtractVec, subtractVec);
			GetVectorAngles(subtractVec, eyeAngleVec);
			TeleportEntity(jockey, NULL_VECTOR, eyeAngleVec, NULL_VECTOR);
		}
	}
	return Plugin_Continue;
}

public Action L4D2_OnChooseVictim(int specialInfected, int &curTarget)
{
	if (!IsAiJockey(specialInfected) || !IsPlayerAlive(specialInfected)) { return Plugin_Continue; }
	char interControlName[32] = {'\0'};
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && IsClientPinned(i))
		{
			IntToString(GetClientPinnedInfectedType(i), interControlName, sizeof(interControlName));
			if (!interControlMap.ContainsKey(interControlName)) { continue; }
			curTarget = i;
			g_bCanAttackPinned[specialInfected] = true;
			return Plugin_Changed;
		}
	}
	g_bCanAttackPinned[specialInfected] = false;
	return Plugin_Continue;
}

public void L4D_OnSwingStart(int client, int weapon)
{
	if (!IsValidSurvivor(client) || !IsPlayerAlive(client)) { return; }
	g_fPlayerShovedTime[client] = GetGameTime();
}

// ***************
//		Stuff
// ***************
public Action setMoveTypeToCustomHandler(Handle timer, int client)
{
	if (!IsAiJockey(client)) { return Plugin_Continue; }
	SetEntityMoveType(client, MOVETYPE_CUSTOM);
	g_fNoActionTime[client][0] = g_fNoActionTime[client][1] = 0.0;
	#if DEBUG_ALL
		PrintToConsoleAll("[Ai-Jockey]：解冻 Jockey，时间戳：%.2f", GetGameTime());
	#endif
	return Plugin_Continue;
}

public Action evt_PlayerShoved(Event event, const char[] name, bool dontBroadcast)
{
	int iShovedPlayer = GetClientOfUserId(event.GetInt("userid"));
	if (IsAiJockey(iShovedPlayer))
	{
		g_bHasBeenShoved[iShovedPlayer] = true;
		g_fShovedTime[iShovedPlayer] = GetGameTime();
	}
	return Plugin_Continue;
}

public void evt_PlayerJump(Event event, const char[] name, bool dontBroadcast)
{
	int iJumpingPlayer = GetClientOfUserId(event.GetInt("userid"));
	if (IsAiJockey(iJumpingPlayer)) { g_bHasBeenShoved[iJumpingPlayer] = false; }
}

public Action evt_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int iSpawnPlayer = GetClientOfUserId(event.GetInt("userid"));
	if (!IsAiJockey(iSpawnPlayer)) { return Plugin_Continue; }
	g_bHasBeenShoved[iSpawnPlayer] = g_bCanAttackPinned[iSpawnPlayer] = g_bCanBackVision[iSpawnPlayer] = false;
	g_fShovedTime[iSpawnPlayer] = g_fNoActionTime[iSpawnPlayer][0] = g_fNoActionTime[iSpawnPlayer][1] = 0.0;
	SetState(iSpawnPlayer, 0, IN_JUMP);
	return Plugin_Continue;
}

public void evt_JockeyRide(Event event, const char[] name, bool dontBroadcast)
{
	if (IsCoop)
	{
		int attacker = GetClientOfUserId(event.GetInt("userid"));
		int victim = GetClientOfUserId(event.GetInt("victim"));
		if (attacker > 0 && victim > 0)
		{
			StumbleByStanders(victim, attacker);
		}
	}
}

bool IsCoop()
{
	static char sGameMode[16];
	sGameMode[0] = 0;
	FindConVar("mp_gamemode").GetString(sGameMode, sizeof(sGameMode));
	return strcmp(sGameMode, "versus", false) != 0 && strcmp(sGameMode, "scavenge", false) != 0;
}

void StumbleByStanders(int pinnedSurvivor, int pinner) 
{
	static float pinnedSurvivorPos[3], pos[3], dir[3];
	GetClientAbsOrigin(pinnedSurvivor, pinnedSurvivorPos);
	for(int i = 1; i <= MaxClients; i++) 
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			if(i != pinnedSurvivor && i != pinner && !IsClientPinned(i)) 
			{
				GetClientAbsOrigin(i, pos);
				SubtractVectors(pos, pinnedSurvivorPos, dir);
				if(GetVectorLength(dir) <= g_hJockeyStumbleRadius.FloatValue) 
				{
					NormalizeVector(dir, dir); 
					L4D_StaggerPlayer(i, pinnedSurvivor, dir);
				}
			}
		} 
	}
}

// ***** 方法 *****
bool IsAiJockey(int client)
{
	return GetInfectedClass(client) == ZC_JOCKEY /* && IsFakeClient(client) */;
}

float NearestSurvivorDistance(int client)
{
	int closestSurvivor = GetClosetMobileSurvivor(client);
	if (IsValidSurvivor(closestSurvivor))
	{
		float selfPos[3] = {0.0}, targetPos[3] = {0.0};
		GetClientAbsOrigin(client, selfPos);
		GetClientAbsOrigin(closestSurvivor, targetPos);
		return GetVectorDistance(selfPos, targetPos);
	}
	return -1.0;
}

bool IsTargetWatchingAttacker(int attacker, int target, int offset)
{
	if (GetClientTeam(attacker) == TEAM_INFECTED && IsPlayerAlive(attacker))
	{
		if (IsValidSurvivor(target) && !IsClientPinned(target))
		{
			int iOffset = RoundToNearest(GetPlayerAimOffset(target, attacker));
			return iOffset <= offset;
		}
	}
	return false;
}

float GetPlayerAimOffset(int attacker, int target)
{
	if (IsClientConnected(attacker) && IsClientInGame(attacker) && IsPlayerAlive(attacker) && IsClientInGame(target) && IsPlayerAlive(target))
	{
		float fAttackerPos[3], fTargetPos[3], fAimVector[3], fDirectVector[3], fResultAngle;
		GetClientEyeAngles(attacker, fAimVector);
		fAimVector[0] = fAimVector[2] = 0.0;
		GetAngleVectors(fAimVector, fAimVector, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(fAimVector, fAimVector);
		// 获取目标位置
		GetClientAbsOrigin(target, fTargetPos);
		GetClientAbsOrigin(attacker, fAttackerPos);
		fAttackerPos[2] = fTargetPos[2] = 0.0;
		MakeVectorFromPoints(fAttackerPos, fTargetPos, fDirectVector);
		NormalizeVector(fDirectVector, fDirectVector);
		// 计算角度
		fResultAngle = RadToDeg(ArcCosine(GetVectorDotProduct(fAimVector, fDirectVector)));
		return fResultAngle;
	}
	return -1.0;
}

void SetState(int client, int no, int value)
{
	g_iState[client][no] = value;
}

int GetState(int client, int no)
{
	return g_iState[client][no];
}

/*float[] UpdatePosition(int jockey, int target, float fForce)
{
	float fBuffer[3] = {0.0}, fTankPos[3] = {0.0}, fTargetPos[3] = {0.0};
	GetClientAbsOrigin(jockey, fTankPos);
	GetClientAbsOrigin(target, fTargetPos);
	SubtractVectors(fTargetPos, fTankPos, fBuffer);
	NormalizeVector(fBuffer, fBuffer);
	ScaleVector(fBuffer, fForce);
	fBuffer[2] = 0.0;
	return fBuffer;
}*/

// 方法，是否是 AI 猴
bool IsJockey(int client)
{
	return view_as<bool>(GetInfectedClass(client) == view_as<int>(ZC_JOCKEY) && IsFakeClient(client));
}

bool Do_Bhop(int client, int &buttons)
{
	if (!IsJockey(client) || !IsPlayerAlive(client))
		return false;

	float vAng[3], vRight[3], vVel[3];
	GetClientEyeAngles(client, vAng);
	GetAngleVectors(vAng, vAng, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(vAng, vAng);
	CopyVectors(vAng, vRight);

	if (buttons & IN_FORWARD || buttons & IN_BACK) {
		ScaleVector(vAng, (buttons & IN_FORWARD == IN_FORWARD) ? g_hBhopSpeed.FloatValue : -g_hBhopSpeed.FloatValue);
	}
	if (buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT) {
		ScaleVector(vRight, (buttons & IN_MOVELEFT == IN_MOVELEFT) ? g_hBhopSpeed.FloatValue : -g_hBhopSpeed.FloatValue);
	}

	AddVectors(vAng, vRight, vAng);
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vVel);
	AddVectors(vVel, vAng, vVel);

	if (!bWontFall(client, vVel))
		return false;

	buttons |= IN_DUCK;
	buttons |= IN_JUMP;
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel);
	return true;
}

bool bWontFall(int client, const float vVel[3]) {
	static float vPos[3];
	static float vEnd[3];
	GetClientAbsOrigin(client, vPos);
	AddVectors(vPos, vVel, vEnd);

	static float vMins[3];
	static float vMaxs[3];
	GetClientMins(client, vMins);
	GetClientMaxs(client, vMaxs);

	static bool bDidHit;
	static Handle hTrace;
	static float vVec[3];
	static float vNor[3];
	static float vPlane[3];

	bDidHit = false;
	vPos[2] += 10.0;
	vEnd[2] += 10.0;
	hTrace = TR_TraceHullFilterEx(vPos, vEnd, vMins, vMaxs, MASK_PLAYERSOLID_BRUSHONLY, bTraceEntityFilter);
	if (TR_DidHit(hTrace)) {
		bDidHit = true;
		TR_GetEndPosition(vVec, hTrace);
		NormalizeVector(vVel, vNor);
		TR_GetPlaneNormal(hTrace, vPlane);
		if (RadToDeg(ArcCosine(GetVectorDotProduct(vNor, vPlane))) > 150.0) {
			delete hTrace;
			return false;
		}
	}

	delete hTrace;
	if (!bDidHit)
		vVec = vEnd;

	static float vDown[3];
	vDown[0] = vVec[0];
	vDown[1] = vVec[1];
	vDown[2] = vVec[2] - 100000.0;

	hTrace = TR_TraceHullFilterEx(vVec, vDown, vMins, vMaxs, MASK_PLAYERSOLID_BRUSHONLY, bTraceEntityFilter);
	if (TR_DidHit(hTrace)) {
		TR_GetEndPosition(vEnd, hTrace);
		if (vVec[2] - vEnd[2] > 128.0) {
			delete hTrace;
			return false;
		}

		static int iEnt;
		if ((iEnt = TR_GetEntityIndex(hTrace)) > MaxClients) {
			static char cls[13];
			GetEdictClassname(iEnt, cls, sizeof cls);
			if (strcmp(cls, "trigger_hurt") == 0) {
				delete hTrace;
				return false;
			}
		}
		delete hTrace;
		return true;
	}

	delete hTrace;
	return false;
}

bool bTraceEntityFilter(int entity, int contentsMask) {
	if (entity <= MaxClients)
		return false;

	static char cls[9];
	GetEntityClassname(entity, cls, sizeof cls);
	if ((cls[0] == 'i' && strcmp(cls[1], "nfected") == 0) || (cls[0] == 'w' && strcmp(cls[1], "itch") == 0))
		return false;

	return true;
}

/*bool jockeyDoBhop(int client, int &buttons, float vec[3])
{
	if (buttons & IN_FORWARD || buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT)
	{
		ClientPush(client, vec);
		return true;
	}
	return false;
}*/

/*void ClientPush(int client, float fForwardVec[3])
{
	float fCurVelVec[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", fCurVelVec);
	AddVectors(fCurVelVec, fForwardVec, fCurVelVec);
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fCurVelVec);
}*/

int getRandomIntInRange(int min, int max)
{
	return (GetURandomInt() % (max - min + 1)) + min;
}
float getRandomFloatInRange(float min, float max)
{
	return GetURandomFloat() * (max - min) + min;
}
void getActionPercent()
{
	int total = 0;
	char cvarString[64] = {'\0'}, actionArray[ACTION_COUNT][4];
	g_hActionChance.GetString(cvarString, sizeof(cvarString));
	ExplodeString(cvarString, ",", actionArray, 4, 4);
	for (int i = 0; i < ACTION_COUNT; i++)
	{
		g_iActionArray[i] = total + StringToInt(actionArray[i]);
		total += StringToInt(actionArray[i]);
	}
}
void getInterControlInfected()
{
	if (interControlMap != null) { interControlMap.Clear(); }
	char cvarString[64] = {'\0'}, interControlArray[ZC_CHARGER][4];
	g_hAllowInterControl.GetString(cvarString, sizeof(cvarString));
	ExplodeString(cvarString, ",", interControlArray, ZC_CHARGER, 4);
	for (int i = 0; i < ZC_CHARGER; i++)
	{
		if (!(strcmp(interControlArray[i], NULL_STRING) == 0)) { interControlMap.SetString(interControlArray[i][0], ""); }
	}
}