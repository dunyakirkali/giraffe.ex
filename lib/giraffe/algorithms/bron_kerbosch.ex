defmodule Giraffe.Algorithms.BronKerbosch do
  @moduledoc """
  Implementation of the Bron-Kerbosch algorithm for finding maximal cliques in graphs.
  """

  @doc """
  Finds all maximal cliques in a graph using the Bron-Kerbosch algorithm with pivot.
  """
  @spec find_cliques([any()], %{any() => %{any() => number()}}) :: [[any()]]
  def find_cliques([], _edges), do: []

  def find_cliques(vertices, edges) do
    normalized_edges =
      vertices
      |> Enum.map(fn v ->
        {v, Map.get(edges, v) |> Enum.into(%{}, fn {k, v} -> {k, v} end)}
      end)
      |> Enum.into(%{})

    bron_kerbosch([], vertices, [], normalized_edges)
    |> Enum.sort_by(&length/1, :desc)
  end

  defp bron_kerbosch(r, [], [], _edges), do: [r]

  defp bron_kerbosch(r, p, x, edges) do
    if Enum.empty?(p) and Enum.empty?(x) do
      [r]
    else
      pivot = choose_pivot(p ++ x, edges)
      candidates = p -- get_non_neighbors(pivot, edges)

      candidates
      |> Enum.flat_map(fn v ->
        new_r = r ++ [v]
        new_p = p |> Enum.filter(&connected?(edges, v, &1)) |> Enum.reject(&(&1 == v))
        new_x = x |> Enum.filter(&connected?(edges, v, &1))

        bron_kerbosch(new_r, new_p, new_x, edges)
      end)
    end
  end

  defp choose_pivot(vertices, edges) do
    Enum.max_by(vertices, fn v ->
      Map.get(edges, v, %{}) |> Map.keys() |> length()
    end)
  end

  defp get_non_neighbors(pivot, edges) do
    neighbors = Map.get(edges, pivot, %{}) |> Map.keys() |> MapSet.new()
    all_vertices = Map.keys(edges) |> MapSet.new()

    MapSet.difference(all_vertices, neighbors)
    |> MapSet.delete(pivot)
    |> MapSet.to_list()
  end

  defp connected?(_edges, v1, v2) when v1 == v2, do: false

  defp connected?(edges, v1, v2) do
    edges |> Map.get(v1, %{}) |> Map.has_key?(v2)
  end
end
