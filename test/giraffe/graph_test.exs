defmodule GraphTest do
  use ExUnit.Case
  doctest Giraffe.Graph

  alias Giraffe.Graph, as: Graph

  describe "directed graph" do
    setup do
      graph =
        Graph.new(type: :directed)
        |> Graph.add_vertex(1)
        |> Graph.add_vertex(2)
        |> Graph.add_vertex(3)
        |> Graph.add_edge(1, 2, 1.0)
        |> Graph.add_edge(2, 3, 2.0)

      {:ok, graph: graph}
    end

    test "vertices", %{graph: graph} do
      assert Enum.sort(Graph.vertices(graph)) == [1, 2, 3]
    end

    test "edges", %{graph: graph} do
      assert Graph.edges(graph) == [{1, 2, 1.0}, {2, 3, 2.0}]
    end
  end

  describe "undirected graph" do
    setup do
      graph =
        Graph.new(type: :undirected)
        |> Graph.add_vertex(1)
        |> Graph.add_vertex(2)
        |> Graph.add_edge(1, 2, 1.0)

      {:ok, graph: graph}
    end

    test "edges are bidirectional", %{graph: graph} do
      assert Graph.edges(graph) == [{1, 2, 1.0}]
    end
  end

  describe "reachable/2" do
    test "directed graph - simple path" do
      g = Giraffe.Graph.new(type: :directed)

      g =
        g
        |> Giraffe.Graph.add_edge(1, 2)
        |> Giraffe.Graph.add_edge(2, 3)
        |> Giraffe.Graph.add_edge(3, 4)

      assert Giraffe.Graph.reachable(g, [1]) |> Enum.sort() == [1, 2, 3, 4]
    end

    test "directed graph - multiple components" do
      g = Giraffe.Graph.new(type: :directed)

      g =
        g
        |> Giraffe.Graph.add_edge(1, 2)
        |> Giraffe.Graph.add_edge(3, 4)

      assert Giraffe.Graph.reachable(g, [1, 3]) |> Enum.sort() == [1, 2, 3, 4]
    end

    test "undirected graph - bidirectional traversal" do
      g = Giraffe.Graph.new(type: :undirected)

      g =
        g
        |> Giraffe.Graph.add_edge(1, 2)
        |> Giraffe.Graph.add_edge(2, 3)

      assert Giraffe.Graph.reachable(g, [3]) |> Enum.sort() == [1, 2, 3]
    end

    test "undirected graph - multiple start vertices" do
      g = Giraffe.Graph.new(type: :undirected)

      g =
        g
        |> Giraffe.Graph.add_edge(1, 2)
        |> Giraffe.Graph.add_edge(4, 5)

      assert Giraffe.Graph.reachable(g, [1, 4]) |> Enum.sort() == [1, 2, 4, 5]
    end
  end
end
