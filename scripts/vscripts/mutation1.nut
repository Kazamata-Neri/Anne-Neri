Msg("Activating Mutation 1\n");


DirectorOptions <-
{
	ActiveChallenge 			= 1
	cm_AggressiveSpecials 		= true
	cm_ShouldHurry 			= 1
	ShouldAllowSpecialsWithTank 	= 1
	ShouldAllowMobsWithTank 		= 0
	cm_SpecialRespawnInterval 		= 5

	//特感总数
	cm_BaseSpecialLimit = 8
	cm_MaxSpecials = 8

	//每只特感最大数量限制
	HunterLimit = 	3
	SmokerLimit = 	3
	JockeyLimit = 	3
	ChargerLimit = 	3
	SpitterLimit = 	2
	BoomerLimit = 	2

	//控制型特感总数
	DominatorLimit = 28

	//用于不藏特
	cm_AggressiveSpecials = 1

	PreferredMobDirection = SPAWN_IN_FRONT_OF_SURVIVORS
	PreferredSpecialDirection = SPAWN_IN_FRONT_OF_SURVIVORS
}

MapData <-{
	g_nSI = 8
	g_nHUNTER = 3
	g_nSMOKER = 3
	g_nJOCKEY = 3
	g_nCHARGER = 3
	g_nSPITTER = 2
	g_nBOOMER = 2
	g_nSRI = 5
	last_set = 0
}

