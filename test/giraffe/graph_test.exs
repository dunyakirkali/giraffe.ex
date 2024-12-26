defmodule GraphTest do
  use ExUnit.Case
  doctest Giraffe.Graph

  alias Giraffe.Graph, as: Graph

  describe "directed graph" do
    setup do
      graph =
        Graph.new(:directed)
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
        Graph.new(:undirected)
        |> Graph.add_vertex(1)
        |> Graph.add_vertex(2)
        |> Graph.add_edge(1, 2, 1.0)

      {:ok, graph: graph}
    end

    test "edges are bidirectional", %{graph: graph} do
      assert Graph.edges(graph) == [{1, 2, 1.0}]
    end
  end
end
