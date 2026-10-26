#!/bin/bash
# Builds the deployment directories Terraform zips: build/app_lambda and build/bootstrap.
set -euo pipefail
cd "$(dirname "$0")"

rm -rf -- build
mkdir -p build

uv export --locked --no-dev --no-emit-project \
  --output-file build/lambda-requirements.txt

for name in app_lambda bootstrap reader; do
  uv pip install --requirement build/lambda-requirements.txt \
    --target "build/$name" \
    --python-version 3.12 \
    --python-platform x86_64-manylinux_2_17 \
    --only-binary :all:

  find "app/$name" -maxdepth 1 -type f -exec cp {} "build/$name/" \;
done

# CA bundle so the app lambda can use sslmode=verify-full against RDS
for name in app_lambda reader; do
  curl -fsSL -o "build/$name/global-bundle.pem" \
    https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem
done
