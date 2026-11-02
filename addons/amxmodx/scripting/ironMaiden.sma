/*
*
*	Iron Maiden by RedSMURF
*
*
*	Description:
*
*	Cvars:
*		None
*
*   Commands:
*       say /maiden [name | all]       "Opens the Maiden menu or executes the specified player(s)."
*       say_team /maiden [name | all]  "Opens the Maiden menu or executes the specified player(s)."
*       ironmaiden_reload                 "Reloads the configuration file."
*
*	Changelog:
*       v1.0: Initial release.
*
*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#if !defined MAX_PLAYERS
    #define MAX_PLAYERS 32
#endif

#if !defined MAX_VALUE_LENGTH
    #define MAX_VALUE_LENGTH 64
#endif

#if !defined MAX_RESOURCE_PATH_LENGTH
    #define MAX_RESOURCE_PATH_LENGTH 128
#endif

#if !defined MAX_FILE_CELL_SIZE
    #define MAX_FILE_CELL_SIZE 192
#endif

#if !defined MAX_PLATFORM_PATH_LENGTH
    #define MAX_PLATFORM_PATH_LENGTH 256
#endif

#define MAX_ENT                     32
#define MAIDEN_CHECK                10.0
#define MAIDEN_OFFSET_BASE          120.0
#define MAIDEN_OFFSET_MIN           65.0
#define MAIDEN_OFFSET_MAX           900.0
#define MAIDEN_OFFSET_STEP          10.0
#define MAIDEN_GHOST_ALPHA          120
#define MAIDEN_ROTATION_STEP        22.5
#define ADMIN_ACCESS                ADMIN_RCON
#define PDATA_NEXT_ATTACK           83
#define XO_CBASEPLAYER              5
#define XO_CBASEPLAYERWEAPON        4
#define MAIDEN_KEY                  111110
#define MAIDEN_ARRAY_ITEM           pev_iuser1
#define VIEW_FORWARD_OFFSET         192.0
#define VIEW_RIGHT_OFFSET           64.0
#define VIEW_UP_OFFSET              32.0
#define HUD_Y_STEP                  0.025
#define HUD_Y_MAX                   0.7
#define MAIDEN_DURATION_OPEN        3.10
#define MAIDEN_DURATION_CLOSE       0.69
#define MAIDEN_SEQ_OPENED           0
#define MAIDEN_SEQ_CLOSED           1
#define MAIDEN_SEQ_OPEN             2
#define MAIDEN_SEQ_CLOSE            3
#define SOUND_NAV                   "buttons/blip1.wav"
#define SOUND_REMOVE                "buttons/button10.wav"
#define SOUND_ALERT                 "buttons/bell1.wav"

new const PLUGIN_VERSION[]          = "1.0"
new const Float:DELAY_ON_LOAD       = 2.0
new const ERROR_FILE[]              = "IronMaiden_ERRORS.log"

enum
{
    SECTION_NONE,
    SECTION_MAIN_SETTINGS,
    SECTION_MAIDEN
}

enum
{
    DTYPE_INT,
    DTYPE_FLOAT,
    DTYPE_FLAGS,
    DTYPE_STRING_MODEL,
    DTYPE_STRING_SOUND,
    DTYPE_ARRAY_MESSAGE,
    DTYPE_ARRAY_MODEL,
    DTYPE_ARRAY_SOUND,
    DTYPE_STRING_MODEL_ID,
    DTYPE_ARRAY_MODEL_ID
}

enum
{
    FLAG_SHOW               = (1 << 0),
    FLAG_GHOST              = (1 << 1),
    FLAG_GROUND             = (1 << 2),
    FLAG_ACTIVE             = (1 << 3),
    FLAG_USED               = (1 << 4)
}

enum
{
    TEAM_NONE,
    TEAM_T,
    TEAM_CT,
    TEAM_BOTH
}

enum
{
    TARGET_GHOST,
    TARGET_SELECT,
    TARGET_HIDE,
    TARGET_CLEAR
}

enum _:MAIN_SETTINGS
{
    SETTING_DEFAULT_MODEL[MAX_RESOURCE_PATH_LENGTH],
    Array:SETTING_DEFAULT_SOUND,
    Array:SETTING_DEFAULT_SOUND_OPEN,
    Array:SETTING_DEFAULT_SOUND_CLOSE,
    Array:SETTING_DEFAULT_MESSAGE,
    Array:SETTING_DEFAULT_MESSAGE_FORCED,
    SETTING_DEFAULT_FLAGS,
    SETTING_DEFAULT_TEAM,
    Float:SETTING_DEFAULT_FRAMERATE,
    SETTING_DEFAULT_HOLD_DURATION[2],
    Float:SETTING_DEFAULT_COOLDOWN[2],
    Float:SETTING_DEFAULT_SHAKE_DISTANCE,
    SETTING_DEFAULT_SHAKE_AMPLITUDE,
    SETTING_DEFAULT_SHAKE_FREQUENCY,
    SETTING_DEFAULT_SHAKE_DURATION,
    bool:SETTING_PLAY_SOUND_ON_DEATH,
    bool:SETTING_WRITE_MESSAGE_ON_DEATH,
    bool:SETTING_KILL_ALL_EXCLUDE_CALLER,

    Float:SETTING_HUD_X,
    Float:SETTING_HUD_Y,
    SETTING_HUD_COLOR[3],
    SETTING_HUD_EFFECT,
    Float:SETTING_HUD_FXTIME,
    Float:SETTING_HUD_HOLDTIME,
    Float:SETTING_HUD_FADEIN,
    Float:SETTING_HUD_FADEOUT,

    Float:SETTING_MINS[3],
    Float:SETTING_MAXS[3],

    bool:SETTING_MAIDEN_LOAD,
    Float:SETTING_MAIDEN_TASK,
}

enum _:MAIDEN
{
    MAIDEN_ID,
    MAIDEN_ITEM,
    MAIDEN_FLAGS,
    MAIDEN_TEAM,
    MAIDEN_VIEW,
    MAIDEN_NAME[MAX_VALUE_LENGTH],
    Float:MAIDEN_COOLDOWN[2],
    Float:MAIDEN_FRAMERATE,

    Float:MAIDEN_ORIGIN[3],
    Float:MAIDEN_ANGLES[3],
    Float:MAIDEN_MINS[3],
    Float:MAIDEN_MAXS[3],

    Float:MAIDEN_NEXT_ACTIVE,
    Float:MAIDEN_NEXT_OPEN
}

enum _:PLAYER_DATA
{
    PDATA_MAIDEN_GHOST,
    PDATA_MAIDEN_MENU,
    bool:PDATA_MAIDEN_ACTION,
    PDATA_MAIDEN_ID,
    Float:PDATA_OFFSET,
    Float:PDATA_NEXT_OFFSET,

    PDATA_MENU_TYPE,
    bool:PDATA_MENU_TRACE,

    Float:PDATA_NEXT_MAIDEN,
    Float:PDATA_NEXT_CHECK,
    Float:PDATA_NEXT_DIE
}

enum
{
    SOUND_MENU_NAV,
    SOUND_MENU_REMOVE,
    SOUND_MENU_ALERT,
    SOUND_MAIDEN,
    SOUND_OPEN,
    SOUND_CLOSE
}

enum
{
    MENU_ROOT,
    MENU_CREATE,
    MENU_EDIT,
    MENU_REMOVE,
    MENU_SHOW,
    MENU_STATUS,
    MENU_ROTATE
}

enum
{
    ROOT_CREATE,
    ROOT_EDIT,
    ROOT_REMOVE,
    ROOT_SAVE,

    ROOT_NOCLIP = 5,
    ROOT_GODMODE
}

enum
{
    EDIT_SHOW,
    EDIT_STATUS
}

enum
{
    REMOVE_NEXT,
    REMOVE_BACK,

    REMOVE_CURRENT = 3,
    REMOVE_ALL
}

enum
{
    SHOW_NEXT,
    SHOW_BACK,

    SHOW_CURRENT = 3,
    SHOW_ALL_SHOW,
    SHOW_ALL_HIDE
}

enum
{
    STATUS_NEXT,
    STATUS_BACK,

    STATUS_CURRENT = 3,
    STATUS_ALL_ENABLE,
    STATUS_ALL_DISABLE
}

enum
{
    ROTATE_UP,
    ROTATE_DOWN,

    ROTATE_GROUND = 3,
    ROTATE_PLACE
}

new Float:g_fDirections[][] =
{
    {-1.0, 0.0, 0.0},
    {1.0, 0.0, 0.0},
    {0.0, -1.0, 0.0},
    {0.0, 1.0, 0.0},
    {0.0, 0.0, -1.0},
    {0.0, 0.0, 1.0}
}

new g_szMenuHandler[][MAX_VALUE_LENGTH] =
{
    "menuHandlerRoot",
    "menuHandlerCreate",
    "menuHandlerEdit",
    "menuHandlerRemove",
    "menuHandlerShow",
    "menuHandlerStatus",
    "menuHandlerRotate"
}

new g_szCN[] = "ironmaiden"

new Array:g_aMaiden,
    Array:g_aMaidenConfig,
    g_eSettings[MAIN_SETTINGS],
    g_ePlayerData[MAX_PLAYERS + 1][PLAYER_DATA],
    bool:g_bFileWasRead, g_iActivePlayers,
    HamHook:g_iFwdUse, HamHook:g_iFwdObjectCaps, HamHook:g_iFwdPreThink,
    g_iMaiden, g_iMaidenConfig, g_iBarTime, Float:g_iHudCurrentY, g_iHudObject_1, g_iHudObject_2, g_iHudObject_3, g_iHudSlot,
    g_iMaxPlayers, g_iSilentVictim, g_iScreenShake

new Float:g_fPlayerOffset[] = { 0.0, 0.0, -9.0 }
new g_szModelRPG[MAX_RESOURCE_PATH_LENGTH] = "models/w_rpg.mdl"

public plugin_init()
{
    register_plugin("Iron Maiden", PLUGIN_VERSION, "RedSMURF")
    register_cvar("RedSMURF_IronMaiden", PLUGIN_VERSION, ADMIN_ACCESS)

    register_clcmd("say /maiden",       "cmdMenu", ADMIN_ACCESS, "-- Opens the Maiden menu.")
    register_clcmd("say_team /maiden",  "cmdMenu", ADMIN_ACCESS, "-- Opens the Maiden menu.")
    register_concmd("ironmaiden_reload",  "cmdReload", ADMIN_ACCESS, "-- Reloads the configuration file")
    register_dictionary("IronMaiden.txt")

    g_iFwdUse = RegisterHam(Ham_Use, "info_target", "fwdUse")
    g_iFwdObjectCaps = RegisterHam(Ham_ObjectCaps, "info_target", "fwdObjectCaps")
    g_iFwdPreThink = RegisterHam(Ham_Player_PreThink, "player", "fwdPreThink")
    RegisterHam(Ham_Killed, "player", "fwdKilled", 1)
    g_iBarTime = get_user_msgid("BarTime")
    g_iScreenShake = get_user_msgid("ScreenShake")
    g_iHudObject_1 = CreateHudSyncObj()
    g_iHudObject_2 = CreateHudSyncObj()
    g_iHudObject_3 = CreateHudSyncObj()
    register_logevent("eventRoundStart", 2, "1=Round_Start")
    DisableForward()
    DisableMaiden()

    maidenInit()
    g_iMaxPlayers = get_maxplayers()
}

public plugin_precache()
{
    g_aMaiden = ArrayCreate(MAIDEN)
    g_aMaidenConfig = ArrayCreate(MAIDEN)
    g_eSettings[SETTING_DEFAULT_SOUND] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)
    g_eSettings[SETTING_DEFAULT_SOUND_OPEN] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)
    g_eSettings[SETTING_DEFAULT_SOUND_CLOSE] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)
    g_eSettings[SETTING_DEFAULT_MESSAGE] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)
    g_eSettings[SETTING_DEFAULT_MESSAGE_FORCED] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)

    precache_model(g_szModelRPG)
    ReadFile()
}

public plugin_end()
{
    ArrayDestroy(g_aMaiden)
    ArrayDestroy(g_aMaidenConfig)
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_SOUND])
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_SOUND_OPEN])
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_SOUND_CLOSE])
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_MESSAGE])
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_MESSAGE_FORCED])
}

public cmdMenu(id, iLevel, iCmd)
{
    if ( !cmd_access(id, iLevel, iCmd, 1) )
        return PLUGIN_HANDLED

    new szTarget[64]
    read_argv(2, szTarget, charsmax(szTarget))
    remove_quotes(szTarget)
    if ( !szTarget[0] )
    {
        maidenSound(id, SOUND_MENU_NAV)
        maidenMenu(id, MENU_ROOT)
        return PLUGIN_HANDLED
    }

    new eMaiden[MAIDEN], bool:bFoundMaiden
    new iArgIndex = 2
    new bool:bProcessed[33]
    while ( szTarget[0] )
    {
        if ( equali(szTarget, "all") )
        {
            for ( new iTarget = 1; iTarget <= g_iMaxPlayers; iTarget ++ )
            {
                if ( !is_user_connected(iTarget) || bProcessed[iTarget]
                || (g_eSettings[SETTING_KILL_ALL_EXCLUDE_CALLER] && iTarget == id) )
                    continue

                bProcessed[iTarget] = true
                if ( !is_user_alive(iTarget) )
                    continue

                bFoundMaiden = false
                for ( new iItem = 0; iItem < g_iMaiden; iItem ++ )
                {
                    ArrayGetArray(g_aMaiden, iItem, eMaiden)
                    if ( eMaiden[MAIDEN_FLAGS] & FLAG_USED )
                        continue

                    maidenMaiden(eMaiden, iTarget, true)
                    ArraySetArray(g_aMaiden, iItem, eMaiden)
                    bFoundMaiden = true
                    break
                }

                if ( !bFoundMaiden )
                {
                    client_print_color(id, id, "%L %L", id, "MAIDEN_CHAT_TAG", id, "MAIDEN_CHAT_NO_MAIDEN")
                    break
                }
            }
        }
        else
        {
            new iTarget = cmd_target(id, szTarget, CMDTARGET_ALLOW_SELF)
            if ( iTarget && !bProcessed[iTarget] )
            {
                bProcessed[iTarget] = true
                if ( !is_user_alive(iTarget) )
                {
                    client_print_color(id, id, "%L %L", id, "MAIDEN_CHAT_TAG", id, "MAIDEN_CHAT_NOT_ALIVE")
                }
                else
                {
                    bFoundMaiden = false
                    for ( new iItem = 0; iItem < g_iMaiden; iItem ++ )
                    {
                        ArrayGetArray(g_aMaiden, iItem, eMaiden)
                        if ( eMaiden[MAIDEN_FLAGS] & FLAG_USED )
                            continue

                        maidenMaiden(eMaiden, iTarget, true)
                        ArraySetArray(g_aMaiden, iItem, eMaiden)
                        bFoundMaiden = true
                        break
                    }

                    if ( !bFoundMaiden )
                    {
                        client_print_color(id, id, "%L %L", id, "MAIDEN_CHAT_TAG", id, "MAIDEN_CHAT_NO_MAIDEN")
                        break
                    }
                }
            }
        }

        iArgIndex ++
        szTarget[0] = EOS
        read_argv(iArgIndex, szTarget, charsmax(szTarget))
        remove_quotes(szTarget)
    }

    return PLUGIN_HANDLED
}

public cmdReload(id, iLevel, iCmd)
{
    if ( !cmd_access(id, iLevel, iCmd, 1) )
        return PLUGIN_HANDLED

    ReadFile()
    console_print(id, "The configuration file has been reloaded successfully !")

    return PLUGIN_HANDLED
}

public eventRoundStart()
{
    maidenReset()
}

ReadFile()
{
    if ( g_bFileWasRead )
    {
        ArrayClear(g_aMaidenConfig)
        g_iMaidenConfig = 0
    }

    new szFile[MAX_RESOURCE_PATH_LENGTH], iFile
    get_configsdir(szFile, charsmax(szFile))
    add(szFile, charsmax(szFile), "/IronMaiden.ini")
    iFile = fopen(szFile, "rt")

    if ( !iFile )
    {
        set_fail_state("An error occured during the opening of the configuration file !")
    }

    new szData[MAX_FILE_CELL_SIZE],
        szKey[MAX_VALUE_LENGTH], szValue[MAX_VALUE_LENGTH],
        eMaiden[MAIDEN], iSection = SECTION_NONE, iLine, iPos

    while( !feof(iFile) )
    {
        iLine ++
        fgets(iFile, szData, charsmax(szData))
        trim(szData)

        switch( szData[0] )
        {
            case EOS, ';', '#':
            {
                continue
            }
            case '[':
            {
                if ( szData[strlen(szData) - 1] == ']' )
                {
                    replace(szData, charsmax(szData), "[", "")
                    replace(szData, charsmax(szData), "]", "")
                    trim(szData)

                    if ( equali(szData, "Main Settings") )
                    {
                        iSection = SECTION_MAIN_SETTINGS
                    }
                    else
                    {
                        if ( g_iMaidenConfig )
                            ArrayPushArray(g_aMaidenConfig, eMaiden)

                        copy(eMaiden[MAIDEN_NAME], charsmax(eMaiden[MAIDEN_NAME]), szData)
                        eMaiden[MAIDEN_FLAGS]                     = g_eSettings[SETTING_DEFAULT_FLAGS]
                        eMaiden[MAIDEN_TEAM]                      = g_eSettings[SETTING_DEFAULT_TEAM]
                        eMaiden[MAIDEN_FRAMERATE]                 = g_eSettings[SETTING_DEFAULT_FRAMERATE]
                        eMaiden[MAIDEN_COOLDOWN][0]               = g_eSettings[SETTING_DEFAULT_COOLDOWN][0]
                        eMaiden[MAIDEN_COOLDOWN][1]               = g_eSettings[SETTING_DEFAULT_COOLDOWN][1]

                        iSection = SECTION_MAIDEN
                        g_iMaidenConfig ++
                    }
                }
                else
                {
                    LogConfigError(iLine, "Unclosed section name: %s", szData)
                    iSection = SECTION_NONE
                }
            }
            default:
            {
                strtok(szData, szKey, charsmax(szKey), szValue, charsmax(szValue), '=')
                iPos = contain(szValue, "#")
                if ( iPos != -1 )
                    szValue[iPos] = EOS

                trim(szKey)
                trim(szValue)

                switch( iSection )
                {
                    case SECTION_NONE:
                    {
                        LogConfigError(iLine, "Data is not in any defined section: %s", szData)
                    }
                    case SECTION_MAIN_SETTINGS:
                    {
                        if ( equali(szKey, "SETTING_DEFAULT_MODEL") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_MODEL], charsmax(g_eSettings[SETTING_DEFAULT_MODEL]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SOUND") )
                            parseSetting(DTYPE_ARRAY_SOUND, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SOUND], charsmax(g_eSettings[SETTING_DEFAULT_SOUND]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SOUND_OPEN") )
                            parseSetting(DTYPE_ARRAY_SOUND, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SOUND_OPEN], charsmax(g_eSettings[SETTING_DEFAULT_SOUND_OPEN]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SOUND_CLOSE") )
                            parseSetting(DTYPE_ARRAY_SOUND, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SOUND_CLOSE], charsmax(g_eSettings[SETTING_DEFAULT_SOUND_CLOSE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_MESSAGE") )
                            parseSetting(DTYPE_ARRAY_MESSAGE, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_MESSAGE], charsmax(g_eSettings[SETTING_DEFAULT_MESSAGE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_MESSAGE_FORCED") )
                            parseSetting(DTYPE_ARRAY_MESSAGE, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_MESSAGE_FORCED], charsmax(g_eSettings[SETTING_DEFAULT_MESSAGE_FORCED]))
                        else if ( equali(szKey, "SETTING_DEFAULT_FLAGS") )
                            parseSetting(DTYPE_FLAGS, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_FLAGS], charsmax(g_eSettings[SETTING_DEFAULT_FLAGS]))
                        else if ( equali(szKey, "SETTING_DEFAULT_TEAM") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_TEAM], charsmax(g_eSettings[SETTING_DEFAULT_TEAM]))
                        else if ( equali(szKey, "SETTING_DEFAULT_FRAMERATE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_FRAMERATE], charsmax(g_eSettings[SETTING_DEFAULT_FRAMERATE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_HOLD_DURATION") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_HOLD_DURATION], charsmax(g_eSettings[SETTING_DEFAULT_HOLD_DURATION]))
                        else if ( equali(szKey, "SETTING_DEFAULT_COOLDOWN") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_COOLDOWN], charsmax(g_eSettings[SETTING_DEFAULT_COOLDOWN]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SHAKE_DISTANCE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SHAKE_DISTANCE], charsmax(g_eSettings[SETTING_DEFAULT_SHAKE_DISTANCE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SHAKE_AMPLITUDE") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SHAKE_AMPLITUDE], charsmax(g_eSettings[SETTING_DEFAULT_SHAKE_AMPLITUDE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SHAKE_FREQUENCY") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SHAKE_FREQUENCY], charsmax(g_eSettings[SETTING_DEFAULT_SHAKE_FREQUENCY]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SHAKE_DURATION") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SHAKE_DURATION], charsmax(g_eSettings[SETTING_DEFAULT_SHAKE_DURATION]))
                        else if ( equali(szKey, "SETTING_PLAY_SOUND_ON_DEATH") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_PLAY_SOUND_ON_DEATH], charsmax(g_eSettings[SETTING_PLAY_SOUND_ON_DEATH]))
                        else if ( equali(szKey, "SETTING_WRITE_MESSAGE_ON_DEATH") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_WRITE_MESSAGE_ON_DEATH], charsmax(g_eSettings[SETTING_WRITE_MESSAGE_ON_DEATH]))
                        else if ( equali(szKey, "SETTING_KILL_ALL_EXCLUDE_CALLER") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_KILL_ALL_EXCLUDE_CALLER], charsmax(g_eSettings[SETTING_KILL_ALL_EXCLUDE_CALLER]))
                        else if ( equali(szKey, "SETTING_HUD_X") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_X], charsmax(g_eSettings[SETTING_HUD_X]))
                        else if ( equali(szKey, "SETTING_HUD_Y") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_Y], charsmax(g_eSettings[SETTING_HUD_Y]))
                        else if ( equali(szKey, "SETTING_HUD_COLOR") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_COLOR], charsmax(g_eSettings[SETTING_HUD_COLOR]))
                        else if ( equali(szKey, "SETTING_HUD_EFFECT") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_EFFECT], charsmax(g_eSettings[SETTING_HUD_EFFECT]))
                        else if ( equali(szKey, "SETTING_HUD_FXTIME") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_FXTIME], charsmax(g_eSettings[SETTING_HUD_FXTIME]))
                        else if ( equali(szKey, "SETTING_HUD_HOLDTIME") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_HOLDTIME], charsmax(g_eSettings[SETTING_HUD_HOLDTIME]))
                        else if ( equali(szKey, "SETTING_HUD_FADEIN") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_FADEIN], charsmax(g_eSettings[SETTING_HUD_FADEIN]))
                        else if ( equali(szKey, "SETTING_HUD_FADEOUT") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_FADEOUT], charsmax(g_eSettings[SETTING_HUD_FADEOUT]))
                        else if ( equali(szKey, "SETTING_MINS") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MINS], charsmax(g_eSettings[SETTING_MINS]))
                        else if ( equali(szKey, "SETTING_MAXS") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MAXS], charsmax(g_eSettings[SETTING_MAXS]))
                        else if ( equali(szKey, "SETTING_MAIDEN_LOAD") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_MAIDEN_LOAD], charsmax(g_eSettings[SETTING_MAIDEN_LOAD]))
                        else if ( equali(szKey, "SETTING_MAIDEN_TASK") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MAIDEN_TASK], charsmax(g_eSettings[SETTING_MAIDEN_TASK]))
                    }
                    case SECTION_MAIDEN:
                    {
                        if ( equali(szKey, "MAIDEN_FLAGS") )
                            parseSetting(DTYPE_FLAGS, szValue, charsmax(szValue), eMaiden[MAIDEN_FLAGS], charsmax(eMaiden[MAIDEN_FLAGS]))
                        else if ( equali(szKey, "MAIDEN_TEAM") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eMaiden[MAIDEN_TEAM], charsmax(eMaiden[MAIDEN_TEAM]))
                        else if ( equali(szKey, "MAIDEN_FRAMERATE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eMaiden[MAIDEN_FRAMERATE], charsmax(eMaiden[MAIDEN_FRAMERATE]))
                        else if ( equali(szKey, "MAIDEN_COOLDOWN") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eMaiden[MAIDEN_COOLDOWN], charsmax(eMaiden[MAIDEN_COOLDOWN]))
                    }
                }
            }
        }
    }

    if ( g_iMaidenConfig )
        ArrayPushArray(g_aMaidenConfig, eMaiden)
    else
        set_fail_state("No Iron Maidens were found in the configuration file.")

    g_bFileWasRead = true
    fclose(iFile)
}

public client_disconnected(id)
{
    new eMaiden[MAIDEN], iItem
    if ( g_ePlayerData[id][PDATA_MAIDEN_GHOST]
    && (iItem = maidenGet(eMaiden, g_ePlayerData[id][PDATA_MAIDEN_GHOST])) != -1 )
    {
        maidenKill(eMaiden[MAIDEN_ID])
        maidenRemove(iItem)
    }

    DisableAction(id)
    g_ePlayerData[id][PDATA_MAIDEN_GHOST]  = 0
    g_ePlayerData[id][PDATA_MAIDEN_MENU]   = 0
}

stock maidenInit()
{
    g_iHudCurrentY = g_eSettings[SETTING_HUD_Y]
    if ( g_eSettings[SETTING_MAIDEN_LOAD] )
        set_task(DELAY_ON_LOAD, "loadData")
}

stock maidenMenu(id, iType)
{
    if ( !is_user_connected(id) )
        return PLUGIN_HANDLED

    new szData[256], iMenu
    formatex(szData, charsmax(szData), "%L", id, "MAIDEN_MENU_TITLE", PLUGIN_VERSION)
    iMenu = menu_create(szData, g_szMenuHandler[iType])
    switch( iType )
    {
        case MENU_ROOT:             { menuRoot(id, iMenu); }
        case MENU_CREATE:           { menuCreate(iMenu);            format(szData, charsmax(szData), "%s^n%L", szData, id, "MAIDEN_ROOT_CREATE"); }
        case MENU_EDIT:             { menuEdit(id, iMenu);          format(szData, charsmax(szData), "%s^n%L", szData, id, "MAIDEN_ROOT_EDIT"); }
        case MENU_REMOVE:           { menuRemove(id, iMenu);        format(szData, charsmax(szData), "%s^n%L", szData, id, "MAIDEN_ROOT_REMOVE"); }
        case MENU_SHOW:             { menuShow(id, iMenu);          format(szData, charsmax(szData), "%s^n%L", szData, id, "MAIDEN_ROOT_SHOW"); }
        case MENU_STATUS:           { menuStatus(id, iMenu);        format(szData, charsmax(szData), "%s^n%L", szData, id, "MAIDEN_ROOT_STATUS"); }
        case MENU_ROTATE:           { menuRotate(id, iMenu);        format(szData, charsmax(szData), "%s^n%L", szData, id, "MAIDEN_ROOT_ROTATE"); }
    }

    if ( menu_pages(iMenu) > 1 )
        format(szData, charsmax(szData), "%s^n%L", szData, id, "MAIDEN_MENU_TITLE_PAGE")

    menu_setprop(iMenu, MPROP_TITLE, szData)
    menu_setprop(iMenu, MPROP_EXIT, MEXIT_ALL)
    menu_setprop(iMenu, MPROP_NUMBER_COLOR, "\r")

    menu_display(id, iMenu)
    return PLUGIN_HANDLED
}

stock menuNav(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "MAIDEN_NAV_NEXT")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "MAIDEN_NAV_BACK")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)
}

public menuRoot(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "MAIDEN_ROOT_CREATE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "MAIDEN_ROOT_EDIT")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "MAIDEN_ROOT_REMOVE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "MAIDEN_ROOT_SAVE")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)

    formatex(szItem, charsmax(szItem), "%L", id, "MAIDEN_ROOT_NOCLIP", id, (pev(id, pev_movetype) == MOVETYPE_NOCLIP) ? "MAIDEN_ON" : "MAIDEN_OFF")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "MAIDEN_ROOT_GODMODE", id, (pev(id, pev_takedamage) == DAMAGE_NO) ? "MAIDEN_ON" : "MAIDEN_OFF")
    menu_additem(iMenu, szItem)
}

public menuHandlerRoot(id, menu, item)
{
    if ( item == MENU_EXIT )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch( item )
    {
        case ROOT_CREATE:
        {
            if ( g_iMaiden >= MAX_ENT )
            {
                client_print_color(id, id, "%L %L", id, "MAIDEN_CHAT_TAG", id, "MAIDEN_CHAT_LIMIT", MAX_ENT)

                maidenSound(id, SOUND_MENU_REMOVE)
                maidenMenu(id, MENU_ROOT)
            }
            else
            {
                maidenSound(id, SOUND_MENU_NAV)
                maidenMenu(id, MENU_CREATE)
            }
        }
        case ROOT_EDIT:
        {
            if ( !g_iMaiden )
            {
                client_print_color(id, id, "%L %L", id, "MAIDEN_CHAT_TAG", id, "MAIDEN_CHAT_NO_MAIDEN")

                maidenSound(id, SOUND_MENU_REMOVE)
                maidenMenu(id, MENU_ROOT)
            }
            else
            {
                maidenSound(id, SOUND_MENU_NAV)
                maidenMenu(id, MENU_EDIT)
            }
        }
        case ROOT_REMOVE:
        {
            if ( !g_iMaiden )
            {
                client_print_color(id, id, "%L %L", id, "MAIDEN_CHAT_TAG", id, "MAIDEN_CHAT_NO_MAIDEN")

                maidenSound(id, SOUND_MENU_REMOVE)
                maidenMenu(id, MENU_ROOT)
            }
            else
            {
                maidenSound(id, SOUND_MENU_REMOVE)
                maidenMenu(id, MENU_REMOVE)
            }
        }
        case ROOT_SAVE:
        {
            saveData(id)
        }
        case ROOT_NOCLIP:
        {
            maidenNoClip(id)
        }
        case ROOT_GODMODE:
        {
            maidenGodMode(id)
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuCreate(iMenu)
{
    new eMaiden[MAIDEN], szItem[64]
    for ( new i = 0; i < g_iMaidenConfig; i ++ )
    {
        ArrayGetArray(g_aMaidenConfig, i, eMaiden)

        copy(szItem, charsmax(szItem), eMaiden[MAIDEN_NAME])
        menu_additem(iMenu, szItem)
    }
}

public menuHandlerCreate(id, menu, item)
{
    if ( !is_user_alive(id) )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }
    else if ( item == MENU_EXIT )
    {
        maidenSound(id, SOUND_MENU_NAV)
        maidenMenu(id, MENU_ROOT)

        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    maidenCreate(id, item)
    maidenSound(id, SOUND_MENU_NAV)
    maidenMenu(id, MENU_ROTATE)

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuEdit(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "MAIDEN_EDIT_SHOW")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "MAIDEN_EDIT_STATUS")
    menu_additem(iMenu, szItem)
}

public menuHandlerEdit(id, menu, item)
{
    switch( item )
    {
        case EDIT_SHOW:
        {
            maidenSound(id, SOUND_MENU_NAV)
            maidenMenu(id, MENU_SHOW)
        }
        case EDIT_STATUS:
        {
            maidenSound(id, SOUND_MENU_NAV)
            maidenMenu(id, MENU_STATUS)
        }
        case MENU_EXIT:
        {
            maidenSound(id, SOUND_MENU_NAV)
            maidenMenu(id, MENU_ROOT)
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuRemove(id, iMenu)
{
    new szItem[64], eMaiden[MAIDEN]
    menuNav(id, iMenu)
    ArrayGetArray(g_aMaiden, g_ePlayerData[id][PDATA_MAIDEN_MENU], eMaiden)

    formatex(szItem, charsmax(szItem), "%L", id, "MAIDEN_REMOVE_CURRENT", eMaiden[MAIDEN_NAME])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "MAIDEN_REMOVE_ALL")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    maidenSelect(eMaiden, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_REMOVE
    ArraySetArray(g_aMaiden, g_ePlayerData[id][PDATA_MAIDEN_MENU], eMaiden)
}

public menuHandlerRemove(id, menu, item)
{
    new eMaiden[MAIDEN]
    ArrayGetArray(g_aMaiden, g_ePlayerData[id][PDATA_MAIDEN_MENU], eMaiden)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        maidenSelect(eMaiden, eMaiden[MAIDEN_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case REMOVE_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_MAIDEN_MENU] >= g_iMaiden - 1 )
                g_ePlayerData[id][PDATA_MAIDEN_MENU] = 0
            else
                g_ePlayerData[id][PDATA_MAIDEN_MENU] ++

            maidenSound(id, SOUND_MENU_NAV)
            maidenMenu(id, MENU_REMOVE)
        }
        case REMOVE_BACK:
        {
            if ( g_ePlayerData[id][PDATA_MAIDEN_MENU] <= 0 )
                g_ePlayerData[id][PDATA_MAIDEN_MENU] = g_iMaiden - 1
            else
                g_ePlayerData[id][PDATA_MAIDEN_MENU] --

            maidenSound(id, SOUND_MENU_NAV)
            maidenMenu(id, MENU_REMOVE)
        }
        case REMOVE_CURRENT:
        {
            eMaiden[MAIDEN_FLAGS] &= ~FLAG_ACTIVE
            maidenSetState(eMaiden)
            maidenKill(eMaiden[MAIDEN_ID])
            maidenRemove(g_ePlayerData[id][PDATA_MAIDEN_MENU])

            client_print_color(id, id, "%L %L", id, "MAIDEN_CHAT_TAG", id, "MAIDEN_CHAT_REMOVE_CURRENT", eMaiden[MAIDEN_NAME])
            g_ePlayerData[id][PDATA_MAIDEN_MENU] = 0

            maidenSound(id, g_iMaiden > 0 ? SOUND_MENU_REMOVE : SOUND_MENU_NAV)
            maidenMenu(id, g_iMaiden > 0 ? MENU_REMOVE : MENU_ROOT)
        }
        case REMOVE_ALL:
        {
            while( g_iMaiden )
            {
                ArrayGetArray(g_aMaiden, 0, eMaiden)
                eMaiden[MAIDEN_FLAGS] &= ~FLAG_ACTIVE

                maidenSetState(eMaiden)
                maidenKill(eMaiden[MAIDEN_ID])
                maidenRemove(0)
            }

            client_print_color(id, id, "%L %L", id, "MAIDEN_CHAT_TAG", id, "MAIDEN_CHAT_REMOVE_ALL")
            g_ePlayerData[id][PDATA_MAIDEN_MENU] = 0

            maidenSound(id, SOUND_MENU_ALERT)
            maidenMenu(id, MENU_ROOT)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                maidenSound(id, SOUND_MENU_NAV)
                maidenMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_MAIDEN_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_MAIDEN_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuShow(id, iMenu)
{
    new szItem[64], eMaiden[MAIDEN]
    menuNav(id, iMenu)
    ArrayGetArray(g_aMaiden, g_ePlayerData[id][PDATA_MAIDEN_MENU], eMaiden)

    formatex(szItem, charsmax(szItem), "%L", id, "MAIDEN_SHOW_CURRENT",
    eMaiden[MAIDEN_FLAGS] & FLAG_SHOW ? "\y" : "\r", eMaiden[MAIDEN_NAME], id, eMaiden[MAIDEN_FLAGS] & FLAG_SHOW ? "MAIDEN_SHOWN" : "MAIDEN_HIDDEN")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "MAIDEN_SHOW_ALL_SHOW")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "MAIDEN_SHOW_ALL_HIDE")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    maidenSelect(eMaiden, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_SHOW
    ArraySetArray(g_aMaiden, g_ePlayerData[id][PDATA_MAIDEN_MENU], eMaiden)
}

public menuHandlerShow(id, menu, item)
{
    new eMaiden[MAIDEN]
    ArrayGetArray(g_aMaiden, g_ePlayerData[id][PDATA_MAIDEN_MENU], eMaiden)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        maidenSelect(eMaiden, eMaiden[MAIDEN_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case SHOW_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_MAIDEN_MENU] >= g_iMaiden - 1 )
                g_ePlayerData[id][PDATA_MAIDEN_MENU] = 0
            else
                g_ePlayerData[id][PDATA_MAIDEN_MENU] ++

            maidenSound(id, SOUND_MENU_NAV)
            maidenMenu(id, MENU_SHOW)
        }
        case SHOW_BACK:
        {
            if ( g_ePlayerData[id][PDATA_MAIDEN_MENU] <= 0 )
                g_ePlayerData[id][PDATA_MAIDEN_MENU] = g_iMaiden - 1
            else
                g_ePlayerData[id][PDATA_MAIDEN_MENU] --

            maidenSound(id, SOUND_MENU_NAV)
            maidenMenu(id, MENU_SHOW)
        }
        case SHOW_CURRENT:
        {
            eMaiden[MAIDEN_FLAGS] ^= FLAG_SHOW
            if ( eMaiden[MAIDEN_FLAGS] & FLAG_SHOW )
                eMaiden[MAIDEN_FLAGS] |= FLAG_ACTIVE
            else
                eMaiden[MAIDEN_FLAGS] &= ~FLAG_ACTIVE
            maidenSetState(eMaiden)

            client_print_color(id, id, "%L %L", id, "MAIDEN_CHAT_TAG", id, "MAIDEN_CHAT_SHOW_CURRENT",
            eMaiden[MAIDEN_NAME], id, eMaiden[MAIDEN_FLAGS] & FLAG_SHOW ? "MAIDEN_CHAT_SHOWN" : "MAIDEN_CHAT_HIDDEN")
            ArraySetArray(g_aMaiden, g_ePlayerData[id][PDATA_MAIDEN_MENU], eMaiden)

            maidenSound(id, SOUND_MENU_NAV)
            maidenMenu(id, MENU_SHOW)
        }
        case SHOW_ALL_SHOW:
        {
            for ( new i = 0; i < g_iMaiden; i ++ )
            {
                ArrayGetArray(g_aMaiden, i, eMaiden)
                eMaiden[MAIDEN_FLAGS] |= (FLAG_SHOW | FLAG_ACTIVE)
                maidenSetState(eMaiden)

                ArraySetArray(g_aMaiden, i, eMaiden)
            }

            client_print_color(id, id, "%L %L", id, "MAIDEN_CHAT_TAG", id, "MAIDEN_CHAT_SHOW_ALL_SHOWN")
            maidenSound(id, SOUND_MENU_ALERT)
            maidenMenu(id, MENU_SHOW)
        }
        case SHOW_ALL_HIDE:
        {
            for ( new i = 0; i < g_iMaiden; i ++ )
            {
                ArrayGetArray(g_aMaiden, i, eMaiden)
                eMaiden[MAIDEN_FLAGS] &= ~(FLAG_SHOW | FLAG_ACTIVE)
                maidenSetState(eMaiden)

                ArraySetArray(g_aMaiden, i, eMaiden)
            }

            client_print_color(id, id, "%L %L", id, "MAIDEN_CHAT_TAG", id, "MAIDEN_CHAT_SHOW_ALL_HIDDEN")
            maidenSound(id, SOUND_MENU_ALERT)
            maidenMenu(id, MENU_SHOW)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                maidenSound(id, SOUND_MENU_NAV)
                maidenMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_MAIDEN_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_MAIDEN_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuStatus(id, iMenu)
{
    new szItem[64], eMaiden[MAIDEN]
    menuNav(id, iMenu)
    ArrayGetArray(g_aMaiden, g_ePlayerData[id][PDATA_MAIDEN_MENU], eMaiden)

    formatex(szItem, charsmax(szItem), "%L", id, "MAIDEN_STATUS_CURRENT",
    eMaiden[MAIDEN_FLAGS] & FLAG_ACTIVE ? "\y" : "\r", eMaiden[MAIDEN_NAME], id, eMaiden[MAIDEN_FLAGS] & FLAG_ACTIVE ? "MAIDEN_ENABLED" : "MAIDEN_DISABLED")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "MAIDEN_STATUS_ALL_ENABLE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "MAIDEN_STATUS_ALL_DISABLE")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    maidenSelect(eMaiden, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_STATUS
    ArraySetArray(g_aMaiden, g_ePlayerData[id][PDATA_MAIDEN_MENU], eMaiden)
}

public menuHandlerStatus(id, menu, item)
{
    new eMaiden[MAIDEN]
    ArrayGetArray(g_aMaiden, g_ePlayerData[id][PDATA_MAIDEN_MENU], eMaiden)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        maidenSelect(eMaiden, eMaiden[MAIDEN_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case STATUS_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_MAIDEN_MENU] >= g_iMaiden - 1 )
                g_ePlayerData[id][PDATA_MAIDEN_MENU] = 0
            else
                g_ePlayerData[id][PDATA_MAIDEN_MENU] ++

            maidenSound(id, SOUND_MENU_NAV)
            maidenMenu(id, MENU_STATUS)
        }
        case STATUS_BACK:
        {
            if ( g_ePlayerData[id][PDATA_MAIDEN_MENU] <= 0 )
                g_ePlayerData[id][PDATA_MAIDEN_MENU] = g_iMaiden - 1
            else
                g_ePlayerData[id][PDATA_MAIDEN_MENU] --

            maidenSound(id, SOUND_MENU_NAV)
            maidenMenu(id, MENU_STATUS)
        }
        case STATUS_CURRENT:
        {
            eMaiden[MAIDEN_FLAGS] ^= FLAG_ACTIVE
            maidenSetState(eMaiden)

            client_print_color(id, id, "%L %L", id, "MAIDEN_CHAT_TAG", id, "MAIDEN_CHAT_STATUS_CURRENT",
            eMaiden[MAIDEN_NAME], id, eMaiden[MAIDEN_FLAGS] & FLAG_ACTIVE ? "MAIDEN_CHAT_ENABLED" : "MAIDEN_CHAT_DISABLED")
            ArraySetArray(g_aMaiden, g_ePlayerData[id][PDATA_MAIDEN_MENU], eMaiden)

            maidenSound(id, SOUND_MENU_NAV)
            maidenMenu(id, MENU_STATUS)
        }
        case STATUS_ALL_ENABLE:
        {
            for ( new i = 0; i < g_iMaiden; i ++ )
            {
                ArrayGetArray(g_aMaiden, i, eMaiden)
                eMaiden[MAIDEN_FLAGS] |= FLAG_ACTIVE
                maidenSetState(eMaiden)

                ArraySetArray(g_aMaiden, i, eMaiden)
            }

            client_print_color(id, id, "%L %L", id, "MAIDEN_CHAT_TAG", id, "MAIDEN_CHAT_STATUS_ALL_ENABLED")
            maidenSound(id, SOUND_MENU_ALERT)
            maidenMenu(id, MENU_STATUS)
        }
        case STATUS_ALL_DISABLE:
        {
            for ( new i = 0; i < g_iMaiden; i ++ )
            {
                ArrayGetArray(g_aMaiden, i, eMaiden)
                eMaiden[MAIDEN_FLAGS] &= ~FLAG_ACTIVE
                maidenSetState(eMaiden)

                ArraySetArray(g_aMaiden, i, eMaiden)
            }

            client_print_color(id, id, "%L %L", id, "MAIDEN_CHAT_TAG", id, "MAIDEN_CHAT_STATUS_ALL_DISABLED")
            maidenSound(id, SOUND_MENU_ALERT)
            maidenMenu(id, MENU_STATUS)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                maidenSound(id, SOUND_MENU_NAV)
                maidenMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_MAIDEN_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_MAIDEN_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuRotate(id, iMenu)
{
    new szItem[64], eMaiden[MAIDEN]
    if ( maidenGet(eMaiden, g_ePlayerData[id][PDATA_MAIDEN_GHOST]) == -1 )
    {
        menu_destroy(iMenu)
        return
    }

    formatex(szItem, charsmax(szItem), "%L", id, "MAIDEN_ROTATE_UP")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "MAIDEN_ROTATE_DOWN")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)

    formatex(szItem, charsmax(szItem), "%L", id, "MAIDEN_ROTATE_GROUND",
    id, eMaiden[MAIDEN_FLAGS] & FLAG_GROUND ? "MAIDEN_ON" : "MAIDEN_OFF")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "MAIDEN_ROTATE_PLACE")
    menu_additem(iMenu, szItem)
}

public menuHandlerRotate(id, menu, item)
{
    new eMaiden[MAIDEN], iItem
    if ( (iItem = maidenGet(eMaiden, g_ePlayerData[id][PDATA_MAIDEN_GHOST])) == -1 )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch( item )
    {
        case ROTATE_UP:
        {
            pev(eMaiden[MAIDEN_ID], pev_angles, eMaiden[MAIDEN_ANGLES])
            eMaiden[MAIDEN_ANGLES][1] -= MAIDEN_ROTATION_STEP
            if ( eMaiden[MAIDEN_ANGLES][1] < -180.0 ) eMaiden[MAIDEN_ANGLES][1] += 360.0

            set_pev(eMaiden[MAIDEN_ID], pev_angles, eMaiden[MAIDEN_ANGLES])
            ArraySetArray(g_aMaiden, iItem, eMaiden)

            maidenSound(id, SOUND_MENU_NAV)
            maidenMenu(id, MENU_ROTATE)
        }
        case ROTATE_DOWN:
        {
            pev(eMaiden[MAIDEN_ID], pev_angles, eMaiden[MAIDEN_ANGLES])
            eMaiden[MAIDEN_ANGLES][1] += MAIDEN_ROTATION_STEP
            if ( eMaiden[MAIDEN_ANGLES][1] > 180.0 ) eMaiden[MAIDEN_ANGLES][1] -= 360.0

            set_pev(eMaiden[MAIDEN_ID], pev_angles, eMaiden[MAIDEN_ANGLES])
            ArraySetArray(g_aMaiden, iItem, eMaiden)

            maidenSound(id, SOUND_MENU_NAV)
            maidenMenu(id, MENU_ROTATE)
        }
        case ROTATE_GROUND:
        {
            eMaiden[MAIDEN_FLAGS] ^= FLAG_GROUND
            ArraySetArray(g_aMaiden, iItem, eMaiden)

            maidenSound(id, SOUND_MENU_NAV)
            maidenMenu(id, MENU_ROTATE)
        }
        case ROTATE_PLACE:
        {
            maidenTrace(eMaiden, id)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_MAIDEN_GHOST] = 0

            eMaiden[MAIDEN_FLAGS] &= ~FLAG_GHOST
            eMaiden[MAIDEN_FLAGS] |= (FLAG_SHOW | FLAG_ACTIVE)
            eMaiden[MAIDEN_ANGLES][0] = -eMaiden[MAIDEN_ANGLES][0]
            maidenSetSize(eMaiden)
            maidenSetState(eMaiden)
            client_print_color(id, id, "%L %L", id, "MAIDEN_CHAT_TAG", id, "MAIDEN_CHAT_CREATE_NEW", eMaiden[MAIDEN_NAME])

            ArraySetArray(g_aMaiden, iItem, eMaiden)
            maidenSound(id, SOUND_MENU_NAV)
            maidenMenu(id, MENU_CREATE)
        }
        case MENU_EXIT:
        {
            maidenKill(eMaiden[MAIDEN_ID])
            maidenRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_MAIDEN_GHOST] = 0

            maidenSound(id, SOUND_MENU_NAV)
            maidenMenu(id, MENU_CREATE)
        }
        default:
        {
            maidenKill(eMaiden[MAIDEN_ID])
            maidenRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_MAIDEN_GHOST] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public maidenTask()
{
    new eMaiden[MAIDEN], iItem, Float:fCurrentTime
    fCurrentTime = get_gametime()

    for ( new id = 1; id <= g_iMaxPlayers; id ++ )
    {
        if ( g_ePlayerData[id][PDATA_NEXT_MAIDEN] )
        {
            if ( fCurrentTime >= g_ePlayerData[id][PDATA_NEXT_MAIDEN] )
            {
                if ( (iItem = maidenGet(eMaiden, g_ePlayerData[id][PDATA_MAIDEN_ID])) != -1 )
                {
                    g_ePlayerData[id][PDATA_MAIDEN_ID] = 0
                    g_ePlayerData[id][PDATA_NEXT_MAIDEN] = 0.0

                    maidenMaiden(eMaiden, id)
                    ArraySetArray(g_aMaiden, iItem, eMaiden)
                }
            }
            else if ( fCurrentTime - g_ePlayerData[id][PDATA_NEXT_CHECK] > 0.1 )
            {
                maidenBar(id, 0)
                g_ePlayerData[id][PDATA_MAIDEN_ID] = 0
                g_ePlayerData[id][PDATA_NEXT_MAIDEN] = 0.0
            }
        }
        else if ( g_ePlayerData[id][PDATA_NEXT_DIE] )
        {
            if ( fCurrentTime >= g_ePlayerData[id][PDATA_NEXT_DIE] )
            {
                if ( (iItem = maidenGet(eMaiden, g_ePlayerData[id][PDATA_MAIDEN_ID])) != -1 )
                {
                    if ( eMaiden[MAIDEN_FLAGS] & FLAG_USED && is_user_alive(id) )
                    {
                        engfunc(EngFunc_SetView, id, id)
                        set_pev(id, pev_flags, pev(id, pev_flags) & ~FL_FROZEN)
                        set_pev(id, pev_movetype, MOVETYPE_WALK)

                        g_iSilentVictim = id
                        ExecuteHamB(Ham_Killed, id, id, GIB_ALWAYS)
                        maidenSound(eMaiden[MAIDEN_ID], SOUND_CLOSE, false)
                    }

                    g_ePlayerData[id][PDATA_MAIDEN_ID] = 0
                    g_ePlayerData[id][PDATA_NEXT_DIE] = 0.0
                    eMaiden[MAIDEN_FLAGS] &= ~FLAG_USED
                    eMaiden[MAIDEN_NEXT_ACTIVE] = fCurrentTime + random_float(eMaiden[MAIDEN_COOLDOWN][0], eMaiden[MAIDEN_COOLDOWN][1])
                    maidenSetSeq(eMaiden[MAIDEN_ID], MAIDEN_SEQ_CLOSED, eMaiden[MAIDEN_FRAMERATE])
                    maidenShake(eMaiden)

                    ArraySetArray(g_aMaiden, iItem, eMaiden)
                }
            }
        }
    }

    for ( new i = 0; i < g_iMaiden; i ++ )
    {
        ArrayGetArray(g_aMaiden, i, eMaiden)

        if ( eMaiden[MAIDEN_NEXT_ACTIVE]
        && fCurrentTime >= eMaiden[MAIDEN_NEXT_ACTIVE] )
        {
            maidenSound(eMaiden[MAIDEN_ID], SOUND_OPEN, false)
            maidenSetSeq(eMaiden[MAIDEN_ID], MAIDEN_SEQ_OPEN, eMaiden[MAIDEN_FRAMERATE])
            eMaiden[MAIDEN_NEXT_ACTIVE] = 0.0
            eMaiden[MAIDEN_NEXT_OPEN] = fCurrentTime + (MAIDEN_DURATION_OPEN / eMaiden[MAIDEN_FRAMERATE])

            ArraySetArray(g_aMaiden, i, eMaiden)
        }
        else if ( eMaiden[MAIDEN_NEXT_OPEN]
        && fCurrentTime >= eMaiden[MAIDEN_NEXT_OPEN] )
        {
            maidenSetSeq(eMaiden[MAIDEN_ID], MAIDEN_SEQ_OPENED, eMaiden[MAIDEN_FRAMERATE])
            eMaiden[MAIDEN_NEXT_OPEN] = 0.0

            ArraySetArray(g_aMaiden, i, eMaiden)
        }
    }
}

stock maidenCreate(id, iItem)
{
    new iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
    if ( !pev_valid(iEnt) )
        return

    new eMaiden[MAIDEN]
    ArrayGetArray(g_aMaidenConfig, iItem, eMaiden)
    eMaiden[MAIDEN_ID] = iEnt
    eMaiden[MAIDEN_ITEM] = iItem
    if ( id )
    {
        EnableAction(id)
        g_ePlayerData[id][PDATA_MAIDEN_GHOST] = eMaiden[MAIDEN_ID]
        g_ePlayerData[id][PDATA_OFFSET] = MAIDEN_OFFSET_BASE

        eMaiden[MAIDEN_FLAGS] |= FLAG_GHOST
    }

    maidenSelect(eMaiden, TARGET_GHOST)
    set_pev(iEnt, pev_classname, g_szCN)
    set_pev(iEnt, pev_impulse, MAIDEN_KEY)
    set_pev(iEnt, MAIDEN_ARRAY_ITEM, g_iMaiden)
    dllfunc(DLLFunc_Spawn, iEnt)
    set_pev(iEnt, pev_solid, SOLID_NOT)
    set_pev(iEnt, pev_movetype, MOVETYPE_FLY)
    engfunc(EngFunc_SetModel, iEnt, g_eSettings[SETTING_DEFAULT_MODEL])

    ArrayPushArray(g_aMaiden, eMaiden)
    if ( ++ g_iMaiden == 1 )
    {
        set_task(g_eSettings[SETTING_MAIDEN_TASK], "maidenTask", MAIDEN_KEY, .flags = "b")
        EnableMaiden()
    }
}

stock maidenCreateView(eMaiden[MAIDEN])
{
    new Float:fOrigin[3], Float:fAngles[3], Float:fRight[3], Float:fForward[3], Float:fDirection[3], Float:fFrac
    engfunc(EngFunc_AngleVectors, eMaiden[MAIDEN_ANGLES], fForward, fRight, NULL_VECTOR)

    xs_vec_copy(eMaiden[MAIDEN_ORIGIN], fOrigin)
    xs_vec_mul_scalar(fForward, VIEW_FORWARD_OFFSET, fForward)
    xs_vec_mul_scalar(fRight, VIEW_RIGHT_OFFSET, fRight)
    xs_vec_add(fOrigin, fForward, fOrigin)
    xs_vec_add(fOrigin, fRight, fOrigin)
    fOrigin[2] += VIEW_UP_OFFSET

    engfunc(EngFunc_TraceLine, eMaiden[MAIDEN_ORIGIN], fOrigin, IGNORE_MONSTERS, eMaiden[MAIDEN_ID], 0)
    get_tr2(0, TR_flFraction, fFrac)
    if ( fFrac < 1.0 )
        get_tr2(0, TR_vecEndPos, fOrigin)

    fOrigin[2] -= VIEW_UP_OFFSET
    xs_vec_sub(eMaiden[MAIDEN_ORIGIN], fOrigin, fDirection)
    engfunc(EngFunc_VecToAngles, fDirection, fAngles)
    new iView = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
    if ( !pev_valid(iView) )
        return

    new szCN[32]
    formatex(szCN, charsmax(szCN), "%s_view", g_szCN)
    set_pev(iView, pev_classname, szCN)
    set_pev(iView, pev_movetype, MOVETYPE_NONE)
    set_pev(iView, pev_solid, SOLID_NOT)
    engfunc(EngFunc_SetModel, iView, g_szModelRPG)
    set_pev(iView, pev_rendermode, kRenderTransTexture)
    set_pev(iView, pev_renderamt, 0.0)
    engfunc(EngFunc_SetOrigin, iView, fOrigin)
    set_pev(iView, pev_angles, fAngles)

    eMaiden[MAIDEN_VIEW] = iView
}

public maidenRemove(iItem)
{
    new eMaiden[MAIDEN]
    ArrayDeleteItem(g_aMaiden, iItem)

    if ( -- g_iMaiden == 0 )
    {
        remove_task(MAIDEN_KEY)
        DisableMaiden()
    }

    for ( new i = iItem; i < g_iMaiden; i ++ )
    {
        ArrayGetArray(g_aMaiden, i, eMaiden)
        set_pev(eMaiden[MAIDEN_ID], MAIDEN_ARRAY_ITEM, i)
    }
}

public saveData(id)
{
    new eMaiden[MAIDEN],
        szFile[128], iFile,
        szData[64]

    get_mapname(szFile, charsmax(szFile))
    format(szFile, charsmax(szFile), "maps/%s_IronMaiden.ini", szFile)

    iFile = fopen(szFile, "wt")
    if ( !iFile )
        return PLUGIN_HANDLED

    for ( new i = 0; i < g_iMaiden; i ++ )
    {
        ArrayGetArray(g_aMaiden, i, eMaiden)

        formatex(szData, charsmax(szData), "[%d]^n", i)
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "item = %d^n", eMaiden[MAIDEN_ITEM])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "flags = %d^n", eMaiden[MAIDEN_FLAGS])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "origin = %.2f %.2f %.2f^n",
        eMaiden[MAIDEN_ORIGIN][0], eMaiden[MAIDEN_ORIGIN][1], eMaiden[MAIDEN_ORIGIN][2])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "angles = %.2f %.2f %.2f^n",
        eMaiden[MAIDEN_ANGLES][0], eMaiden[MAIDEN_ANGLES][1], eMaiden[MAIDEN_ANGLES][2])
        fputs(iFile, szData)
    }

    client_print_color(id, id, "%L %L", id, "MAIDEN_CHAT_TAG", id, "MAIDEN_CHAT_SAVE", szFile)
    fclose(iFile)

    maidenSound(id, SOUND_MENU_NAV)
    maidenMenu(id, MENU_ROOT)
    return PLUGIN_HANDLED
}

public loadData()
{
    new szFile[128], iFile,
        szData[64], szKey[32], szValue[32],
        Float:fOrigin[3], Float:fAngles[3], iItem, iFlags, iCount = -1

    get_mapname(szFile, charsmax(szFile))
    format(szFile, charsmax(szFile), "maps/%s_IronMaiden.ini", szFile)
    iFile = fopen(szFile, "rt")
    if ( !iFile )
        return

    while( !feof(iFile) )
    {
        fgets(iFile, szData, charsmax(szData))

        if ( szData[0] == '[' )
        {
            if ( iCount != -1 )
                LoadDataMaiden(iItem, iFlags, fOrigin, fAngles, iCount)

            iCount ++
        }
        else
        {
            strtok(szData, szKey, charsmax( szKey ), szValue, charsmax( szValue ), '=')
            trim(szKey)
            trim(szValue)

            if ( equal(szKey, "item") )
            {
                iItem = str_to_num(szValue)
            }
            else if ( equal(szKey, "flags") )
            {
                iFlags = str_to_num(szValue)
            }
            else if ( equal(szKey, "origin") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fOrigin[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fOrigin[1] = str_to_float(szKey)
                fOrigin[2] = str_to_float(szValue)
            }
            else if ( equal(szKey, "angles") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fAngles[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fAngles[1] = str_to_float(szKey)
                fAngles[2] = str_to_float(szValue)
            }
        }
    }

    if ( iCount != -1 )
        LoadDataMaiden(iItem, iFlags, fOrigin, fAngles, iCount)

    fclose(iFile)
}

stock LoadDataMaiden(iItem, iFlags, Float:fOrigin[3], Float:fAngles[3], iCount)
{
    new eMaiden[MAIDEN]
    maidenCreate(0, iItem)
    ArrayGetArray(g_aMaiden, iCount, eMaiden)

    eMaiden[MAIDEN_FLAGS] = iFlags
    fAngles[0] = -fAngles[0]
    xs_vec_copy(fOrigin, eMaiden[MAIDEN_ORIGIN])
    xs_vec_copy(fAngles, eMaiden[MAIDEN_ANGLES])

    maidenSetBox(eMaiden)
    maidenSetSize(eMaiden)
    maidenSetState(eMaiden)
    ArraySetArray(g_aMaiden, iCount, eMaiden)
}

public maidenNoClip(id)
{
    set_pev(id, pev_movetype, pev(id, pev_movetype) == MOVETYPE_NOCLIP ? MOVETYPE_WALK : MOVETYPE_NOCLIP)

    maidenSound(id, SOUND_MENU_NAV)
    maidenMenu(id, MENU_ROOT)
}

public maidenGodMode(id)
{
    new Float:flTakeDamage
    pev(id, pev_takedamage, flTakeDamage)
    set_pev(id, pev_takedamage, flTakeDamage == DAMAGE_NO ? DAMAGE_AIM : DAMAGE_NO)

    maidenSound(id, SOUND_MENU_NAV)
    maidenMenu(id, MENU_ROOT)
}

public fwdUse(iEnt, iCaller, iActivator, iType, Float:fValue)
{
    if ( !isMaiden(iEnt)
    || !is_user_alive(iActivator) )
        return HAM_IGNORED

    new eMaiden[MAIDEN]
    if ( maidenGet(eMaiden, iEnt) == -1 )
        return HAM_IGNORED

    new Float:fCurrentTime = get_gametime()
    if ( !(eMaiden[MAIDEN_FLAGS] & FLAG_ACTIVE)
    || (eMaiden[MAIDEN_FLAGS] & FLAG_USED)
    || !(eMaiden[MAIDEN_TEAM] & get_user_team(iActivator))
    || fCurrentTime < eMaiden[MAIDEN_NEXT_ACTIVE] )
        return HAM_IGNORED

    g_ePlayerData[iActivator][PDATA_NEXT_CHECK] = fCurrentTime
    if ( !g_ePlayerData[iActivator][PDATA_NEXT_MAIDEN] )
    {
        new iDuration
        iDuration = random_num(g_eSettings[SETTING_DEFAULT_HOLD_DURATION][0], g_eSettings[SETTING_DEFAULT_HOLD_DURATION][1])

        maidenBar(iActivator, iDuration)
        g_ePlayerData[iActivator][PDATA_MAIDEN_ID] = iEnt
        g_ePlayerData[iActivator][PDATA_NEXT_MAIDEN] = fCurrentTime + iDuration
    }
    else if ( !fValue )
    {
        maidenBar(iActivator, 0)
        g_ePlayerData[iActivator][PDATA_MAIDEN_ID] = 0
        g_ePlayerData[iActivator][PDATA_NEXT_MAIDEN] = 0.0
    }

    return HAM_IGNORED
}

public fwdObjectCaps(iEnt)
{
    if ( !isMaiden(iEnt) )
        return GetHamReturnStatus() == HAM_SUPERCEDE ? HAM_SUPERCEDE : HAM_IGNORED

    SetHamReturnInteger(FCAP_CONTINUOUS_USE | FCAP_ONOFF_USE)
    return HAM_SUPERCEDE
}

public fwdPreThink(id)
{
    if ( !is_user_alive(id) )
        return HAM_IGNORED

    static eMaiden[MAIDEN], iButton, Float:fCurrentTime
    iButton = pev(id, pev_button)
    fCurrentTime = get_gametime()

    if ( maidenGet(eMaiden, g_ePlayerData[id][PDATA_MAIDEN_GHOST]) != -1 )
    {
        if ( g_ePlayerData[id][PDATA_MAIDEN_GHOST] )
        {
            if ( fCurrentTime > g_ePlayerData[id][PDATA_NEXT_OFFSET] )
            {
                if ( iButton & IN_ATTACK )
                {
                    g_ePlayerData[id][PDATA_OFFSET]      += MAIDEN_OFFSET_STEP
                    g_ePlayerData[id][PDATA_OFFSET]      = floatclamp(g_ePlayerData[id][PDATA_OFFSET], MAIDEN_OFFSET_MIN, MAIDEN_OFFSET_MAX)
                    g_ePlayerData[id][PDATA_NEXT_OFFSET] = fCurrentTime + 0.1
                }
                else if ( iButton & IN_ATTACK2 )
                {
                    g_ePlayerData[id][PDATA_OFFSET]      -= MAIDEN_OFFSET_STEP
                    g_ePlayerData[id][PDATA_OFFSET]      = floatclamp(g_ePlayerData[id][PDATA_OFFSET], MAIDEN_OFFSET_MIN, MAIDEN_OFFSET_MAX)
                    g_ePlayerData[id][PDATA_NEXT_OFFSET] = fCurrentTime + 0.1
                }
            }

            set_pdata_float(id, PDATA_NEXT_ATTACK, fCurrentTime + 0.1, XO_CBASEPLAYER, XO_CBASEPLAYER)
            iButton &= ~(IN_ATTACK | IN_ATTACK2)
            set_pev(id, pev_button, iButton)

            maidenTrace(eMaiden, id)
        }
    }
    else if ( g_ePlayerData[id][PDATA_MAIDEN_ACTION] )
    {
        maidenCheck(id)
    }

    return HAM_IGNORED
}

public fwdKilled(id, iAttacker, bGib)
{
    DisableAction(id)
    g_ePlayerData[id][PDATA_MAIDEN_MENU] = 0
    if ( g_ePlayerData[id][PDATA_MAIDEN_GHOST] )
    {
        new eMaiden[MAIDEN], iItem
        if ( (iItem = maidenGet(eMaiden, g_ePlayerData[id][PDATA_MAIDEN_GHOST])) != -1 )
        {
            maidenKill(eMaiden[MAIDEN_ID])
            maidenRemove(iItem)
        }

        g_ePlayerData[id][PDATA_MAIDEN_GHOST] = 0
    }

    if ( id == g_iSilentVictim )
    {
        set_pev(id, pev_deadflag, DEAD_DISCARDBODY)
        g_iSilentVictim = 0
    }

    if ( g_ePlayerData[id][PDATA_NEXT_DIE] )
    {
        new eMaiden[MAIDEN], iItem
        if ( (iItem = maidenGet(eMaiden, g_ePlayerData[id][PDATA_MAIDEN_ID])) != -1 )
        {
            g_ePlayerData[id][PDATA_MAIDEN_ID] = 0
            g_ePlayerData[id][PDATA_NEXT_DIE] = 0.0
            eMaiden[MAIDEN_FLAGS] &= ~FLAG_USED
            eMaiden[MAIDEN_NEXT_OPEN] = get_gametime()
            maidenSetSeq(eMaiden[MAIDEN_ID], MAIDEN_SEQ_OPENED, eMaiden[MAIDEN_FRAMERATE])

            ArraySetArray(g_aMaiden, iItem, eMaiden)
        }
    }
}

stock maidenTrace(eMaiden[MAIDEN], id)
{
    new Float:fVec1[3]
    pev(id, pev_origin, eMaiden[MAIDEN_ORIGIN])
    pev(id, pev_v_angle, fVec1)
    engfunc(EngFunc_MakeVectors, fVec1)
    global_get(glb_v_forward, fVec1)

    xs_vec_mul_scalar(fVec1, g_ePlayerData[id][PDATA_OFFSET], fVec1)
    xs_vec_add(fVec1, eMaiden[MAIDEN_ORIGIN], fVec1)

    engfunc(EngFunc_TraceLine, eMaiden[MAIDEN_ORIGIN], fVec1, DONT_IGNORE_MONSTERS, id, 0)
    get_tr2(0, TR_vecEndPos, eMaiden[MAIDEN_ORIGIN])

    maidenSetBox(eMaiden)
    maidenSetOffset(eMaiden)
    set_pev(eMaiden[MAIDEN_ID], pev_origin, eMaiden[MAIDEN_ORIGIN])
}

stock maidenCheck(id)
{
    new eMaiden[MAIDEN], Float:fVec1[3], Float:fVec2[3], Float:fVec3[3], Float:fMins[3], Float:fMaxs[3], Float:fNearest[3]
    new iBest, Float:fBestDist, Float:fDot, Float:fDist

    pev(id, pev_origin, fVec1)
    pev(id, pev_view_ofs, fVec2)
    xs_vec_add(fVec1, fVec2, fVec1)

    pev(id, pev_v_angle, fVec2)
    engfunc(EngFunc_MakeVectors, fVec2)
    global_get(glb_v_forward, fVec2)

    iBest = -1
    fBestDist = MAIDEN_CHECK
    for ( new i = 0; i < g_iMaiden; i ++ )
    {
        ArrayGetArray(g_aMaiden, i, eMaiden)
        xs_vec_sub(eMaiden[MAIDEN_ORIGIN], fVec1, fVec3)
        fDot = xs_vec_dot(fVec2, fVec3)

        if ( fDot < 0.0 )
            continue

        pev(eMaiden[MAIDEN_ID], pev_absmin, fMins)
        pev(eMaiden[MAIDEN_ID], pev_absmax, fMaxs)
        xs_vec_mul_scalar(fVec2, fDot, fVec3)
        xs_vec_add(fVec3, fVec1, fVec3)

        fNearest[0] = floatclamp(fVec3[0], fMins[0], fMaxs[0])
        fNearest[1] = floatclamp(fVec3[1], fMins[1], fMaxs[1])
        fNearest[2] = floatclamp(fVec3[2], fMins[2], fMaxs[2])
        fDist = get_distance_f(fVec3, fNearest)
        if ( fDist < fBestDist )
        {
            fBestDist = fDist
            iBest = i
        }
    }

    if ( iBest != -1
    && g_ePlayerData[id][PDATA_MAIDEN_MENU] != iBest )
    {
        ArrayGetArray(g_aMaiden, g_ePlayerData[id][PDATA_MAIDEN_MENU], eMaiden)
        maidenSelect(eMaiden, eMaiden[MAIDEN_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

        g_ePlayerData[id][PDATA_MENU_TRACE] = true
        g_ePlayerData[id][PDATA_MAIDEN_MENU] = iBest
        maidenMenu(id, g_ePlayerData[id][PDATA_MENU_TYPE])
    }
}

stock maidenShake(eMaiden[MAIDEN])
{
    new Float:fOrigin[3]
    for ( new id = 1; id <= g_iMaxPlayers; id ++ )
    {
        if ( !is_user_alive(id) )
            continue

        pev(id, pev_origin, fOrigin)
        if ( xs_vec_distance(fOrigin, eMaiden[MAIDEN_ORIGIN]) > g_eSettings[SETTING_DEFAULT_SHAKE_DISTANCE] )
            continue

        message_begin(MSG_ONE_UNRELIABLE, g_iScreenShake, .player = id)
        write_short(g_eSettings[SETTING_DEFAULT_SHAKE_AMPLITUDE] * 4096)
        write_short(g_eSettings[SETTING_DEFAULT_SHAKE_DURATION] * 4096)
        write_short(g_eSettings[SETTING_DEFAULT_SHAKE_FREQUENCY] * 4096)
        message_end()
    }
}

stock maidenSetBox(eMaiden[MAIDEN])
{
    new Float:fMins[3], Float:fMaxs[3],
        Float:fForward[3], Float:fRight[3], Float:fUp[3],
        Float:fCorners[8][3]

    eMaiden[MAIDEN_ANGLES][0] = -eMaiden[MAIDEN_ANGLES][0]
    engfunc(EngFunc_AngleVectors, eMaiden[MAIDEN_ANGLES], fForward, fRight, fUp)
    xs_vec_copy(g_eSettings[SETTING_MINS], fMins)
    xs_vec_copy(g_eSettings[SETTING_MAXS], fMaxs)

    for ( new i = 0; i < 8; i ++ )
    {
        fCorners[i][0] = (i & 1) ? fMaxs[0] : fMins[0]
        fCorners[i][1] = (i & 2) ? fMaxs[1] : fMins[1]
        fCorners[i][2] = (i & 4) ? fMaxs[2] : fMins[2]

        boxRotate(fCorners[i], fForward, fRight, fUp)
    }

    xs_vec_copy(fCorners[0], fMins)
    xs_vec_copy(fCorners[0], fMaxs)
    for ( new i = 1; i < 8; i ++ )
    {
        fMins[0] = floatmin(fMins[0], fCorners[i][0])
        fMins[1] = floatmin(fMins[1], fCorners[i][1])
        fMins[2] = floatmin(fMins[2], fCorners[i][2])

        fMaxs[0] = floatmax(fMaxs[0], fCorners[i][0])
        fMaxs[1] = floatmax(fMaxs[1], fCorners[i][1])
        fMaxs[2] = floatmax(fMaxs[2], fCorners[i][2])
    }

    xs_vec_copy(fMins, eMaiden[MAIDEN_MINS])
    xs_vec_copy(fMaxs, eMaiden[MAIDEN_MAXS])
}

stock boxRotate(Float:fLocal[3], Float:fForward[3], Float:fRight[3], Float:fUp[3])
{
    new Float:fOut[3]
    fOut[0] = fLocal[0] * fForward[0] - fLocal[1] * fRight[0] + fLocal[2] * fUp[0]
    fOut[1] = fLocal[0] * fForward[1] - fLocal[1] * fRight[1] + fLocal[2] * fUp[1]
    fOut[2] = fLocal[0] * fForward[2] - fLocal[1] * fRight[2] + fLocal[2] * fUp[2]

    xs_vec_copy(fOut, fLocal)
}

stock maidenSetOffset(eMaiden[MAIDEN])
{
    new Float:fGaps[6], Float:fVec1[3], Float:fCurrentGap
    fGaps[0] = -eMaiden[MAIDEN_MINS][0]
    fGaps[1] = eMaiden[MAIDEN_MAXS][0]
    fGaps[2] = -eMaiden[MAIDEN_MINS][1]
    fGaps[3] = eMaiden[MAIDEN_MAXS][1]
    fGaps[4] = -eMaiden[MAIDEN_MINS][2]
    fGaps[5] = eMaiden[MAIDEN_MAXS][2]

    if ( eMaiden[MAIDEN_FLAGS] & FLAG_GROUND )
    {
        xs_vec_sub(eMaiden[MAIDEN_ORIGIN], Float:{0.0, 0.0, 9999.9}, fVec1)
        engfunc(EngFunc_TraceLine, eMaiden[MAIDEN_ORIGIN], fVec1, DONT_IGNORE_MONSTERS, eMaiden[MAIDEN_ID], 0)
        get_tr2(0, TR_vecEndPos, eMaiden[MAIDEN_ORIGIN])
    }

    for ( new i = 5; i >= 0; i -- )
    {
        xs_vec_mul_scalar(g_fDirections[i], 9999.9, fVec1)
        xs_vec_add(fVec1, eMaiden[MAIDEN_ORIGIN], fVec1)
        engfunc(EngFunc_TraceLine, eMaiden[MAIDEN_ORIGIN], fVec1, DONT_IGNORE_MONSTERS, eMaiden[MAIDEN_ID], 0)
        get_tr2(0, TR_vecEndPos, fVec1)
        fCurrentGap = xs_vec_distance(eMaiden[MAIDEN_ORIGIN], fVec1)

        if ( fCurrentGap < fGaps[i] )
        {
            get_tr2(0, TR_vecPlaneNormal, fVec1)
            xs_vec_mul_scalar(fVec1, fGaps[i] - fCurrentGap, fVec1)
            xs_vec_add(eMaiden[MAIDEN_ORIGIN], fVec1, eMaiden[MAIDEN_ORIGIN])
        }
    }
}

stock maidenSetSeq(iEnt, iSeq, Float:fFramerate)
{
    set_pev(iEnt, pev_sequence, iSeq)
    set_pev(iEnt, pev_frame, 0.0)
    set_pev(iEnt, pev_framerate, fFramerate)
    set_pev(iEnt, pev_animtime, get_gametime())
}

stock maidenSetSize(eMaiden[MAIDEN])
{
    maidenSelect(eMaiden, TARGET_CLEAR)
    engfunc(EngFunc_SetOrigin, eMaiden[MAIDEN_ID], eMaiden[MAIDEN_ORIGIN])
    set_pev(eMaiden[MAIDEN_ID], pev_angles, eMaiden[MAIDEN_ANGLES])
    set_pev(eMaiden[MAIDEN_ID], pev_solid, eMaiden[MAIDEN_FLAGS] & FLAG_SHOW ? SOLID_BBOX : SOLID_NOT)
    set_pev(eMaiden[MAIDEN_ID], pev_movetype, MOVETYPE_NONE)

    engfunc(EngFunc_SetSize, eMaiden[MAIDEN_ID], eMaiden[MAIDEN_MINS], eMaiden[MAIDEN_MAXS])
    maidenCreateView(eMaiden)
}

stock maidenSetState(eMaiden[MAIDEN])
{
    if ( eMaiden[MAIDEN_FLAGS] & FLAG_SHOW )
    {
        set_pev(eMaiden[MAIDEN_ID], pev_solid, SOLID_BBOX)
        maidenSelect(eMaiden, TARGET_CLEAR)
    }
    else
    {
        set_pev(eMaiden[MAIDEN_ID], pev_solid, SOLID_NOT)
        maidenSelect(eMaiden, TARGET_HIDE)
    }
}

stock maidenStrip(id)
{
    new iWeapons[32], iNum, szName[32], iEnt
    get_user_weapons(id, iWeapons, iNum)
    for ( new i; i < iNum; i ++ )
    {
        if ( !get_weaponname(iWeapons[i], szName, charsmax(szName)) )
            continue

        iEnt = -1
        while ( (iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "classname", szName)) > 0 )
        {
            if ( pev(iEnt, pev_owner) != id )
                continue

            ExecuteHam(Ham_RemovePlayerItem, id, iEnt)
            user_has_weapon(id, iWeapons[i], 0)
            ExecuteHamB(Ham_Item_Kill, iEnt)
            break
        }
    }
}

stock maidenOffset(eMaiden[MAIDEN], id)
{
    new Float:fAng[3], Float:fFwd[3], Float:fRight[3], Float:fOrigin[3]
    xs_vec_copy(eMaiden[MAIDEN_ANGLES], fAng)
    fAng[0] = 0.0
    fAng[2] = 0.0
    engfunc(EngFunc_AngleVectors, fAng, fFwd, fRight, NULL_VECTOR)

    xs_vec_copy(eMaiden[MAIDEN_ORIGIN], fOrigin)
    xs_vec_add_scaled(fOrigin, fFwd, g_fPlayerOffset[0], fOrigin)
    xs_vec_add_scaled(fOrigin, fRight, g_fPlayerOffset[1], fOrigin)
    fOrigin[2] += g_fPlayerOffset[2]

    engfunc(EngFunc_SetOrigin, id, fOrigin)
    set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0})
    set_pev(id, pev_angles, fAng)
    set_pev(id, pev_v_angle, fAng)
    set_pev(id, pev_fixangle, 1)
}

stock maidenMaiden(eMaiden[MAIDEN], id, bool:bForced = false)
{
    if ( !pev_valid(eMaiden[MAIDEN_VIEW]) )
        return

    maidenStrip(id)
    maidenOffset(eMaiden, id)
    maidenSetSeq(eMaiden[MAIDEN_ID], MAIDEN_SEQ_CLOSE, eMaiden[MAIDEN_FRAMERATE])
    maidenSound(eMaiden[MAIDEN_ID], SOUND_OPEN, false)
    eMaiden[MAIDEN_FLAGS] |= FLAG_USED
    g_ePlayerData[id][PDATA_MAIDEN_ID] = eMaiden[MAIDEN_ID]
    g_ePlayerData[id][PDATA_NEXT_DIE] = get_gametime() + (MAIDEN_DURATION_CLOSE / eMaiden[MAIDEN_FRAMERATE])
    set_pev(id, pev_movetype, MOVETYPE_NONE)
    set_pev(id, pev_flags, pev(id, pev_flags) | FL_FROZEN)
    engfunc(EngFunc_SetView, id, eMaiden[MAIDEN_VIEW])

    if ( g_eSettings[SETTING_WRITE_MESSAGE_ON_DEATH] )
        maidenMessage(id, bForced)

    if ( g_eSettings[SETTING_PLAY_SOUND_ON_DEATH] )
        for ( new i = 1; i <= g_iMaxPlayers; i ++ )
            maidenSound(i, SOUND_MAIDEN)
}

stock maidenBar(id, iDuration)
{
    message_begin_f(MSG_ONE_UNRELIABLE, g_iBarTime, .player = id)
    write_short(iDuration)
    message_end()
}

stock maidenSelect(eMaiden[MAIDEN], iAction)
{
    if ( iAction == TARGET_SELECT )
    {
        if ( eMaiden[MAIDEN_FLAGS] & FLAG_ACTIVE )  { set_pev(eMaiden[MAIDEN_ID], pev_rendercolor, Float:{0.0, 255.0, 0.0}); }
        else                                                { set_pev(eMaiden[MAIDEN_ID], pev_rendercolor, Float:{255.0, 0.0, 0.0}); }

        set_pev(eMaiden[MAIDEN_ID], pev_renderfx, kRenderFxGlowShell)
        set_pev(eMaiden[MAIDEN_ID], pev_rendermode, kRenderTransAlpha)
        set_pev(eMaiden[MAIDEN_ID], pev_renderamt, 16.0)
    }
    else if ( iAction == TARGET_GHOST )
    {
        set_pev(eMaiden[MAIDEN_ID], pev_renderfx, kRenderFxNone)
        set_pev(eMaiden[MAIDEN_ID], pev_rendercolor, Float:{255.0, 255.0, 255.0})
        set_pev(eMaiden[MAIDEN_ID], pev_rendermode, kRenderTransAlpha)
        set_pev(eMaiden[MAIDEN_ID], pev_renderamt, float(MAIDEN_GHOST_ALPHA))
    }
    else if ( iAction == TARGET_HIDE )
    {
        set_pev(eMaiden[MAIDEN_ID], pev_renderfx, kRenderFxNone)
        set_pev(eMaiden[MAIDEN_ID], pev_rendercolor, Float:{255.0, 255.0, 255.0})
        set_pev(eMaiden[MAIDEN_ID], pev_rendermode, kRenderTransAlpha)
        set_pev(eMaiden[MAIDEN_ID], pev_renderamt, 0.0)
    }
    else if ( iAction == TARGET_CLEAR )
    {
        set_pev(eMaiden[MAIDEN_ID], pev_renderfx, kRenderFxNone)
        set_pev(eMaiden[MAIDEN_ID], pev_rendercolor, Float:{255.0, 255.0, 255.0})
        set_pev(eMaiden[MAIDEN_ID], pev_rendermode, kRenderNormal)
        set_pev(eMaiden[MAIDEN_ID], pev_renderamt, 255.0)
    }
}

stock maidenMessage(id, bool:bForced = false)
{
    new szName[MAX_NAME_LENGTH], szMessage[128], iHudObject
    get_user_name(id, szName, charsmax(szName))

    if ( bForced )
        ArrayGetString(g_eSettings[SETTING_DEFAULT_MESSAGE_FORCED], random(ArraySize(g_eSettings[SETTING_DEFAULT_MESSAGE_FORCED])), szMessage, charsmax(szMessage))
    else
        ArrayGetString(g_eSettings[SETTING_DEFAULT_MESSAGE], random(ArraySize(g_eSettings[SETTING_DEFAULT_MESSAGE])), szMessage, charsmax(szMessage))

    switch ( g_iHudSlot )
    {
        case 0:  iHudObject = g_iHudObject_1
        case 1:  iHudObject = g_iHudObject_2
        default: iHudObject = g_iHudObject_3
    }

    set_hudmessage(g_eSettings[SETTING_HUD_COLOR][0], g_eSettings[SETTING_HUD_COLOR][1], g_eSettings[SETTING_HUD_COLOR][2], g_eSettings[SETTING_HUD_X], g_iHudCurrentY,
    g_eSettings[SETTING_HUD_EFFECT], g_eSettings[SETTING_HUD_FXTIME], g_eSettings[SETTING_HUD_HOLDTIME], g_eSettings[SETTING_HUD_FADEIN], g_eSettings[SETTING_HUD_FADEOUT])
    ShowSyncHudMsg(0, iHudObject, "%s%s", szName, szMessage)

    g_iHudSlot ++
    g_iHudCurrentY += HUD_Y_STEP
    if ( g_iHudCurrentY > HUD_Y_MAX )
    {
        g_iHudCurrentY = g_eSettings[SETTING_HUD_Y]
        g_iHudSlot = 0
    }
}

stock maidenSound(iEnt, iSound, bool:bPlayer = true)
{
    new szSample[64]
    switch( iSound )
    {
        case SOUND_MENU_NAV:    copy(szSample, charsmax(szSample), SOUND_NAV)
        case SOUND_MENU_REMOVE: copy(szSample, charsmax(szSample), SOUND_REMOVE)
        case SOUND_MENU_ALERT:  copy(szSample, charsmax(szSample), SOUND_ALERT)
        case SOUND_MAIDEN:      ArrayGetString(g_eSettings[SETTING_DEFAULT_SOUND], random(ArraySize(g_eSettings[SETTING_DEFAULT_SOUND])), szSample, charsmax(szSample))
        case SOUND_OPEN:        ArrayGetString(g_eSettings[SETTING_DEFAULT_SOUND_OPEN], random(ArraySize(g_eSettings[SETTING_DEFAULT_SOUND_OPEN])), szSample, charsmax(szSample))
        case SOUND_CLOSE:       ArrayGetString(g_eSettings[SETTING_DEFAULT_SOUND_CLOSE], random(ArraySize(g_eSettings[SETTING_DEFAULT_SOUND_CLOSE])), szSample, charsmax(szSample))
    }

    if ( bPlayer )
        client_cmd(iEnt, "spk %s", szSample)
    else
        engfunc(EngFunc_EmitSound, iEnt, CHAN_VOICE, szSample, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}

stock maidenReset()
{
    new eMaiden[MAIDEN]
    for ( new i = 0; i < g_iMaiden; i ++ )
    {
        ArrayGetArray(g_aMaiden, i, eMaiden)
        eMaiden[MAIDEN_FLAGS] &= ~FLAG_USED
        ArraySetArray(g_aMaiden, i, eMaiden)
    }

    for ( new id = 1; id <= g_iMaxPlayers; id ++ )
    {
        g_ePlayerData[id][PDATA_NEXT_MAIDEN] = 0.0
        g_ePlayerData[id][PDATA_NEXT_CHECK] = 0.0
    }
}

stock maidenGet(eMaiden[MAIDEN], iEnt)
{
    if ( !isMaiden(iEnt) )
        return -1

    new iItem
    iItem = pev(iEnt, MAIDEN_ARRAY_ITEM)
    if ( iItem < 0 || iItem >= g_iMaiden )
        return -1

    ArrayGetArray(g_aMaiden, iItem, eMaiden)
    return iItem
}

stock bool:isMaiden(iEnt)
{
    return pev_valid(iEnt) && pev(iEnt, pev_impulse) == MAIDEN_KEY
}

stock maidenKill(iEnt)
{
    if ( pev_valid(iEnt) )
        set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
}

stock parseSetting(iType, szValue[], iValueLen, any:aOutput[], iOutputLength)
{
    switch ( iType )
    {
        case DTYPE_INT:
        {
            new szTok[MAX_VALUE_LENGTH], szTmp[MAX_VALUE_LENGTH], iCounter
            copy(szTmp, charsmax(szTmp), szValue)

            strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
            trim(szTok)
            while ( szTok[0] )
            {
                aOutput[iCounter ++] = str_to_num(szTok)

                strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
                trim(szTok)
            }
        }
        case DTYPE_FLOAT:
        {
            new szTok[MAX_VALUE_LENGTH], szTmp[MAX_VALUE_LENGTH], iCounter
            copy(szTmp, charsmax(szTmp), szValue)

            strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
            trim(szTok)
            while ( szTok[0] )
            {
                aOutput[iCounter ++] = str_to_float(szTok)

                strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
                trim(szTok)
            }
        }
        case DTYPE_FLAGS:
        {
            aOutput[0] = read_flags(szValue)
        }
        case DTYPE_STRING_MODEL:
        {
            copy(aOutput, iOutputLength, szValue)
            if ( !g_bFileWasRead ) precache_model(szValue)
        }
        case DTYPE_STRING_SOUND:
        {
            copy(aOutput, iOutputLength, szValue)
            if ( !g_bFileWasRead ) precache_sound(szValue)
        }
        case DTYPE_ARRAY_MESSAGE:
        {
            replace_all(szValue, iValueLen, "^"", " ")
            replace_all(szValue, iValueLen, "^^n", "^n")
            ArrayPushString(aOutput[0], szValue)
        }
        case DTYPE_ARRAY_MODEL:
        {
            precache_model(szValue)
            ArrayPushString(aOutput[0], szValue)
        }
        case DTYPE_ARRAY_SOUND:
        {
            ArrayPushString(aOutput[0], szValue)
            if ( !g_bFileWasRead ) precache_sound(szValue)
        }
        case DTYPE_STRING_MODEL_ID:
        {
            if ( !g_bFileWasRead )
                aOutput[0] = precache_model(szValue)
        }
        case DTYPE_ARRAY_MODEL_ID:
        {
            if ( !g_bFileWasRead )
                ArrayPushCell(aOutput[0], precache_model(szValue))
        }
    }
}

stock EnableAction(id)
{
    if ( !g_ePlayerData[id][PDATA_MAIDEN_ACTION] )
    {
        new eMaiden[MAIDEN]
        for ( new i = 0; i < g_iMaiden; i ++ )
        {
            ArrayGetArray(g_aMaiden, i, eMaiden)
            if ( eMaiden[MAIDEN_FLAGS] & FLAG_SHOW )
                continue

            maidenSelect(eMaiden, TARGET_GHOST)
        }

        g_ePlayerData[id][PDATA_MAIDEN_ACTION] = true
        if ( ++ g_iActivePlayers == 1 )
            EnableForward()
    }
}

stock DisableAction(id)
{
    if ( g_ePlayerData[id][PDATA_MAIDEN_ACTION] )
    {
        new eMaiden[MAIDEN]
        for ( new i = 0; i < g_iMaiden; i ++ )
        {
            ArrayGetArray(g_aMaiden, i, eMaiden)
            if ( eMaiden[MAIDEN_FLAGS] & FLAG_SHOW )
                continue

            maidenSelect(eMaiden, TARGET_HIDE)
        }

        g_ePlayerData[id][PDATA_MAIDEN_ACTION] = false
        if ( -- g_iActivePlayers == 0 )
            DisableForward()
    }
}

stock EnableForward()
{
    EnableHamForward(g_iFwdPreThink)
}

stock DisableForward()
{
    DisableHamForward(g_iFwdPreThink)
}

stock EnableMaiden()
{
    EnableHamForward(g_iFwdUse)
    EnableHamForward(g_iFwdObjectCaps)
}

stock DisableMaiden()
{
    DisableHamForward(g_iFwdUse)
    DisableHamForward(g_iFwdObjectCaps)
}

stock LogConfigError(const iLine, const szText[], any:...)
{
    new szError[MAX_PLATFORM_PATH_LENGTH]
    vformat(szError, charsmax(szError), szText, 3)

    log_to_file(ERROR_FILE, "^nLine %d: %s", iLine, szError)
}





