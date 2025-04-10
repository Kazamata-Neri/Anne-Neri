Msg("Activating Mutation16\n");


DirectorOptions <-
{
	//藏特, 要改建议都改
	ActiveChallenge 			= 1
	cm_AggressiveSpecials 		= 1
	cm_ShouldHurry 			= 1
	ShouldAllowSpecialsWithTank 	= 1
	cm_SpecialRespawnInterval 		= 5

	cm_BaseSpecialLimit = 5		//一波的特感数量
	cm_MaxSpecials = 5		//场上允许特感存在的数量

	//每只特感最大数量限制
	HunterLimit = 	5
	SmokerLimit = 	0
	JockeyLimit = 	0
	ChargerLimit = 	0
	SpitterLimit = 	0
	BoomerLimit = 	0

	//控制型特感总数
	DominatorLimit = 28

	PreferredMobDirection = SPAWN_IN_FRONT_OF_SURVIVORS
	PreferredSpecialDirection = SPAWN_IN_FRONT_OF_SURVIVORS
}

MapData <-{
	g_nSI = 5
	g_nHUNTER = 5
	g_nSMOKER = 0
	g_nJOCKEY = 0
	g_nCHARGER = 0
	g_nSPITTER = 0
	g_nBOOMER = 0
	g_nSRI = 5
	last_set = 0
}

