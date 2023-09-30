# swmud_blight_scripts
Blightmud scripts for SWmud.

These scripts can be used in the latest images.

#### Setup:
- Install [docker desktop](https://www.docker.com/products/docker-desktop/) 
- Install [cygwin](https://www.cygwin.com/) if you run windows

#### Development
From the terminal and from this git directory WITHOUT customer character scripts:
```bash
docker run -it -v swmud:/home/miko/.config/blightmud/swmud \
    -v 000_connect.lua:/home/miko/.config/blightmud/000_connect.lua \
    docker.io/mikotaichou/swblight:dev
```

From the terminal and this git directory WITH customer character scripts:
```bash
docker run -it -v swmud:/home/miko/.config/blightmud/swmud \
    -v 000_connect.lua:/home/miko/.config/blightmud/000_connect.lua \
    -v <LOCAL SCRIPT FILE>:/home/miko/.config/blightmud/private/021_character.lua \
    docker.io/mikotaichou/swblight:dev
```

#### Latest Published Version:
From the terminal or cygwin command line, run:
```bash
docker run -it docker.io/mikotaichou/swblight:latest
``` 

If you would like to save the logs to your local machine automagically, run:
```bash
docker run -it -v <LOCAL LOG PATH HERE>:/home/miko/.local/share/blightmud/logs \
    docker.io/mikotaichou/swblight:latest
```

To mount your own character lua automatically on startup, run:
```bash
docker run -it -v <LOCAL SCRIPT FILE>:/home/miko/.config/blightmud/private/021_character.lua \
    -v <LOCAL LOG PATH HERE>:/home/miko/.local/share/blightmud/logs \
    docker.io/mikotaichou/swblight:latest
```