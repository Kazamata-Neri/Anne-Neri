#pragma semicolon 1
#pragma newdecls required

// 头文件
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include "treeutil\treeutil.sp"

#define CVAR_FLAG FCVAR_NOTIFY
#define EYE_ANGLE_UP_HEIGHT 15.0
#define NAV_MESH_HEIGHT 20.0
#define FALL_DETECT_HEIGHT 120.0
#define COMMAND_INTERVAL 1.0
#define PLAYER_HEIGHT 72.0

// Velocity
enum VelocityOverride {
	VelocityOvr_None = 0,
	VelocityOvr_Velocity,
	VelocityOvr_OnlyWhenNegative,
	VelocityOvr_InvertReuseVelocity
};

enum AimType
{
	AimEye,
	AimBody,
	AimChest
};

public Plugin myinfo = 
{
	name 			= "Ai Boomer 2.0",
	author 			= "夜羽真白",
	description 	= "Ai Boomer 增强 2.0 版本",
	version 		= "2.0.0.0",
	url 			= "https://steamcommunity.com/id/saku_ra/"
}

ConVar g_hAllowBhop, g_hBhopSpeed, g_hUpVision, g_hTurnVision, g_hForceBile, g_hBileFindRange, g_hVomitRange, g_hVomitMaxDamageDist, g_hVomitDuration, g_hVomitInterval, g_hTurnInterval;
// Bools
bool can_bile[MAXPLAYERS + 1] = { true }, in_bile_interval[MAXPLAYERS + 1] = { false };
// Ints，bile_frame 0 位：当前目标索引，1 位：循环次数
int bile_frame[MAXPLAYERS + 1][2];
// Handles
Handle bile_interval_timer[MAXPLAYERS + 1] = { null };
// Lists
ArrayList targetList[MAXPLAYERS + 1] = { null };

public void OnPluginStart()
{
	// CreateConVars
	g_hAllowBhop = CreateConVar("ai_BoomerBhop", "1", "是否开启 Boomer 连跳", CVAR_FLAG, true, 0.0, true, 1.0);
	g_hBhopSpeed = CreateConVar("ai_BoomerBhopSpeed", "120.0", "Boomer 连跳速度", CVAR_FLAG, true, 0.0);
	g_hUpVision = CreateConVar("ai_BoomerUpVision", "1", "Boomer 喷吐时是否上抬视角", CVAR_FLAG, true, 0.0, true, 1.0);
	g_hTurnVision = CreateConVar("ai_BoomerTurnVision", "1", "Boomer 喷吐时是否旋转视角", CVAR_FLAG, true, 0.0, true, 1.0);
	g_hForceBile = CreateConVar("ai_BoomerForceBile", "1", "是否开启生还者到 Boomer 喷吐范围内强制被喷", CVAR_FLAG, true, 0.0, true, 1.0);
	g_hBileFindRange = CreateConVar("ai_BoomerBileFindRange", "400", "在这个距离内有被控或倒地的生还 Boomer 会优先攻击，0 = 关闭此功能", CVAR_FLAG, true, 0.0);
	g_hTurnInterval = CreateConVar("ai_BoomerTurnInterval", "5", "Boomer 喷吐旋转视角时每隔多少帧转移一个目标", CVAR_FLAG, true, 0.0);
	g_hVomitRange = FindConVar("z_vomit_range");
	g_hVomitMaxDamageDist = FindConVar("z_vomit_maxdamagedist");
	g_hVomitDuration = FindConVar("z_vomit_duration");
	g_hVomitInterval = FindConVar("z_vomit_interval");
	// HookEvents
	HookEvent("player_spawn", evt_PlayerSpawn);
	HookEvent("player_shoved", evt_PlayerShoved);
	// SetConVars
	SetConVarFloat(FindConVar("boomer_exposed_time_tolerance"), 10000.0);
	SetConVarFloat(FindConVar("boomer_vomit_delay"), 0.1);
}
public void OnPluginEnd()
{
	ResetConVar(FindConVar("boomer_exposed_time_tolerance"));
	ResetConVar(FindConVar("boomer_vomit_delay"));
	for (int i = 0; i < MAXPLAYERS + 1; i++) { delete targetList[i]; }
}

