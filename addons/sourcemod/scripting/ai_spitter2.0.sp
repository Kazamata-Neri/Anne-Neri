#pragma semicolon 1
#pragma newdecls required

// 头文件
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include "treeutil\treeutil.sp"

#define CVAR_FLAG FCVAR_NOTIFY
#define SPITTER_JUMP_DELAY 1.0
#define CHECK_PINNED_TIME 1.0
#define SPITTER_KILL_DELAY 10.0

// Velocity
enum VelocityOverride {
	VelocityOvr_None = 0,
	VelocityOvr_Velocity,
	VelocityOvr_OnlyWhenNegative,
	VelocityOvr_InvertReuseVelocity
};

public Plugin myinfo = 
{
	name 			= "Ai-Spitter-Enhance 2.0",
	author 			= "夜羽真白",
	description 	= "Ai Spitter 增强 2.0 版本",
	version 		= "2023-1-3",
	url 			= "https://steamcommunity.com/id/saku_ra/"
}

ConVar
	g_hAllowBhop,
	g_hBhopSpeed,
	g_hTargetPolicy,
	g_hPinnedPriority,
	g_hKilledAfterSpit;
float
	clientDelay[MAXPLAYERS + 1][8];
int
	pinnedPriority[6] = {0},
	pinnedTarget = -1,
	crowdedTarget = -1;
Handle
	checkPinnedTimer = null;

enum
{
	DEFAULT_TARGET = 1,
	NEAREST_TARGET,
	PINNED_TARGET,
	CROWDED_TARGET
};

public void OnPluginStart()
{
	g_hAllowBhop = CreateConVar("ai_SpitterBhop", "1", "是否开启 Spitter 连跳功能", CVAR_FLAG, true, 0.0, true, 1.0);
	g_hBhopSpeed = CreateConVar("ai_SpitterBhopSpeed", "100", "Spitter 连跳的速度", CVAR_FLAG, true, 0.0);
	g_hTargetPolicy = CreateConVar("ai_SpitterTarget", "3", "Spitter 目标选择：1=默认 2=最近 3=被控优先，否则第一个生还 4=人多处", CVAR_FLAG, true, 1.0, true, 4.0);
	g_hPinnedPriority = CreateConVar("ai_SpitterPinnedPr", "6,3,1,5", "被控目标优先级（被控特感编号，逗号分隔）", CVAR_FLAG);
	g_hKilledAfterSpit = CreateConVar("ai_SpiiterDieAfterSpit", "0", "是否开启 Spitter 吐完痰后处死功能", CVAR_FLAG, true, 0.0, true, 1.0);
	// HookEvent
	HookEvent("ability_use", abilityUseHandler);
	// AddChangeHook
	g_hPinnedPriority.AddChangeHook(pinnedPriorityCvarChangedHandler);
	// GetPriority
	getPinnedPriority();
	// CreateTimer
	delete checkPinnedTimer;
	checkPinnedTimer = CreateTimer(CHECK_PINNED_TIME, checkPinnedAndCrowdTargetHandler, _, TIMER_REPEAT);
}
public void OnPluginEnd()
{
	delete checkPinnedTimer;
}

void pinnedPriorityCvarChangedHandler(ConVar convar, const char[] oldValue, const char[] newValue)
{
	getPinnedPriority();
}

public void abilityUseHandler(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_hKilledAfterSpit.BoolValue) { return; }
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (isAiSpitter(client) && IsPlayerAlive(client)) { CreateTimer(SPITTER_KILL_DELAY, killSpitterHandler, client); }
}

