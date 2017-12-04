type filter_t

val make : int -> 
           [ `Band_pass | `High_pass | `Low_pass | `Notch | `All_pass | `Peaking | `Low_shelf | `High_shelf ] ->
           ?gain:float -> 
           float -> 
           float -> filter_t
        
val process : filter_t -> float -> float