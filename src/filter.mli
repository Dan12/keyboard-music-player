type t

val make : int -> 
           [ `Band_pass | `High_pass | `Low_pass | `Notch | `All_pass | `Peaking | `Low_shelf | `High_shelf ] ->
           ?gain:float -> 
           float -> 
           float -> t
        
val process : t -> float*float -> float*float