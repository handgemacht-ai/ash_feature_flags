defmodule Support.CheckFlags do
  @moduledoc false
  use AshFeatureFlags, check_telemetry: true

  flags do
    flag :on do
      default true
    end

    flag :off do
      default false
    end
  end
end
