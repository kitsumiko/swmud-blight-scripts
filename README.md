# Miko's Scripts for SWMud

These scripts can be used in the latest images.

## Setup:
- Install [docker desktop](https://www.docker.com/products/docker-desktop/) 
- Install [cygwin](https://www.cygwin.com/) if you run windows

## [In Progress] Development
Clone the repo and cd into it:
```bash
git clone https://github.com/mikotaichou/swmud-blight-scripts.git
cd swmud-blight-scripts
```

### Without Custom Character Scripts
From the terminal and from this git directory WITHOUT customer character scripts:
```bash
docker run -it -v swmud:/home/miko/.config/blightmud/ \
    -v .:/home/miko/.config/blightmud \
    docker.io/mikotaichou/swblight:dev
```

### With Custom Character Scripts
*A file must be named 020_character.lua as an entrypoint in the mounted folder!*

From the terminal and this git directory WITH customer character scripts:
```bash
docker run -it -v swmud:/home/miko/.config/blightmud/ \
    -v .:/home/miko/.config/blightmud \
    -v <LOCAL SCRIPT DIR>:/home/miko/.config/blightmud/private \
    docker.io/mikotaichou/swblight:dev
```

## Latest Published Version:
This version does not require the scripts repo to function.

### Default
From the terminal or cygwin command line, run:
```bash
docker run -it docker.io/mikotaichou/swblight:latest
``` 

### Default with Logs
If you would like to save the logs to your local machine automagically, run:
```bash
docker run -it \
    -v <LOCAL LOG PATH HERE>:/home/miko/.local/share/blightmud/logs \
    docker.io/mikotaichou/swblight:latest
```

### Default, Logs, and Custom Character Scriptfile
*A file must be named 020_character.lua as an entrypoint in the mounted folder!*

To mount your own character lua automatically on startup, run:
```bash
docker run -it \
    -v <LOCAL SCRIPT DIR>:/home/miko/.config/blightmud/private \
    -v <LOCAL LOG PATH HERE>:/home/miko/.local/share/blightmud/logs \
    docker.io/mikotaichou/swblight:latest
```