(* The filter type *)
type filter_t

(* [make sample_rate type gain freqency q] create a new audio filter
 * using the given parameters
 *)
val make : int -> 
           [ `Band_pass | `High_pass | `Low_pass | `Notch | `All_pass | `Peaking | `Low_shelf | `High_shelf ] ->
           ?gain:float -> 
           float -> 
           float -> filter_t
        
(* process the next sample with the audio filter *)
val process : filter_t -> float -> float