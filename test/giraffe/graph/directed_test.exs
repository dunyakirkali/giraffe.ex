defmodule Giraffe.Graph.DirectedTest do
  use ExUnit.Case, async: true
  doctest Giraffe.Graph.Directed

  alias Giraffe.Graph.Directed, as: Graph

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
    test "adds directed edges" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1.0)

      assert Graph.edges(graph) == [{:a, :b, 1.0}]
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

    test "respects direction of edges" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1.0)

      assert Graph.get_shortest_path(graph, :b, :a) == :no_path
    end
  end

  describe "get_paths/3" do
    test "finds all paths between vertices" do
      graph =
        Graph.new()
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

    test "respects direction of edges in path finding" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1.0)

      assert Graph.get_paths(graph, :b, :a) == []
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

    test "returns false for a graph with a self-loop" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :a, 1.0)

      assert Graph.is_acyclic?(graph) == false
    end
  end

  describe "is_cyclic?/1" do
    test "returns true for a graph with a self-loop" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :a, 1.0)

      assert Graph.is_cyclic?(graph)
    end

    test "returns true for a graph with a cycle" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1.0)
        |> Graph.add_edge(:b, :c, 1.0)
        |> Graph.add_edge(:c, :a, 1.0)

      assert Graph.is_cyclic?(graph)
    end

    test "returns false for an acyclic graph" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1.0)
        |> Graph.add_edge(:b, :c, 1.0)

      refute Graph.is_cyclic?(graph)
    end

    test "returns false for an empty graph" do
      graph = Graph.new()
      refute Graph.is_cyclic?(graph)
    end

    test "returns false for a single vertex" do
      graph =
        Graph.new()
        |> Graph.add_vertex(:a)

      refute Graph.is_cyclic?(graph)
    end

    test "returns true for a complex cyclic graph" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1.0)
        |> Graph.add_edge(:b, :c, 1.0)
        |> Graph.add_edge(:c, :d, 1.0)
        |> Graph.add_edge(:d, :b, 1.0)

      assert Graph.is_cyclic?(graph)
    end
  end

  describe "neighbors/2" do
    test "returns all neighboring vertices" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1.0)
        |> Graph.add_edge(:b, :c, 1.0)
        |> Graph.add_edge(:c, :a, 1.0)

      assert Graph.neighbors(graph, :b) == [:a, :c]
    end

    test "returns empty list for non-existent vertex" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1.0)

      assert Graph.neighbors(graph, :c) == []
    end

    test "returns both incoming and outgoing neighbors" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1.0)
        |> Graph.add_edge(:c, :b, 1.0)
        |> Graph.add_edge(:b, :d, 1.0)

      assert Graph.neighbors(graph, :b) == [:a, :c, :d]
    end
  end

  describe "postorder/1" do
    test "returns vertices in postorder for a simple path" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1.0)
        |> Graph.add_edge(:b, :c, 1.0)

      assert Graph.postorder(graph) == [:c, :b, :a]
    end

    test "returns vertices in postorder for a tree-like graph" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1.0)
        |> Graph.add_edge(:b, :c, 1.0)
        |> Graph.add_edge(:b, :d, 1.0)
        |> Graph.add_edge(:c, :e, 1.0)

      assert Graph.postorder(graph) == [:e, :c, :d, :b, :a]
    end

    test "handles disconnected components" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b, 1.0)
        |> Graph.add_vertex(:c)
        |> Graph.add_vertex(:d)

      result = Graph.postorder(graph)
      assert length(result) == 4
      assert :b in result
      assert :a in result
      assert :c in result
      assert :d in result
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
end
