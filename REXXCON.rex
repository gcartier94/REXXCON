/*REXX----------------------------------------------------------------*/
/*                                                                    */
/* NAME: REXXCON                                                     */
/*                                                                    */
/* FUNCTION: A simple to use REXX script to perform a connection test */
/* using the z/OS Web Enablement Toolkit with an external host.       */
/*                                                                    */
/*                                                                    */
/* DEPENDENCY: z/OS Web Enablement Toolkit should be available.       */
/* For further information check the "z/OS MVS Programming            */
/* Callable Services for High-Level Languages" documentation          */
/*                                                                    */
/* PROGRAM ENTRY                                                      */
/* in parm:                                                           */
/*          input_url: The host base url for the connection           */
/*                     i.e: "https://google.com"                      */
/*                                                                    */
/*          port_number: The remote host port for the connection.     */
/*                       Notice that the default for HTTP is 80 and   */
/*                       443 for HTTPS.                               */
/*                       i.e: "443"                                   */
/* PROGRAM EXIT                                                       */
/* return code: 00: Connection sucessful                              */
/*             -01: Connection failed                                 */
/*                                                                    */
/*                                                                    */
/*--------------------------------------------------------------------*/
/* DATES DESCRIPTION                                                  */
/*--------------------------------------------------------------------*/
/* 06/20/20 - Initial Version                                         */
/* 08/28/20 - Customization                                           */
/*--------------------------------------------------------------------*/

Parse arg input_url port_number

/* Basic connection information */
host_base_url =  input_url
connection_port = port_number

/* Security variables */
use_keyring = 'NO'
ssl_keyring = '<KeyRing Owner>/<KeyRing>'


/* ------------------------------- */
/*  SCRIPT EXECUTION               */
/* ------------------------------- */
Call Build_Header
Call Rexx_Log 'Info', 'Initiating REXXCON...'
Call Get_Toolkit_Constants
Call Create_Handler HWTH_handleType_CONNECTION
Call Setup_Http_Connection host_base_url
Call Connect_To_Host
If RC == 0 Then Do
  Call Rexx_Log 'Info', 'Connection successful!'
  Call Rexx_Log 'Info', 'Initiating disconnection procedures...'
  Call Disconnect_From_Host
  Call Terminate_Handler connection_handle, HWTH_NOFORCE
  Call Rexx_Log 'Info', 'Have a great day!'
  Exit 0
End
Else Do
  Call Rexx_Log 'Error', 'Connection failed!'
  Exit -1
End

/* End of Script */


/* ------------------------------- */
/*  SUBROUTINES                    */
/* ------------------------------- */
Get_Toolkit_Constants:
  Call Rexx_Log 'Info', 'Retrieving toolkit constants...'
  Call hwtcalls 'on'
  Call syscalls 'SIGOFF'
  Address hwthttp "hwtconst ",
                  "toolkit_rc ",
                  "toolkit_diag."
  rexx_rc = RC
  If Toolkit_Has_Error(rexx_rc,toolkit_rc) Then Do
     Call Toolkit_Surface_Diag 'hwtconst', rexx_rc, toolkit_rc, toolkit_diag.
     Fatal_Error( '** hwtconst (hwthttp) failure **' , 16)
  End
  Return 0

Create_Handler:
  Call Rexx_Log 'Info', 'Creating handler...'
  handle_type = Arg(1)
  toolkit_rc = -1
  toolkit_diag. = ''
  Address hwthttp "hwthinit ",
                  "toolkit_rc ",
                  "handle_type ",
                  "handle_out ",
                  "toolkit_diag."
  rexx_rc = RC
  If Toolkit_Has_Error(rexx_rc,toolkit_rc) Then Do
     Return Fatal_Error( '** hwthinit failure **' , 16)
  End
  If handle_type == HWTH_handleType_CONNECTION Then
     connection_handle = handle_out
  Else
     request_handle = handle_out
  Return 0

Terminate_Handler:
  Call Rexx_Log 'Info', 'Terminating handler...'
  handleIn = Arg(1)
  force_option = Arg(2)
  toolkit_rc = -1
  toolkit_diag. = ''
  Address hwthttp "hwthterm ",
                  "toolkit_rc ",
                  "handleIn",
                  "force_option ",
                  "toolkit_diag."
  rexx_rc = RC
  If Toolkit_Has_Error(rexx_rc,toolkit_rc) Then Do
     Call Toolkit_Surface_Diag 'hwthterm', rexx_rc, toolkit_rc, toolkit_diag.
     Return Fatal_Error( '** hwthterm failure **' , 16)
  End
  Return 0


