# Productive

An assembly line like pipeline that supports binary or greater logic branching using pattern 
matching in a way that is easy to reason about and extend.  Think [plug](https://github.com/elixir-lang/plug) 
with the ability to build any _product_ instead of a _connection_.


## Why?

We are very fortunate as Elixir developers as we are already provided the `case` special form, the
`|>` operator and now the `with` special form. Using these tools one can already express a procedure 
as a pipeline.  However, when a pipeline becomes more complex due to quantity of steps of branching
bewteen the steps, these low level language contructs begin to break down.

Let's consider the use case of reading a BEAM file's `:abstract_code` chunks.

  1. Use case initially implemented with `case`

      ```elixir
      case File.read(path) do
        {:ok, binary} ->
          case :beam_lib.chunks(binary, :abstract_code) do
            {:ok, data} ->
              {:ok, wrap(data)}
            error ->
              error
          end
        error ->
          error
      end
      ```

  1. Use case reafactored to use `|>` and functions

      ```elixir
      path
      |> File.read()
      |> read_chunks()
      |> wrap()

      defp read_chunks({:ok, binary}) do
        {:ok, :beam_lib.chunks(binary, :abstract_code)
      end
      defp read_chunks(error), do: error

      defp wrap({:ok, data}) do
        {:ok, wrap(data)}
      end
      defp wrap(error), do: error
      ```

  1. Use case reafactored to use `with`

      ```elixir
      with {:ok, binary} <- File.read(path),
           {:ok, data} <- :beam_lib.chunks(binary, :abstract_code),
           do: {:ok, wrap(data)}
      ```

While `case`, `|>` and `with` are very useful, they each have limitations. 

  1. `case` tends to hide the high level steps in the pipeline due to branching and nesting.  Additionally, it can become very 
     ugly fast when there are many steps and/or many branching conditions.  Notice in the `case` implementation above, with
     only two steps it is already a little hard to quickly pick out the steps.

  1. `with` is useful only when each step in the flow has a binary branch, ie. `{:ok, something}` or `{:error, error}`.

  1. `|>` can also become very ugly fast when there are many steps and/or many branching conditions.  While it is not as hard 
     to reason about as the `case` implementation, it can still become unruly.  Additionally, it can be hard to develop a 
     pattern for dealing with reusing steps in other pipelines.

### Terminology

Before we implement this use case as a _productive_ pipeline, let's clarify some terminology.

  1. A **product** is the data structure that accumulates a pipelines state.  A product is passed into and returned from every 
     step in a pipeline. As the name infers, a product is the ultimate thing we are building in the pipeline. The product of
     a [plug](https://github.com/elixir-lang/plug) is the connection. While not a requirement, it is recommended to implement 
     the product as a struct.

  1. A **pipeline** is the enumerated steps necessary to complete a task.

  1. A **step** is a single unit of work. The step defines one or functions to determine the state of the product 
     and is how branching is accomplished.  A step also defines one or more functions to perform work based on the determined
     state of the product.  Both the state determination and work performing are multi-clause functions employing pattern matching
     to select the correct clause.  While a step can do as much work as one desires, it is recommended for a step to do a single thing
     well, as it will more easily compose with other steps and promote code resuse.


### A Simple Example

Using the same use case from above let's implement this pipeline using _productive_.

  1. Define a product

      ```elixir
      defmodule AbstractCodeChunks do
        defstruct code_chunks: nil,
                  errors: [],
                  file_contents: nil,
                  filepath: nil,
                  halted: false

        def init, do: %AbstractCodeChunks{}

        def init(args) is_list(args) do
          %AbstractCodeChunks{
            filepath: Keyword.get(args, :filepath)
          }
        end
      end
      ```

  1. Define a pipeline

      ```elixir
      defmodule ReadBeamFileAbstractCodeChunks do
        use Productive.Pipeline

        # notice how wasy it is to reason about the high level steps and 
        # order of steps  to complete a product
        step ReadFile
        step ExtractAbstractCodeChunks
        step WrapChunks
      end
      ```

  1. Define the steps

      ```elixir
      defmodule ReadFile do
        use Productive.Step

        @read   "read"
        @unread "unread"

        # Block invalid start state
        def prepare(%{filepath: nil}, _opts), do: raise "filepath cannot be nil"

        # Valid start states
        def prepare(%{file_contents: nil, filepath: _}, _opts), do: @unread
        def prepare(_product, _opts), do: @read

        def work(@read, product, _opts), do: product

        def work(@unread, %{filepath: filepath} = product, _opts) do
          %{product | file_contents: File.read(filepath)}
        end
      end

      defmodule ExtractAbstractCodeChunks do
        use Productive.Step

        @read "read"

        # Block invalid start state
        def prepare(%{file_contents: nil}, _opts), do: raise "file_contents cannot be nil"

        # Valid start states
        def prepare(_product, _opts), do: @read

        def work(@read, product, _opts) do
          :beam_lib.chunks(binary, :abstract_code)
          |> process_chunks( product )
        end

        defp process_chunks({:ok, data}, product), do: %{product | code_chunks: {:ok, data}}

        defp process_chunks(error, product) do
          product
          |> add_errors_and_halt!( error )
        end
      end

      defmodule WrapChunks do
        use Productive.Step

        @chunks_extracted "chunks_extracted"

        # Block invalid start state
        def prepare(%{code_chunks: nil}, _opts), do: raise "code_chunks cannot be nil"

        # Valid start states
        def prepare(%{code_chunks: _}, _opts), do: @chunks_extracted

        def work(@chunks_extracted, %{code_chunks: code_chunks} = product, _opts) do
          %{product | code_chunks: wrap(code_chunks)}
        end

        defp wrap(data) do
          # does something ...
        end
      end
      ```
  1. Use the pipeline

    ```elixir
    product = AbstractCodeChunks.init(filepath: "/some/file/path")

    case ReadBeamFileAbstractCodeChunks.call(product) do
      {:ok, product} ->
        # Do something with the finialized product
      {:error, errors} ->
        raise Enum.join(errors, " ; ")
    end

    # or expressed with pipelines and functions ##########

    AbstractCodeChunks.init(filepath: "/some/file/path")
    |> ReadBeamFileAbstractCodeChunks.call
    |> process_results
    
    defp process_results({:ok, product}) do
      # Do something with the finialized product
    end
    
    defp process_results({:error, errors})
      raise Enum.join(errors, " ; ")
    end
    ```

It should be obvious that implementing a pipeline as simple as this using _productive_ is overkill. I 
would favor the implementation using `with` for this use case.  However, this use case did provide a 
simple example to show a 1-to-1 comparison.

However, you can see that each step of the pipeline is portable. The only API requirements are in the
data structure of the product (more specifically only the part of the product the step operates on). Thus, 
code resuse becomes easy and encouraged. 

Additionally, all knowledge of state calculation and work performance is captured in a single module which 
makes reasoning about the step and the greater pipeline much easier. While examining the implementation of
a step, all implementation of other steps in the pipeline are located in a different module and not obscuring 
this step's logic. Everything the step needs to know is carried with the product. Also, the step does not care what 
step occurred before or after it. The step only needs to be able to handle the current calculated state of the
product.

Debugging the pipeline becomes easier as the state is easily examinable by interrogating the product. Not having
state spread out in random places makes reasoning about the pipeline much easier.

Finally, each step of the pipeline is now easily unit testable.

While this use case only has binary branching between steps, a _productive_ pipeline can have infinite 
branching between steps.

### A More Complex Example

Next, let's look at a more complex use case so we can see the real power of _productive_.

TODO

Our use case is TODO

Implemented as a `case` statment we can see the deficiencies of this factoring of the code.

TODO

Refactored using `|>` and functions you can see the deficiencies of this factoring of the code.

TODO

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add productive to your list of dependencies in `mix.exs`:

        def deps do
          [{:productive, "~> 0.2.0"}]
        end

  2. Ensure productive is started before your application:

        def application do
          [applications: [:productive]]
        end
