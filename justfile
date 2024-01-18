set positional-arguments

default:
  @just --list

terraform *ARGS:
  op run --env-file=".env" --no-masking -- terraform {{ARGS}}

ansible-playbook *ARGS:
  op run --env-file=".ansible-env" --  ansible-playbook {{ARGS}}