/*---------------------------*/
/*                           */
/* HTTP CONNECTION FUNCTIONS */
/*                           */
/*---------------------------*/

Setup_Http_Connection:
  Call Rexx_Log 'Info', 'Setting up connection...'
  toolkit_rc = -1
  toolkit_diag. = ''
  Address hwthttp "hwthset ",
                  "toolkit_rc ",
                  "connection_handle ",
                  "HWTH_OPT_VERBOSE ",
                  "HWTH_VERBOSE_ON ",
                  "toolkit_diag."
  rexx_rc = RC
  If Toolkit_Has_Error(rexx_rc,toolkit_rc) Then Do
     Return Fatal_Error( '** hwthset (HWTH_OPT_VERBOSE) failure **' , 16)
  End


  /*-------------------------------------------------------------*/
  /* This code will be executed only if the module is configured */
  /* to use SSL keyring for connection                           */
  /*-------------------------------------------------------------*/
  If use_keyring == 'YES' Then Do
    toolkit_rc = -1
    toolkit_diag. = ''
    Address hwthttp "hwthset ",
                    "toolkit_rc ",
                    "connection_handle ",
                    "HWTH_OPT_USE_SSL ",
                    "HWTH_SSL_USE ",
                    "toolkit_diag."
    rexx_rc = RC
    If Toolkit_Has_Error(rexx_rc,toolkit_rc) Then Do
       Call Toolkit_Surface_Diag 'hwthset', rexx_rc, toolkit_rc, toolkit_diag.
       Return Fatal_Error( '** hwthset (HWTH_OPT_USE_SSL) failure **' , 16)
    End

    /* Defining the SSL Version */
    toolkit_rc = -1
    toolkit_diag. = ''
    Address hwthttp "hwthset ",
                    "toolkit_rc ",
                    "connection_handle ",
                    "HWTH_OPT_SSLVERSION ",
                    "HWTH_SSLVERSION_TLSv12",
                    "toolkit_diag."
    rexx_rc = RC
    If Toolkit_Has_Error(rexx_rc,toolkit_rc) Then Do
       Call Toolkit_Surface_Diag 'hwthset', rexx_rc, toolkit_rc, toolkit_diag.
       Return Fatal_Error( '** hwthset (HWTH_OPT_SSLVERSION) failure **' , 16)
    End

    /* Set SSL key type */
    toolkit_rc = -1
    toolkit_diag. = ''
    Address hwthttp "hwthset ",
                    "toolkit_rc ",
                    "connection_handle ",
                    "HWTH_OPT_SSLKEYTYPE ",
                    "HWTH_SSLKEYTYPE_KEYRINGNAME ",
                    "toolkit_diag."
    rexx_rc = RC
    If Toolkit_Has_Error(rexx_rc,toolkit_rc) Then Do
       Call Toolkit_Surface_Diag 'hwthset', rexx_rc, toolkit_rc, toolkit_diag.
       Return Fatal_Error( '** hwthset (HWTH_OPT_SSLKEYTYPE) failure **' , 16)
    End

    /* Set the SSL Keyring previously defined in the environment variables */
    toolkit_rc = -1
    toolkit_diag. = ''
    Address hwthttp "hwthset ",
                    "toolkit_rc ",
                    "connection_handle ",
                    "HWTH_OPT_SSLKEY ",
                    "ssl_keyring ",
                    "toolkit_diag."
    rexx_rc = RC
    If Toolkit_Has_Error(rexx_rc,toolkit_rc) Then Do
       Call Toolkit_Surface_Diag 'hwthset', rexx_rc, toolkit_rc, toolkit_diag.
       Return Fatal_Error( '** hwthset (HWTH_OPT_SSLKEY) failure **' , 16)
    End
  End /* End of SSL configurations */

  /* Set connection URI */
  connection_uri = Arg(1)
  toolkit_rc = -1
  toolkit_diag. = ''
  Address hwthttp "hwthset ",
                  "toolkit_rc ",
                  "connection_handle ",
                  "HWTH_OPT_URI ",
                  "connection_uri ",
                  "toolkit_diag."
  rexx_rc = RC
  If Toolkit_Has_Error(rexx_rc,toolkit_rc) Then Do
     Call Toolkit_Surface_Diag 'hwthset', rexx_rc, toolkit_rc, toolkit_diag.
     Return Fatal_Error( '** hwthset (HWTH_OPT_URI) failure **' , 16)
  End

  /* Set connection PORT */
  toolkit_rc = -1
  toolkit_diag. = ''
  Address hwthttp "hwthset ",
                  "toolkit_rc ",
                  "connection_handle ",
                  "HWTH_OPT_PORT ",
                  "connection_port ",
                  "toolkit_diag."
  rexx_rc = RC
  If Toolkit_Has_Error(rexx_rc,toolkit_rc) Then Do
     Call Toolkit_Surface_Diag 'hwthset', rexx_rc, toolkit_rc, toolkit_diag.
     Return Fatal_Error( '** hwthset (HWTH_OPT_PORT) failure **' , 16)
  End

  /* Set cookie configuration */
  toolkit_rc = -1
  toolkit_diag. = ''
  Address hwthttp "hwthset ",
                  "toolkit_rc ",
                  "connection_handle ",
                  "HWTH_OPT_COOKIETYPE ",
                  "HWTH_COOKIETYPE_SESSION ",
                  "toolkit_diag."
  rexx_rc = RC
  If Toolkit_Has_Error(rexx_rc,toolkit_rc) Then Do
     Call Toolkit_Surface_Diag 'hwthset', rexx_rc, toolkit_rc, toolkit_diag.
     Return Fatal_Error( '** hwthset (HWTH_OPT_COOKIETYPE) failure **' , 16)
  End
