(* code adapted from: https://github.com/savonet/ocaml-mm *)

let pi = 3.14159265358979323846

type filter_t = {
  p0 : float;
  p1 : float;
  p2 : float;
  q1 : float;
  q2 : float;

  mutable x1 : float;
  mutable x2 : float;
  mutable y0 : float;
  mutable y1 : float;
  mutable y2 : float;
}

let make sr kind ?(gain=0.) freq q =
  let samplerate = float_of_int sr in
  let w0 = 2. *. pi *. freq /. samplerate in
  let cos_w0 = cos w0 in
  let sin_w0 = sin w0 in
  let alpha = sin w0 /. (2. *. q) in
  let a = if gain = 0. then 1. else 10. ** (gain /. 40.) in
  let b0,b1,b2,a0,a1,a2 =
  match kind with
    | `Low_pass ->
      let b1 = 1. -. cos_w0 in
      let b0 = b1 /. 2. in
      b0,b1,b0,(1. +. alpha),(-.2. *. cos_w0),(1. -. alpha)
    | `High_pass ->
      let b1 = 1. +. cos_w0 in
      let b0 = b1 /. 2. in
      let b1 = -. b1 in
      b0,b1,b0,(1. +. alpha),(-.2. *. cos_w0),(1. -. alpha)
    | `Band_pass ->
      let b0 = sin_w0 /. 2. in
      b0,0.,-.b0,(1. +. alpha),(-.2. *. cos_w0),(1. -. alpha)
    | `Notch ->
      let b1 = -2. *. cos_w0 in
      1.,b1,1.,(1.+.alpha),b1,(1.-.alpha)
    | `All_pass ->
      let b0 = 1. -. alpha in
      let b1 = -.2. *. cos_w0 in
      let b2 = 1. +. alpha in
      b0,b1,b2,b2,b1,b0
    | `Peaking ->
      let ama = alpha *. a in
      let ada = alpha /. a in
      let b1 = -.2. *. cos_w0 in
      1.+.ama,b1,1.-.ama,1.+.ada,b1,1.-.ada
    | `Low_shelf ->
      let s = 2. *. (sqrt a) *. alpha in
      (a *. ((a +. 1.) -. (a -. 1.) *. cos_w0 +. s)),
      2. *. a *. ((a -. 1.) -. (a +. 1.) *. cos_w0),
      a *. ((a +. 1.) -. (a -. 1.) *. cos_w0 -. s),
      (a +. 1.) +. (a -. 1.) *. cos_w0 +. s,
      -.2. *. (a -. 1.) +. (a +. 1.) *. cos_w0,
      (a +. 1.) +. (a -. 1.) *. cos_w0 -. s
    | `High_shelf ->
      let s = 2. *. (sqrt a) *. alpha in
      a *. ((a +. 1.) +. (a -. 1.) *. cos_w0 +. s),
      -.2. *. a *. ((a -. 1.) +. (a +. 1.) *. cos_w0),
      a *. ((a +. 1.) +. (a -. 1.) *. cos_w0 -. s),
      (a +. 1.) -. (a -. 1.) *. cos_w0 +. s,
      2. *. (a -. 1.) -. (a +. 1.) *. cos_w0,
      (a +. 1.) -. (a -. 1.) *. cos_w0 -. s
  in
  {
    p0 = b0 /. a0;
    p1 = b1 /. a0;
    p2 = b2 /. a0;
    q1 = a1 /. a0;
    q2 = a2 /. a0;

    x1 = 0.;
    x2 = 0.;
    y0 = 0.;
    y1 = 0.;
    y2 = 0.;
  }

let process filter sample =
  let x0 = sample in
  let y0 = filter.p0 *. x0 +. filter.p1 *. filter.x1 +. filter.p2 *. filter.x2 -. filter.q1 *. filter.y1 -. filter.q2 *. filter.y2 in
  filter.x2 <- filter.x1;
  filter.x1 <- x0;
  filter.y2 <- filter.y1;
  filter.y1 <- y0;
  y0