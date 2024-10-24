Msg("Activating Mutation 4\n");


DirectorOptions <-
{
	ActiveChallenge = 1
	cm_ShouldHurry = 1

	cm_BaseSpecialLimit = 12	//一波的特感数量
	cm_MaxSpecials = 12	//场上允许特感存在的数量

	cm_SpecialRespawnInterval 		= 15

	//每只特感最大数量限制
	HunterLimit = 	3
	SmokerLimit = 	3
	JockeyLimit = 	3
	ChargerLimit = 	3
	SpitterLimit = 	3
	BoomerLimit = 	3

	//控制型特感总数
	DominatorLimit = 28

	//用于是否藏特	1=不藏特/0 = 藏特
	cm_AggressiveSpecials = 1
}

MapData <-{
	g_nBSI = 12
	g_nMSI = 12
	g_nHUNTER = 3
	g_nSMOKER = 3
	g_nJOCKEY = 3
	g_nCHARGER = 3
	g_nSPITTER = 3
	g_nBOOMER = 3
	g_nAS = 1
	g_nSRI = 5
	last_set = 0
}

function Update()
{
	local htlm = Convars.GetStr("survival_max_specials");
	local time = Convars.GetStr("director_special_respawn_interval");
	switch (htlm) {
////////////////////////////////战役写实部分////////////////////////////////
	case "2":
		MapData.g_nBSI = 3
		MapData.g_nMSI = 2
		MapData.g_nHUNTER = 1
		MapData.g_nSMOKER = 1
		MapData.g_nJOCKEY = 1
		MapData.g_nCHARGER = 1
		MapData.g_nSPITTER = 1
		MapData.g_nBOOMER = 1
		MapData.g_nAS = 0
		break;
	case "3":
		MapData.g_nBSI = 3
		MapData.g_nMSI = 3
		MapData.g_nHUNTER = 1
		MapData.g_nSMOKER = 1
		MapData.g_nJOCKEY = 1
		MapData.g_nCHARGER = 1
		MapData.g_nSPITTER = 1
		MapData.g_nBOOMER = 1
		MapData.g_nAS = 0
		break;
	case "4":
		MapData.g_nBSI = 4
		MapData.g_nMSI = 4
		MapData.g_nHUNTER = 1
		MapData.g_nSMOKER = 1
		MapData.g_nJOCKEY = 1
		MapData.g_nCHARGER = 1
		MapData.g_nSPITTER = 1
		MapData.g_nBOOMER = 1
		MapData.g_nAS = 0
		break;
	case "5":
		MapData.g_nBSI = 5
		MapData.g_nMSI = 5
		MapData.g_nHUNTER = 1
		MapData.g_nSMOKER = 1
		MapData.g_nJOCKEY = 1
		MapData.g_nCHARGER = 1
		MapData.g_nSPITTER = 1
		MapData.g_nBOOMER = 1
		MapData.g_nAS = 0
		break;
	case "6":
		MapData.g_nBSI = 6
		MapData.g_nMSI = 6
		MapData.g_nHUNTER = 1
		MapData.g_nSMOKER = 1
		MapData.g_nJOCKEY = 1
		MapData.g_nCHARGER = 1
		MapData.g_nSPITTER = 1
		MapData.g_nBOOMER = 1
		MapData.g_nAS = 0
		break;
////////////////////////////////绝境求生部分////////////////////////////////
	case "8":
		MapData.g_nBSI = 8
		MapData.g_nMSI = 8
		MapData.g_nHUNTER = 3
		MapData.g_nSMOKER = 3
		MapData.g_nJOCKEY = 3
		MapData.g_nCHARGER = 3
		MapData.g_nSPITTER = 2
		MapData.g_nBOOMER = 2
		MapData.g_nAS = 1
		break;
	case "9":
		MapData.g_nBSI = 9
		MapData.g_nMSI = 9
		MapData.g_nHUNTER = 3
		MapData.g_nSMOKER = 3
		MapData.g_nJOCKEY = 3
		MapData.g_nCHARGER = 3
		MapData.g_nSPITTER = 3
		MapData.g_nBOOMER = 3
		MapData.g_nAS = 1
		break;
	case "10":
		MapData.g_nBSI = 10
		MapData.g_nMSI = 10
		MapData.g_nHUNTER = 3
		MapData.g_nSMOKER = 3
		MapData.g_nJOCKEY = 3
		MapData.g_nCHARGER = 3
		MapData.g_nSPITTER = 3
		MapData.g_nBOOMER = 3
		MapData.g_nAS = 1
		break;
	case "11":
		MapData.g_nBSI = 11
		MapData.g_nMSI = 11
		MapData.g_nHUNTER = 3
		MapData.g_nSMOKER = 3
		MapData.g_nJOCKEY = 3
		MapData.g_nCHARGER = 3
		MapData.g_nSPITTER = 3
		MapData.g_nBOOMER = 3
		MapData.g_nAS = 1
		break;
	case "12":
		MapData.g_nBSI = 12
		MapData.g_nMSI = 12
		MapData.g_nHUNTER = 3
		MapData.g_nSMOKER = 3
		MapData.g_nJOCKEY = 3
		MapData.g_nCHARGER = 3
		MapData.g_nSPITTER = 3
		MapData.g_nBOOMER = 3
		MapData.g_nAS = 1
		break;
	case "13":
		MapData.g_nBSI = 13
		MapData.g_nMSI = 13
		MapData.g_nHUNTER = 4
		MapData.g_nSMOKER = 4
		MapData.g_nJOCKEY = 4
		MapData.g_nCHARGER = 4
		MapData.g_nSPITTER = 3
		MapData.g_nBOOMER = 3
		MapData.g_nAS = 1
		break;
	case "14":
		MapData.g_nBSI = 14
		MapData.g_nMSI = 14
		MapData.g_nHUNTER = 4
		MapData.g_nSMOKER = 4
		MapData.g_nJOCKEY = 4
		MapData.g_nCHARGER = 4
		MapData.g_nSPITTER = 3
		MapData.g_nBOOMER = 3
		MapData.g_nAS = 1
		break;
	case "15":
		MapData.g_nBSI = 15
		MapData.g_nMSI = 15
		MapData.g_nHUNTER = 4
		MapData.g_nSMOKER = 4
		MapData.g_nJOCKEY = 4
		MapData.g_nCHARGER = 4
		MapData.g_nSPITTER = 3
		MapData.g_nBOOMER = 3
		MapData.g_nAS = 1
		break;
	case "16":
		MapData.g_nBSI = 16
		MapData.g_nMSI = 16
		MapData.g_nHUNTER = 4
		MapData.g_nSMOKER = 4
		MapData.g_nJOCKEY = 4
		MapData.g_nCHARGER = 4
		MapData.g_nSPITTER = 3
		MapData.g_nBOOMER = 3
		MapData.g_nAS = 1
		break;
	case "17":
		MapData.g_nBSI = 17
		MapData.g_nMSI = 17
		MapData.g_nHUNTER = 4
		MapData.g_nSMOKER = 4
		MapData.g_nJOCKEY = 4
		MapData.g_nCHARGER = 4
		MapData.g_nSPITTER = 4
		MapData.g_nBOOMER = 4
		MapData.g_nAS = 1
		break;
	case "18":
		MapData.g_nBSI = 18
		MapData.g_nMSI = 18
		MapData.g_nHUNTER = 4
		MapData.g_nSMOKER = 4
		MapData.g_nJOCKEY = 4
		MapData.g_nCHARGER = 4
		MapData.g_nSPITTER = 4
		MapData.g_nBOOMER = 4
		MapData.g_nAS = 1
		break;
	case "19":
		MapData.g_nBSI = 19
		MapData.g_nMSI = 19
		MapData.g_nHUNTER = 4
		MapData.g_nSMOKER = 4
		MapData.g_nJOCKEY = 4
		MapData.g_nCHARGER = 4
		MapData.g_nSPITTER = 4
		MapData.g_nBOOMER = 4
		MapData.g_nAS = 1
		break;
	case "20":
		MapData.g_nBSI = 20
		MapData.g_nMSI = 20
		MapData.g_nHUNTER = 4
		MapData.g_nSMOKER = 4
		MapData.g_nJOCKEY = 4
		MapData.g_nCHARGER = 4
		MapData.g_nSPITTER = 4
		MapData.g_nBOOMER = 4
		MapData.g_nAS = 1
		break;
	case "21":
		MapData.g_nBSI = 21
		MapData.g_nMSI = 21
		MapData.g_nHUNTER = 5
		MapData.g_nSMOKER = 5
		MapData.g_nJOCKEY = 5
		MapData.g_nCHARGER = 5
		MapData.g_nSPITTER = 4
		MapData.g_nBOOMER = 4
		MapData.g_nAS = 1
		break;
	case "22":
		MapData.g_nBSI = 22
		MapData.g_nMSI = 22
		MapData.g_nHUNTER = 5
		MapData.g_nSMOKER = 5
		MapData.g_nJOCKEY = 5
		MapData.g_nCHARGER = 5
		MapData.g_nSPITTER = 4
		MapData.g_nBOOMER = 4
		MapData.g_nAS = 1
		break;
	case "23":
		MapData.g_nBSI = 23
		MapData.g_nMSI = 23
		MapData.g_nHUNTER = 5
		MapData.g_nSMOKER = 5
		MapData.g_nJOCKEY = 5
		MapData.g_nCHARGER = 5
		MapData.g_nSPITTER = 4
		MapData.g_nBOOMER = 4
		MapData.g_nAS = 1
		break;
	case "24":
		MapData.g_nBSI = 24
		MapData.g_nMSI = 24
		MapData.g_nHUNTER = 5
		MapData.g_nSMOKER = 5
		MapData.g_nJOCKEY = 5
		MapData.g_nCHARGER = 5
		MapData.g_nSPITTER = 4
		MapData.g_nBOOMER = 4
		MapData.g_nAS = 1
		break;
	case "25":
		MapData.g_nBSI = 25
		MapData.g_nMSI = 25
		MapData.g_nHUNTER = 5
		MapData.g_nSMOKER = 5
		MapData.g_nJOCKEY = 5
		MapData.g_nCHARGER = 5
		MapData.g_nSPITTER = 5
		MapData.g_nBOOMER = 5
		MapData.g_nAS = 1
		break;
	case "26":
		MapData.g_nBSI = 26
		MapData.g_nMSI = 26
		MapData.g_nHUNTER = 5
		MapData.g_nSMOKER = 5
		MapData.g_nJOCKEY = 5
		MapData.g_nCHARGER = 5
		MapData.g_nSPITTER = 5
		MapData.g_nBOOMER = 5
		MapData.g_nAS = 1
		break;
	case "27":
		MapData.g_nBSI = 27
		MapData.g_nMSI = 27
		MapData.g_nHUNTER = 5
		MapData.g_nSMOKER = 5
		MapData.g_nJOCKEY = 5
		MapData.g_nCHARGER = 5
		MapData.g_nSPITTER = 5
		MapData.g_nBOOMER = 5
		MapData.g_nAS = 1
		break;
	case "28":
		MapData.g_nBSI = 28
		MapData.g_nMSI = 28
		MapData.g_nHUNTER = 5
		MapData.g_nSMOKER = 5
		MapData.g_nJOCKEY = 5
		MapData.g_nCHARGER = 5
		MapData.g_nSPITTER = 5
		MapData.g_nBOOMER = 5
		MapData.g_nAS = 1
		break;
	default:
		MapData.g_nBSI = 12
		MapData.g_nMSI = 12
		MapData.g_nHUNTER = 3
		MapData.g_nSMOKER = 3
		MapData.g_nJOCKEY = 3
		MapData.g_nCHARGER = 3
		MapData.g_nSPITTER = 3
		MapData.g_nBOOMER = 3
		MapData.g_nAS = 1
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
	DirectorOptions.cm_BaseSpecialLimit = MapData.g_nBSI
	DirectorOptions.cm_MaxSpecials = MapData.g_nMSI
	DirectorOptions.HunterLimit = MapData.g_nHUNTER
	DirectorOptions.SmokerLimit = MapData.g_nSMOKER
	DirectorOptions.JockeyLimit = MapData.g_nJOCKEY
	DirectorOptions.ChargerLimit = MapData.g_nCHARGER
	DirectorOptions.SpitterLimit = MapData.g_nSPITTER
	DirectorOptions.BoomerLimit = MapData.g_nBOOMER
	DirectorOptions.cm_AggressiveSpecials = MapData.g_nAS
	DirectorOptions.cm_SpecialRespawnInterval = MapData.g_nSRI

	interval = DirectorOptions.cm_SpecialRespawnInterval
	if(Time() >= MapData.last_set + interval)
	{
		Director.ResetSpecialTimers();
		MapData.last_set = Time();
	}
}