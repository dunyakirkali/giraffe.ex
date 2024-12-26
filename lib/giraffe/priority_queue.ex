defmodule Giraffe.PriorityQueue do
  @moduledoc """
  A Priority Queue implementation using a list-based heap structure.
  Lower priority values are dequeued first.
  """

  alias Giraffe.PriorityQueue, as: PriorityQueue

  defstruct items: []

  @type t :: %__MODULE__{
          items: list({number(), any()})
        }

  @doc """
  Creates a new empty priority queue
  """
  def new, do: %PriorityQueue{}

  @doc """
  Enqueues an item with a given priority
  """
  def enqueue(%PriorityQueue{items: items}, priority, value) do
    %PriorityQueue{items: insert({priority, value}, items)}
  end

  @doc """
  Dequeues the item with the lowest priority
  Returns {item, new_queue} or :empty if queue is empty
  """
  def dequeue(%PriorityQueue{items: []}), do: :empty

  def dequeue(%PriorityQueue{items: [{_priority, value} | rest]}) do
    {value, %PriorityQueue{items: rest}}
  end

  @doc """
  Returns the size of the queue
  """
  def size(%PriorityQueue{items: items}), do: length(items)

  @doc """
  Checks if the queue is empty
  """
  def empty?(%PriorityQueue{items: []}), do: true
  def empty?(%PriorityQueue{items: _}), do: false

  # Private helper functions
  defp insert(item, []), do: [item]

  defp insert({priority, _} = item, [{head_priority, _} | _] = items)
       when priority < head_priority do
    [item | items]
  end

  defp insert(item, [head | tail]) do
    [head | insert(item, tail)]
  end
end
