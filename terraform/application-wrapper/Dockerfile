FROM rocker/r-ver:4.2.1

WORKDIR /service

RUN apt clean && apt-get update
# install dependencies
RUN apt-get -y install wget && apt-get -y install gnupg && apt-get -y install curl
RUN wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | apt-key add -
RUN echo "deb https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list
RUN apt-get update
# next flow dependencies
RUN apt-get -y install temurin-17-jdk

# install nextflow
RUN wget -qO- https://get.nextflow.io | bash && chmod +x nextflow && cp ./nextflow /usr/local
RUN apt-get -y install graphviz

ENV PATH="${PATH}:/usr/local/"

# cleanup
RUN rm -f /service/nextflow

# set desired nextflow version
RUN export NXF_VER=23.04.1

# install Go
RUN wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz

RUN  rm -rf /usr/local/go && tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz

ENV PATH="${PATH}:/usr/local/go/bin"

RUN apt-get install software-properties-common && add-apt-repository ppa:deadsnakes/ppa && sudo apt-get update & apt-get -y install python3.8
RUN python3.8 --version

# cleanup
RUN rm -f go1.21.0.linux-amd64.tar.gz

COPY . .

RUN ls /service

RUN go build -o /service/main main.go

RUN mkdir -p data

# Add additional dependencies below ...

ENTRYPOINT [ "/service/main" ]