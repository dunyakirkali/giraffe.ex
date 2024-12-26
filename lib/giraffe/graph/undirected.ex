defmodule Giraffe.Graph.Undirected do
  @moduledoc """
  Implementation of an undirected graph with weighted edges.
  Vertices can be any term, and edges have numeric weights.
  """

  defstruct vertices: MapSet.new(),
            edges: %{}

  @type vertex :: any()
  @type weight :: number()
  @type edge :: {vertex(), vertex(), weight()}
  @type t :: %__MODULE__{
          vertices: MapSet.t(),
          edges: %{vertex() => %{vertex() => weight()}}
        }

  @spec new() :: t()
  def new, do: %__MODULE__{}

  @spec add_vertex(t(), vertex()) :: t()
  def add_vertex(%__MODULE__{vertices: vertices} = graph, vertex) do
    %{graph | vertices: MapSet.put(vertices, vertex)}
  end

  @spec add_edge(t(), vertex(), vertex(), weight()) :: t()
  def add_edge(%__MODULE__{edges: edges, vertices: vertices} = graph, vertex1, vertex2, weight) do
    new_vertices =
      vertices
      |> MapSet.put(vertex1)
      |> MapSet.put(vertex2)

    new_edges =
      edges
      |> Map.update(vertex1, %{vertex2 => weight}, fn map -> Map.put(map, vertex2, weight) end)
      |> Map.update(vertex2, %{vertex1 => weight}, fn map -> Map.put(map, vertex1, weight) end)

    %{graph | edges: new_edges, vertices: new_vertices}
  end

  @spec vertices(t()) :: [vertex()]
  def vertices(%__MODULE__{vertices: vertices}), do: MapSet.to_list(vertices)

  @spec edges(t()) :: [edge()]
  def edges(%__MODULE__{edges: edges}) do
    edges
    |> Enum.flat_map(fn {from, targets} ->
      Enum.map(targets, fn {to, weight} ->
        if from <= to, do: [{from, to, weight}], else: []
      end)
    end)
    |> List.flatten()
  end

  @spec get_shortest_path(t(), vertex(), vertex()) :: {:ok, [vertex()], weight()} | :no_path
  def get_shortest_path(graph, start, finish) do
    case dijkstra(graph, start, finish) do
      {:ok, distances, predecessors} ->
        case Map.get(distances, finish) do
          nil ->
            :no_path

          :infinity ->
            :no_path

          total_weight ->
            path = build_path(predecessors, finish)
            {:ok, path, total_weight}
        end

      :no_path ->
        :no_path
    end
  end

  @spec get_paths(t(), vertex(), vertex()) :: [{[vertex()], weight()}]
  def get_paths(graph, start, finish) do
    find_all_paths(graph, start, finish, [start], MapSet.new([start]), 0.0)
  end

  # Private Functions

  defp dijkstra(%__MODULE__{edges: edges, vertices: vertices} = graph, start, finish) do
    if not MapSet.member?(vertices, start) or not MapSet.member?(vertices, finish) do
      :no_path
    else
      distances =
        MapSet.to_list(vertices)
        |> Map.new(fn vertex ->
          if vertex == start, do: {vertex, 0}, else: {vertex, :infinity}
        end)

      dijkstra_traverse(edges, MapSet.to_list(vertices) |> MapSet.new(), distances, %{})
    end
  end

  defp dijkstra_traverse(edges, unvisited, distances, predecessors)
       when map_size(distances) > 0 do
    case find_min_distance_vertex(unvisited, distances) do
      nil ->
        {:ok, distances, predecessors}

      current ->
        if Map.get(distances, current) == :infinity do
          :no_path
        else
          neighbors = Map.get(edges, current, %{})

          {new_distances, new_predecessors} =
            update_distances(neighbors, current, distances, predecessors)

          dijkstra_traverse(
            edges,
            MapSet.delete(unvisited, current),
            new_distances,
            new_predecessors
          )
        end
    end
  end

  defp find_min_distance_vertex(unvisited, distances) do
    Enum.min_by(
      MapSet.to_list(unvisited),
      fn vertex -> Map.get(distances, vertex, :infinity) end,
      &<=/2,
      fn -> nil end
    )
  end

  defp update_distances(neighbors, current, distances, predecessors) do
    current_distance = Map.get(distances, current)

    Enum.reduce(neighbors, {distances, predecessors}, fn {neighbor, weight},
                                                         {dist_acc, pred_acc} ->
      case Map.get(dist_acc, neighbor) do
        nil ->
          {dist_acc, pred_acc}

        neighbor_distance ->
          potential_distance = current_distance + weight

          if neighbor_distance == :infinity or potential_distance < neighbor_distance do
            {Map.put(dist_acc, neighbor, potential_distance),
             Map.put(pred_acc, neighbor, current)}
          else
            {dist_acc, pred_acc}
          end
      end
    end)
  end

  defp build_path(predecessors, target) do
    build_path_recursive(predecessors, target, [target])
  end

  defp build_path_recursive(predecessors, current, path) do
    case Map.get(predecessors, current) do
      nil -> path
      predecessor -> build_path_recursive(predecessors, predecessor, [predecessor | path])
    end
  end

  defp find_all_paths(_graph, current, finish, path, _visited, weight) when current == finish do
    [{Enum.reverse(path), weight}]
  end

  defp find_all_paths(%__MODULE__{edges: edges}, current, finish, path, visited, weight) do
    neighbors = Map.get(edges, current, %{})

    neighbors
    |> Enum.flat_map(fn {neighbor, edge_weight} ->
      if not MapSet.member?(visited, neighbor) do
        find_all_paths(
          %__MODULE__{edges: edges},
          neighbor,
          finish,
          [neighbor | path],
          MapSet.put(visited, neighbor),
          weight + edge_weight
        )
      else
        []
      end
    end)
  end
end
