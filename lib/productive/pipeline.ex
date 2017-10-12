defmodule Productive.Pipeline do

  defmacro __using__( opts ) do
    quote do

      @logger unquote(opts[:logger])

      def call( product, opts \\ [] ) do
        product =
          Enum.reduce_while( steps(), product, fn({step, step_opts}, product) ->
            opts = Keyword.merge( opts, step_opts )
            product = apply( step, :call, [product, opts] )
            if product.halted do
              {:halt, product}
            else
              {:cont, product}
            end
          end)

        if halted?( product, opts ) do
          product
          |> process_halted( opts )
        else
          product
          |> process_result( opts )
        end
      end

      defp halted?( product, opts \\ [] ), do: product.halted

      defp process_halted( %{halted_status: halted_status, errors: []} = product, _opts ) do
        {halted_status, product}
      end

      defp process_halted( product, opts ), do: {:error, product.errors}

      defp process_result( product, opts ), do: {:ok, product}

      defp info( msg ), do: apply( @logger, :info, [msg] )

      defp log_use_case( module, state \\ %{} ) do
        pipeline_name = Module.split( __MODULE__ )
                        |> Enum.slice( 1, 100 )
                        |> Enum.join(".")

        info "Responding as use case: #{pipeline_name}"
      end

      defoverridable [
        process_halted: 2,
        process_result: 2
      ]

      import Productive.Pipeline

      Module.register_attribute(__MODULE__, :steps, accumulate: true)
      @before_compile Productive.Pipeline

    end
  end

  defmacro __before_compile__(env) do
    steps = Module.get_attribute(env.module, :steps)

    if steps == [] do
      raise "no steps have been defined in #{inspect env.module}"
    end

    quote do
      def steps do
        unquote(Enum.reverse(steps))
      end
    end
  end

  defmacro step(step, opts \\ []) do
    quote do
      @steps unquote({step, opts})
    end
  end

end
