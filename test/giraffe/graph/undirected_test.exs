defmodule Giraffe.Graph.UndirectedTest do
  use ExUnit.Case

  alias Giraffe.Graph.Undirected, as: Graph

  describe "new/0" do
    test "creates empty graph" do
      graph = Graph.new()
      assert Graph.vertices(graph) == []
      assert Graph.edges(graph) == []
    end
  end

  describe "add_vertex/2" do
    test "adds vertices" do
      graph =
        Graph.new()
        |> Graph.add_vertex(:a)
        |> Graph.add_vertex(:b)

      assert Enum.sort(Graph.vertices(graph)) == [:a, :b]
    end

    test "handles duplicate vertices" do
      graph =
        Graph.new()
        |> Graph.add_vertex(:a)
        |> Graph.add_vertex(:a)

      assert Graph.vertices(graph) == [:a]
    end
  end

  describe "add_edge/4" do
    test "adds bidirectional edges" do
      graph =
        Graph.new()
        |> Graph.add_vertex(:a)
        |> Graph.add_vertex(:b)
        |> Graph.add_edge(:a, :b, 1.0)

      assert Graph.edges(graph) == [{:a, :b, 1.0}]
    end

    test "updates existing edge weight" do
      graph =
        Graph.new()
        |> Graph.add_vertex(:a)
        |> Graph.add_vertex(:b)
        |> Graph.add_edge(:a, :b, 1.0)
        |> Graph.add_edge(:a, :b, 2.0)

      assert Graph.edges(graph) == [{:a, :b, 2.0}]
    end

    test "automatically adds vertices when creating edges" do
      graph =
        Graph.new()
        |> Graph.add_edge(:x, :y, 1.0)

      vertices = Graph.vertices(graph)
      assert Enum.sort(vertices) == [:x, :y]
      assert Graph.edges(graph) == [{:x, :y, 1.0}]
    end
  end

  describe "get_shortest_path/3" do
    test "finds shortest path in simple graph" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1.0)
        |> Graph.add_edge(:b, :c, 2.0)

      assert Graph.get_shortest_path(graph, :a, :c) == {:ok, [:a, :b, :c], 3.0}
    end

    test "finds shortest path when multiple paths exist" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1.0)
        |> Graph.add_edge(:b, :c, 2.0)
        |> Graph.add_edge(:a, :c, 5.0)

      assert Graph.get_shortest_path(graph, :a, :c) == {:ok, [:a, :b, :c], 3.0}
    end

    test "returns :no_path when no path exists" do
      graph =
        Graph.new()
        |> Graph.add_vertex(:a)
        |> Graph.add_vertex(:b)

      assert Graph.get_shortest_path(graph, :a, :b) == :no_path
    end
  end

  describe "get_paths/3" do
    test "finds all paths between vertices" do
      graph =
        Graph.new()
        |> Graph.add_vertex(:a)
        |> Graph.add_vertex(:b)
        |> Graph.add_vertex(:c)
        |> Graph.add_edge(:a, :b, 1.0)
        |> Graph.add_edge(:b, :c, 2.0)
        |> Graph.add_edge(:a, :c, 5.0)

      paths = Graph.get_paths(graph, :a, :c)
      assert length(paths) == 2
      assert {[:a, :b, :c], 3.0} in paths
      assert {[:a, :c], 5.0} in paths
    end

    test "returns empty list when no paths exist" do
      graph =
        Graph.new()
        |> Graph.add_vertex(:a)
        |> Graph.add_vertex(:b)

      assert Graph.get_paths(graph, :a, :b) == []
    end
  end

  describe "cliques/1" do
    test "finds cliques in a triangle" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1.0)
        |> Graph.add_edge(:b, :c, 1.0)
        |> Graph.add_edge(:c, :a, 1.0)

      cliques = Graph.cliques(graph)
      assert length(cliques) == 1
      assert List.first(cliques) |> Enum.sort() == [:a, :b, :c]
    end

    test "finds cliques in a square with diagonal" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1.0)
        |> Graph.add_edge(:b, :c, 1.0)
        |> Graph.add_edge(:c, :d, 1.0)
        |> Graph.add_edge(:d, :a, 1.0)
        |> Graph.add_edge(:a, :c, 1.0)

      cliques = Graph.cliques(graph)
      assert length(cliques) == 2

      assert Enum.any?(cliques, fn clique ->
               Enum.sort(clique) == [:a, :b, :c]
             end)

      assert Enum.any?(cliques, fn clique ->
               Enum.sort(clique) == [:a, :c, :d]
             end)
    end

    test "handles empty graph" do
      graph = Graph.new()
      assert Graph.cliques(graph) == [[]]
    end

    test "handles single vertex" do
      graph =
        Graph.new()
        |> Graph.add_vertex(:a)

      assert Graph.cliques(graph) == [[:a]]
    end

    test "handles disconnected vertices" do
      graph =
        Graph.new()
        |> Graph.add_vertex(:a)
        |> Graph.add_vertex(:b)

      cliques = Graph.cliques(graph)
      assert length(cliques) == 2
      assert [:a] in cliques
      assert [:b] in cliques
    end
  end

  describe "is_acyclic?/1" do
    test "returns true for an acyclic graph" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1.0)
        |> Graph.add_edge(:b, :c, 1.0)

      assert Graph.is_acyclic?(graph) == true
    end

    test "returns false for a cyclic graph" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1.0)
        |> Graph.add_edge(:b, :c, 1.0)
        |> Graph.add_edge(:c, :a, 1.0)

      assert Graph.is_acyclic?(graph) == false
    end

    test "returns true for an empty graph" do
      graph = Graph.new()
      assert Graph.is_acyclic?(graph) == true
    end

    test "returns true for a graph with a single vertex and no edges" do
      graph =
        Graph.new()
        |> Graph.add_vertex(:a)

      assert Graph.is_acyclic?(graph) == true
    end
  end

  describe "is_cyclic?/1" do
    test "returns true for a triangle" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1.0)
        |> Graph.add_edge(:b, :c, 1.0)
        |> Graph.add_edge(:c, :a, 1.0)

      assert Graph.is_cyclic?(graph)
    end

    test "returns true for a square" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1.0)
        |> Graph.add_edge(:b, :c, 1.0)
        |> Graph.add_edge(:c, :d, 1.0)
        |> Graph.add_edge(:d, :a, 1.0)

      assert Graph.is_cyclic?(graph)
    end

    test "returns false for a path" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1.0)
        |> Graph.add_edge(:b, :c, 1.0)

      refute Graph.is_cyclic?(graph)
    end

    test "returns false for a star graph" do
      graph =
        Graph.new()
        |> Graph.add_edge(:center, :a, 1.0)
        |> Graph.add_edge(:center, :b, 1.0)
        |> Graph.add_edge(:center, :c, 1.0)

      refute Graph.is_cyclic?(graph)
    end

    test "returns false for a single edge" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1.0)

      refute Graph.is_cyclic?(graph)
    end

    test "returns false for isolated vertices" do
      graph =
        Graph.new()
        |> Graph.add_vertex(:a)
        |> Graph.add_vertex(:b)
        |> Graph.add_vertex(:c)

      refute Graph.is_cyclic?(graph)
    end

    test "returns true for complex graph with multiple cycles" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1.0)
        |> Graph.add_edge(:b, :c, 1.0)
        |> Graph.add_edge(:c, :a, 1.0)
        |> Graph.add_edge(:c, :d, 1.0)
        |> Graph.add_edge(:d, :e, 1.0)
        |> Graph.add_edge(:e, :c, 1.0)

      assert Graph.is_cyclic?(graph)
    end
  end

  describe "neighbors/2" do
    test "returns all neighboring vertices" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1.0)
        |> Graph.add_edge(:b, :c, 1.0)

      assert Graph.neighbors(graph, :b) == [:a, :c]
    end

    test "returns empty list for non-existent vertex" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1.0)

      assert Graph.neighbors(graph, :c) == []
    end

    test "returns neighbors for vertex with multiple connections" do
      graph =
        Graph.new()
        |> Graph.add_edge(:center, :a, 1.0)
        |> Graph.add_edge(:center, :b, 1.0)
        |> Graph.add_edge(:center, :c, 1.0)

      assert Graph.neighbors(graph, :center) == [:a, :b, :c]
    end
  end
end
