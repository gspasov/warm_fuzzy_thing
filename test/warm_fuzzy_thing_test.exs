defmodule WarmFuzzyThingTest do
  use ExUnit.Case
  doctest WarmFuzzyThing
  doctest WarmFuzzyThing.Either
  doctest WarmFuzzyThing.Maybe

  alias WarmFuzzyThing.Maybe
  alias WarmFuzzyThing.Either

  describe "Maybe" do
    test "fmap will apply handler over value if 'Just' is passed" do
      result = Maybe.fmap({:ok, 1}, fn value -> value + 1 end)
      assert result == {:ok, 2}
    end

    test "fmap will not call handler if 'Nothing' is passed" do
      result = Maybe.fmap(nil, fn _ -> raise("not called") end)
      assert result == nil
    end

    test "bind will return a 'Just' if handler returns an :ok tuple" do
      result = Maybe.bind({:ok, 1}, fn v -> {:ok, v + 1} end)
      assert result == {:ok, 2}
    end

    test "bind will return a 'Nothing' if handler returns nil" do
      result = Maybe.bind({:ok, 1}, fn v -> nil end)
      assert result == nil
    end

    test "bind raise exception if handler does not return neither :ok tuple nor nil" do
      assert_raise CaseClauseError, fn ->
        Maybe.bind({:ok, 1}, fn _value -> 1 end)
      end
    end

    test "fold will return the value applied to the given handler if Maybe is 'Just'" do
      result = Maybe.fold({:ok, 1}, fn value -> value + 1 end)
      assert result == 2
    end

    test "fold will return default value if Maybe is 'Nothing'" do
      result = Maybe.fold(nil, 2, fn value -> value + 1 end)
      assert result == 2
    end

    test "~> will apply a handler over the value if Maybe is 'Just'" do
      import Maybe, only: [~>: 2]
      result = {:ok, 1} ~> fn value -> value + 1 end
      assert result == {:ok, 2}
    end

    test "~> wont call handler if Maybe is 'Nothing'" do
      import Maybe, only: [~>: 2]
      result = nil ~> fn _ -> raise("not called") end
      assert result == nil
    end

    test "~>> will return a Just if the Maybe is 'Just' and the handler result is an :ok tuple" do
      import Maybe, only: [~>>: 2]
      result = {:ok, 1} ~>> fn v -> {:ok, v + 1} end
      assert result == {:ok, 2}
    end

    test "~>> will return a Nothing if the Maybe is 'Just' and the handler result is nil" do
      import Maybe, only: [~>>: 2]
      result = {:ok, 1} ~>> fn v -> nil end
      assert result == nil
    end

    test "~>> will return a Nothing if the Maybe is 'Nothing'" do
      import Maybe, only: [~>>: 2]
      result = nil ~>> fn v -> raise("not called") end
      assert result == nil
    end

    test "<~> will apply handler to value if Maybe is 'Just'" do
      import Maybe, only: [<~>: 2]
      result = {:ok, 1} <~> fn value -> value + 1 end
      assert result == 2

      result_2 = {:ok, 1} <~> {10, fn value -> value + 1 end}
      assert result_2 == 2
    end

    test "<~> returns default value if Maybe is 'Nothing'" do
      import Maybe, only: [<~>: 2]
      result = nil <~> {10, fn _ -> raise("not called") end}
      assert result == 10
    end

    test "<~> returns nil if default value is not passed and Maybe is 'Nothing'" do
      import Maybe, only: [<~>: 2]
      result = nil <~> fn _ -> raise("not called") end
      assert result == nil
    end
  end

  describe "Either" do
    test "fmap applies a function over the value when working with 'Right'" do
      result = Either.fmap({:ok, 1}, fn value -> value + 2 end)
      assert result == {:ok, 3}
    end

    test "fmap does not execute function when working with 'Left'" do
      result = Either.fmap({:error, :not_found}, fn _ -> raise("not called") end)
      assert result == {:error, :not_found}
    end

    test "bind returns a 'Left' if handler returns a 'Left' Either" do
      result = Either.bind({:ok, 1}, fn _value -> {:error, :bad} end)
      assert result == {:error, :bad}
    end

    test "bind returns a 'Right' if handler returns a 'Right' Either" do
      result = Either.bind({:ok, 1}, fn value -> {:ok, value + 1} end)
      assert result == {:ok, 2}
    end

    test "bind always returns a 'Left' if Either is already 'Left'" do
      result = Either.bind({:error, :bad}, fn _ -> raise("not called") end)
      assert result == {:error, :bad}
    end

    test "bind raises exception if handler does not return an Either" do
      assert_raise CaseClauseError, fn ->
        Either.bind({:ok, 1}, fn _value -> 1 end)
      end
    end

    test "fold will apply handler over value if 'Right' is passed" do
      result = Either.fold({:ok, 1}, fn value -> value + 1 end)
      assert result == 2
    end

    test "fold will return default value if 'Left' is passed" do
      result = Either.fold({:error, :bad}, 2, fn _ -> raise("not called") end)
      assert result == 2
    end

    test "~> will apply handler over value if 'Right' is passed" do
      import Either, only: [~>: 2]
      result1 = {:ok, 1} ~> fn value -> value + 1 end
      assert result1 == {:ok, 2}
    end

    test "~> always returns 'Left' if 'Left' is passed" do
      import Either, only: [~>: 2]
      result1 = {:error, :bad} ~> fn value -> raise("not called") end
      assert result1 == {:error, :bad}
    end

    test "~>> returns a 'Right' if handler returns 'Right'" do
      import Either, only: [~>>: 2]
      result = {:ok, 1} ~>> fn v -> {:ok, v + 1} end
      assert result == {:ok, 2}
    end

    test "~>> returns a 'Left' if handler returns 'Left'" do
      import Either, only: [~>>: 2]
      result = {:ok, 1} ~>> fn _ -> {:error, :bad} end
      assert result == {:error, :bad}
    end

    test "~>> if called with 'Left' will not call handler and return 'Left'" do
      import Either, only: [~>>: 2]
      result = {:error, :bad} ~>> fn _ -> raise("not called") end
      assert result == {:error, :bad}
    end

    test "<~> applies the handler over the value if Either is 'Right'" do
      import Either, only: [<~>: 2]
      result = {:ok, 1} <~> fn value -> value + 1 end
      assert result == 2

      result_2 = {:ok, 1} <~> {10, fn value -> value + 1 end}
      assert result_2 == 2
    end

    test "<~> returns default value if Either is 'Left'" do
      import Either, only: [<~>: 2]
      result = {:error, :bad} <~> {20, fn value -> value + 1 end}
      assert result == 20
    end

    test "<~> returns nil if default is not passed and Either is 'Left'" do
      import Either, only: [<~>: 2]
      result = {:error, :bad} <~> fn value -> value + 1 end
      assert result == nil
    end
  end
end
