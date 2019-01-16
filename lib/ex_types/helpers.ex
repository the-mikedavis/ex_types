defmodule ExTypes.Helpers do
  defmacro deftype(type) do
    quote do
      defmodule ExTypes.unquote(type) do
        defstruct [:elements, :qualifier]
      end
    end
  end
end