function Update()
{
	local htlm = Convars.GetStr("survival_max_specials");
	local time = Convars.GetStr("director_special_respawn_interval");
	switch (htlm) {
	case "6":
		MapData.g_nSI = 6
		MapData.g_nHUNTER = 2
		MapData.g_nSMOKER = 2
		MapData.g_nJOCKEY = 2
		MapData.g_nCHARGER = 2
		MapData.g_nSPITTER = 2
		MapData.g_nBOOMER = 2
		break;
	case "7":
		MapData.g_nSI = 7
		MapData.g_nHUNTER = 2
		MapData.g_nSMOKER = 2
		MapData.g_nJOCKEY = 2
		MapData.g_nCHARGER = 2
		MapData.g_nSPITTER = 2
		MapData.g_nBOOMER = 2
		break;
	case "8":
		MapData.g_nSI = 8
		MapData.g_nHUNTER = 3
		MapData.g_nSMOKER = 3
		MapData.g_nJOCKEY = 3
		MapData.g_nCHARGER = 3
		MapData.g_nSPITTER = 2
		MapData.g_nBOOMER = 2
		break;
	case "9":
		MapData.g_nSI = 9
		MapData.g_nHUNTER = 3
		MapData.g_nSMOKER = 3
		MapData.g_nJOCKEY = 3
		MapData.g_nCHARGER = 3
		MapData.g_nSPITTER = 3
		MapData.g_nBOOMER = 3
		break;
	case "10":
		MapData.g_nSI = 10
		MapData.g_nHUNTER = 3
		MapData.g_nSMOKER = 3
		MapData.g_nJOCKEY = 3
		MapData.g_nCHARGER = 3
		MapData.g_nSPITTER = 3
		MapData.g_nBOOMER = 3
		break;
	case "11":
		MapData.g_nSI = 11
		MapData.g_nHUNTER = 3
		MapData.g_nSMOKER = 3
		MapData.g_nJOCKEY = 3
		MapData.g_nCHARGER = 3
		MapData.g_nSPITTER = 3
		MapData.g_nBOOMER = 3
		break;
	case "12":
		MapData.g_nSI = 12
		MapData.g_nHUNTER = 3
		MapData.g_nSMOKER = 3
		MapData.g_nJOCKEY = 3
		MapData.g_nCHARGER = 3
		MapData.g_nSPITTER = 3
		MapData.g_nBOOMER = 3
		break;
	case "13":
		MapData.g_nSI = 13
		MapData.g_nHUNTER = 4
		MapData.g_nSMOKER = 4
		MapData.g_nJOCKEY = 4
		MapData.g_nCHARGER = 4
		MapData.g_nSPITTER = 3
		MapData.g_nBOOMER = 3
		break;
	case "14":
		MapData.g_nSI = 14
		MapData.g_nHUNTER = 4
		MapData.g_nSMOKER = 4
		MapData.g_nJOCKEY = 4
		MapData.g_nCHARGER = 4
		MapData.g_nSPITTER = 3
		MapData.g_nBOOMER = 3
		break;
	case "15":
		MapData.g_nSI = 15
		MapData.g_nHUNTER = 4
		MapData.g_nSMOKER = 4
		MapData.g_nJOCKEY = 4
		MapData.g_nCHARGER = 4
		MapData.g_nSPITTER = 3
		MapData.g_nBOOMER = 3
		break;
	case "16":
		MapData.g_nSI = 16
		MapData.g_nHUNTER = 4
		MapData.g_nSMOKER = 4
		MapData.g_nJOCKEY = 4
		MapData.g_nCHARGER = 4
		MapData.g_nSPITTER = 3
		MapData.g_nBOOMER = 3
		break;
	case "17":
		MapData.g_nSI = 17
		MapData.g_nHUNTER = 4
		MapData.g_nSMOKER = 4
		MapData.g_nJOCKEY = 4
		MapData.g_nCHARGER = 4
		MapData.g_nSPITTER = 4
		MapData.g_nBOOMER = 4
		break;
	case "18":
		MapData.g_nSI = 18
		MapData.g_nHUNTER = 4
		MapData.g_nSMOKER = 4
		MapData.g_nJOCKEY = 4
		MapData.g_nCHARGER = 4
		MapData.g_nSPITTER = 4
		MapData.g_nBOOMER = 4
		break;
	case "19":
		MapData.g_nSI = 19
		MapData.g_nHUNTER = 4
		MapData.g_nSMOKER = 4
		MapData.g_nJOCKEY = 4
		MapData.g_nCHARGER = 4
		MapData.g_nSPITTER = 4
		MapData.g_nBOOMER = 4
		break;
	case "20":
		MapData.g_nSI = 20
		MapData.g_nHUNTER = 4
		MapData.g_nSMOKER = 4
		MapData.g_nJOCKEY = 4
		MapData.g_nCHARGER = 4
		MapData.g_nSPITTER = 4
		MapData.g_nBOOMER = 4
		break;
	case "21":
		MapData.g_nSI = 21
		MapData.g_nHUNTER = 5
		MapData.g_nSMOKER = 5
		MapData.g_nJOCKEY = 5
		MapData.g_nCHARGER = 5
		MapData.g_nSPITTER = 4
		MapData.g_nBOOMER = 4
		break;
	case "22":
		MapData.g_nSI = 22
		MapData.g_nHUNTER = 5
		MapData.g_nSMOKER = 5
		MapData.g_nJOCKEY = 5
		MapData.g_nCHARGER = 5
		MapData.g_nSPITTER = 4
		MapData.g_nBOOMER = 4
		break;
	case "23":
		MapData.g_nSI = 23
		MapData.g_nHUNTER = 5
		MapData.g_nSMOKER = 5
		MapData.g_nJOCKEY = 5
		MapData.g_nCHARGER = 5
		MapData.g_nSPITTER = 4
		MapData.g_nBOOMER = 4
		break;
	case "24":
		MapData.g_nSI = 24
		MapData.g_nHUNTER = 5
		MapData.g_nSMOKER = 5
		MapData.g_nJOCKEY = 5
		MapData.g_nCHARGER = 5
		MapData.g_nSPITTER = 4
		MapData.g_nBOOMER = 4
		break;
	case "25":
		MapData.g_nSI = 25
		MapData.g_nHUNTER = 5
		MapData.g_nSMOKER = 5
		MapData.g_nJOCKEY = 5
		MapData.g_nCHARGER = 5
		MapData.g_nSPITTER = 5
		MapData.g_nBOOMER = 5
		break;
	case "26":
		MapData.g_nSI = 26
		MapData.g_nHUNTER = 5
		MapData.g_nSMOKER = 5
		MapData.g_nJOCKEY = 5
		MapData.g_nCHARGER = 5
		MapData.g_nSPITTER = 5
		MapData.g_nBOOMER = 5
		break;
	case "27":
		MapData.g_nSI = 27
		MapData.g_nHUNTER = 5
		MapData.g_nSMOKER = 5
		MapData.g_nJOCKEY = 5
		MapData.g_nCHARGER = 5
		MapData.g_nSPITTER = 5
		MapData.g_nBOOMER = 5
		break;
	case "28":
		MapData.g_nSI = 28
		MapData.g_nHUNTER = 5
		MapData.g_nSMOKER = 5
		MapData.g_nJOCKEY = 5
		MapData.g_nCHARGER = 5
		MapData.g_nSPITTER = 5
		MapData.g_nBOOMER = 5
		break;
	default:
		MapData.g_nSI = 10
		MapData.g_nHUNTER = 3
		MapData.g_nSMOKER = 3
		MapData.g_nJOCKEY = 3
		MapData.g_nCHARGER = 3
		MapData.g_nSPITTER = 3
		MapData.g_nBOOMER = 3
		break;
	}
	switch (time) {
	case "0":
		MapData.g_nSRI = 0
		break;
	case "5":
		MapData.g_nSRI = 5
		break;
	case "10":
		MapData.g_nSRI = 10
		break;
	case "15":
		MapData.g_nSRI = 15
		break;
	case "20":
		MapData.g_nSRI = 20
		break;
	case "25":
		MapData.g_nSRI = 25
		break;
	case "30":
		MapData.g_nSRI = 30
		break;
	case "35":
		MapData.g_nSRI = 35
		break;
	case "40":
		MapData.g_nSRI = 40
		break;
	case "45":
		MapData.g_nSRI = 45
		break;
	default:
		MapData.g_nSRI = 5
		break;
	}
	//DirectorOptions.DominatorLimit = MapData.g_nSI
	DirectorOptions.cm_BaseSpecialLimit = MapData.g_nSI
	DirectorOptions.cm_MaxSpecials = MapData.g_nSI
	DirectorOptions.HunterLimit = MapData.g_nHUNTER
	DirectorOptions.SmokerLimit = MapData.g_nSMOKER
	DirectorOptions.JockeyLimit = MapData.g_nJOCKEY
	DirectorOptions.ChargerLimit = MapData.g_nCHARGER
	DirectorOptions.SpitterLimit = MapData.g_nSPITTER
	DirectorOptions.BoomerLimit = MapData.g_nBOOMER
	DirectorOptions.cm_SpecialRespawnInterval = MapData.g_nSRI

	interval = DirectorOptions.cm_SpecialRespawnInterval
	if(Time() >= MapData.last_set + interval)
	{
		Director.ResetSpecialTimers();
		MapData.last_set = Time();
	}
}