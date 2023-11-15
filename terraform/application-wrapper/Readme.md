To build:

`docker build -t pennsieve/app-wrapper .`

On arm64 architectures:

`docker build -f Dockerfile_arm64 -t pennsieve/app-wrapper .`

To run:

`docker-compose up --build`
