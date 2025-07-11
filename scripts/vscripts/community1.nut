Msg("Activating community1\n");


DirectorOptions <-
{
	ActiveChallenge 			= 1
	cm_AggressiveSpecials 		= true
	cm_ShouldHurry 			= 1
	ShouldAllowSpecialsWithTank 	= 1
	cm_SpecialRespawnInterval 		= 16

	//特感总数
	cm_BaseSpecialLimit = 7
	cm_MaxSpecials = 7

	//每只特感最大数量限制
	HunterLimit = 	3
	SmokerLimit = 	2
	JockeyLimit = 	3
	ChargerLimit = 	2
	SpitterLimit = 	1
	BoomerLimit = 	1

	//控制型特感总数
	DominatorLimit = 28

	//用于不藏特
	cm_AggressiveSpecials = 1

	PreferredMobDirection = SPAWN_IN_FRONT_OF_SURVIVORS
	PreferredSpecialDirection = SPAWN_IN_FRONT_OF_SURVIVORS
}

MapData <-{
	g_nSI = 7
	g_nHUNTER = 3
	g_nSMOKER = 2
	g_nJOCKEY = 3
	g_nCHARGER = 2
	g_nSPITTER = 1
	g_nBOOMER = 1
	g_nSRI = 16
	last_set = 0
}

function Update()
{
	local htlm = Convars.GetStr("survival_max_specials");
	local time = Convars.GetStr("director_special_respawn_interval");
	switch (htlm) {
	case "4":
		MapData.g_nSI = 4
		MapData.g_nHUNTER = 2
		MapData.g_nSMOKER = 1
		MapData.g_nJOCKEY = 1
		MapData.g_nCHARGER = 1
		MapData.g_nSPITTER = 0
		MapData.g_nBOOMER = 0
		break;
	case "5":
		MapData.g_nSI = 5
		MapData.g_nHUNTER = 2
		MapData.g_nSMOKER = 0
		MapData.g_nJOCKEY = 2
		MapData.g_nCHARGER = 1
		MapData.g_nSPITTER = 0
		MapData.g_nBOOMER = 1
		break;
	case "6":
		MapData.g_nSI = 6
		MapData.g_nHUNTER = 2
		MapData.g_nSMOKER = 1
		MapData.g_nJOCKEY = 2
		MapData.g_nCHARGER = 2
		MapData.g_nSPITTER = 1
		MapData.g_nBOOMER = 1
		break;
	case "7":
		MapData.g_nSI = 7
		MapData.g_nHUNTER = 3
		MapData.g_nSMOKER = 2
		MapData.g_nJOCKEY = 3
		MapData.g_nCHARGER = 2
		MapData.g_nSPITTER = 1
		MapData.g_nBOOMER = 1
		break;
	default:
		MapData.g_nSI = 7
		MapData.g_nHUNTER = 3
		MapData.g_nSMOKER = 2
		MapData.g_nJOCKEY = 3
		MapData.g_nCHARGER = 2
		MapData.g_nSPITTER = 1
		MapData.g_nBOOMER = 1
		break;
	}
	switch (time) {
	case "0":
		MapData.g_nSRI = 0
		break;
	case "1":
		MapData.g_nSRI = 1
		break;
	case "2":
		MapData.g_nSRI = 2
		break;
	case "3":
		MapData.g_nSRI = 3
		break;
	case "4":
		MapData.g_nSRI = 4
		break;
	case "5":
		MapData.g_nSRI = 5
		break;
	case "6":
		MapData.g_nSRI = 6
		break;
	case "7":
		MapData.g_nSRI = 7
		break;
	case "8":
		MapData.g_nSRI = 8
		break;
	case "9":
		MapData.g_nSRI = 9
		break;
	case "10":
		MapData.g_nSRI = 10
		break;
	case "11":
		MapData.g_nSRI = 11
		break;
	case "12":
		MapData.g_nSRI = 12
		break;
	case "13":
		MapData.g_nSRI = 13
		break;
	case "14":
		MapData.g_nSRI = 14
		break;
	case "15":
		MapData.g_nSRI = 15
		break;
	case "16":
		MapData.g_nSRI = 16
		break;
	case "17":
		MapData.g_nSRI = 17
		break;
	case "18":
		MapData.g_nSRI = 18
		break;
	case "19":
		MapData.g_nSRI = 19
		break;
	case "20":
		MapData.g_nSRI = 20
		break;
	default:
		MapData.g_nSRI = 16
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