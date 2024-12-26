defmodule Giraffe.Algorithms.BellmanFordTest do
  use ExUnit.Case
  alias Giraffe.Algorithms.BellmanFord

  test "finds shortest paths in a directed graph" do
    graph = %{
      a: [{:a, :b, 1}, {:a, :c, 4}],
      b: [{:b, :c, 2}, {:b, :d, 2}],
      c: [{:c, :d, 3}],
      d: []
    }

    assert BellmanFord.shortest_paths(graph, :a) == {:ok, %{a: 0, b: 1, c: 3, d: 3}}
  end

  test "detects negative cycle in a directed graph" do
    graph = %{
      a: [{:a, :b, 1}],
      b: [{:b, :c, -1}],
      c: [{:c, :a, -1}]
    }

    assert BellmanFord.shortest_paths(graph, :a) == {:error, :negative_cycle}
  end

  test "finds shortest paths in an undirected graph" do
    graph = %{
      a: [{:a, :b, 1}, {:a, :c, 4}],
      b: [{:b, :a, 1}, {:b, :c, 2}, {:b, :d, 2}],
      c: [{:c, :a, 4}, {:c, :b, 2}, {:c, :d, 3}],
      d: [{:d, :b, 2}, {:d, :c, 3}]
    }

    assert BellmanFord.shortest_paths(graph, :a) == {:ok, %{a: 0, b: 1, c: 3, d: 3}}
  end
end