public Action killSpitterHandler(Handle timer, int client)
{
	if (!isAiSpitter(client) || !IsPlayerAlive(client)) { return Plugin_Continue; }
	ForcePlayerSuicide(client);
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int spitter, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (!isAiSpitter(spitter) || !IsPlayerAlive(spitter)) { return Plugin_Continue; }
	static float velVec[3],  curSpeed;
	float fclientEyeAngles[3] = {0.0};
	//static int targetDist;
	GetEntPropVector(spitter, Prop_Data, "m_vecVelocity", velVec);
	GetClientEyeAngles(spitter, fclientEyeAngles);
	curSpeed = SquareRoot(Pow(velVec[0], 2.0) + Pow(velVec[1], 2.0));
	//targetDist = GetClosetSurvivorDistance(spitter);
	if (GetEntityMoveType(spitter) & MOVETYPE_LADDER)
	{
		buttons &= ~IN_JUMP;
		buttons &= ~IN_DUCK;
	}
	if ((buttons & IN_ATTACK) && delayExpired(spitter, 0, SPITTER_JUMP_DELAY))
	{
		delayStart(spitter, 0);
		buttons |= IN_JUMP;
		return Plugin_Changed;
	}
	if (!(/*targetDist < 1000.0 && */curSpeed > 180.0) || !(GetEntityFlags(spitter) & FL_ONGROUND) || !g_hAllowBhop.BoolValue) { return Plugin_Continue; }
	buttons |= IN_DUCK;
	buttons |= IN_JUMP;
	if(buttons & IN_FORWARD)
	{
		Client_Push(spitter, fclientEyeAngles, g_hBhopSpeed.FloatValue, VelocityOverride:{VelocityOvr_None,VelocityOvr_None,VelocityOvr_None});
	}
	else if(buttons & IN_BACK)
	{
		fclientEyeAngles[1] += 180.0;
		Client_Push(spitter, fclientEyeAngles, g_hBhopSpeed.FloatValue*2, VelocityOverride:{VelocityOvr_None,VelocityOvr_None,VelocityOvr_None});
	}
	else if(buttons & IN_MOVELEFT)
	{
		fclientEyeAngles[1] += 45.0;
		Client_Push(spitter, fclientEyeAngles, g_hBhopSpeed.FloatValue, VelocityOverride:{VelocityOvr_None,VelocityOvr_None,VelocityOvr_None});
	}
	else if(buttons & IN_MOVERIGHT)
	{
		fclientEyeAngles[1] += -45.0;
		Client_Push(spitter, fclientEyeAngles, g_hBhopSpeed.FloatValue, VelocityOverride:{VelocityOvr_None,VelocityOvr_None,VelocityOvr_None});
	}
	else
	{
		Client_Push(spitter, fclientEyeAngles, g_hBhopSpeed.FloatValue, VelocityOverride:{VelocityOvr_None,VelocityOvr_None,VelocityOvr_None});
	}
	return Plugin_Continue;
}

