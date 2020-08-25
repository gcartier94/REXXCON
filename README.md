# REXXCON

A simple REXX tool to test TCP/IP HTTP/HTTPS connection with a remote host using the [z/OS Web Enablement Toolkit](https://www.ibm.com/support/knowledgecenter/SSLTBW_2.2.0/com.ibm.zos.v2r2.ieac100/ieac1-client-web-enablement.htm).


## Requirements

* z/OS Web Enablement Toolkit should be available. 

For further details make sure to check the z/OS MVS Programming Callable Services for High-Level Languages" documentation.


## Installation

Upload the REXXCON.rex code to a z/OS dataset with the following specifications

* LRECL: >= 80
* Record format: FB

## Usage

REXXCON takes 2 arguments:

1. input_url: The remote host URL (i.e https://google.com)
2. port_number: The remote port number for the connection (i.e 443 for HTTPS or 80 for HTTP)

You can call the REXXCON tool from either JCL or from another REXX script.

From JCL
```jcl
//TESTJCL JOB (AEA1,MVS),TESTCARD,CLASS=9,MSGCLASS=X,
// NOTIFY=&SYSUID
//STEP02 EXEC PGM=IKJEFT01
//SYSPROC DD DSN=<REXX.LIBRARY>,DISP=SHR
//SYSTSPRT DD SYSOUT=A
//SYSTSIN DD *
REXXCON https://google.com 443
/*
```

From REXX
```rexx
Call REXXCON "https://google.com" "443"
```

## Expected Output

The output might contain additional debug information, but the end result should have something like this:

```
 --------------------------------------------------
       ____  _______  ___  ____________  _   __
      / __ \/ ____/ |/ / |/ / ____/ __ \/ | / /
     / /_/ / __/  |   /|   / /   / / / /  |/ /
    / _, _/ /___ /   |/   / /___/ /_/ / /|  /
   /_/ |_/_____//_/|_/_/|_\____/\____/_/ |_/
 --------------------------------------------------

 >> REXXCON [Info] -  Initiating REXXCON...
 >> REXXCON [Info] -  Retrieving toolkit constants...
 >> REXXCON [Info] -  Creating handler...
 >> REXXCON [Info] -  Setting up connection...
 >> REXXCON [Info] -  Connecting to host...
 >> REXXCON [Info] -  Connection successful!
 >> REXXCON [Info] -  Initiating disconnection procedures...
 >> REXXCON [Info] -  Terminating handler...
 >> REXXCON [Info] -  Have a great day!
```

## Considerations regarding HTTPS

To connect using HTTPS (Some remote hosts only accept HTTPS) make sure to properly configure AT-TLS on your environment so the connection can be upgraded to HTTPS.

In absence of an AT-TLS policy you can create a SAF keyring containing the digital certificate of the remote host.

Once the Keyring is created update the REXX code with the following:

```rexx
/* Security variables */
use_keyring = 'YES'
ssl_keyring = '<KeyRing Owner>/<KeyRing>'
```

Where:

- use_keyring: Should be YES
- ssl_keyring: Should contain the Keyring in the format described above. (i.e "Userid/KeyRingName")

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License
[Apache-2.0](https://choosealicense.com/licenses/apache-2.0/)