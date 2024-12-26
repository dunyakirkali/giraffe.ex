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
    r = MapSet.new()
    p = MapSet.new(vertices)
    x = MapSet.new()

    bron_kerbosch(r, p, x, edges)
    |> Enum.map(&MapSet.to_list/1)
    |> Enum.sort_by(&length/1, :desc)
  end

  defp bron_kerbosch(r, p, x, edges) do
    if MapSet.size(p) == 0 and MapSet.size(x) == 0 do
      [r]
    else
      pivot = choose_pivot(MapSet.union(p, x), edges)
      p_without_neighbors = MapSet.difference(p, neighbors(pivot, edges))

      p_without_neighbors
      |> MapSet.to_list()
      |> Enum.flat_map(fn v ->
        new_r = MapSet.put(r, v)
        v_neighbors = neighbors(v, edges)
        new_p = MapSet.intersection(p, v_neighbors)
        new_x = MapSet.intersection(x, v_neighbors)

        bron_kerbosch(new_r, new_p, new_x, edges)
      end)
    end
  end

  defp choose_pivot(vertices, edges) do
    vertices
    |> MapSet.to_list()
    |> Enum.max_by(fn v ->
      edges
      |> Map.get(v, %{})
      |> map_size()
    end)
  end

  defp neighbors(vertex, edges) do
    edges
    |> Map.get(vertex, %{})
    |> Map.keys()
    |> MapSet.new()
  end
end
