# Docker TribesNext


## Fork Updates

- [Classic v1.5.2](http://tribes2stats.com/files/mods/classic_v152.zip)
- [Ruby 1.9](https://ftp.ruby-lang.org/pub/ruby/binaries/mswin32/unstable/ruby-1.9.0-2-i386-mswin32.zip)


---

## Information
TribesNext dedicated server patched and running within Docker under wine.

*This is TribesNext RC2a with the wine patches included.*

The image will pull required files and install them at build time (providing the sources are live). 

Docker image is completely self contained when built; it is currently based off Debian Jessie 32bit. This brings in the server at around 1.6GB once built.

The server runs as the gameserv user


## Ports
Exposed ports are `666`, `28000`, the standard TribesNext ports, these can be mapped to whatever you need when you run the container, example below.


## Volumes
No volumes are used


## Usage
**Build the image**

`docker build . -t tribesnext-server`

**Run a container**

NB: the `--rm` arg will destroy the container when stopped; internal ports (666) can be mapped to available host ports (27999) per container
```
docker run -d --rm \
-p 27999:666/tcp \
-p 28000:28000/udp \
--name tribesnext-server \
tribesnext-server:latest
```

**Stop container**

`docker stop tribesnext-server`


## Server Customization
You can customize the server at build time by dropping the appropriate files at the appropriate locations in `_custom/`, these will be copied into the image into the install location within the container at build time.


You can override the following defaults at build time
```
ARG SRVUSER=gameserv
ARG SRVUID=1000
ARG SRVDIR=/tmp/tribes2/
```

You can also override the start-server script by added one to _custom this will overwrite the default at build time.



## Notes
You can modify the installer script to update the source locations of the required files.

`tribesnext-server-installer` may also be used in standalone mode to install TribesNext RC2a on the host system under wine but your mileage may vary.

Testing has been minimal but it is running the NET247 server so you can try it out at any point.

## 2do
* Thinner base OS
* Reduce duplicate data across scripts

