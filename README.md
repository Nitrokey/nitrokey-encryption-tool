# Nitrokey Encryption Tool
Encryption Tool is a command line interface application which uses on-device RSA keys 
(through OpenSC and PKCS#11) to encrypt/decrypt AES key used in turn to 
perform operation on user data.

## Requirements

Following are requirements for the tool to work:
- Linux (library paths adjusted for Ubuntu 16.10), 
- Python 3 (with PIP), 
- OpenSC v0.17 (might not work with lower version),
- Python libraries from `requirements.txt`.

### Installation
#### Python
To install required Python 3 libraries please issue following command:
```bash
pip3 install -r requirements.txt --user
```
which will install required packages locally in user-level directory 
(as oppossed to global, OS-level).
It is possible to install Python dependencies in separate environment through `virtualenv` ([guide](http://docs.python-guide.org/en/latest/dev/virtualenvs/#lower-level-virtualenv)) 
or with recent `pipenv` ([guide](http://docs.python-guide.org/en/latest/dev/virtualenvs/#installing-pipenv)) tools. 

#### OpenSC
OpenSC compilation manual (if needed when not available from system's package repository) should be available on main project site.
[Here](https://github.com/OpenSC/OpenSC/wiki/Compiling-and-Installing-on-Unix-flavors) is for Linux.

## Usage

### Preparation
Before using Smart Card with the tool please make sure it has any RSA key generated in at least one of the slots.
If it is not the case please do so. Tool supports RSA with 2048 or 4096 bits.

Please run the tool to see are any PGP keys available to work with. 
Note: usually only `Encryption key` slot (`key 0`) could be used on OpenPGP Smart Card:
```bash
# Inserted custom OpenPGP v2.2 Smart Card
$ python3 encryption_tool.py
Namespace(cmd='status', pin=None, token=0, verbose=False)
Listing tokens (2):

Token 0. "User PIN (OpenPGP card)"
Please provide user PIN for the device (will not be echoed): 
Investigating device 0
Public RSA keys found: 2
Private RSA keys found: 2

Test key 0: <PublicKey label='Encryption key' id='02' 2048-bit RSA>
Decrypting data with the device / done
Encryption/decryption test result with key 0: success

Test key 1: <PublicKey label='Authentication key' id='03' 2048-bit RSA>
Decrypting data with the device | done
Encryption/decryption test result with key 1: failure

Token 1. "User PIN (sig) (OpenPGP card)"
Investigating device 1
Public RSA keys found: 1
Private RSA keys found: 1

Test key 0: <PublicKey label='Signature key' id='01' 2048-bit RSA>
Decrypting data with the device \ done
Encryption/decryption test result with key 0: failure

Working configurations:
Token 0 ("User PIN (OpenPGP card)"): key 0

```

#### Nitrokey HSM (SmartCard-HSM)
Tool supports generating keys with Nitrokey HSM. 
Command `--create_keys` will do so as in following:

```bash
python3 encryption_tool.py --token 0 create_keys "key label"
```
This will create RSA keypair with 2048 bits.

The `--token` switch allow to choose on which device one wants to work on.
To list all connected devices please use `list_tokens` command:
```bash
# OpenPGP card inserted
$ python3 encryption_tool.py list_tokens
Namespace(cmd='list_tokens', pin=None, token=0)
Listing tokens (2):
0. User PIN (OpenPGP card)
1. User PIN (sig) (OpenPGP card)
```

#### Nitrokey Pro/Storage (OpenPGP v2.1+)
Unfortunately Encryption Tool cannot generate the keys on OpenPGP cards. Please use GPG to do so as in following snippet:
```bash
$ gpg --card-edit
# inside GPG prompt
> admin
> generate
# please fill in the details, might be bogus if desired
> (...)
# once finished it is possible to verify key generation with:
$ gpg --card-status
``` 

### Commands
Available commands are shown in Tool's help screen:
```bash
$ python3 encryption_tool.py --help
usage: encryption_tool.py [-h] [--token TOKEN] [--pin PIN]
                          {decrypt,encrypt,list_keys,list_tokens,status,create_keys}
                          ...

Encrypt/decrypt or generate key through PKCS#11

positional arguments:
  {decrypt,encrypt,list_keys,list_tokens,status,create_keys}
                        Action to be run by the tool. Each action has its own
                        help (use <action> --help). Description:
    decrypt             Decrypt file with private key from the device
    encrypt             Encrypt file with public key from the device
    list_keys           List public keys saved on token (no PIN needed)
    list_tokens         List available tokens
    status              Show what RSA keys are available and perform simple
                        encryption/decryption test. Default action.
    create_keys         Create RSA keys for use in tool. Warning: it will not
                        work with OpenSC in version 0.16. Only Smartcard-HSM
                        is supported.

optional arguments:
  -h, --help            show this help message and exit
  --token TOKEN         Token number to work on. Use list_tokens to see what
                        tokens are available. (default: 0)
  --pin PIN             User PIN. Will be asked when needed if not provided
                        through switch.
```

For commands parameters and detailed command help please add `--help` switch to given command, eg.:
```bash
$ python3 encryption_tool.py decrypt --help
usage: encryption_tool.py decrypt [-h] input output keyid

positional arguments:
  input       Input file
  output      Output file
  keyid       Key pair number to work on. Use list_keys to see what key pairs
              are available

optional arguments:
  -h, --help  show this help message and exit
```

### Running
Before running the tool please make sure `scdaemon` is not running 
(especially after running `gpg --card-status` or `--card-edit`) 
and `pcscd` process is started, like with the following snippet:
```bash
sudo killall scdaemon pcscd
sudo pcscd
```

Otherwise the tool might not claim the device to work and following message will be shown:
```bash
Traceback (most recent call last):
  File "encryption_tool.py", line 437, in <module>
    with get_session(tokenID=args.token, skipPin=True) as session:
  File "encryption_tool.py", line 61, in get_session
    raise RuntimeError(error_message)
RuntimeError: Cannot open token with ID 0. See if it is inserted or check if the Token ID is correct. Make sure pcscd (sudo pcscd) is running. Kill and run it again.
```
Simple device reinsertion to USB port instead might help too.

### Test script
A simple test script named `encryption_tool_test.sh` is available to test overall RSA+AES encryption/decryption operations. 

Please run `sudo bash encryption_tool_test.sh`. It will run the tool and compare its output 
after encryption->decryption operations with the input file, which is the script itself. `sudo` is needed to kill and restart `pcscd` and `scdaemon` services. 
It accepts optional file path as only argument,
```bash
sudo bash encryption_tool_test.sh [file_path]
```
in which case it will use chosen file as data source to test.
In the end besides the `diff`, `wc -l` and `ls -l` stats will be shown to the user on both input and output files.

## Tested environment
Tool was tested on 
- Ubuntu 16.10, 
- inside a docker container (not required), 
- OpenSC 0.17 (compiled from sources),

with:
- Nitrokey Pro/Storage (OpenPGP 2.1),
- Nitrokey HSM (SmartCard-HSM),
- Custom OpenPGP 2.2 card with Gemalto IDBRidge CT30, USB Smart Card Reader.