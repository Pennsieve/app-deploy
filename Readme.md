## app-deploy

Deploys an application to the cloud (AWS)

To build:

arm64:

`docker build -f Dockerfile_arm64 --progress=plain -t pennsieve/app-deploy .`

x86 (64bit):

`docker build --progress=plain -t pennsieve/app-deploy .`

Supported commands:

`make`
