FROM golang:bullseye

WORKDIR /service

# next flow dependencies
RUN wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | apt-key add -
RUN echo "deb https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list
RUN apt-get update
RUN apt-get -y install temurin-17-jdk

# install nextflow
RUN wget -qO- https://get.nextflow.io | bash && chmod +x nextflow && cp ./nextflow /usr/local
RUN apt-get -y install graphviz

ENV PATH="${PATH}:/usr/local/"

# cleanup
RUN rm -f /service/nextflow

# set desired nextflow version
RUN export NXF_VER=23.10.0

RUN apt-get clean
RUN apt-get -y install software-properties-common
RUN add-apt-repository "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) universe"
RUN apt-get clean && apt-get -y install python3.9
RUN python3.9 --version

COPY . .

RUN ls /service
RUN ls /service/workflows
RUN ls /service/taskRunner

RUN go build -o /service/main main.go

RUN mkdir -p workflows


RUN apt-get -y install python3-pip
RUN pip install -r /service/taskRunner/requirements.txt

ENTRYPOINT [ "/service/main" ]