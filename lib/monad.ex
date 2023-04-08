defmodule Monad do
  @spec maybe_to_either(maybe, reason) :: either
        when maybe: nil | {:ok, value},
             either: {:ok, value} | {:error, reason},
             value: any(),
             reason: any()
  def maybe_to_either(maybe, reason)

  def maybe_to_either(:error, reason), do: {:error, reason}
  def maybe_to_either({:ok, value}, _), do: {:ok, value}

  @spec either_to_maybe(either) :: maybe
        when maybe: nil | {:ok, value},
             either: {:ok, value} | {:error, reason},
             value: any(),
             reason: any()
  def either_to_maybe(either)
  def either_to_maybe({:error, _reason}), do: :error
  def either_to_maybe({:ok, value}), do: {:ok, value}
end
