defmodule WarmFuzzyThingTest do
  use ExUnit.Case
  doctest WarmFuzzyThing
  doctest WarmFuzzyThing.Either
  doctest WarmFuzzyThing.Maybe

  alias WarmFuzzyThing.Maybe
  alias WarmFuzzyThing.Either

  describe "Maybe" do
    test "map" do
      result =
        {:ok, 1}
        |> Maybe.fmap(fn value -> value + 1 end)
        |> Maybe.fmap(fn value -> value + 1 end)
        |> Maybe.fmap(fn value -> value + 1 end)

      assert result == {:ok, 4}
    end

    test "bind" do
      result =
        {:ok, 1}
        |> Maybe.fmap(fn value -> value + 1 end)
        |> Maybe.bind(fn _value -> nil end)

      assert result == nil
    end

    test "fold" do
      result =
        {:ok, 1}
        |> Maybe.fmap(fn value -> value + 1 end)
        |> Maybe.fmap(fn value -> value + 1 end)
        |> Maybe.fmap(fn value -> value + 1 end)
        |> Maybe.fold(fn value -> value + 1 end)

      assert result == 5
    end

    test "~>" do
      import Maybe, only: [~>: 2]
      result1 = {:ok, 1} ~> fn value -> value + 1 end
      assert result1 == {:ok, 2}

      result =
        {:ok, 1}
        |> Maybe.~>(fn value -> value + 1 end)
        |> Maybe.~>(fn value -> value + 1 end)
        |> Maybe.~>(fn value -> value + 1 end)

      assert result == {:ok, 4}
    end

    test "~>>" do
      import Maybe, only: [~>>: 2]
      result1 = {:ok, 1} ~>> fn _value -> nil end
      assert result1 == nil

      result =
        {:ok, 1}
        |> Maybe.~>(fn value -> value + 1 end)
        |> Maybe.~>>(fn _value -> nil end)

      assert result == nil
    end

    test "<~>" do
      import Maybe, only: [<~>: 2]
      result1 = {:ok, 1} <~> fn value -> value + 1 end

      assert result1 == 2

      result =
        {:ok, 1}
        |> Maybe.~>(fn value -> value + 1 end)
        |> Maybe.~>(fn value -> value + 1 end)
        |> Maybe.~>(fn value -> value + 1 end)
        |> Maybe.<~>(fn value -> value + 1 end)

      assert result == 5
    end
  end

  describe "Either" do
    test "map" do
      result =
        {:ok, 1}
        |> Either.fmap(fn value -> value + 1 end)
        |> Either.fmap(fn value -> value + 1 end)
        |> Either.fmap(fn value -> value + 1 end)

      assert result == {:ok, 4}
    end

    test "bind" do
      result =
        {:ok, 1}
        |> Either.fmap(fn value -> value + 1 end)
        |> Either.bind(fn _value -> {:error, "something is wrong"} end)

      assert result == {:error, "something is wrong"}
    end

    test "fold" do
      result =
        {:ok, 1}
        |> Either.fmap(fn value -> value + 1 end)
        |> Either.fmap(fn value -> value + 1 end)
        |> Either.fmap(fn value -> value + 1 end)
        |> Either.fold(fn value -> value + 1 end)

      assert result == 5
    end

    test "~>" do
      import Either, only: [~>: 2]
      result1 = {:ok, 1} ~> fn value -> value + 1 end
      assert result1 == {:ok, 2}

      result =
        {:ok, 1}
        |> Either.~>(fn value -> value + 1 end)
        |> Either.~>(fn value -> value + 1 end)
        |> Either.~>(fn value -> value + 1 end)

      assert result == {:ok, 4}
    end

    test "~>>" do
      import Either, only: [~>>: 2]
      result1 = {:ok, 1} ~>> fn _value -> {:error, "something is wrong"} end
      assert result1 == {:error, "something is wrong"}

      result =
        {:ok, 1}
        |> Either.~>(fn value -> value + 1 end)
        |> Either.~>>(fn _value -> {:error, "something is wrong"} end)

      assert result == {:error, "something is wrong"}
    end

    test "<~>" do
      import Either, only: [<~>: 2]
      result1 = {:ok, 1} <~> fn value -> value + 1 end

      assert result1 == 2

      result =
        {:ok, 1}
        |> Either.~>(fn value -> value + 1 end)
        |> Either.~>(fn value -> value + 1 end)
        |> Either.~>(fn value -> value + 1 end)
        |> Either.<~>(fn value -> value + 1 end)

      assert result == 5
    end
  end
end
