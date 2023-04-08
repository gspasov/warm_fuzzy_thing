defmodule Monad.Either do
  @spec unit(value :: term()) :: {:ok, term()}
  def unit(value), do: {:ok, value}

  @spec map({:ok, value} | {:error, reason}, (value -> new_value)) ::
          {:ok, new_value} | {:error, reason}
        when value: term(), new_value: term(), reason: term()
  def map({:error, _reason} = error, _fun), do: error
  def map({:ok, data}, fun) when is_function(fun), do: {:ok, fun.(data)}

  @spec bind(
          {:ok, value} | {:error, reason},
          (value -> {:ok, new_value} | {:error, new_reason})
        ) ::
          {:ok, new_value} | {:error, reason | new_reason}
        when value: term(), new_value: term(), reason: term(), new_reason: term()
  def bind({:error, _reason} = error, _fun), do: error
  def bind({:ok, data}, fun) when is_function(fun), do: fun.(data)

  @spec fold({:ok, data} | {:error, reason}, default :: new_value, (data -> new_value)) :: data
        when data: term(), new_value: term(), reason: term()
  def fold(input, default \\ nil, function)

  def fold({:error, _reason}, default, _fun), do: default
  def fold({:ok, data}, _default, fun) when is_function(fun), do: fun.(data)

  @spec on_left(input, (reason -> :ok)) :: input
        when input: {:ok, term()} | {:error, reason}, reason: term()
  def on_left({:error, _} = error, fun) when is_function(fun) do
    fun.()
    error
  end

  def on_left({:ok, _} = data, fun) when is_function(fun), do: data

  @spec on_right(input, (value -> :ok)) :: input
        when input: {:ok, value} | {:error, any()}, value: term()
  def on_right({:error, _} = error, fun) when is_function(fun), do: error

  def on_right({:ok, value} = data, fun) do
    fun.(value)
    data
  end

  @doc """
  Map
  """
  @spec ({:ok, value} | {:error, reason}) ~> (value -> new_value) ::
          {:ok, new_value} | {:error, reason}
        when value: term(), new_value: term(), reason: any()
  def {:error, reason} ~> _, do: {:error, reason}
  def {:ok, value} ~> fun when is_function(fun), do: {:ok, fun.(value)}

  @doc """
  Bind
  """
  @spec ({:ok, value} | {:error, reason}) ~>> (value -> {:ok, new_value} | {:error, new_reason}) ::
          {:ok, new_value} | {:error, reason | new_reason}
        when value: term(), new_value: term(), reason: any(), new_reason: any()
  def {:error, reason} ~>> _, do: {:error, reason}

  def {:ok, value} ~>> fun when is_function(fun) do
    case fun.(value) do
      {:ok, _} = res -> res
      {:error, _} = error -> error
    end
  end

  @doc """
  Fold
  """
  @spec ({:ok, value} | {:error, any()}) <~> ((value -> new_value) | new_value) :: new_value
        when value: term(), new_value: term()
  def {:error, _} <~> default, do: default
  def {:ok, value} <~> fun when is_function(fun), do: fun.(value)
end
