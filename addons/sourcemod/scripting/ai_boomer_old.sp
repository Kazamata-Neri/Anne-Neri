#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

ConVar
	g_hBoomerBhop,
	g_hBoomerBhopSpeed,
	g_hVomitRange;

bool
	g_bBoomerBhop;

float
	g_fVomitRange;

public Plugin myinfo = {
	name = "AI BOOMER",
	author = "Breezy",
	description = "Improves the AI behaviour of special infected",
	version = "1.0",
	url = "github.com/breezyplease"
};

public void OnPluginStart() {
	g_hBoomerBhop = CreateConVar("ai_boomer_bhop", "1", "Flag to enable bhop facsimile on AI boomers");
	g_hBoomerBhopSpeed = CreateConVar("ai_boomer_bhop_speed", "80", "胖子连跳速度");
	g_hVomitRange = FindConVar("z_vomit_range");
	
	g_hBoomerBhop.AddChangeHook(vCvarChanged);
	g_hVomitRange.AddChangeHook(vCvarChanged);

	FindConVar("z_vomit_fatigue").SetInt(0);
	FindConVar("z_boomer_near_dist").SetInt(1);

	HookEvent("ability_use", Event_AbilityUse);
}

public void OnPluginEnd() {
	FindConVar("z_vomit_fatigue").RestoreDefault();
	FindConVar("z_boomer_near_dist").RestoreDefault();
}

public void OnConfigsExecuted() {
	vGetCvars();
}

void vCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	vGetCvars();
}

void vGetCvars() {
	g_bBoomerBhop = g_hBoomerBhop.BoolValue;
	g_fVomitRange = g_hVomitRange.FloatValue;
}

void Event_AbilityUse(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client) || !IsFakeClient(client))
		return;

	static char sUse[16];
	event.GetString("ability", sUse, sizeof sUse);
	if (strcmp(sUse, "ability_vomit") == 0) {
		int flags = GetEntityFlags(client) & ~FL_ONGROUND;
		SetEntityFlags(client, flags & ~FL_FROZEN);
		vBoomer_OnVomit(client);
		SetEntityFlags(client, flags);
	}
}

int g_iCurTarget[MAXPLAYERS + 1];
public Action L4D2_OnChooseVictim(int specialInfected, int &curTarget) {
	g_iCurTarget[specialInfected] = curTarget;
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons) {
	if (!g_bBoomerBhop)
		return Plugin_Continue;

	if (!IsClientInGame(client) || !IsFakeClient(client) || GetClientTeam(client) != 3 || !IsPlayerAlive(client) || GetEntProp(client, Prop_Send, "m_zombieClass") != 2 || GetEntProp(client, Prop_Send, "m_isGhost") )
		return Plugin_Continue;

	if (!bIsGrounded(client) || GetEntityMoveType(client) == MOVETYPE_LADDER || GetEntProp(client, Prop_Data, "m_nWaterLevel") > 1)
		return Plugin_Continue;

	static float vVel[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVel);
	if (SquareRoot(Pow(vVel[0], 2.0) + Pow(vVel[1], 2.0)) < GetEntPropFloat(client, Prop_Send, "m_flMaxspeed") - 10.0)
		return Plugin_Continue;

	static float fCurTargetDist;
	static float fNearestSurDist;
	vGetSurDistance(client, fCurTargetDist, fNearestSurDist);
	if (fCurTargetDist > 0.50 * g_fVomitRange && -1.0 < fNearestSurDist < 99999) {
		static float vAng[3];
		GetClientEyeAngles(client, vAng);
		return aBunnyHop(client, buttons, vAng);
	}

	return Plugin_Continue;
}

bool bIsGrounded(int client) {
	int iEnt = GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");
	return iEnt != -1 && IsValidEntity(iEnt);
	//return GetEntityFlags(client) & FL_ONGROUND != 0;
}

Action aBunnyHop(int client, int &buttons, const float vAng[3]) {
	float vFwd[3];
	float vRig[3];
	float vDir[3];
	float vVel[3];
	bool bPressed;
	if (buttons & IN_FORWARD || buttons & IN_BACK) {
		GetAngleVectors(vAng, vFwd, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(vFwd, vFwd);
		ScaleVector(vFwd, buttons & IN_FORWARD ? g_hBoomerBhopSpeed.FloatValue : -g_hBoomerBhopSpeed.FloatValue);
		bPressed = true;
	}

	if (buttons & IN_MOVERIGHT || buttons & IN_MOVELEFT) {
		GetAngleVectors(vAng, NULL_VECTOR, vRig, NULL_VECTOR);
		NormalizeVector(vRig, vRig);
		ScaleVector(vRig, buttons & IN_MOVERIGHT ? g_hBoomerBhopSpeed.FloatValue : -g_hBoomerBhopSpeed.FloatValue);
		bPressed = true;
	}

	if (bPressed) {
		AddVectors(vFwd, vRig, vDir);
		GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vVel);
		AddVectors(vVel, vDir, vVel);
		if (!bWontFall(client, vVel))
			return Plugin_Continue;

		buttons |= IN_DUCK;
		buttons |= IN_JUMP;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel);
		return Plugin_Changed;
	}

	return Plugin_Continue;
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

