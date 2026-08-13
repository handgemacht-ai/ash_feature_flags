defmodule AshFeatureFlags.RetryPolicy do
  @moduledoc """
  Bounded exponential retry policy for the cache's failed override loads.

  The delay for attempt `n` is `base_ms * 2^n`, capped at `max_ms`; the attempt
  counter saturates at `max_attempts` so it cannot grow without bound. Naming
  these three constants as a struct makes the two distinct caps explicit — the
  delay cap (`max_ms`) and the counter cap (`max_attempts`) — where the call
  site previously inlined `min(base * Integer.pow(2, attempts), @max_backoff_ms)`
  next to `min(attempts + 1, @max_attempts)` with no shared vocabulary.
  """

  @enforce_keys [:base_ms, :max_ms, :max_attempts]
  defstruct [:base_ms, :max_ms, :max_attempts]

  @type t :: %__MODULE__{
          base_ms: pos_integer(),
          max_ms: pos_integer(),
          max_attempts: pos_integer()
        }

  @doc """
  Build a policy from a `retry_ms` base together with the library-wide delay
  and counter bounds.
  """
  @spec new(pos_integer(), pos_integer(), pos_integer()) :: t()
  def new(base_ms, max_ms, max_attempts)
      when is_integer(base_ms) and base_ms > 0 and
             is_integer(max_ms) and max_ms > 0 and
             is_integer(max_attempts) and max_attempts > 0 do
    %__MODULE__{
      base_ms: base_ms,
      max_ms: max_ms,
      max_attempts: max_attempts
    }
  end

  @doc """
  The delay, in milliseconds, for the given attempt number, capped at `max_ms`.

  Attempt numbering starts at `0` (the first retry after a failure), so the
  first retry waits `base_ms`; once `base_ms * 2^n` reaches `max_ms` the delay
  saturates there.
  """
  @spec delay(t(), non_neg_integer()) :: pos_integer()
  def delay(%__MODULE__{base_ms: base_ms, max_ms: max_ms}, attempts)
      when is_integer(attempts) and attempts >= 0 do
    min(base_ms * Integer.pow(2, attempts), max_ms)
  end

  @doc """
  The next attempt counter, saturating at `max_attempts` instead of growing
  without bound.
  """
  @spec next_attempt(t(), non_neg_integer()) :: pos_integer()
  def next_attempt(%__MODULE__{max_attempts: max_attempts}, attempts)
      when is_integer(attempts) and attempts >= 0 do
    min(attempts + 1, max_attempts)
  end
end
