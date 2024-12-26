defmodule Giraffe.Algorithms.BellmanFord do
  @moduledoc """
  Implementation of the Bellman-Ford algorithm for finding shortest paths in graphs.
  """

  @type vertex :: any()
  @type edge :: {vertex(), vertex(), number()}
  @type graph :: %{vertex() => [edge()]}

  @doc """
  Finds the shortest paths from a source vertex to all other vertices in the graph.

  Returns a map of vertices to their shortest distance from the source.
  If a negative cycle is detected, returns `{:error, :negative_cycle}`.
  """
  @spec shortest_paths(graph(), vertex()) ::
          {:ok, %{vertex() => number()}} | {:error, :negative_cycle}
  def shortest_paths(graph, source) do
    vertices = Map.keys(graph)
    edges = Enum.flat_map(graph, fn {_, edges} -> edges end)

    distances = Enum.into(vertices, %{}, fn v -> {v, :infinity} end)
    distances = Map.put(distances, source, 0)

    distances =
      Enum.reduce(1..(length(vertices) - 1), distances, fn _, acc ->
        Enum.reduce(edges, acc, fn {u, v, weight}, dists ->
          if dists[u] != :infinity and dists[u] + weight < dists[v] do
            Map.put(dists, v, dists[u] + weight)
          else
            dists
          end
        end)
      end)

    if Enum.any?(edges, fn {u, v, weight} ->
         distances[u] != :infinity and distances[u] + weight < distances[v]
       end) do
      {:error, :negative_cycle}
    else
      {:ok, distances}
    end
  end
end
