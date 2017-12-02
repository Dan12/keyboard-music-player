(* code adapted from: https://github.com/savonet/ocaml-mm *)

(** Internal data for computing FFT. *)
type t

(** Initialize FFT for an analysis of [2^n] samples. *)
val init : int -> t

(** Duration of the FFT buffer analysis in samples. *)
val duration : t -> int

(** [complex_create buf ofs len] create a array of complex numbers of size
[len] by copying data from [buf] from ofset [ofs] (the imaginary part
is null). *)
val complex_create : (int32, Bigarray.int32_elt, Bigarray.c_layout) Bigarray.Array1.t -> (Complex.t array * Complex.t array)

(** Perform an FFT analysis. *)
val fft : t -> Complex.t array -> unit

val cosine : Complex.t array -> unit