public Action L4D2_OnChooseVictim(int specialInfected, int &curTarget)
{
	if (!isAiSpitter(specialInfected) || !IsPlayerAlive(specialInfected)) { return Plugin_Continue; }
	static int newTarget;
	static float selfPos[3], targetPos[3];
	GetClientAbsOrigin(specialInfected, selfPos);
	switch (g_hTargetPolicy.IntValue)
	{
		case NEAREST_TARGET:
		{
			newTarget = GetClosetSurvivor(specialInfected);
			if (!IsValidSurvivor(newTarget) || !IsPlayerAlive(newTarget)) { return Plugin_Continue; }
			curTarget = newTarget;
			return Plugin_Changed;
		}
		case PINNED_TARGET:
		{
			if (IsValidSurvivor(pinnedTarget) && IsPlayerAlive(pinnedTarget))
			{
				GetEntPropVector(pinnedTarget, Prop_Send, "m_vecOrigin", targetPos);
				//if (GetVectorDistance(selfPos, targetPos) > g_hSpitRange.FloatValue) { return Plugin_Continue; }
				curTarget = pinnedTarget;
				return Plugin_Changed;
			}
		}
		case CROWDED_TARGET:
		{
			if (IsValidSurvivor(crowdedTarget) && IsPlayerAlive(crowdedTarget))
			{
				GetEntPropVector(pinnedTarget, Prop_Send, "m_vecOrigin", targetPos);
				//if (GetVectorDistance(selfPos, targetPos) > g_hSpitRange.FloatValue) { return Plugin_Continue; }
				curTarget = crowdedTarget;
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

// 口水连跳
stock void Client_Push(int client, float clientEyeAngle[3], float power,VelocityOverride override[3] = {VelocityOvr_None, VelocityOvr_None, VelocityOvr_None}) 
{
	float forwardVector[3];
	float newVel[3];
	
	GetAngleVectors(clientEyeAngle, forwardVector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(forwardVector, forwardVector);
	ScaleVector(forwardVector, power);
	//PrintToChatAll("Tank velocity: %.2f", forwardVector[1]);
	
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", newVel);
	
	for( int i = 0; i < 3; i++ ) 
	{
		switch( override[i] ) 
		{
			case VelocityOvr_Velocity: 
			{
				newVel[i] = 0.0;
			}
			case VelocityOvr_OnlyWhenNegative: 
			{				
				if( newVel[i] < 0.0 ) 
				{
					newVel[i] = 0.0;
				}
			}
			case VelocityOvr_InvertReuseVelocity: 
			{				
				if( newVel[i] < 0.0 ) 
				{
					newVel[i] *= -1.0;
				}
			}
		}
		
		newVel[i] += forwardVector[i];
	}
	
	SetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", newVel);
}


// 方法
/*bool IsAiSpitter(int client)
{
	if(IsFakeClient(client) && GetClientTeam(client) == TEAM_INFECTED && IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_zombieClass") == ZC_SPITTER && GetEntProp(client, Prop_Send, "m_isGhost") != 1)
	{
		return true;
	}
	else
	{
		return false;
	}
}*/

// 连跳操作
/*bool Do_Bhop(int client, int &buttons)
{
	if (!IsAiSpitter(client) || !IsPlayerAlive(client))
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
}*/

/*bool bWontFall(int client, const float vVel[3]) {
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
}*/

/*bool bTraceEntityFilter(int entity, int contentsMask) {
	if (entity <= MaxClients)
		return false;

	static char cls[9];
	GetEntityClassname(entity, cls, sizeof cls);
	if ((cls[0] == 'i' && strcmp(cls[1], "nfected") == 0) || (cls[0] == 'w' && strcmp(cls[1], "itch") == 0))
		return false;

	return true;
}*/
/*void clientPush(int client, float eyeAngle[3], float force)
{
	static float eyeAngleVec[3], velVec[3];
	GetAngleVectors(eyeAngle, eyeAngleVec, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(eyeAngleVec, eyeAngleVec);
	ScaleVector(eyeAngleVec, force);
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", velVec);
	AddVectors(velVec, eyeAngleVec, velVec);
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velVec);
}*/

bool isAiSpitter(int client)
{
	return GetInfectedClass(client) == ZC_SPITTER && IsFakeClient(client);
}

void delayStart(int client, int no)
{
	if (!IsValidClient(client)) { return; }
	clientDelay[client][no] = GetGameTime();
}

bool delayExpired(int client, int no, float ttl)
{
	return GetGameTime() - clientDelay[client][no] > ttl;
}

void getPinnedPriority()
{
	char priority[32] = {'\0'}, result[6][4];
	g_hPinnedPriority.GetString(priority, sizeof(priority));
	ExplodeString(priority, ",", result, 6, 4);
	for (int i = 0; i < 6; i++)
	{
		if (result[i][0] == '\0') { continue; }
		pinnedPriority[i] = StringToInt(result[i]);
	}
}

public Action checkPinnedAndCrowdTargetHandler(Handle timer)
{
	pinnedTarget = getTargetByPriority();
	crowdedTarget = getCrowdTarget();
	return Plugin_Continue;
}

stock bool spitterCanSeeTarget(int spitter, int target)
{
	if (!isAiSpitter(spitter) || !IsPlayerAlive(spitter) || !IsValidSurvivor(target) || !IsPlayerAlive(target)) { return false; }
	static Handle trace;
	static float selfPos[3], targetPos[3];
	GetClientEyePosition(spitter, selfPos);
	GetClientEyePosition(target, targetPos);
	trace = TR_TraceRayFilterEx(selfPos, targetPos, MASK_VISIBLE, RayType_EndPoint, rayFilter, spitter);
	if (TR_DidHit(trace) && TR_GetEntityIndex(trace) != target)
	{
		delete trace;
		return false;
	}
	delete trace;
	return true;
}
stock bool rayFilter(int entity, int contentsMask, any self)
{
	return entity < 1 && entity > MaxClients && entity != self;
}

int getTargetByPriority()
{
	static int i, pummelTarget, pouncedTarget, pulledTarget, jockedTarget;
	static float flow;
	static ArrayList flowList;
	pummelTarget = pouncedTarget = pulledTarget = jockedTarget = -1;
	flow = 0.0;
	flowList = new ArrayList(2);
	for (i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != TEAM_SURVIVOR || !IsPlayerAlive(i)) { continue; }
		flow = L4D2Direct_GetFlowDistance(i);
		if (flow && flow != -9999.0) { flowList.Set(flowList.Push(flow), i, 1); }
		// 检测被撞
		if (GetEntPropEnt(i, Prop_Send, "m_pummelAttacker") > 0)
		{
			pummelTarget = i;
			continue;
		}
		// 检测被扑
		if (GetEntPropEnt(i, Prop_Send, "m_pounceAttacker") > 0)
		{
			pouncedTarget = i;
			continue;
		}
		// 检测被拉
		if (GetEntPropEnt(i, Prop_Send, "m_tongueOwner") > 0)
		{
			pulledTarget = i;
			continue;
		}
		// 检测被骑
		if (GetEntPropEnt(i, Prop_Send, "m_jockeyAttacker") > 0)
		{
			jockedTarget = i;
			continue;
		}
	}
	// 没有人被控，选取路程最高的玩家
	if (!IsValidSurvivor(pummelTarget) && !IsValidSurvivor(pouncedTarget) && !IsValidSurvivor(pulledTarget) && !IsValidSurvivor(jockedTarget))
	{
		// 没有活着的生还者，返回 -1
		if (flowList.Length < 1)
		{
			delete flowList;
			return -1;
		}
		// 两名及以上生还者
		flowList.Sort(Sort_Descending, Sort_Float);
		if (flowList.Length >= 2)
		{
			i = flowList.Get(0, 1);
			delete flowList;
			if(!IsClientIncapped(i))
			{
				return i;
			}
		}
	}
	// 根据优先级选取被控玩家
	for (i = 0; i < 6; i++)
	{
		switch (pinnedPriority[i])
		{
			case ZC_CHARGER: { if (IsValidSurvivor(pummelTarget)) { return pummelTarget; } }
			case ZC_HUNTER: { if (IsValidSurvivor(pouncedTarget)) { return pouncedTarget; } }
			case ZC_JOCKEY: { if (IsValidSurvivor(jockedTarget)) { return jockedTarget; } }
			case ZC_SMOKER: { if (IsValidSurvivor(pulledTarget)) { return pulledTarget; } }
		}
	}
	return -1;
}

int getCrowdTarget()
{
	static int i, j, index;
	static float selfPos[3], targetPos[3];
	static ArrayList flowList;
	flowList = new ArrayList(2);
	for (i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != TEAM_SURVIVOR	|| !IsPlayerAlive(i)) { continue; }
		GetClientAbsOrigin(i, selfPos);
		index = flowList.Push(i);
		for (j = 1; j <= MaxClients; j++)
		{
			if (!IsClientInGame(j) || GetClientTeam(j) != TEAM_SURVIVOR	|| !IsPlayerAlive(j) || i == j) { continue; }
			GetEntPropVector(j, Prop_Send, "m_vecOrigin", targetPos);
			flowList.Set(index, view_as<float>(flowList.Get(index, 1)) + GetVectorDistance(selfPos, targetPos), 1);
		}
	}
	if (flowList.Length < 1)
	{
		delete flowList;
		return -1;
	}
	flowList.SortCustom(sortByDistanceAsc);
	i = flowList.Get(0, 0);
	delete flowList;
	return i;
}

int sortByDistanceAsc(int index1, int index2, ArrayList array, Handle hndl)
{
	return FloatCompare(array.Get(index1, 1), array.Get(index2, 1));
}
