defmodule Giraffe.Algorithms.BellmanFord do
  @moduledoc """
  Implementation of the Bellman-Ford algorithm for finding shortest paths in graphs.
  Time complexity: O(VLogV)
  """

  @type vertex :: any()
  @type edge :: {vertex(), vertex(), number()}
  @type adjacency_list :: %{vertex() => [{vertex(), vertex(), number()}]}
  @type graph_struct :: %{required(:edges) => map(), required(:vertices) => MapSet.t()}

  @doc """
  Finds the shortest paths from a source vertex to all other vertices in the graph.
  Returns nil when graph has negative cycle.
  """
  @spec shortest_paths(adjacency_list() | graph_struct(), vertex()) ::
          {:ok, %{vertex() => number() | :infinity}} | {:error, :negative_cycle}
  def shortest_paths(graph, source) do
    {vertices, edges} = extract_graph_data(graph)
    distances = init_distances(source, vertices)

    distances =
      for _ <- 1..length(vertices),
          {u, v, weight} <- edges,
          reduce: distances do
        acc -> update_distance({u, v, weight}, acc)
      end

    if has_negative_cycle?(distances, edges) do
      {:error, :negative_cycle}
    else
      {:ok, distances}
    end
  end

  defp init_distances(source, vertices) do
    Map.new(vertices, fn v ->
      if v == source, do: {v, 0}, else: {v, :infinity}
    end)
  end

  defp update_distance({u, v, weight}, distances) do
    du = Map.get(distances, u, :infinity)
    dv = Map.get(distances, v, :infinity)

    if du != :infinity and du + weight < dv do
      Map.put(distances, v, du + weight)
    else
      distances
    end
  end

  defp has_negative_cycle?(distances, edges) do
    Enum.any?(edges, fn {u, v, weight} ->
      du = Map.get(distances, u, :infinity)
      dv = Map.get(distances, v, :infinity)
      du != :infinity and du + weight < dv
    end)
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
