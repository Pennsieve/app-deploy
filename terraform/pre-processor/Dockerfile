FROM rocker/r-ver:4.2.1

WORKDIR /service

RUN apt clean && apt-get update && apt-get -y install alien
# install dependencies
RUN apt-get -y install wget && apt-get -y install gnupg && apt-get -y install curl

# install Go
RUN wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz

RUN  rm -rf /usr/local/go && tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz

ENV PATH="${PATH}:/usr/local/go/bin"

# cleanup
RUN rm -f go1.21.0.linux-amd64.tar.gz

COPY . .

RUN ls /service

RUN go build -o /service/main main.go

RUN mkdir -p data

# Add additional dependencies below ...

ENTRYPOINT [ "/service/main" ]