void vGetSurDistance(int client, float &CurTargetDist, float &NearestSurDist) {
	static float vPos[3];
	static float vTar[3];

	GetClientAbsOrigin(client, vPos);
	if (!bIsAliveSur(g_iCurTarget[client]))
		CurTargetDist = -1.0;
	else {
		GetClientAbsOrigin(g_iCurTarget[client], vTar);
		CurTargetDist = GetVectorDistance(vPos, vTar);
	}

	static int i;
	static int iCount;
	static float fDists[MAXPLAYERS + 1];

	iCount = 0;
	GetClientAbsOrigin(client, vPos);
	for (i = 1; i <= MaxClients; i++) {
		if (i != client && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i)) {
			GetClientAbsOrigin(i, vTar);
			fDists[iCount++] = GetVectorDistance(vPos, vTar);
		}
	}

	if (!iCount)
		NearestSurDist = -1.0;
	else {
		SortFloats(fDists, iCount, Sort_Ascending);
		NearestSurDist = fDists[0];
	}
}
/*
float fCurTargetDistance(int client) {
	if (!bIsAliveSur(g_iCurTarget[client]))
		return -1.0;

	static float vPos[3];
	static float vTar[3];
	GetClientAbsOrigin(client, vPos);
	GetClientAbsOrigin(g_iCurTarget[client], vTar);
	return GetVectorDistance(vPos, vTar);
}

float fNearestSurDistance(int client) {
	static int i;
	static int iCount;
	static float vPos[3];
	static float vTar[3];
	static float fDists[MAXPLAYERS + 1];
	
	iCount = 0;
	GetClientAbsOrigin(client, vPos);
	for (i = 1; i <= MaxClients; i++) {
		if (i != client && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i)) {
			GetClientAbsOrigin(i, vTar);
			fDists[iCount++] = GetVectorDistance(vPos, vTar);
		}
	}

	if (!iCount)
		return -1.0;

	SortFloats(fDists, iCount, Sort_Ascending);
	return fDists[0];
}*/

#define PLAYER_HEIGHT 72.0
void vBoomer_OnVomit(int client) {
	static int iTarget;
	iTarget = g_iCurTarget[client];//GetClientAimTarget(client, true);
	if (!bIsAliveSur(iTarget))
		iTarget = iGetClosestSur(client, iTarget, g_fVomitRange);

	if (iTarget == -1)
		return;

	static float vPos[3];
	static float vTar[3];
	static float vVelocity[3];
	GetClientAbsOrigin(client, vPos);
	GetClientEyePosition(iTarget, vTar);
	MakeVectorFromPoints(vPos, vTar, vVelocity);

	static float vLength;
	vLength = GetVectorLength(vVelocity);
	if (vLength < g_fVomitRange)
		vLength = 0.5 * g_fVomitRange;
	else {
		float fHeight = vTar[2] - vPos[2];
		if (fHeight > PLAYER_HEIGHT)
			vLength += GetVectorDistance(vPos, vTar) / vLength * PLAYER_HEIGHT;
	}

	static float vAngles[3];
	GetVectorAngles(vVelocity, vAngles);
	NormalizeVector(vVelocity, vVelocity);
	ScaleVector(vVelocity, vLength);
	TeleportEntity(client, NULL_VECTOR, vAngles, vVelocity);
}

bool bIsAliveSur(int client) {
	return 0 < client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
}

int iGetClosestSur(int client, int iExclude = -1, float fDistance) {
	static int i;
	static int iCount;
	static float fDist;
	static float vPos[3];
	static float vTar[3];
	static int iTargets[MAXPLAYERS + 1];
	
	iCount = 0;
	GetClientEyePosition(client, vPos);
	iCount = GetClientsInRange(vPos, RangeType_Visibility, iTargets, MAXPLAYERS);
	
	if (!iCount)
		return -1;
			
	static int iTarget;
	static ArrayList aTargets;
	aTargets = new ArrayList(2);
	for (i = 0; i < iCount; i++) {
		iTarget = iTargets[i];
		if (iTarget && iTarget != iExclude && GetClientTeam(iTarget) == 2 && IsPlayerAlive(iTarget) && !GetEntProp(iTarget, Prop_Send, "m_isIncapacitated")) {
			GetClientAbsOrigin(iTarget, vTar);
			fDist = GetVectorDistance(vPos, vTar);
			if (fDist < fDistance)
				aTargets.Set(aTargets.Push(fDist), iTarget, 1);
		}
	}

	if (!aTargets.Length) {
		delete aTargets;
		return -1;
	}

	aTargets.Sort(Sort_Ascending, Sort_Float);
	iTarget = aTargets.Get(0, 1);
	delete aTargets;
	return iTarget;
}
