defmodule Portal.Macros.Tokenizer do
  defmacro __using__(_) do
    calling_module = __CALLER__.module
    Module.register_attribute(calling_module, :rules, persist: true)

    quote do
      alias Portal.Token

      def tokenize(input) do
        attrs = unquote(calling_module).__info__(:attributes)
        do_tokenize(input, attrs[:rules], [])
      end

      def do_tokenize("", _rules, tokens), do: tokens

      def do_tokenize(input, rules, tokens) do
        rule = get_rule(rules, input)

        cond do
          no_rule?(rule) ->
            raise "Invalid input (tokenizer)\n\n input: #{input}"

          ignore?(rule) ->
            do_tokenize(rest(rule, input), rules, tokens)

          value?(rule) ->
            do_tokenize(
              rest(rule, input),
              rules,
              tokens ++ [%Token{id: rule[:id], value: get_value(rule, input)}]
            )

          true ->
            do_tokenize(
              rest(rule, input),
              rules,
              tokens ++ [%Token{id: rule[:id]}]
            )
        end
      end

      # === utils

      def get_rule(rules, input) do
        Enum.reduce_while(rules, %{}, fn r, acc ->
          if Regex.match?(r[:regex], input) do
            {:halt, r}
          else
            {:cont, acc}
          end
        end)
      end

      def no_rule?(rule) when rule == %{}, do: true

      def no_rule?(_rule), do: false

      def ignore?(%{ignore?: true}), do: true

      def ignore?(_rule), do: false

      def value?(%{value?: true}), do: true

      def value?(_rule), do: false

      def rest(%{regex: regex}, input) do
        regex
        |> Regex.split(input)
        |> Enum.at(1)
      end

      def get_value(%{regex: regex}, input) do
        regex
        |> Regex.run(input)
        |> Enum.at(0)
      end
    end
  end
end
