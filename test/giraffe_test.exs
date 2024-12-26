defmodule GiraffeTest do
  use ExUnit.Case
  doctest Giraffe

  test "greets the world" do
    assert Giraffe.hello() == :world
  end
end
