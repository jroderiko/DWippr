# DWippr

A utility for securely wiping drives and generating a NIST-800-88 compliant verification report, written in Bash.


# Installation
Clone the repository using this command:
`git clone https://github.com/jroderiko/DWippr`

Use the `dwnsetup.sh` script to configure DWippr. This will create the log directory and config file. During the setup you can choose disks to exclude when running DWippr. This can also be done by adding them manually to `dw.conf` under `NONO_DISKS`.

# Usage

The following usage assumes the default configuration. Variables will be included where relevant like this `$VAR`.

When running DWippr you'll be prompted for the technician's name (probably you) `$TECH`. Next you'll be prompted for the Batch Number `$DSKSRC`. The source field is used for generating the log file names.

A list of available disks will be printed (excluding those in `$NONO_DISKS`). Simply type the name of the disk like so `sda` and press Enter.

DWippr uses "sd" and "nvme" to determine the disk type and use the appropriate tool to scan the disk. If the Sanitize method is supported, it is executed. Otherwise `nvme format` and `hdparm` Secure Erase are used.

Once the wipe is executed the report is generated in the log directory. 

Lastly DWippr will ask if you want to read the report. The report is piped to `more`, so pressing `q` will exit the report.


# Configuration
If you'd like to change the conf file or define your own here is a brief explanation.

To exclude disks from wipes you can add them to `NONO_DISKS`. 
`NONO_DISKS=(sda nvme0n1 etc)`

The log directory is defined like so:
`DW_LOGDIR=/path/to/logdir`

The config file contains variables needed for the final DWippr report. Each of these has a prefix string that can be changed to customize your report. Here is the full list of report variables:

```
TECH
DSKSRC
DSKTYPE
TOOL
DMETHOD
```
