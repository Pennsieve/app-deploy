#!/bin/sh
if [ -z "${AWS_LAMBDA_RUNTIME_API}" ]; then
  exec /usr/local/bin/aws-lambda-rie /service/bootstrap $@
else
  exec /service/bootstrap $@
fi