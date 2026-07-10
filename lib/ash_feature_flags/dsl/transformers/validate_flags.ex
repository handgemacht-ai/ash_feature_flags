defmodule AshFeatureFlags.Dsl.Transformers.ValidateFlags do
  @moduledoc """
  Compile-time validation for declared flags: names are present and unique and
  every default is a boolean.
  """

  use Spark.Dsl.Transformer

  alias AshFeatureFlags.Dsl.Flag
  alias Spark.Dsl.Transformer

  @impl true
  def transform(dsl_state) do
    flags =
      dsl_state
      |> Transformer.get_entities([:flags])
      |> Enum.filter(&match?(%Flag{}, &1))

    with :ok <- validate_names(flags, dsl_state),
         :ok <- validate_defaults(flags, dsl_state),
         :ok <- validate_unique(flags, dsl_state) do
      {:ok, dsl_state}
    end
  end

  defp validate_names(flags, dsl_state) do
    if Enum.any?(flags, &is_nil(&1.name)) do
      {:error, error(dsl_state, "every flag must declare a non-nil name")}
    else
      :ok
    end
  end

  defp validate_defaults(flags, dsl_state) do
    case Enum.find(flags, &(not is_boolean(&1.default))) do
      nil ->
        :ok

      flag ->
        {:error,
         error(
           dsl_state,
           "flag #{inspect(flag.name)} default must be a boolean, got: #{inspect(flag.default)}"
         )}
    end
  end

  defp validate_unique(flags, dsl_state) do
    names = Enum.map(flags, & &1.name)

    case names -- Enum.uniq(names) do
      [] ->
        :ok

      duplicates ->
        listed = duplicates |> Enum.uniq() |> Enum.map_join(", ", &inspect/1)
        {:error, error(dsl_state, "flag names must be unique; duplicated: #{listed}")}
    end
  end

  defp error(dsl_state, message) do
    Spark.Error.DslError.exception(
      module: Transformer.get_persisted(dsl_state, :module),
      message: message,
      path: [:flags]
    )
  end
end
