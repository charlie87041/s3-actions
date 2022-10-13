FROM ubuntu:22.04
ENV DEBIAN_FRONTEND noninteractive


LABEL "com.github.actions.name"="Core S3 Actions"
LABEL "com.github.actions.description"="s3 integration fo coreservices"

LABEL repository="https://github.com/charlie87041/s3-actions"
LABEL homepage="https://jarv.is/"
LABEL maintainer="Jake Jarvis <jake@jarv.is>"

# https://github.com/aws/aws-cli/blob/master/CHANGELOG.rst
ENV AWSCLI_VERSION='1.18.69'

RUN apt-get update \
    && apt-get -y install awscli \
    && apt-get -y install jq

COPY . /home/install
RUN chmod 777 -R /home/install/
WORKDIR /home/install
ENTRYPOINT ["/home/install/script.sh"]