public void evt_PlayerShoved(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsBoomer(client))
	{
		in_bile_interval[client] = true;
		CreateTimer(1.5, Timer_ResetAbility, client);
	}
}
public void evt_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsBoomer(client))
	{
		can_bile[client] = true;
		in_bile_interval[client] = false;
		bile_frame[client][0] = bile_frame[client][1] = 0;
		delete bile_interval_timer[client];
		// Build ArrayList
		if (targetList[client] != null) { targetList[client].Clear(); }
		else { targetList[client] = new ArrayList(2); }
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3])
{
	if (IsBoomer(client))
	{
		float self_pos[3] = {0.0}, self_eye_pos[3] = {0.0}, targetPos[3] = {0.0}, target_eye_pos[3] = {0.0}, vec_speed[3] = {0.0}, cur_speed = 0.0, fclientEyeAngles[3] = {0.0};
		int flags = GetEntityFlags(client), target = GetClientAimTarget(client, true), closet_survivor_dist = GetClosetSurvivorDistance(client);
		bool has_sight = view_as<bool>(GetEntProp(client, Prop_Send, "m_hasVisibleThreats"));
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vec_speed);
		cur_speed = SquareRoot(Pow(vec_speed[0], 2.0) + Pow(vec_speed[1], 2.0));
		GetClientAbsOrigin(client, self_pos);
		GetClientEyePosition(client, self_eye_pos);
		GetClientEyeAngles(client, fclientEyeAngles);
		if (has_sight && IsValidSurvivor(target) && !in_bile_interval[client] && targetList[client].Length < 1)
		{
			float aim_angles[3] = {0.0}, dist = GetVectorDistance(self_pos, targetPos), height = self_pos[2] - targetPos[2];
			ComputeAimAngles(client, target, aim_angles, AimEye);
			if (g_hUpVision.BoolValue)
			{
				if (height == 0.0 || height < 0.0) { aim_angles[0] -= dist / (PLAYER_HEIGHT * 4.3); }
				else if (height > 0.0) { aim_angles[0] -= dist / (PLAYER_HEIGHT * 5); }
			}
			TeleportEntity(client, NULL_VECTOR, aim_angles, NULL_VECTOR);
		}
		if (targetList[client].Length >= 1 && !in_bile_interval[client] && g_hTurnVision.BoolValue)
		{
			if (bile_frame[client][0] < targetList[client].Length && bile_frame[client][1] < g_hTurnInterval.IntValue)
			{
				float aimAngles[3] = {0.0}, dist = GetVectorDistance(self_pos, targetPos), height = 0.0;
				int turnTarget = targetList[client].Get(bile_frame[client][0], 1);
				height = self_pos[2] - targetPos[2];
				ComputeAimAngles(client, turnTarget, aimAngles, AimEye);
				if (g_hUpVision.BoolValue)
				{
					if (height == 0.0 || height < 0.0) { aimAngles[0] -= dist / (PLAYER_HEIGHT * 4.3); }
					else if (height > 0.0) { aimAngles[0] -= dist / (PLAYER_HEIGHT * 5); }
				}
				TeleportEntity(client, NULL_VECTOR, aimAngles, NULL_VECTOR);
				bile_frame[client][1] += 1;
			}
			else if (bile_frame[client][0] >= targetList[client].Length)
			{
				targetList[client].Clear();
				bile_frame[client][0] = bile_frame[client][1] = 0;
			}
			else
			{
				bile_frame[client][0] += 1;
				bile_frame[client][1] = 0;
			}
		}
		// 靠近生还者，立即喷吐
		if ((flags & FL_ONGROUND) && IsValidSurvivor(target) && has_sight && closet_survivor_dist <= RoundToNearest(1.0 * g_hVomitRange.FloatValue) && !in_bile_interval[client] && can_bile[client] && Player_IsVisible_To(target, client))
		{
			buttons |= IN_FORWARD;
			buttons |= IN_ATTACK;
			if (can_bile[client]) { CreateTimer(g_hVomitDuration.FloatValue, Timer_ResetBile, client); }
			can_bile[client] = false;
		}
		// 目标是被控或者倒地的生还，则令其蹲下攻击
		if (IsValidSurvivor(target) && (IsClientIncapped(target) || IsClientPinned(target)))
		{
			buttons |= IN_DUCK;
			buttons |= IN_ATTACK2;
		}
		// 强行被喷
		if (g_hForceBile.BoolValue && (buttons & IN_ATTACK) && (flags & FL_ONGROUND) && !in_bile_interval[client] && IsValidSurvivor(target))
		{
			in_bile_interval[client] = true;
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == view_as<int>(TEAM_SURVIVOR) && IsPlayerAlive(i))
				{
					GetClientEyePosition(i, target_eye_pos);
					Handle hTrace = TR_TraceRayFilterEx(self_eye_pos, target_eye_pos, MASK_VISIBLE, RayType_EndPoint, TR_RayFilter, client);
					if (!TR_DidHit(hTrace) || TR_GetEntityIndex(hTrace) == i)
					{
						if (GetVectorDistance(self_eye_pos, target_eye_pos) <= g_hVomitMaxDamageDist.FloatValue)
						{
							L4D_CTerrorPlayer_OnVomitedUpon(i, client);
						}
					}
					delete hTrace;
				}
			}
			CreateTimer(g_hVomitInterval.FloatValue, Timer_ResetAbility, client);
		}
		// 连跳
		if (g_hAllowBhop.BoolValue /*&& has_sight*/ && (flags & FL_ONGROUND) /*&& 0.5 * g_hVomitRange.FloatValue < closet_survivor_dist < 10000.0*/ && cur_speed > 180.0/* && IsValidSurvivor(target)*/)
		{
			buttons |= IN_DUCK;
			buttons |= IN_JUMP;
			if(buttons & IN_FORWARD)
			{
				Client_Push(client, fclientEyeAngles, g_hBhopSpeed.FloatValue, VelocityOverride:{VelocityOvr_None,VelocityOvr_None,VelocityOvr_None});
			}
			else if(buttons & IN_BACK)
			{
				fclientEyeAngles[1] += 180.0;
				Client_Push(client, fclientEyeAngles, g_hBhopSpeed.FloatValue*2, VelocityOverride:{VelocityOvr_None,VelocityOvr_None,VelocityOvr_None});
			}
			else if(buttons & IN_MOVELEFT)
			{
				fclientEyeAngles[1] += 45.0;
				Client_Push(client, fclientEyeAngles, g_hBhopSpeed.FloatValue, VelocityOverride:{VelocityOvr_None,VelocityOvr_None,VelocityOvr_None});
			}
			else if(buttons & IN_MOVERIGHT)
			{
				fclientEyeAngles[1] += -45.0;
				Client_Push(client, fclientEyeAngles, g_hBhopSpeed.FloatValue, VelocityOverride:{VelocityOvr_None,VelocityOvr_None,VelocityOvr_None});
			}
			else
			{
				Client_Push(client, fclientEyeAngles, g_hBhopSpeed.FloatValue, VelocityOverride:{VelocityOvr_None,VelocityOvr_None,VelocityOvr_None});
			}
			//return Plugin_Continue;
		}
		// 爬梯时，禁止连跳
		if (GetEntityMoveType(client) & MOVETYPE_LADDER)
		{
			buttons &= ~IN_JUMP;
			buttons &= ~IN_DUCK;
		}
	}
	return Plugin_Continue;
}
// 重置胖子能力使用限制
public Action Timer_ResetAbility(Handle timer, int client)
{
	if (IsBoomer(client) && IsPlayerAlive(client))
	{
		can_bile[client] = true;
		in_bile_interval[client] = false;
		return Plugin_Continue;
	}
	return Plugin_Stop;
}
public Action Timer_ResetBile(Handle timer, int client)
{
	if (IsBoomer(client) && IsPlayerAlive(client))
	{
		can_bile[client] = false;
		in_bile_interval[client] = true;
		// 喷吐时间过后，清除目标集合数据
		targetList[client].Clear();
		bile_frame[client][0] = bile_frame[client][1] = 0;
		CreateTimer(g_hVomitInterval.FloatValue, Timer_ResetAbility, client);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

// 获取目标
public Action L4D2_OnChooseVictim(int specialInfected, int &curTarget)
{
	if (IsBoomer(specialInfected) && IsPlayerAlive(specialInfected))
	{
		float eyePos[3] = {0.0}, targetEyePos[3] = {0.0}, dist = 0.0;
		GetClientEyePosition(specialInfected, eyePos);
		// 寻找范围内符合要求的玩家，优先找被控或者倒地的
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsPlayerAlive(i) && (IsClientIncapped(i) || IsClientPinned(i)))
			{
				GetClientEyePosition(i, targetEyePos);
				eyePos[2] = targetEyePos[2] = 0.0;
				dist = GetVectorDistance(eyePos, targetEyePos);
				if (g_hBileFindRange.FloatValue > 0.0 && dist <= g_hBileFindRange.FloatValue)
				{
					Handle hTrace = TR_TraceRayFilterEx(eyePos, targetEyePos, MASK_VISIBLE, RayType_EndPoint, TR_RayFilter, specialInfected);
					if (!TR_DidHit(hTrace) || TR_GetEntityIndex(hTrace) == i)
					{
						curTarget = i;
						return Plugin_Changed;
					}
					delete hTrace;
				}
			}
		}
	}
	return Plugin_Continue;
}

