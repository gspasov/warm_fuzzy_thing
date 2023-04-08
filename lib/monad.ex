defmodule Monad do
  @spec maybe_to_either({:ok, value} | :error, reason) :: {:ok, value} | {:error, reason}
        when value: term(), reason: any()
  def maybe_to_either(maybe, reason)

  def maybe_to_either(:error, reason), do: {:error, reason}
  def maybe_to_either({:ok, data}, _), do: {:ok, data}

  @spec either_to_maybe({:ok, value} | {:error, any()}) :: {:ok, value} | :error
        when value: term()
  def either_to_maybe(either)
  def either_to_maybe({:error, _reason}), do: :error
  def either_to_maybe({:ok, value}), do: {:ok, value}
end
