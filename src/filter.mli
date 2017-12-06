(* The filter type *)
type filter_t

(* The different kinds of filters *)
type filter_kind = FKNone | FKBand_pass | FKHigh_pass | FKLow_pass | FKNotch | FKAll_pass | FKPeaking | FKLow_shelf | FKHigh_shelf

(* [make sample_rate type gain freqency q] create a new audio filter
 * using the given parameters
 *)
val make : int -> filter_kind -> ?gain:float -> float -> float -> filter_t

(* process the next sample with the audio filter *)
val process : filter_t -> float -> float
