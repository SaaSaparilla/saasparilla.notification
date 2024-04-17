default: lint build test

lint:
  echo Linting...
  cargo fmt
  cargo clippy

build:
  echo Building...
  cargo build --future-incompat-report --color always

test:
  echo Testing...
  cargo test

release: lint build test
  echo Creating release build...
  cargo build --future-incompat-report --color always --release --locked

run-director:
  cargo run --bin saasaparilla-notification-director -- --config-file-path=crates/director/config.toml

run-distrubutor:
  cargo run --bin saasaparilla-notification-distrubutor -- --config-file-path=crates/distrubutor/config.toml

run-receiver:
  cargo run --bin saasaparilla-notification-receiver -- --config-file-path=crates/receiver/config.toml

docker-build-all: docker-build-dependencies docker-build-director docker-build-distributor docker-build-receiver

docker-build-dependencies:
  echo Building dependencies...
  docker buildx build . --file ./docker/Dockerfile --target dependencyBuilder

docker-build-director:
  echo Building director image...
  docker buildx build . --file ./docker/Dockerfile --target minimal --build-arg COMPONENT=director -t saasaparilla/notification/director:latest

docker-build-distributor:
  echo Building distributor image...
  docker buildx build . --file ./docker/Dockerfile --target minimal --build-arg COMPONENT=distributor -t saasaparilla/notification/distributor:latest

docker-build-receiver:
  echo Building receiver image...
  docker buildx build . --file ./docker/Dockerfile --target minimal --build-arg COMPONENT=receiver -t saasaparilla/notification/receiver:latest

run-docker: docker-build-all
  echo Running locally...
  docker-compose --file ./docker/docker-compose.yaml down
  docker-compose --file ./docker/docker-compose.yaml up
  docker-compose --file ./docker/docker-compose.yaml down

run-kind: docker-build-all
  echo Deploying kind cluster...
  kind delete cluster --name saasaparilla-notification
  kind create cluster --config kind/cluster.yaml --name saasaparilla-notification --wait 5m
  #TODO: install flux
  #TODO: await service reconciliation
  #TODO: run integration tests
  kind delete cluster --name saasaparilla-notification
