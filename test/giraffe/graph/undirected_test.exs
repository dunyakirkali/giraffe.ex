defmodule Giraffe.Graph.UndirectedTest do
  use ExUnit.Case, async: true
  doctest Giraffe.Graph.Undirected

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

  describe "postorder/1" do
    test "returns vertices in postorder for a simple path" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1.0)
        |> Graph.add_edge(:b, :c, 1.0)

      result = Graph.postorder(graph)
      assert length(result) == 3
      assert :c in result
      assert :b in result
      assert :a in result
    end

    test "returns vertices in postorder for a tree-like graph" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1.0)
        |> Graph.add_edge(:b, :c, 1.0)
        |> Graph.add_edge(:b, :d, 1.0)

      result = Graph.postorder(graph)
      assert length(result) == 4
      assert :c in result
      assert :d in result
      assert :b in result
      assert :a in result
    end

    test "handles disconnected components" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1.0)
        |> Graph.add_vertex(:c)

      result = Graph.postorder(graph)
      assert length(result) == 3
      assert :a in result
      assert :b in result
      assert :c in result
    end
  end

  describe "vertex labels" do
    test "adds vertex with label" do
      graph =
        Graph.new()
        |> Graph.add_vertex(1, "First")

      assert MapSet.member?(graph.vertices, 1)
      assert Graph.get_label(graph, 1) == "First"
    end

    test "adds vertex without label" do
      graph =
        Graph.new()
        |> Graph.add_vertex(1)

      assert MapSet.member?(graph.vertices, 1)
      assert Graph.get_label(graph, 1) == nil
    end

    test "sets label for existing vertex" do
      graph =
        Graph.new()
        |> Graph.add_vertex(1)
        |> Graph.set_label(1, "Updated")

      assert Graph.get_label(graph, 1) == "Updated"
    end

    test "ignores set_label for non-existing vertex" do
      graph = Graph.new()
      updated_graph = Graph.set_label(graph, 1, "Label")

      assert graph == updated_graph
      assert Graph.get_label(graph, 1) == nil
    end

    test "maintains labels when adding edges" do
      graph =
        Graph.new()
        |> Graph.add_vertex(1, "Start")
        |> Graph.add_vertex(2, "End")
        |> Graph.add_edge(1, 2, 1)

      assert Graph.get_label(graph, 1) == "Start"
      assert Graph.get_label(graph, 2) == "End"
    end
  end

  describe "bellman_ford/2" do
    test "finds shortest paths from source vertex" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1)
        |> Graph.add_edge(:b, :c, 2)
        |> Graph.add_edge(:a, :c, 5)

      distances = Graph.bellman_ford(graph, :a)
      assert distances[:a] == 0
      assert distances[:b] == 1
      assert distances[:c] == 3
    end

    test "handles disconnected components" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1)
        |> Graph.add_vertex(:c)

      distances = Graph.bellman_ford(graph, :a)
      assert distances[:a] == 0
      assert distances[:b] == 1
      assert distances[:c] == :infinity
    end

    test "returns nil for negative cycles" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1)
        |> Graph.add_edge(:b, :c, -3)
        |> Graph.add_edge(:c, :a, 1)

      assert Graph.bellman_ford(graph, :a) == nil
    end
  end

  describe "edges/2" do
    test "returns all edges connected to vertex" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1)
        |> Graph.add_edge(:a, :c, 2)

      edges = Graph.edges(graph, :a)
      assert length(edges) == 2
      assert {:a, :b, 1} in edges
      assert {:a, :c, 2} in edges
    end

    test "returns edges regardless of direction specified at creation" do
      graph =
        Graph.new()
        |> Graph.add_edge(:b, :a, 1)

      edges = Graph.edges(graph, :a)
      assert edges == [{:a, :b, 1}]
    end

    test "returns empty list for isolated vertex" do
      graph =
        Graph.new()
        |> Graph.add_vertex(:a)

      assert Graph.edges(graph, :a) == []
    end

    test "returns empty list for non-existent vertex" do
      graph = Graph.new()
      assert Graph.edges(graph, :a) == []
    end
  end

  describe "shortest_paths/2" do
    test "finds shortest paths in connected graph" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1)
        |> Graph.add_edge(:b, :c, 2)
        |> Graph.add_edge(:a, :c, 5)

      assert Graph.shortest_paths(graph, :a) == {:ok, %{a: 0, b: 1, c: 3}}
    end

    test "handles unreachable vertices" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1)
        |> Graph.add_vertex(:c)

      {:ok, distances} = Graph.shortest_paths(graph, :a)
      assert distances[:a] == 0
      assert distances[:b] == 1
      assert distances[:c] == :infinity
    end

    test "detects negative cycles" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1)
        |> Graph.add_edge(:b, :c, -3)
        |> Graph.add_edge(:c, :a, 1)

      assert Graph.shortest_paths(graph, :a) == {:error, :negative_cycle}
    end
  end

  describe "vertex operations" do
    test "get_label returns nil for non-existent vertex" do
      graph = Graph.new()
      assert Graph.get_label(graph, :a) == nil
    end

    test "set_label is idempotent" do
      graph =
        Graph.new()
        |> Graph.add_vertex(:a, "First")
        |> Graph.set_label(:a, "First")

      assert Graph.get_label(graph, :a) == "First"
    end

    test "add_vertex preserves existing edges" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1)
        |> Graph.add_vertex(:a, "New Label")

      assert Graph.edges(graph, :a) == [{:a, :b, 1}]
      assert Graph.get_label(graph, :a) == "New Label"
    end
  end

  describe "reachable vertices" do
    test "includes all vertices in connected component" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1)
        |> Graph.add_edge(:b, :c, 1)
        |> Graph.add_vertex(:d)

      assert Enum.sort(Graph.reachable(graph, [:a])) == [:a, :b, :c]
    end

    test "handles multiple starting vertices" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1)
        |> Graph.add_edge(:c, :d, 1)

      assert Enum.sort(Graph.reachable(graph, [:a, :c])) == [:a, :b, :c, :d]
    end

    test "returns only starting vertex if isolated" do
      graph =
        Graph.new()
        |> Graph.add_vertex(:a)
        |> Graph.add_vertex(:b)

      assert Graph.reachable(graph, [:a]) == [:a]
    end

    test "handles empty starting set" do
      graph =
        Graph.new()
        |> Graph.add_vertex(:a)

      assert Graph.reachable(graph, []) == []
    end
  end

  describe "edge weight operations" do
    test "updates edge weight" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1)
        |> Graph.add_edge(:a, :b, 2)

      assert Graph.edges(graph) == [{:a, :b, 2}]
    end

    test "maintains symmetry when updating weights" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1)
        |> Graph.add_edge(:b, :a, 2)

      edges = Graph.edges(graph)
      assert length(edges) == 1
      assert {:a, :b, 2} in edges
    end
  end

  describe "graph properties" do
    test "empty graph is acyclic" do
      assert Graph.is_acyclic?(Graph.new())
    end

    test "single edge is acyclic" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1)

      assert Graph.is_acyclic?(graph)
    end

    test "isolated vertices are acyclic" do
      graph =
        Graph.new()
        |> Graph.add_vertex(:a)
        |> Graph.add_vertex(:b)

      assert Graph.is_acyclic?(graph)
    end

    test "triangle is cyclic" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1)
        |> Graph.add_edge(:b, :c, 1)
        |> Graph.add_edge(:c, :a, 1)

      assert Graph.is_cyclic?(graph)
    end

    test "path with multiple vertices is acyclic" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1)
        |> Graph.add_edge(:b, :c, 1)
        |> Graph.add_edge(:c, :d, 1)

      assert Graph.is_acyclic?(graph)
    end
  end
end
