# ExTypes

An Elixir interpretation of Erlang's
[`erl_types`](https://github.com/erlang/otp/blob/d6285b0a347b9489ce939511ee9a979acd868f71/lib/hipe/cerl/erl_types.erl).

ExTypes is useful for translating erl_types, as found in dialyzer PLT files,
to quote form or string form.

## Installation

```elixir
def deps do
  [
    {:ex_types, git: "git@github.com:the-mikedavis/ex_types.git"}
  ]
end
```
