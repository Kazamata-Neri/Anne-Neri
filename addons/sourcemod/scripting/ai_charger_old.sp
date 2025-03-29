#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

ConVar
	g_hChargerBhop,
	g_hChargeProximity,
	g_hChargeMaxSpeed,
	g_hChargeStartSpeed,
	g_hHealthThreshold,
	g_hAimOffsetSensitivity;

float
	g_fChargeProximity,
	g_fChargeMaxSpeed,
	g_fChargeStartSpeed,
	g_fAimOffsetSensitivity;

int
	g_iHealthThreshold;

bool
	g_bChargerBhop,
	g_bShouldCharge[MAXPLAYERS + 1];

public Plugin myinfo = {
	name = "AI CHARGER",
	author = "Breezy",
	description = "Improves the AI behaviour of special infected",
	version = "1.0",
	url = "github.com/breezyplease"
};

public void OnPluginStart() {
	g_hChargerBhop = CreateConVar("ai_charger_bhop", "1", "Flag to enable bhop facsimile on AI chargers");
	g_hChargeProximity = CreateConVar("ai_charge_proximity", "300.0", "How close a client will approach before charging");
	g_hHealthThreshold = CreateConVar("ai_health_threshold_charger", "300", "Charger will charge if its health drops to this level");
	g_hAimOffsetSensitivity = CreateConVar("ai_aim_offset_sensitivity_charger", "0", "If the charger has a target, it will not straight charge if the target's aim on the horizontal axis is within this radius", _, true, 0.0, true, 180.0);
	g_hChargeMaxSpeed = FindConVar("z_charge_max_speed");
	g_hChargeStartSpeed = FindConVar("z_charge_start_speed");

	g_hChargerBhop.AddChangeHook(vCvarChanged);
	g_hChargeProximity.AddChangeHook(vCvarChanged);
	g_hChargeMaxSpeed.AddChangeHook(vCvarChanged);
	g_hChargeStartSpeed.AddChangeHook(vCvarChanged);
	g_hHealthThreshold.AddChangeHook(vCvarChanged);
	g_hAimOffsetSensitivity.AddChangeHook(vCvarChanged);

	HookEvent("player_spawn", Event_PlayerSpawn);
	//HookEvent("charger_charge_start", Event_ChargerChargeStart);
}

public void OnConfigsExecuted() {
	vGetCvars();
}

void vCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	vGetCvars();
}

void vGetCvars() {
	g_bChargerBhop = g_hChargerBhop.BoolValue;
	g_fChargeMaxSpeed = g_hChargeMaxSpeed.FloatValue;
	g_fChargeStartSpeed = g_hChargeStartSpeed.FloatValue;
	g_fChargeProximity = g_hChargeProximity.FloatValue;
	g_iHealthThreshold = g_hHealthThreshold.IntValue;
	g_fAimOffsetSensitivity = g_hAimOffsetSensitivity.FloatValue;
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	g_bShouldCharge[GetClientOfUserId(event.GetInt("userid"))] = false;
}

/*void Event_ChargerChargeStart(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client) || !IsFakeClient(client))
		return;

	int flags = GetEntityFlags(client);
	SetEntityFlags(client, (flags & ~FL_FROZEN) & ~FL_ONGROUND);
	vCharger_OnCharge(client);
	SetEntityFlags(client, flags);
}*/

