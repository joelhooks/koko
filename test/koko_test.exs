defmodule KokoTest do
  use ExUnit.Case
  doctest Koko

  test "greets the world" do
    assert Koko.hello() == :world
  end
end
