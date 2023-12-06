set positional-arguments

default:
  @just --list

terraform *ARGS:
  op run --env-file=".env" -- terraform {{ARGS}}
