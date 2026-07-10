import Config

config :logger, level: :warning

# Avoid strict domain/resource inclusion checks so ETS-backed test fixtures can
# be defined inline.
config :ash, :validate_domain_config_inclusion?, false
config :ash, :validate_domain_resource_inclusion?, false
