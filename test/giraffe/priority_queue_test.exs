defmodule Giraffe.PriorityQueueTest do
  use ExUnit.Case, async: true
  doctest Giraffe.PriorityQueue

  alias Giraffe.PriorityQueue, as: PriorityQueue

  describe "new/0" do
    test "creates an empty priority queue" do
      queue = PriorityQueue.new()
      assert queue.items == []
    end
  end

  describe "enqueue/3" do
    test "adds items in priority order" do
      queue =
        PriorityQueue.new()
        |> PriorityQueue.enqueue(3, "low")
        |> PriorityQueue.enqueue(1, "high")
        |> PriorityQueue.enqueue(2, "medium")

      assert queue.items == [{1, "high"}, {2, "medium"}, {3, "low"}]
    end

    test "handles items with same priority" do
      queue =
        PriorityQueue.new()
        |> PriorityQueue.enqueue(1, "first")
        |> PriorityQueue.enqueue(1, "second")

      assert length(queue.items) == 2
    end
  end

  describe "dequeue/1" do
    test "removes and returns highest priority item" do
      queue =
        PriorityQueue.new()
        |> PriorityQueue.enqueue(3, "low")
        |> PriorityQueue.enqueue(1, "high")
        |> PriorityQueue.enqueue(2, "medium")

      {item, new_queue} = PriorityQueue.dequeue(queue)
      assert item == "high"
      {item2, _} = PriorityQueue.dequeue(new_queue)
      assert item2 == "medium"
    end

    test "returns :empty for empty queue" do
      assert PriorityQueue.dequeue(PriorityQueue.new()) == :empty
    end
  end

  describe "size/1" do
    test "returns correct size" do
      queue = PriorityQueue.new()
      assert PriorityQueue.size(queue) == 0

      queue =
        queue
        |> PriorityQueue.enqueue(1, "a")
        |> PriorityQueue.enqueue(2, "b")

      assert PriorityQueue.size(queue) == 2
    end
  end

  describe "empty?/1" do
    test "returns true for empty queue" do
      assert PriorityQueue.empty?(PriorityQueue.new())
    end

    test "returns false for non-empty queue" do
      queue =
        PriorityQueue.new()
        |> PriorityQueue.enqueue(1, "item")

      refute PriorityQueue.empty?(queue)
    end
  end

  test "inspect" do
    queue =
      Enum.reduce(0..4, PriorityQueue.new(), fn i, acc ->
        acc |> PriorityQueue.enqueue(i, ?a + i)
      end)

    str = "#{inspect(queue)}"
    assert "#PriorityQueue<size: 5, queue: ~c\"abcde\">" = str
  end

  test "can enqueue random elements and pull them out in priority order" do
    queue =
      Enum.reduce(Enum.shuffle(0..9), PriorityQueue.new(), fn i, acc ->
        acc
        |> PriorityQueue.enqueue(i, ?a + i)
        |> PriorityQueue.enqueue(i, ?a + i)
      end)

    result =
      Enum.reduce(1..21, {queue, []}, fn _, {q, acc} ->
        case PriorityQueue.dequeue(q) do
          :empty ->
            Enum.reverse(acc)

          {char, q1} ->
            {q1, [char | acc]}
        end
      end)

    assert [?a, ?a, ?b, ?b, ?c, ?c, ?d, ?d, ?e, ?e, ?f, ?f, ?g, ?g, ?h, ?h, ?i, ?i, ?j, ?j] =
             result
  end

  describe "peek/1" do
    test "returns highest priority item without removing it" do
      queue =
        PriorityQueue.new()
        |> PriorityQueue.enqueue(3, "low")
        |> PriorityQueue.enqueue(1, "high")
        |> PriorityQueue.enqueue(2, "medium")

      assert PriorityQueue.peek(queue) == {:ok, "high"}
      # Size remains unchanged
      assert PriorityQueue.size(queue) == 3
    end

    test "returns :empty for empty queue" do
      assert PriorityQueue.peek(PriorityQueue.new()) == :empty
    end

    test "peek followed by dequeue returns same item" do
      queue =
        PriorityQueue.new()
        |> PriorityQueue.enqueue(1, "high")

      assert PriorityQueue.peek(queue) == {:ok, "high"}
      {dequeued_item, _} = PriorityQueue.dequeue(queue)
      assert dequeued_item == "high"
    end
  end
end
