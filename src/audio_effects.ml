let pi = 3.14159265358979323846

type t =
  {
    b : int; (* number of bits *)
    n : int; (* number of samples *)
    circle : Complex.t array;
    temp : Complex.t array;
  }

let init b =
  let n = 1 lsl b in
  let h = n / 2 in
  let fh = float h in
  let circle = Array.make h Complex.zero in
  for i = 0 to h - 1 do
    let theta = pi *. float_of_int i /. fh in
    circle.(i) <- {Complex.re = cos theta; Complex.im = sin theta}
  done;
  {
    b = b;
    n = n;
    circle = circle;
    temp = Array.make n Complex.zero;
  }

let duration f = f.n

let complex_create (buf:(int32, Bigarray.int32_elt, Bigarray.c_layout) Bigarray.Array1.t) =
  let len = Bigarray.Array1.dim buf/2 in
  let max = float_of_int (1 lsl 31) in
  let left = 
    Array.init len (fun i -> {Complex.re = Int32.to_float (buf.{i*2}) /. max; Complex.im = 0.})
  in
  let right = 
    Array.init len (fun i -> {Complex.re = Int32.to_float (buf.{i*2+1}) /. max; Complex.im = 0.})
  in
  (left, right)

let fft f d =
  (* TODO: greater should be ok too? *)
  assert (Array.length d = f.n);
  let ( +~ ) = Complex.add in
  let ( -~ ) = Complex.sub in
  let ( *~ ) = Complex.mul in
  let rec fft
    t (* temporary buffer *)
    d (* data *)
    s (* stride in the data array *)
    n (* number of samples *)
    =
    if (n > 1) then
      let h = n / 2 in
      for i = 0 to h - 1 do
        t.(s + i) <- d.(s + 2 * i);          (* even *)
        t.(s + h + i) <- d.(s + 2 * i + 1)   (* odd  *)
      done;
      fft d t s h;
      fft d t (s + h) h;
      let a = f.n / n in
      for i = 0 to h - 1 do
        let wkt = f.circle.(i * a) *~ t.(s + h + i) in
        d.(s + i) <- t.(s + i) +~ wkt ;
        d.(s + h + i) <- t.(s + i) -~ wkt
      done
  in
  fft f.temp d 0 f.n

let ccoef k c =
  {Complex.re = k *. c.Complex.re; Complex.im = k *. c.Complex.im}

let iter f d =
  let len = Array.length d in
  let n = float len in
  for i = 0 to len - 1 do
    let k = f (float i) n in
    d.(i) <- ccoef k d.(i)
  done

let cosine d = iter (fun i n -> sin (pi *. i /. n)) d