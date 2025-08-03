# WSL2 dev config

curl -sSL https://raw.githubusercontent.com/Ujstor/wsl2-config/main/install.sh | bash

# WSL Management Quick Reference

## Basic Commands

**List all distributions:**
```bash
wsl --list --verbose
wsl -l -v
```

**Start a distribution:**
```bash
wsl -d <DistroName>
wsl -d Debian-Dev
```

**Stop a distribution:**
```bash
wsl --terminate <DistroName>
wsl -t Debian-Dev
```

**Set default distribution:**
```bash
wsl --set-default <DistroName>
```

## Installation & Setup

**Install new distribution:**
```bash
wsl --install -d <DistroName>
wsl --install -d Ubuntu
```

**Update WSL:**
```bash
wsl --update
```

## Instance Management

**Export (backup) instance:**
```bash
wsl --export <DistroName> <BackupPath>
wsl --export Debian-Dev C:\backups\debian-dev.tar
```

**Import (restore/clone) instance:**
```bash
wsl --import <NewName> <InstallPath> <BackupFile>
wsl --import Debian-Test C:\WSL\Debian-Test C:\backups\debian-dev.tar
```

**Remove instance:**
```bash
wsl --unregister <DistroName>
wsl --unregister Debian-Test
```

## Configuration

**Set WSL version:**
```bash
wsl --set-version <DistroName> <Version>
wsl --set-version Debian-Dev 2
```

**Run as specific user:**
```bash
wsl -d <DistroName> --user <username>
wsl -d Debian-Dev --user root
```

## Troubleshooting

**Restart WSL service:**
```bash
wsl --shutdown
```

**Check WSL status:**
```bash
wsl --status
```

**Reset instance (nuclear option):**
```bash
wsl --unregister <DistroName>
```
