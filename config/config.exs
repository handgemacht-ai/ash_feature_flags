import Config

# Keep the library quiet by default; consumers configure their own logger.
config :logger, level: :warning

import_config "#{config_env()}.exs"
