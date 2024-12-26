defmodule Graph.UndirectedTest do
  use ExUnit.Case

  alias Giraffe.Graph.Undirected, as: Undirected

  describe "new/0" do
    test "creates empty graph" do
      graph = Undirected.new()
      assert Undirected.vertices(graph) == []
      assert Undirected.edges(graph) == []
    end
  end

  describe "add_vertex/2" do
    test "adds vertices" do
      graph =
        Undirected.new()
        |> Undirected.add_vertex(:a)
        |> Undirected.add_vertex(:b)

      assert Enum.sort(Undirected.vertices(graph)) == [:a, :b]
    end

    test "handles duplicate vertices" do
      graph =
        Undirected.new()
        |> Undirected.add_vertex(:a)
        |> Undirected.add_vertex(:a)

      assert Undirected.vertices(graph) == [:a]
    end
  end

  describe "add_edge/4" do
    test "adds bidirectional edges" do
      graph =
        Undirected.new()
        |> Undirected.add_vertex(:a)
        |> Undirected.add_vertex(:b)
        |> Undirected.add_edge(:a, :b, 1.0)

      assert Undirected.edges(graph) == [{:a, :b, 1.0}]
    end

    test "updates existing edge weight" do
      graph =
        Undirected.new()
        |> Undirected.add_vertex(:a)
        |> Undirected.add_vertex(:b)
        |> Undirected.add_edge(:a, :b, 1.0)
        |> Undirected.add_edge(:a, :b, 2.0)

      assert Undirected.edges(graph) == [{:a, :b, 2.0}]
    end

    test "automatically adds vertices when creating edges" do
      graph =
        Undirected.new()
        |> Undirected.add_edge(:x, :y, 1.0)

      vertices = Undirected.vertices(graph)
      assert Enum.sort(vertices) == [:x, :y]
      assert Undirected.edges(graph) == [{:x, :y, 1.0}]
    end
  end

  describe "get_shortest_path/3" do
    test "finds shortest path in simple graph" do
      graph =
        Undirected.new()
        |> Undirected.add_edge(:a, :b, 1.0)
        |> Undirected.add_edge(:b, :c, 2.0)

      assert Undirected.get_shortest_path(graph, :a, :c) == {:ok, [:a, :b, :c], 3.0}
    end

    test "finds shortest path when multiple paths exist" do
      graph =
        Undirected.new()
        |> Undirected.add_edge(:a, :b, 1.0)
        |> Undirected.add_edge(:b, :c, 2.0)
        |> Undirected.add_edge(:a, :c, 5.0)

      assert Undirected.get_shortest_path(graph, :a, :c) == {:ok, [:a, :b, :c], 3.0}
    end

    test "returns :no_path when no path exists" do
      graph =
        Undirected.new()
        |> Undirected.add_vertex(:a)
        |> Undirected.add_vertex(:b)

      assert Undirected.get_shortest_path(graph, :a, :b) == :no_path
    end
  end

  describe "get_paths/3" do
    test "finds all paths between vertices" do
      graph =
        Undirected.new()
        |> Undirected.add_vertex(:a)
        |> Undirected.add_vertex(:b)
        |> Undirected.add_vertex(:c)
        |> Undirected.add_edge(:a, :b, 1.0)
        |> Undirected.add_edge(:b, :c, 2.0)
        |> Undirected.add_edge(:a, :c, 5.0)

      paths = Undirected.get_paths(graph, :a, :c)
      assert length(paths) == 2
      assert {[:a, :b, :c], 3.0} in paths
      assert {[:a, :c], 5.0} in paths
    end

    test "returns empty list when no paths exist" do
      graph =
        Undirected.new()
        |> Undirected.add_vertex(:a)
        |> Undirected.add_vertex(:b)

      assert Undirected.get_paths(graph, :a, :b) == []
    end
  end
end
