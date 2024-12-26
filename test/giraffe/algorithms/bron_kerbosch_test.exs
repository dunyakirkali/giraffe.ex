defmodule Giraffe.Algorithms.BronKerboschTest do
  use ExUnit.Case

  alias Giraffe.Algorithms.BronKerbosch

  describe "find_cliques/2" do
    test "empty graph returns empty list" do
      assert BronKerbosch.find_cliques([], %{}) == []
    end

    test "single vertex returns singleton clique" do
      vertices = [:a]
      edges = %{a: %{}}
      assert BronKerbosch.find_cliques(vertices, edges) == [[:a]]
    end

    test "two disconnected vertices return two singleton cliques" do
      vertices = [:a, :b]
      edges = %{a: %{}, b: %{}}
      cliques = BronKerbosch.find_cliques(vertices, edges)
      assert length(cliques) == 2
      assert [:a] in cliques
      assert [:b] in cliques
    end

    test "finds clique in a complete triangle" do
      vertices = [:a, :b, :c]

      edges = %{
        a: %{b: 1, c: 1},
        b: %{a: 1, c: 1},
        c: %{a: 1, b: 1}
      }

      cliques = BronKerbosch.find_cliques(vertices, edges)
      assert length(cliques) == 1
      assert Enum.sort(hd(cliques)) == [:a, :b, :c]
    end

    test "finds multiple cliques in a diamond graph" do
      vertices = [:a, :b, :c, :d]

      edges = %{
        a: %{b: 1, c: 1},
        b: %{a: 1, c: 1, d: 1},
        c: %{a: 1, b: 1, d: 1},
        d: %{b: 1, c: 1}
      }

      cliques = BronKerbosch.find_cliques(vertices, edges)
      assert length(cliques) == 2
      assert Enum.sort(hd(cliques)) == [:a, :b, :c]
      assert Enum.sort(List.last(cliques)) == [:b, :c, :d]
    end

    test "finds cliques in a complex graph" do
      vertices = [:a, :b, :c, :d, :e]

      edges = %{
        a: %{b: 1, c: 1, d: 1},
        b: %{a: 1, c: 1},
        c: %{a: 1, b: 1, d: 1},
        d: %{a: 1, c: 1, e: 1},
        e: %{d: 1}
      }

      cliques = BronKerbosch.find_cliques(vertices, edges)
      assert length(cliques) == 3
      assert Enum.any?(cliques, fn clique -> Enum.sort(clique) == [:a, :b, :c] end)
      assert Enum.any?(cliques, fn clique -> Enum.sort(clique) == [:a, :c, :d] end)
      assert Enum.any?(cliques, fn clique -> Enum.sort(clique) == [:d, :e] end)
    end

    test "handles graph with isolated vertices and edges" do
      vertices = [:a, :b, :c, :d]

      edges = %{
        a: %{b: 1},
        b: %{a: 1},
        c: %{},
        d: %{}
      }

      cliques = BronKerbosch.find_cliques(vertices, edges)
      assert length(cliques) == 4
      assert Enum.sort([:a, :b]) in Enum.map(cliques, &Enum.sort/1)
      assert [:c] in cliques
      assert [:d] in cliques
    end

    test "finds cliques in a complete graph" do
      vertices = [:a, :b, :c, :d]

      edges = %{
        a: %{b: 1, c: 1, d: 1},
        b: %{a: 1, c: 1, d: 1},
        c: %{a: 1, b: 1, d: 1},
        d: %{a: 1, b: 1, c: 1}
      }

      cliques = BronKerbosch.find_cliques(vertices, edges)
      assert length(cliques) == 1
      assert Enum.sort(hd(cliques)) == [:a, :b, :c, :d]
    end
  end
end
