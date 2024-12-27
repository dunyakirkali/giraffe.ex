defmodule Giraffe.Graph.BaseTest do
  use ExUnit.Case, async: true
  doctest Giraffe.Graph.Base

  # We'll test using Directed graph implementation since Base is a behavior
  alias Giraffe.Graph.Directed, as: Graph

  describe "new/1" do
    test "creates an empty graph" do
      graph = Graph.new()
      assert graph.vertices == MapSet.new()
      assert graph.edges == %{}
      assert graph.labels == %{}
    end

    test "creates an empty graph with options" do
      graph = Graph.new(type: :directed)
      assert graph.vertices == MapSet.new()
      assert graph.edges == %{}
      assert graph.labels == %{}
    end
  end

  describe "add_vertex/3" do
    test "adds a vertex without labels" do
      graph = Graph.new() |> Graph.add_vertex(:a)
      assert Graph.has_vertex?(graph, :a)
      assert Graph.vertex_labels(graph, :a) == []
    end

    test "adds a vertex with labels" do
      graph = Graph.new() |> Graph.add_vertex(:a, [:label1, :label2])
      assert Graph.has_vertex?(graph, :a)
      assert Graph.vertex_labels(graph, :a) == [:label1, :label2]
    end

    test "adding the same vertex twice is idempotent" do
      graph =
        Graph.new()
        |> Graph.add_vertex(:a, [:label1])
        |> Graph.add_vertex(:a, [:label2])

      assert Graph.has_vertex?(graph, :a)
      assert Graph.vertex_labels(graph, :a) == [:label2]
    end
  end

  describe "has_vertex?/2" do
    test "returns true for existing vertex" do
      graph = Graph.new() |> Graph.add_vertex(:a)
      assert Graph.has_vertex?(graph, :a)
    end

    test "returns false for non-existing vertex" do
      graph = Graph.new()
      refute Graph.has_vertex?(graph, :a)
    end
  end

  describe "vertices/1" do
    test "returns empty list for empty graph" do
      assert Graph.new() |> Graph.vertices() == []
    end

    test "returns list of vertices" do
      graph =
        Graph.new()
        |> Graph.add_vertex(:a)
        |> Graph.add_vertex(:b)

      assert Graph.vertices(graph) |> Enum.sort() == [:a, :b]
    end
  end

  describe "num_vertices/1" do
    test "returns 0 for empty graph" do
      assert Graph.new() |> Graph.num_vertices() == 0
    end

    test "returns correct count of vertices" do
      graph =
        Graph.new()
        |> Graph.add_vertex(:a)
        |> Graph.add_vertex(:b)

      assert Graph.num_vertices(graph) == 2
    end
  end

  describe "num_edges/1" do
    test "returns 0 for empty graph" do
      assert Graph.new() |> Graph.num_edges() == 0
    end

    test "returns correct count of edges" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b)
        |> Graph.add_edge(:b, :c)

      assert Graph.num_edges(graph) == 2
    end

    test "handles multiple edges from same vertex" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b)
        |> Graph.add_edge(:a, :c)

      assert Graph.num_edges(graph) == 2
    end
  end

  describe "vertex_labels/2" do
    test "returns empty list for vertex without labels" do
      graph = Graph.new() |> Graph.add_vertex(:a)
      assert Graph.vertex_labels(graph, :a) == []
    end

    test "returns labels for vertex with labels" do
      graph = Graph.new() |> Graph.add_vertex(:a, [:label1, :label2])
      assert Graph.vertex_labels(graph, :a) == [:label1, :label2]
    end

    test "returns empty list for non-existent vertex" do
      graph = Graph.new()
      assert Graph.vertex_labels(graph, :a) == []
    end
  end

  describe "reachable/2" do
    test "returns empty list for empty graph" do
      assert Graph.new() |> Graph.reachable([]) == []
    end

    test "returns starting vertex if no edges" do
      graph = Graph.new() |> Graph.add_vertex(:a)
      assert Graph.reachable(graph, [:a]) == [:a]
    end

    test "returns reachable vertices" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b)
        |> Graph.add_edge(:b, :c)
        |> Graph.add_edge(:d, :e)

      assert Graph.reachable(graph, [:a]) |> Enum.sort() == [:a, :b, :c]
      assert Graph.reachable(graph, [:d]) |> Enum.sort() == [:d, :e]
      assert Graph.reachable(graph, [:a, :d]) |> Enum.sort() == [:a, :b, :c, :d, :e]
    end

    test "handles cycles" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b)
        |> Graph.add_edge(:b, :c)
        |> Graph.add_edge(:c, :a)

      assert Graph.reachable(graph, [:a]) |> Enum.sort() == [:a, :b, :c]
    end
  end

  describe "postorder/1" do
    test "returns empty list for empty graph" do
      assert Graph.new() |> Graph.postorder() == []
    end

    test "returns vertices in post-order" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b)
        |> Graph.add_edge(:b, :c)

      assert Graph.postorder(graph) == [:c, :b, :a]
    end

    test "handles cycles" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b)
        |> Graph.add_edge(:b, :c)
        |> Graph.add_edge(:c, :a)

      result = Graph.postorder(graph)
      assert length(result) == 3
      assert Enum.sort(result) == [:a, :b, :c]
    end

    test "handles disconnected components" do
      graph =
        Graph.new()
        |> Graph.add_edge(:a, :b)
        |> Graph.add_edge(:c, :d)

      result = Graph.postorder(graph)
      assert length(result) == 4
      assert Enum.sort(result) == [:a, :b, :c, :d]
    end
  end
end
