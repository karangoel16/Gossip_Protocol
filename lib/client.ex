defmodule Project2.Client do
    use GenServer

    def start_link(args) do
        GenServer.start_link(__MODULE__,:ok,name: args)
        #Project2.Exdistutils.start_distributed(Integer.to_string(args)|>String.to_atom)
        #IO.inspect Node.self()
        #IO.inspect  :"project2@10.228.7.203"
        loop()
    end

    def init(:ok) do
        {:ok,{}}
    end

    def handle_call({check , msg , name},_from,state) do
      case check do
          :msg->var=:rand.uniform(tuple_size(state))
                GenServer.call({Integer.to_string(var)|>String.to_atom,Node.self()},{:msg,msg},:infinite)
                {:reply,msg,state}
          :complete->
                state=Enum.to_list(1..String.to_integer(msg))|>List.to_tuple
                state=Tuple.delete_at(state,name-1)#delete yourself from list
                {:reply,msg,state }
          :line->#we need to add previous and the new state here
                state=Tuple.append(state,msg)
                {:reply,msg,state}
          :link->#we made this to check our network
                {:reply,state,state}
      end
    end


    def loop do
        Process.sleep(1_000_000)
        loop()
    end
end
