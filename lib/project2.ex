defmodule Project2 do
  use GenServer
  def start_link do
    GenServer.start_link(__MODULE__,:ok,name: :Server)
  end
  def init(:ok) do
    {:ok,%{}}
  end

  def main(args\\[]) do
    if List.to_tuple(args)|>tuple_size<2 do
      Process.stop()
    end
    number_of_node=elem(List.to_tuple(args),0)
    Project2.Exdistutils.start_distributed(:project2)
    start_link() #this is where the server genserver starts
    IO.puts "... build topology"
    temp=:os.system_time(:millisecond)
    Enum.map(1..String.to_integer(number_of_node),fn(x)->spawn(fn->Project2.Client.start_link(Integer.to_string(x)|>String.to_atom) end)end)
    case elem(List.to_tuple(args),1)|>String.to_atom do
      :full->Enum.map(1..String.to_integer(number_of_node),fn(x)->GenServer.cast({Integer.to_string(x)|>String.to_atom,Node.self()},{:complete,number_of_node,x})end)
      :line->Enum.map(2..String.to_integer(number_of_node),fn(x)->GenServer.cast({Integer.to_string(x)|>String.to_atom,Node.self()},{:line,x-1,x})end)
             #this is for backward adding of the nodes
             Enum.map(1..(String.to_integer(number_of_node)-1),fn(x)->GenServer.cast({Integer.to_string(x)|>String.to_atom,Node.self()},{:line,x+1,x})end)
             #this is for forward adding of the terminal in the state of the GenServer
      end
    IO.puts(:os.system_time(:millisecond)-temp)
    #loop()
  end

  def spawnner(number_of_node,temp\\0) do
    IO.puts(temp)
    case String.to_integer(number_of_node)>temp do
      true->Process.spawn((fn->Project2.Client.start_link(Integer.to_string(temp)|>String.to_atom) end),[])
            spawnner(number_of_node,temp+1)
             {:ok}
      false->{:ok}
  end
  end

  def loop do
    loop
  end
end
