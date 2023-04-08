defmodule Monad.Either do
  @type t(reason, value) :: {:error, reason} | {:ok, value}

  @spec map(either, function) :: either
        when either: {:error, reason} | {:ok, value},
             function: (value -> new_value),
             value: any(),
             new_value: any(),
             reason: any()
  def map({:error, reason}, _fun), do: {:error, reason}
  def map({:ok, value}, fun) when is_function(fun), do: {:ok, fun.(value)}

  @spec bind(either, function) :: either
        when either: {:error, reason} | {:ok, value},
             function: (value -> either),
             value: any(),
             reason: any()
  def bind({:error, reason}, _fun), do: {:error, reason}
  def bind({:ok, value}, fun) when is_function(fun), do: fun.(value)

  @spec fold(either, default :: new_value, function) :: new_value
        when either: {:error, reason} | {:ok, value},
             function: (value -> new_value),
             value: any(),
             new_value: any(),
             reason: any()
  def fold(input, default \\ nil, function)

  def fold({:error, _reason}, default, _fun), do: default
  def fold({:ok, value}, _default, fun) when is_function(fun), do: fun.(value)

  @spec on_left(either, function) :: either
        when either: {:error, reason} | {:ok, value},
             function: (reason -> :ok),
             value: any(),
             reason: any()
  def on_left(either, function)

  def on_left({:ok, value}, _fun), do: {:ok, value}

  def on_left({:error, reason}, fun) when is_function(fun) do
    fun.(reason)
    {:error, reason}
  end

  @spec on_right(either, function) :: either
        when either: {:error, reason} | {:ok, value},
             function: (value -> :ok),
             value: any(),
             reason: any()
  def on_right(either, function)
  def on_right({:error, reason}, _fun), do: {:error, reason}

  def on_right({:ok, value}, fun) do
    fun.(value)
    {:ok, value}
  end

  @doc """
  Map
  """
  @spec either ~> function :: either
        when either: {:error, reason} | {:ok, value},
             function: (value -> new_value),
             value: any(),
             new_value: any(),
             reason: any()
  def {:error, reason} ~> _, do: {:error, reason}
  def {:ok, value} ~> fun when is_function(fun), do: {:ok, fun.(value)}

  @doc """
  Bind
  """
  @spec either ~>> function :: either
        when either: {:error, reason} | {:ok, value},
             function: (value -> either),
             value: any(),
             reason: any()
  def {:error, reason} ~>> _, do: {:error, reason}

  def {:ok, value} ~>> fun when is_function(fun) do
    case fun.(value) do
      {:ok, value} -> {:ok, value}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Fold
  """
  @spec either <~> ((default :: new_value) | function) :: new_value
        when either: {:error, reason} | {:ok, value},
             function: (value -> new_value),
             value: any(),
             new_value: any(),
             reason: any()
  def {:error, _} <~> default, do: default
  def {:ok, value} <~> fun when is_function(fun), do: fun.(value)
end