// 当生还被胖子喷中时，开始计算范围内的玩家
public Action L4D_OnVomitedUpon(int victim, int &attacker, bool &boomerExplosion)
{
	// 当前 Boomer 目标集合中没有目标，开始获取目标
	if (IsBoomer(attacker) && targetList[attacker].Length < 1)
	{
		float eyePos[3] = {0.0}, targetEyePos[3] = {0.0}, dist = 0.0;
		GetClientEyePosition(attacker, eyePos);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (i != victim && IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsPlayerAlive(i))
			{
				GetClientEyePosition(i, targetEyePos);
				eyePos[2] = targetEyePos[2] = 0.0;
				dist = GetVectorDistance(eyePos, targetEyePos);
				if (dist <= g_hVomitMaxDamageDist.FloatValue)
				{
					Handle trace = TR_TraceRayFilterEx(eyePos, targetEyePos, MASK_VISIBLE, RayType_EndPoint, TR_RayFilter, attacker);
					if (!TR_DidHit(trace) || TR_GetEntityIndex(trace) == i)
					{
						int index = targetList[attacker].Push(dist);
						targetList[attacker].Set(index, i, 1);
					}
					delete trace;
				}
			}
		}
		if (targetList[attacker].Length > 1)
		{
			targetList[attacker].Sort(Sort_Ascending, Sort_Float);
		}
/* 		PrintToConsoleAll("输出 boomer 目标数组");
		for (int i = 0; i < targetList[attacker].Length; i++)
		{
			PrintToConsoleAll("第：%d 个，%d - %N，距离：%.2f", i + 1, targetList[attacker].Get(i, 1), targetList[attacker].Get(i, 1), targetList[attacker].Get(i, 0));
		} */
	}
	return Plugin_Continue;
}

