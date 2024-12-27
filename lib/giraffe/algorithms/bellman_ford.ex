defmodule Giraffe.Algorithms.BellmanFord do
  @moduledoc """
  Implementation of the Bellman-Ford algorithm for finding shortest paths in graphs.
  """

  @type vertex :: any()
  @type edge :: {vertex(), vertex(), number()}
  @type adjacency_list :: %{vertex() => [{vertex(), vertex(), number()}]}
  @type graph_struct :: %{required(:edges) => map(), required(:vertices) => MapSet.t()}

  @doc """
  Finds the shortest paths from a source vertex to all other vertices in the graph.

  Returns a map of vertices to their shortest distance from the source.
  If a negative cycle is detected, returns `{:error, :negative_cycle}`.
  """
  @spec shortest_paths(adjacency_list() | graph_struct(), vertex()) ::
          {:ok, %{vertex() => number()}} | {:error, :negative_cycle}
  def shortest_paths(graph, source) do
    {vertices, edges} = extract_graph_data(graph)

    # Initialize distances
    distances = Map.new(vertices, fn v -> {v, if(v == source, do: 0, else: :infinity)} end)

    # Relax edges |V| - 1 times
    distances =
      Enum.reduce(1..(length(vertices) - 1), distances, fn _, acc ->
        Enum.reduce(edges, acc, fn {u, v, weight}, dists ->
          if dists[u] != :infinity and dists[u] + weight < (dists[v] || :infinity) do
            Map.put(dists, v, dists[u] + weight)
          else
            dists
          end
        end)
      end)

    # Check for negative cycles
    if Enum.any?(edges, fn {u, v, weight} ->
         distances[u] != :infinity and distances[u] + weight < distances[v]
       end) do
      {:error, :negative_cycle}
    else
      {:ok, distances}
    end
  end

  # Private helper to extract vertices and edges from different graph formats
  defp extract_graph_data(graph) do
    cond do
      is_map(graph) && Map.has_key?(graph, :vertices) && Map.has_key?(graph, :edges) ->
        # Handle graph struct format
        vertices = MapSet.to_list(graph.vertices)

        edges =
          for {from, targets} <- graph.edges,
              {to, weight} <- targets,
              do: {from, to, weight}

        {vertices, edges}

      is_map(graph) ->
        # Handle adjacency list format
        vertices = Map.keys(graph)
        edges = Enum.flat_map(graph, fn {_, edges} -> edges end)
        {vertices, edges}
    end
  end
end
