defmodule AshFeatureFlags.Store.Ash do
  @moduledoc """
  Default `AshFeatureFlags.Store` implementation over an
  `AshFeatureFlags.Store.Resource` resource, using `Ash.read/1`, `Ash.create/1`
  and `Ash.destroy/1`.
  """

  @behaviour AshFeatureFlags.Store

  require Ash.Query

  @impl true
  def all(%{store: nil}), do: {:ok, %{}}

  def all(%{store: resource}) do
    case Ash.read(resource) do
      {:ok, rows} -> {:ok, Map.new(rows, &{&1.key, &1.value})}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def put(%{store: nil}, _flag, _value), do: {:error, :no_store}

  def put(%{store: resource}, flag, value) do
    resource
    |> Ash.Changeset.for_create(:upsert, %{key: flag, value: value})
    |> Ash.create()
    |> case do
      {:ok, _record} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def delete(%{store: nil}, _flag), do: {:error, :no_store}

  def delete(%{store: resource}, flag) do
    resource
    |> Ash.Query.filter(key == ^flag)
    |> Ash.read_one()
    |> case do
      {:ok, nil} -> :ok
      {:ok, record} -> destroy(record)
      {:error, reason} -> {:error, reason}
    end
  end

  defp destroy(record) do
    case Ash.destroy(record) do
      :ok -> :ok
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end