function Update()
{
	local htlm = Convars.GetStr("survival_max_specials");
	local time = Convars.GetStr("director_special_respawn_interval");
	switch (htlm) {
	case "4":
		MapData.g_nSI = 4
		MapData.g_nHUNTER = 4
		MapData.g_nSMOKER = 0
		MapData.g_nJOCKEY = 0
		MapData.g_nCHARGER = 0
		MapData.g_nSPITTER = 0
		MapData.g_nBOOMER = 0
		break;
	case "5":
		MapData.g_nSI = 5
		MapData.g_nHUNTER = 5
		MapData.g_nSMOKER = 0
		MapData.g_nJOCKEY = 0
		MapData.g_nCHARGER = 0
		MapData.g_nSPITTER = 0
		MapData.g_nBOOMER = 0
		break;
	case "6":
		MapData.g_nSI = 6
		MapData.g_nHUNTER = 6
		MapData.g_nSMOKER = 0
		MapData.g_nJOCKEY = 0
		MapData.g_nCHARGER = 0
		MapData.g_nSPITTER = 0
		MapData.g_nBOOMER = 0
		break;
	case "7":
		MapData.g_nSI = 7
		MapData.g_nHUNTER = 7
		MapData.g_nSMOKER = 0
		MapData.g_nJOCKEY = 0
		MapData.g_nCHARGER = 0
		MapData.g_nSPITTER = 0
		MapData.g_nBOOMER = 0
		break;
	case "8":
		MapData.g_nSI = 8
		MapData.g_nHUNTER = 8
		MapData.g_nSMOKER = 0
		MapData.g_nJOCKEY = 0
		MapData.g_nCHARGER = 0
		MapData.g_nSPITTER = 0
		MapData.g_nBOOMER = 0
		break;
	case "9":
		MapData.g_nSI = 9
		MapData.g_nHUNTER = 9
		MapData.g_nSMOKER = 0
		MapData.g_nJOCKEY = 0
		MapData.g_nCHARGER = 0
		MapData.g_nSPITTER = 0
		MapData.g_nBOOMER = 0
		break;
	case "10":
		MapData.g_nSI = 10
		MapData.g_nHUNTER = 10
		MapData.g_nSMOKER = 0
		MapData.g_nJOCKEY = 0
		MapData.g_nCHARGER = 0
		MapData.g_nSPITTER = 0
		MapData.g_nBOOMER = 0
		break;
	case "11":
		MapData.g_nSI = 11
		MapData.g_nHUNTER = 11
		MapData.g_nSMOKER = 0
		MapData.g_nJOCKEY = 0
		MapData.g_nCHARGER = 0
		MapData.g_nSPITTER = 0
		MapData.g_nBOOMER = 0
		break;
	case "12":
		MapData.g_nSI = 12
		MapData.g_nHUNTER = 12
		MapData.g_nSMOKER = 0
		MapData.g_nJOCKEY = 0
		MapData.g_nCHARGER = 0
		MapData.g_nSPITTER = 0
		MapData.g_nBOOMER = 0
		break;
	case "13":
		MapData.g_nSI = 13
		MapData.g_nHUNTER = 13
		MapData.g_nSMOKER = 0
		MapData.g_nJOCKEY = 0
		MapData.g_nCHARGER = 0
		MapData.g_nSPITTER = 0
		MapData.g_nBOOMER = 0
		break;
	case "14":
		MapData.g_nSI = 14
		MapData.g_nHUNTER = 14
		MapData.g_nSMOKER = 0
		MapData.g_nJOCKEY = 0
		MapData.g_nCHARGER = 0
		MapData.g_nSPITTER = 0
		MapData.g_nBOOMER = 0
		break;
	case "15":
		MapData.g_nSI = 15
		MapData.g_nHUNTER = 15
		MapData.g_nSMOKER = 0
		MapData.g_nJOCKEY = 0
		MapData.g_nCHARGER = 0
		MapData.g_nSPITTER = 0
		MapData.g_nBOOMER = 0
		break;
	case "16":
		MapData.g_nSI = 16
		MapData.g_nHUNTER = 16
		MapData.g_nSMOKER = 0
		MapData.g_nJOCKEY = 0
		MapData.g_nCHARGER = 0
		MapData.g_nSPITTER = 0
		MapData.g_nBOOMER = 0
		break;
	case "17":
		MapData.g_nSI = 17
		MapData.g_nHUNTER = 17
		MapData.g_nSMOKER = 0
		MapData.g_nJOCKEY = 0
		MapData.g_nCHARGER = 0
		MapData.g_nSPITTER = 0
		MapData.g_nBOOMER = 0
		break;
	case "18":
		MapData.g_nSI = 18
		MapData.g_nHUNTER = 18
		MapData.g_nSMOKER = 0
		MapData.g_nJOCKEY = 0
		MapData.g_nCHARGER = 0
		MapData.g_nSPITTER = 0
		MapData.g_nBOOMER = 0
		break;
	case "19":
		MapData.g_nSI = 19
		MapData.g_nHUNTER = 19
		MapData.g_nSMOKER = 0
		MapData.g_nJOCKEY = 0
		MapData.g_nCHARGER = 0
		MapData.g_nSPITTER = 0
		MapData.g_nBOOMER = 0
		break;
	case "20":
		MapData.g_nSI = 20
		MapData.g_nHUNTER = 20
		MapData.g_nSMOKER = 0
		MapData.g_nJOCKEY = 0
		MapData.g_nCHARGER = 0
		MapData.g_nSPITTER = 0
		MapData.g_nBOOMER = 0
		break;
	case "21":
		MapData.g_nSI = 21
		MapData.g_nHUNTER = 21
		MapData.g_nSMOKER = 0
		MapData.g_nJOCKEY = 0
		MapData.g_nCHARGER = 0
		MapData.g_nSPITTER = 0
		MapData.g_nBOOMER = 0
		break;
	case "22":
		MapData.g_nSI = 22
		MapData.g_nHUNTER = 22
		MapData.g_nSMOKER = 0
		MapData.g_nJOCKEY = 0
		MapData.g_nCHARGER = 0
		MapData.g_nSPITTER = 0
		MapData.g_nBOOMER = 0
		break;
	case "23":
		MapData.g_nSI = 23
		MapData.g_nHUNTER = 23
		MapData.g_nSMOKER = 0
		MapData.g_nJOCKEY = 0
		MapData.g_nCHARGER = 0
		MapData.g_nSPITTER = 0
		MapData.g_nBOOMER = 0
		break;
	case "24":
		MapData.g_nSI = 24
		MapData.g_nHUNTER = 24
		MapData.g_nSMOKER = 0
		MapData.g_nJOCKEY = 0
		MapData.g_nCHARGER = 0
		MapData.g_nSPITTER = 0
		MapData.g_nBOOMER = 0
		break;
	case "25":
		MapData.g_nSI = 25
		MapData.g_nHUNTER = 25
		MapData.g_nSMOKER = 0
		MapData.g_nJOCKEY = 0
		MapData.g_nCHARGER = 0
		MapData.g_nSPITTER = 0
		MapData.g_nBOOMER = 0
		break;
	case "26":
		MapData.g_nSI = 26
		MapData.g_nHUNTER = 26
		MapData.g_nSMOKER = 0
		MapData.g_nJOCKEY = 0
		MapData.g_nCHARGER = 0
		MapData.g_nSPITTER = 0
		MapData.g_nBOOMER = 0
		break;
	case "27":
		MapData.g_nSI = 27
		MapData.g_nHUNTER = 27
		MapData.g_nSMOKER = 0
		MapData.g_nJOCKEY = 0
		MapData.g_nCHARGER = 0
		MapData.g_nSPITTER = 0
		MapData.g_nBOOMER = 0
		break;
	case "28":
		MapData.g_nSI = 28
		MapData.g_nHUNTER = 28
		MapData.g_nSMOKER = 0
		MapData.g_nJOCKEY = 0
		MapData.g_nCHARGER = 0
		MapData.g_nSPITTER = 0
		MapData.g_nBOOMER = 0
		break;
	default:
		MapData.g_nSI = 5
		MapData.g_nHUNTER = 5
		MapData.g_nSMOKER = 0
		MapData.g_nJOCKEY = 0
		MapData.g_nCHARGER = 0
		MapData.g_nSPITTER = 0
		MapData.g_nBOOMER = 0
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