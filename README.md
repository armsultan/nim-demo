# NGINX Instance Manager (NIM) Demo Environment

A Container based demo of [NGINX Instance Manager
(NIM)](https://www.nginx.com/products/nginx/nginx-instance-manager/) to
Simplifies NGINX Discovery, Configuration and Maintenance

For more deployments details, see [Deploying NIM Using
Containers](https://docs.nginx.com/nginx-instance-manager/tutorials/containers/)

## The Demo environment

This demo has
 * NGINX Instance Manager (`nginx-instance-manager`)
 * NGINX Plus (`nginx-plus-1`) with a OOTB configuration as a load balancer to
   two nginx oss werb servers
 * NGINX OSS (`nginx-oss-1` and `nginx-oss2`) with a OOTB configuration as a
   webserver with a simple hello web page
 * Optional: Enable other NGINX OSS servers to be discovered by NIM
   ### Topology

The base demo environment. Two NGINX OSS and Once NGINX Plus instances are
deployed with the nginx-agent and is managed by nim

There are several NGINX OSS instances disabled (commented out) in the
[`docker-compose`](docker-compose.yml) config that can be deployed (uncomment
out)

```
                 +---------------+                        
                 |               |       +----------------------------+
                 |               |       |                            |
                 |               |       |        nginx-oss-1         |
                 |               |       | (NGINX OSS + nginx-agent ) |
                 |               +------->                            |
                 |               |       +----------------------------+
                 |               |
+---------------->               |       +----------------------------+
nim.example.com  |  NGINX        |       |                            |
UI/API - HTTP 80 |  Instance     |       |       nginx-oss-2          |
                 |  Managerplus  |       | (NGINX OSS + nginx-agent ) |
                 | (ADC)         +------->                            |
+---------------->               |       +----------------------------+
GRPC 10443       |               |       
                 |               |       +----------------------------+
                 |               |       |                            |
+---------------->               |       |        nginx-plus-1        |
NGINX Dashboard/ |               |       | (NGINX Plus + nginx-agent )|
HTTP/Port 8080   |               +------->                            |
                 |               |       +----------------------------+
                 |               |
                 |               +-------> Various NGINX OSS instances
                 |               |         (Enabled in docker-compose.yml)
                 +---------------+               
```

### File Structure

#### NGINX Instance Manager
```
nginx-instance-manager -
etc/
└── nginx/
    ├── conf.d/
    │   ├── nginx-manager-grpc.conf ...........Virtual Server for NIM GRPC Proxy service
    │   ├── nginx-manager-noauth-http.conf.....Virtual Server for NIM UI/API
    │   ├── nginx-manager-upstreams-grpc.conf..Upstream for NIM GRPC (localhost) 
    │   ├── nginx-manager-upstreams.conf.......Upstream for UI/API (localhost)
    │   └── status_api.conf....................NGINX Plus Dashboard and API
└── nginx-manager/
    │   ├── nginx-manager.conf ...Configuration file for NIM
    │   └── nginx-manager.lic ....NIM License File (Use your own license)
└── ssl/
    ├── nginx/
    │    ├── nginx-repo.crt.......NGINX Plus repository certificate file (Use your own crt file)
    │    └── nginx-repo.key.......NGINX Plus repository key file (Use your own key file)
    ├── dhparam/
    │    └── dhparam.pem..........2048 or 4096 bit DH parameters
    ├── example.com.crt...........Self-signed wildcard cert for *.example.com
    └── example.com.key...........Private key for Self-signed wildcard cert for *.example.com 
```

#### NGINX OSS
```
nginx-oss-agent -
etc/
└── nginx/
    ├── conf.d/
    │   ├── hello-html.conf .........Virtual Server for HTML Demo page (Dockerfile will ADD this)
    │   ├── hello-plain-text.conf ...Virtual Server for Plain text Demo page (Alternative demo page, must be ADDed in Dockerfile)
    │   └── status_stub.conf.........NGINX OSS Basic Status information
└── ssl/
    ├── nginx/
    │    ├── nginx-repo.crt.......NGINX Plus repository certificate file (Use your own crt file)
    │    └── nginx-repo.key.......NGINX Plus repository key file (Use your own key file)
usr/
└── share/
    └── nginx/
        └── html /
             ├── index.html.......HTML Demo page 
             └── nginx-repo.key....Sample HTML Image
```

##### NGINX Plus
```
nginx-plus-agent -
etc/
└── nginx/
    ├── conf.d/
    │   ├── example.com.conf .......Virtual Server configuration for www.example.com
    │   ├── upstreams.conf..........Upstream configurations
    │   └── status_api.conf.........NGINX Plus Live Activity Monitoring available on port 8080
    └── nginx.conf .................Main NGINX configuration file with global settings
└── ssl/
    ├── nginx/
    │    ├── nginx-repo.crt.......NGINX Plus repository certificate file (Use your own crt file)
    │    └── nginx-repo.key.......NGINX Plus repository key file (Use your own key file)
    ├── dhparam/
    │    └── dhparam.pem..........2048 or 4096 bit DH parameters
    ├── example.com.crt...........Self-signed wildcard cert for *.example.com
    └── example.com.key...........Private key for Self-signed wildcard cert for *.example.com 
```

## Prerequisites:

 1. NGINX Plus evaluation license file. You can get it the NGINX Plus licenses
    from [here](https://www.nginx.com/free-trial-request/)
 2. NGINX Instance Manager evaluation license file. You can get it the NGINX
    Plus licenses from
    [here](https://www.nginx.com/products/nginx/nginx-instance-manager/)
 3. A Docker host. With [Docker](https://docs.docker.com/get-docker/) and
    [Docker Compose](https://docs.docker.com/compose/install/)
 4. **Optional**: The demo uses hostnames: `nim.example.com`. For hostname
    resolution you will need to add hostname bindings to your hosts file:

For example, on Linux/Unix/macOS the host file is `/etc/hosts`

```bash
# NIM Demo (local docker host)
127.0.0.1 nim.example.com
```

> **Note:** DNS resolution between containers is provided by default using a new
> bridged network by docker networking with a `172.20.0.0/24` internal network
> address spaces. NGINX Plus Config uses the Docker DNS server (127.0.0.11) to
> provide DNS resolution between NGINX and upstream servers

## Build and run the demo environment

Provided the Prerequisites have been met before running the stpes below, this is
a **working** environment. 

### Build the demo

Before we can start, we need to copy our NGINX Plus repo key and certificate
(`nginx-repo.key` and `nginx-repo.crt`) into the directory,
`nginx-plus/etc/ssl/nginx/`, then build our stack:

```bash
# Enter working directory
cd nim-demo

# Make sure your Nginx Plus repo key and certificate exist here
ls nginx-plus-agent/etc/ssl/nginx/nginx-*
nginx-repo.crt              nginx-repo.key

# And the same key/cert exist here for the OSS agent
ls nginx-oss-agent/etc/ssl/nginx/nginx-*
nginx-repo.crt              nginx-repo.key

# And the same key/cert here for the NIM agent
ls nginx-instance-manager/etc/ssl/nginx/nginx-*
nginx-repo.crt              nginx-repo.key

# Finally, make sure NIM license key (from my.f5.com) exists here
ls nginx-instance-manager/etc/nginx-manager/*.lic
nginx-manager.lic

# Download docker images and build
docker-compose pull
docker-compose build --no-cache

# [Development Only] Build a single service to cut down on build time
docker-compose build --no-cache [SERVICE]
```

-----------------------
> See other other useful [`docker`](docs/useful-docker-commands.md) and
> [`docker-compose`](docs/useful-docker-compose-commands.md) commands
-----------------------

#### Start the Demo stack:

Run `docker-compose` in the foreground so we can see real-time log output to the
terminal:

```bash
docker-compose up
```

If there is a docker network conflict error, you can delete the `overlay` docker
network first:

```bash
docker network rm nginx-nim-demo_overlay
```

And if you made changes to any of the Docker containers or NGINX configurations,
run:

```bash
# Recreate containers and start demo
docker-compose up --force-recreate
```

**Confirm** the containers are running. You should see three containers running.
You will see extra containers if you have deployed other NGINX instances

```bash
docker ps
CONTAINER ID   IMAGE                                   COMMAND                  CREATED         STATUS         PORTS                                                                                        NAMES
b74f6f73b6ba   nginx-nim-demo_nginx-plus               "/entrypoint.sh"         5 seconds ago   Up 4 seconds   80/tcp, 443/tcp, 8080/tcp                                                                    nginx-nim-demo_nginx-plus_1
2aeb350f7bca   nginx-nim-demo_nginx-instance-manager   "/entrypoint.sh"         5 seconds ago   Up 4 seconds   0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp, 0.0.0.0:8080->8080/tcp, 0.0.0.0:10443->10443/tcp   nginx-nim-demo_nginx-instance-manager_1                                                                           nginx-nim-demo_nginx-1-10_1
f0c9a8ce4d22   nginx-nim-demo_nginx1                   "/entrypoint.sh"         6 seconds ago   Up 4 seconds   80/tcp, 443/tcp                                                                              nginx-nim-demo_nginx1_1
9b674924b699   nginx-nim-demo_nginx2                   "/entrypoint.sh"         6 seconds ago   Up 4 seconds   80/tcp, 443/tcp
```

The demo environment is ready in seconds. You can access the NIM Managment UI at
[`http://localhost`](http://localhost) or
[`http://localhost/api`](http://localhost)

You will see three instances registered and ready to be managed by NIM in the
[Inventory Page](http://localhost/ui/inventory/)

Other Pages include [Documentation](http://localhost/docs/), [OpenAPI
page](http://localhost/swagger-ui/) and 

## DEMO Stuff

TODO: 
 * API demo
 * Metrics