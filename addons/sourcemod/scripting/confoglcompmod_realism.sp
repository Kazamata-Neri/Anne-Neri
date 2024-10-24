#pragma semicolon 1

#if defined(AUTOVERSION)
#include "version.inc"
#else
#define PLUGIN_VERSION	"2021-07-07"
#endif

#if !defined(DEBUG_ALL)
#define DEBUG_ALL 	0
#endif

#include <sourcemod>
#include <sdktools>
#include <socket>
#include <sdkhooks>
#include <left4dhooks>
#include "includes/constants.sp"
#include "includes/functions.sp"
#include "includes/debug.sp"
#include "includes/survivorindex.sp"
#include "includes/configs.sp"
#include "includes/customtags.inc"
#include "modules/ReqMatch.sp"
#include "modules/CvarSettings.sp"
#include "modules/ClientSettings.sp"

public Plugin:myinfo = 
{
	name = "Confogl's Competitive Mod",
	author = "Confogl Team",
	description = "A competitive mod for L4D2",
	version = PLUGIN_VERSION,
	url = "http://confogl.googlecode.com/"
}

public OnPluginStart()
{
	Debug_OnModuleStart();
	Configs_OnModuleStart();
	SI_OnModuleStart();
	RM_OnModuleStart();
	CVS_OnModuleStart();
	CLS_OnModuleStart();
	AddCustomServerTag("Anne", true);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RM_APL();
	Configs_APL();

	RegPluginLibrary("confogl");
}

public OnPluginEnd()
{
	CVS_OnModuleEnd();

	RemoveCustomServerTag("Anne");
}

public OnMapStart()
{

	RM_OnMapStart();


}

public OnMapEnd()
{

}
public Action L4D_OnHasConfigurableDifficulty(int &retVal)
{
	retVal = 1;
	return Plugin_Handled;
}

public OnConfigsExecuted()
{
	CVS_OnConfigsExecuted();
}

public OnClientPutInServer(client)
{
	RM_OnClientPutInServer();
}