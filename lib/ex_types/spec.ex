defmodule ExTypes.Spec do
  @moduledoc """
  Functions for converting erl_types to things useful in spec declarations.
  """

  @doc """
  Convert erl_types to Elixir quotes
  """
  @spec t_to_quote(:erl_types.erl_type()) :: Macro.t()
  def t_to_quote(t)
  # represent atoms as functions: :any => any()
  def t_to_quote(:any), do: {:any, [], []}
  def t_to_quote(t) when is_atom(t), do: t
  # integers are integers
  def t_to_quote(t) when is_number(t), do: t

  # an atom is an atom is an atom
  def t_to_quote({:c, :atom, atom, _qualifier}) when is_atom(atom), do: {atom, [], []}
  def t_to_quote({:c, :atom, [atom], _qualifier}), do: atom

  def t_to_quote({:c, :atom, atom_list, _qualifier}) when is_list(atom_list),
    do: quote_union(atom_list)

  def t_to_quote({:c, :number, {:int_rng, 0, 1_114_111}, :integer}), do: {:char, [], []}

  # binaries become `binary()`
  def t_to_quote({:c, :binary, _elements, _qualifier}), do: {:binary, [], []}

  def t_to_quote({:c, :tuple, elements, _qualifier}), do: {:{}, [], quote_elements(elements)}

  # not a real type but whatever
  def t_to_quote({:c, :tuple_set, [{_arity, elements}], _qualifier}), do: quote_elements(elements)

  # we can be pretty accurate here and look for improper lists
  # (those that don't end in the nil list element)
  def t_to_quote({:c, :list, elements, _qualifier}) do
    case Enum.reverse(elements) do
      [] -> []
      [{:c, nil, [], _qual} | tail] -> quote_elements(tail)
      elements -> {:maybe_improper_list, [], quote_elements(elements)}
    end
  end

  # empty cons cell
  def t_to_quote({:c, nil, [], _qualifier}), do: []

  def t_to_quote({:c, :map, {_pairs, _def_key, _def_val}, _qualifier}), do: {:map, [], []}

  def t_to_quote({:c, :union, elements, _qualifier}), do: quote_union(elements)

  def t_to_quote({:c, :opaque, [opaque], _qualifier}), do: t_to_quote(opaque)

  def t_to_quote({:opaque, module, func, _, _expansion}), do: {{:., [], [module, func]}, [], []}

  defp quote_elements(elements) do
    elements
    |> Enum.reject(&is_none?/1)
    |> Enum.map(&t_to_quote/1)
  end

  defp quote_union(elements) when is_list(elements) do
    elements
    |> Enum.reject(&is_none?/1)
    |> _quote_union()
  end

  defp _quote_union([_a, _b] = elements), do: {:|, [], Enum.map(elements, &t_to_quote/1)}
  defp _quote_union([head | tail]), do: {:|, [], [t_to_quote(head), _quote_union(tail)]}

  defp is_none?(:none), do: true
  defp is_none?(_), do: false

  def spec(fun, t_domain, t_range) do
    {:@, [context: Elixir, import: Kernel],
     [
       {:spec, [context: Elixir],
        [
          {:::, [],
           [
             {fun, [], Enum.map(t_domain, &t_to_quote/1)},
             t_to_quote(t_range)
           ]}
        ]}
     ]}
  end

  @default_line_length 80

  def iolist(fun, t_domain, t_range, line_length \\ @default_line_length) do
    fun
    |> spec(t_domain, t_range)
    |> Macro.to_string()
    |> Code.format_string!(line_length: line_length)
  end

  def string(fun, t_domain, t_range, line_length \\ @default_line_length) do
    fun
    |> iolist(t_domain, t_range, line_length)
    |> List.flatten()
    |> Enum.join("")
  end
end