Return 0

Connect_To_Host:
  Call Rexx_Log 'Info', 'Connecting to host...'
  toolkit_rc = -1
  toolkit_diag. = ''
  Address hwthttp "hwthconn ",
                  "toolkit_rc ",
                  "connection_handle ",
                  "toolkit_diag."
  rexx_rc = RC
  If Toolkit_Has_Error(rexx_rc,toolkit_rc) Then Do
    Call Toolkit_Surface_Diag 'hwthconn', rexx_rc, toolkit_rc, toolkit_diag.
    Return Fatal_Error( '** hwthconn failure **' , 16)
  End
  Return 0

Disconnect_From_Host:
  toolkit_rc = -1
  toolkit_diag. = ''
  Address hwthttp "hwthdisc ",
                  "toolkit_rc ",
                  "connection_handle ",
                  "toolkit_diag."
  rexx_rc = RC
  If Toolkit_Has_Error(rexx_rc,toolkit_rc) Then Do
     Return Fatal_Error( '** hwthdisc failure **' , 16)
  End
  Return 0

/*--------------------------*/
/*                          */
/* ERROR HANDLING FUNCTIONS */
/*                          */
/*--------------------------*/

Toolkit_Has_Error: Procedure
 rexx_rc = Arg(1)
 If rexx_rc <> 0 Then
    Return 1
 toolkit_rc = Strip(Arg(2),'L',0)
 If toolkit_rc == '' Then
       Return 0
 If toolkit_rc <= HWTJ_WARNING | toolkit_rc <= HWTH_WARNING Then
       Return 0
 Return 1

 Toolkit_Surface_Diag: Procedure Expose toolkit_diag.
  who = Arg(1)
  rexx_rc = Arg(2)
  toolkit_rc = Arg(3)
  Say
  Say '*ERROR* ('||who||') at time: '||Time()
  Say 'Rexx RC: '||rexx_rc||', Toolkit toolkit_rc: '||D2X(toolkit_rc)
  Say 'toolkit_diag.ReasonCode: '||toolkit_diag.HWTH_reasonCode
  Say 'toolkit_diag.ReasonDesc: '||toolkit_diag.HWTH_reasonDesc
  Say
  Return

Rexx_Log: Procedure
  type = Arg(1)
  message = Arg(2)
  Say '>> REXXCON ['||type||'] - ' message
  Return

Fatal_Error: Procedure
  reason = Arg(1)
  exit_code = Arg(2)
  Call Rexx_Log 'Error', 'Connection testing failed!'
  Call Rexx_Log 'Error', 'Fatal error due to: '||reason
  Exit exit_code


Build_Header: Procedure
  Say
  Say
  Say '--------------------------------------------------'
  Say '      ____  _______  ___  ____________  _   __    '
  Say '     / __ \/ ____/ |/ / |/ / ____/ __ \/ | / /    '
  Say '    / /_/ / __/  |   /|   / /   / / / /  |/ /     '
  Say '   / _, _/ /___ /   |/   / /___/ /_/ / /|  /      '
  Say '  /_/ |_/_____//_/|_/_/|_\____/\____/_/ |_/       '
  Say '--------------------------------------------------'
  Say
  Return