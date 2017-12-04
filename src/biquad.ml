let pi = 3.14159265358979323846

class biquad_filter samplerate (kind:[`Low_pass | `High_pass | `Band_pass | `Notch | `All_pass | `Peaking | `Low_shelf | `High_shelf]) ?(gain=0.) freq q =
  let samplerate = float samplerate in
  object (self)
  val mutable p0 = 0.
  val mutable p1 = 0.
  val mutable p2 = 0.
  val mutable q1 = 0.
  val mutable q2 = 0.

  method private init =
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
    p0 <- b0 /. a0;
    p1 <- b1 /. a0;
    p2 <- b2 /. a0;
    q1 <- a1 /. a0;
    q2 <- a2 /. a0

  initializer
  self#init

  val mutable x1 = 0.
  val mutable x2 = 0.
  val mutable y0 = 0.
  val mutable y1 = 0.
  val mutable y2 = 0.

  method process buf ofs len =
    for i = ofs to ofs + len - 1 do
      let x0 = buf.(i) in
      let y0 = p0 *. x0 +. p1 *. x1 +. p2 *. x2 -. q1 *. y1 -. q2 *. y2 in
      buf.(i) <- y0;
      x2 <- x1;
      x1 <- x0;
      y2 <- y1;
      y1 <- y0
    done
end