// 方法，是否 AI 胖子
bool IsBoomer(int client)
{
	return view_as<bool>(GetInfectedClass(client) == view_as<int>(ZC_BOOMER) && IsFakeClient(client));
}

// 胖子连跳
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

void ComputeAimAngles(int client, int target, float angles[3], AimType type = AimEye)
{
	float selfpos[3], targetpos[3], lookat[3];
	GetClientEyePosition(client, selfpos);
	switch (type)
	{
		case AimEye:
		{
			GetClientEyePosition(target, targetpos);
		}
		case AimBody:
		{
			GetClientAbsOrigin(target, targetpos);
		}
		case AimChest:
		{
			GetClientAbsOrigin(target, targetpos);
			targetpos[2] += 45.0;
		}
	}
	MakeVectorFromPoints(selfpos, targetpos, lookat);
	GetVectorAngles(lookat, angles);
}

/* void GetBileTarget(int client, float selfPos[3], float eyePos[3])
{
	int index = 0;
	float[3] targetPos[3] = {0.0}, targetEyePos[3] = {0.0};
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsPlayerAlive(i))
		{
			GetClientAbsOrigin(i, targetPos);
			GetClientEyePosition(i, targetEyePos);
			if (GetVectorDistance(selfPos, targetPos) <= g_hVomitMaxDamageDist.FloatValue)
			{
				Handle hTrace = TR_TraceRayFilterEx(eyePos, targetEyePos, MASK_VISIBLE, RayType_EndPoint, TR_RayFilter, client);
				if (!TR_DidHit(hTrace) || TR_GetEntityIndex(hTrace) == i) { bile_target[client][index++] = i; }
				delete hTrace;
			}
		}
	}
	bile_target_num[client][0] = index;
} */
// old version
/* if (bile_target_num[client][0] >= 1 && g_hTurnVision.BoolValue && !in_bile_interval[client])
{
	// LogMessage("[Ai-Boomer]：当前Boomer的bile_target_num[0]：%d，[1]：%d，[2]：%d", bile_target_num[client][0], bile_target_num[client][1], bile_target_num[client][2]);
	if (IsValidSurvivor(bile_target[client][bile_target_num[client][1]]) && bile_target_num[client][2] < g_hTurnInterval.IntValue)
	{
		float aim_angles[3] = {0.0}, dist = 0.0, height = 0.0;
		dist = GetVectorDistance(self_pos, target_pos);
		height = self_pos[2] - target_pos[2];
		ComputeAimAngles(client, bile_target[client][bile_target_num[client][1]], aim_angles, AimEye);
		if (g_hUpVision.BoolValue)
		{
			if (height == 0.0 || height < 0.0)
			{
				aim_angles[0] -= dist / (PLAYER_HEIGHT * 4.3);
			}
			else if (height > 0.0)
			{
				aim_angles[0] -= dist / (PLAYER_HEIGHT * 5);
			}
		}
		TeleportEntity(client, NULL_VECTOR, aim_angles, NULL_VECTOR);
		bile_target_num[client][2] += 1;
	}
	// 当前目标索引小于目标数目时，目标索引 + 1，重置循环次数
	else if (bile_target_num[client][1] < bile_target_num[client][0])
	{
		bile_target_num[client][1] += 1;
		bile_target_num[client][2] = 0;
	}
	// 最后一个目标循环完成，表示喷完了，此时重置 Boomer 目标数组
	else if (bile_target_num[client][1] == bile_target_num[client][0])
	{
		ResetBileTarget(client);
	}
} */
// 当前 Boomer 目标数组中没有目标时，开始计算范围内是否有目标
/* if (IsBoomer(attacker) && IsValidSurvivor(victim) && bile_target_num[attacker][0] < 1)
{
	// 计算范围内的玩家
	int target_num = 0;
	float self_pos[3] = {0.0}, target_pos[3] = {0.0}, self_eye_pos[3] = {0.0}, target_eye_pos[3] = {0.0};
	GetClientAbsOrigin(attacker, self_pos);
	GetClientEyePosition(attacker, self_eye_pos);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i != victim && IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == view_as<int>(TEAM_SURVIVOR) && IsPlayerAlive(i))
		{
			GetClientAbsOrigin(i, target_pos);
			GetClientEyePosition(i, target_eye_pos);
			if (GetVectorDistance(self_pos, target_pos) <= g_hVomitMaxDamageDist.FloatValue)
			{
				// 判断可视性
				Handle hTrace = TR_TraceRayFilterEx(self_eye_pos, target_eye_pos, MASK_VISIBLE, RayType_EndPoint, TR_RayFilter, attacker);
				if (!TR_DidHit(hTrace) || TR_GetEntityIndex(hTrace) == i)
				{
					bile_target[attacker][target_num++] = i;
					// PrintToConsoleAll("[Ai-Boomer]：在范围内的玩家 %N，实际i的值 %N，加入玩家", bile_target[attacker][target_num], i);
				}
				delete hTrace;
			}
		}
	}
	// LogMessage("[Ai-Boomer]：当前范围内的目标：%d 个", target_num);
	bile_target_num[attacker][0] = target_num;
} */
/* void ResetBileTarget(int client)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		bile_target[client][i] = 0;
	}
	bile_target_num[client][0] = bile_target_num[client][1] = bile_target_num[client][2] = 0;
} */
// 阻止或恢复喷吐
/* void BlockBile(int client, bool block = true)
{
	int ability = GetEntPropEnt(client, Prop_Send,"m_customAbility");
	if (IsValidEntity(ability) && block)
	{
		SetEntPropFloat(ability, Prop_Send, "m_timestamp", GetGameTime() + 0.5);
	}
	else if (IsValidEntity(ability) && !block)
	{
		SetEntPropFloat(ability, Prop_Send, "m_timestamp", GetGameTime() - 0.5);
	}
} */