int g_iCurTarget[MAXPLAYERS + 1];
public Action L4D2_OnChooseVictim(int specialInfected, int &curTarget) {
	g_iCurTarget[specialInfected] = curTarget;
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons) {
	int flags = GetEntityFlags(client);
	if (!IsClientInGame(client) || !IsFakeClient(client) || GetClientTeam(client) != 3 || !IsPlayerAlive(client) || GetEntProp(client, Prop_Send, "m_zombieClass") != 6 || GetEntProp(client, Prop_Send, "m_isGhost") )
		return Plugin_Continue;

	static float fNearestSurDist;
	fNearestSurDist = fNearestSurDistance(client);
	if (fNearestSurDist > g_fChargeProximity && GetEntProp(client, Prop_Data, "m_iHealth") > g_iHealthThreshold) {
		if (!g_bShouldCharge[client])
			vResetAbilityTime(client, 0.1);
	}
	else
		g_bShouldCharge[client] = true;
		
	if (g_bShouldCharge[client] && bCanCharge(client)) {
		static int iTarget;
		iTarget = GetClientAimTarget(client, true);
		if (bIsAliveSur(iTarget) && !bIncapacitated(iTarget)) {
			static float vPos[3];
			static float vTar[3];
			GetClientAbsOrigin(client, vPos);
			GetClientAbsOrigin(iTarget, vTar);
			if (GetVectorDistance(vPos, vTar) < 150.0 && !bHitWall(client, iTarget) && (flags & FL_ONGROUND)) {
				buttons |= IN_ATTACK;
				buttons |= IN_ATTACK2;
				return Plugin_Changed;
			}
		}
	}

	if (!g_bChargerBhop || fCurTargetDistance(client) < 1.0 || fNearestSurDist > 99999 || !bIsGrounded(client) || GetEntityMoveType(client) == MOVETYPE_LADDER || GetEntProp(client, Prop_Data, "m_nWaterLevel") > 1/* || !GetEntProp(client, Prop_Send, "m_hasVisibleThreats")*/)
		return Plugin_Continue;

	static float vVel[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVel);
	if (SquareRoot(Pow(vVel[0], 2.0) + Pow(vVel[1], 2.0)) < GetEntPropFloat(client, Prop_Send, "m_flMaxspeed") - 10.0)
		return Plugin_Continue;

	static float vAng[3];
	GetClientEyeAngles(client, vAng);
	if(flags & FL_ONGROUND)
	{
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
		ScaleVector(vFwd, buttons & IN_FORWARD ? 60.0 : -60.0);
		bPressed = true;
	}

	if (buttons & IN_MOVERIGHT || buttons & IN_MOVELEFT) {
		GetAngleVectors(vAng, NULL_VECTOR, vRig, NULL_VECTOR);
		NormalizeVector(vRig, vRig);
		ScaleVector(vRig, buttons & IN_MOVERIGHT ? 60.0 : -60.0);
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
}

bool bHitWall(int client, int iTarget) {
	static float vPos[3];
	static float vTar[3];
	GetClientAbsOrigin(client, vPos);
	GetClientAbsOrigin(iTarget, vTar);
	vPos[2] += 10.0;
	vTar[2] += 10.0;

	MakeVectorFromPoints(vPos, vTar, vTar);
	static float fDist;
	fDist = GetVectorLength(vTar) - 49.0;
	NormalizeVector(vTar, vTar);
	ScaleVector(vTar, fDist <= 0.0 ? 0.0 : fDist);
	AddVectors(vPos, vTar, vTar);

	static float vMins[3];
	static float vMaxs[3];
	GetClientMins(client, vMins);
	GetClientMaxs(client, vMaxs);
	vMins[2] += 10.0;
	vMaxs[2] -= 10.0;

	static bool bDidHit;
	static Handle hTrace;
	hTrace = TR_TraceHullFilterEx(vPos, vTar, vMins, vMaxs, MASK_PLAYERSOLID_BRUSHONLY, bTraceEntityFilter);
	bDidHit = TR_DidHit(hTrace);
	delete hTrace;
	return bDidHit;
}

bool bCanCharge(int client) {
	if (GetEntPropEnt(client, Prop_Send, "m_pummelVictim") > 0 || GetEntPropEnt(client, Prop_Send, "m_carryVictim") > 0)
		return false;

	static int iEnt;
	iEnt = GetEntPropEnt(client, Prop_Send, "m_customAbility");
	return iEnt > MaxClients && !GetEntProp(iEnt, Prop_Send, "m_isCharging") && GetEntPropFloat(iEnt, Prop_Send, "m_timestamp") < GetGameTime();
}

void vResetAbilityTime(int client, float fTime)
{
	static int iEnt;
	iEnt = GetEntPropEnt(client, Prop_Send, "m_customAbility");
	if (iEnt > MaxClients)
		SetEntPropFloat(iEnt, Prop_Send, "m_timestamp", GetGameTime() + fTime);
}

#define PLAYER_HEIGHT	72.0
/*void vCharger_OnCharge(int client) {
	static int iTarget;
	iTarget = g_iCurTarget[client];//GetClientAimTarget(client, true);
	if (!bIsAliveSur(iTarget) || bIncapacitated(iTarget) || bIsPinned(iTarget) || bHitWall(client, iTarget) || bWithinViewAngle(client, iTarget, g_fAimOffsetSensitivity))
		iTarget = iGetClosestSur(client, iTarget, g_fChargeMaxSpeed);

	if (iTarget == -1)
		return;

	static float vVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vVelocity);

	static float vLength;
	vLength = GetVectorLength(vVelocity);
	vLength = vLength < g_fChargeStartSpeed ? g_fChargeStartSpeed : vLength;

	static float vPos[3];
	static float vTar[3];
	GetClientAbsOrigin(client, vPos);
	GetClientEyePosition(iTarget, vTar);
	float fDelta = vTar[2] - vPos[2];
	if (fDelta > PLAYER_HEIGHT)
		vLength += fDelta;

	if (GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") == -1)
		vLength += g_fChargeMaxSpeed;

	vTar[2] += GetVectorDistance(vPos, vTar) / vLength * PLAYER_HEIGHT;
	MakeVectorFromPoints(vPos, vTar, vVelocity);

	static float vAngles[3];
	GetVectorAngles(vVelocity, vAngles);
	NormalizeVector(vVelocity, vVelocity);
	ScaleVector(vVelocity, vLength);
	TeleportEntity(client, NULL_VECTOR, vAngles, vVelocity);
}*/

bool bIsAliveSur(int client) {
	return 0 < client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
}

bool bIncapacitated(int client) {
	return !!GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

/*bool bIsPinned(int client) {
	if (GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0)
		return true;
	if (GetEntPropEnt(client, Prop_Send, "m_carryAttacker") > 0)
		return true;
	if (GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0)
		return true;
	if (GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0)
		return true;
	if (GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0)
		return true;
	return false;
}*/

/*int iGetClosestSur(int client, int iExclude = -1, float fDistance) {
	static int i;
	static int iCount;
	static int iIndex;
	static float fDist;
	static float vAng[3];
	static float vSrc[3];
	static float vTar[3];
	static int iTargets[MAXPLAYERS + 1];
	
	iCount = 0;
	GetClientEyePosition(client, vSrc);
	iCount = GetClientsInRange(vSrc, RangeType_Visibility, iTargets, MAXPLAYERS);

	if (!iCount)
		return -1;

	static ArrayList aClients;
	aClients = new ArrayList(3);
	float fFOV = GetFOVDotProduct(g_fAimOffsetSensitivity);
	for (i = 0; i < iCount; i++) {
		if (iTargets[i] && iTargets[i] != iExclude && GetClientTeam(iTargets[i]) == 2 && IsPlayerAlive(iTargets[i]) && !bIncapacitated(iTargets[i]) && !bIsPinned(iTargets[i]) && !bHitWall(client, iTargets[i])) {
			GetClientEyePosition(iTargets[i], vTar);
			fDist = GetVectorDistance(vSrc, vTar);
			if (fDist < fDistance) {
				iIndex = aClients.Push(fDist);
				aClients.Set(iIndex, iTargets[i], 1);

				GetClientEyeAngles(iTargets[i], vAng);
				aClients.Set(iIndex, !PointWithinViewAngle(vTar, vSrc, vAng, fFOV) ? 0 : 1, 2);
			}
		}
	}

	if (!aClients.Length) {
		delete aClients;
		return -1;
	}

	aClients.Sort(Sort_Ascending, Sort_Float);
	iIndex = aClients.FindValue(0, 2);
	i = aClients.Get(iIndex != -1 && aClients.Get(iIndex, 0) < 0.5 * fDistance ? iIndex : 0, 1);
	delete aClients;
	return i;
}*/

/*bool bWithinViewAngle(int client, int iViewer, float fOffsetThreshold) {
	static float vSrc[3];
	static float vTar[3];
	static float vAng[3];
	GetClientEyePosition(iViewer, vSrc);
	GetClientEyePosition(client, vTar);
	if (bIsVisibleTo(vSrc, vTar)) {
		GetClientEyeAngles(iViewer, vAng);
		return PointWithinViewAngle(vSrc, vTar, vAng, GetFOVDotProduct(fOffsetThreshold));
	}

	return false;
}*/

// credits = "AtomicStryker"
/*bool bIsVisibleTo(const float vPos[3], const float vTarget[3]) {
	static float vAngles[3], vLookAt[3];
	MakeVectorFromPoints(vPos, vTarget, vLookAt); // compute vector from start to target
	GetVectorAngles(vLookAt, vAngles); // get angles from vector for trace

	// execute Trace
	static Handle hTrace;
	static bool bIsVisible;

	bIsVisible = false;
	hTrace = TR_TraceRayFilterEx(vPos, vAngles, MASK_ALL, RayType_Infinite, bTraceEntityFilter);
	if (TR_DidHit(hTrace)) {
		static float vStart[3];
		TR_GetEndPosition(vStart, hTrace); // retrieve our trace endpoint

		if ((GetVectorDistance(vPos, vStart, false) + 25.0) >= GetVectorDistance(vPos, vTarget))
			bIsVisible = true; // if trace ray length plus tolerance equal or bigger absolute distance, you hit the target
	}

	delete hTrace;
	return bIsVisible;
}*/

// https://github.com/nosoop/stocksoup

/**
 * Checks if a point is in the field of view of an object.  Supports up to 180 degree FOV.
 * I forgot how the dot product stuff works.
 * 
 * Direct port of the function of the same name from the Source SDK:
 * https://github.com/ValveSoftware/source-sdk-2013/blob/beaae8ac45a2f322a792404092d4482065bef7ef/sp/src/public/mathlib/vector.h#L461-L477
 * 
 * @param vecSrcPosition	Source position of the view.
 * @param vecTargetPosition	Point to check if within view angle.
 * @param vecLookDirection	The direction to look towards.  Note that this must be a forward
 * 							angle vector.
 * @param flCosHalfFOV		The width of the forward view cone as a dot product result. For
 * 							subclasses of CBaseCombatCharacter, you can use the
 * 							`m_flFieldOfView` data property.  To manually calculate for a
 * 							desired FOV, use `GetFOVDotProduct(angle)` from math.inc.
 * @return					True if the point is within view from the source position at the
 * 							specified FOV.
 */
/*bool PointWithinViewAngle(const float vecSrcPosition[3], const float vecTargetPosition[3], const float vecLookDirection[3], float flCosHalfFOV) {
	static float vecDelta[3];
	SubtractVectors(vecTargetPosition, vecSrcPosition, vecDelta);
	static float cosDiff;
	cosDiff = GetVectorDotProduct(vecLookDirection, vecDelta);
	if (cosDiff < 0.0)
		return false;

	// a/sqrt(b) > c  == a^2 > b * c ^2
	return cosDiff * cosDiff >= GetVectorLength(vecDelta, true) * flCosHalfFOV * flCosHalfFOV;
}*/

/**
 * Calculates the width of the forward view cone as a dot product result from the given angle.
 * This manually calculates the value of CBaseCombatCharacter's `m_flFieldOfView` data property.
 *
 * For reference: https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/server/hl2/npc_bullseye.cpp#L151
 *
 * @param angle     The FOV value in degree
 * @return          Width of the forward view cone as a dot product result
 */
/*float GetFOVDotProduct(float angle) {
	return Cosine(DegToRad(angle) / 2.0);
}*/
