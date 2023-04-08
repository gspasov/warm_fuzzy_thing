defmodule Monad.Maybe do
  @spec unit(term()) :: {:ok, term()}
  def unit(value), do: {:ok, value}

  @spec map({:ok, value} | nil, (value -> new_value)) ::
          {:ok, new_value} | nil
        when value: term(), new_value: term()
  def map(nil, _fun), do: nil
  def map({:ok, value}, fun) when is_function(fun), do: {:ok, fun.(value)}

  @spec bind(
          {:ok, value} | nil,
          (value -> {:ok, new_value} | nil)
        ) ::
          {:ok, new_value} | nil
        when value: term(), new_value: term()
  def bind(nil, _fun), do: nil
  def bind({:ok, value}, fun) when is_function(fun), do: fun.(value)

  @spec fold({:ok, value} | nil, default :: new_value, (value -> new_value)) :: value
        when value: term(), new_value: term()
  def fold(input, default \\ nil, function)

  def fold(nil, default, _fun), do: default
  def fold({:ok, value}, _default, fun) when is_function(fun), do: fun.(value)

  @spec on_nothing({:ok, term()} | nil, (() -> :ok)) :: nil
  def on_nothing(nil, fun) when is_function(fun) do
    fun.()
    nil
  end

  def on_nothing({:ok, _} = data, fun) when is_function(fun), do: data

  @spec on_just({:ok, value} | nil, (value -> :ok)) :: {:ok, value} when value: term()
  def on_just(nil, fun) when is_function(fun), do: nil

  def on_just({:ok, value} = data, fun) do
    fun.(value)
    data
  end

  @doc """
  Map
  """
  @spec ({:ok, value} | nil) ~> (value -> new_value) ::
          {:ok, new_value} | nil
        when value: term(), new_value: term()
  def nil ~> _, do: nil
  def {:ok, value} ~> fun when is_function(fun), do: {:ok, fun.(value)}

  @doc """
  Bind
  """
  @spec ({:ok, value} | nil) ~>> (value -> result) :: result
        when value: term(), new_value: term(), result: {:ok, new_value} | nil
  def nil ~>> _, do: nil

  def {:ok, value} ~>> fun when is_function(fun) do
    case fun.(value) do
      {:ok, _} = res -> res
      nil -> nil
    end
  end

  @doc """
  Fold
  """
  @spec ({:ok, value} | nil) <~> ((value -> new_value) | new_value) :: new_value
        when value: term(), new_value: term()
  def nil <~> default, do: default
  def {:ok, value} <~> fun when is_function(fun), do: fun.(value)
end
