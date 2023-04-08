defmodule Monad.Maybe do
  @type t(value) :: nil | {:ok, value}

  @spec map(maybe, function) :: maybe
        when maybe: nil | {:ok, value},
             function: (value -> new_value),
             value: any(),
             new_value: any()
  def map(nil, _fun), do: nil
  def map({:ok, value}, fun) when is_function(fun), do: {:ok, fun.(value)}

  @spec bind(maybe, function) :: maybe
        when maybe: nil | {:ok, value},
             function: (value -> maybe),
             value: any()
  def bind(nil, _fun), do: nil

  def bind({:ok, value}, fun) when is_function(fun) do
    case fun.(value) do
      nil -> nil
      {:ok, value} -> {:ok, value}
    end
  end

  @spec fold(maybe, default :: new_value, function) :: new_value
        when maybe: nil | {:ok, value},
             function: (value -> new_value),
             value: any(),
             new_value: any()
  def fold(input, default \\ nil, function)

  def fold(nil, default, _fun), do: default
  def fold({:ok, value}, _default, fun) when is_function(fun), do: fun.(value)

  @spec on_nothing(maybe, function) :: maybe
        when maybe: nil | {:ok, value},
             function: (() -> :ok),
             value: any()
  def on_nothing(maybe, function)

  def on_nothing({:ok, value}, _fun), do: value

  def on_nothing(nil, fun) when is_function(fun) do
    fun.()
    nil
  end

  @spec on_just(maybe, function) :: maybe
        when maybe: nil | {:ok, value},
             function: (value -> :ok),
             value: any()
  def on_just(nil, _fun), do: nil

  def on_just({:ok, value}, fun) do
    fun.(value)
    {:ok, value}
  end

  @doc """
  Map
  """
  @spec maybe ~> function :: maybe
        when maybe: nil | {:ok, value},
             function: (value -> new_value),
             value: any(),
             new_value: any()
  def nil ~> _, do: nil
  def {:ok, value} ~> fun when is_function(fun), do: {:ok, fun.(value)}

  @doc """
  Bind
  """
  @spec maybe ~>> function :: maybe
        when maybe: nil | {:ok, value},
             function: (value -> maybe),
             value: any()
  def nil ~>> _, do: nil

  def {:ok, value} ~>> fun when is_function(fun) do
    case fun.(value) do
      nil -> nil
      {:ok, value} -> {:ok, value}
    end
  end

  @doc """
  Fold
  """
  @spec maybe <~> ((default :: new_value) | function) :: new_value
        when maybe: nil | {:ok, value},
             function: (value -> new_value),
             value: any(),
             new_value: any()
  def nil <~> default, do: default
  def {:ok, value} <~> fun when is_function(fun), do: fun.(value)
end
