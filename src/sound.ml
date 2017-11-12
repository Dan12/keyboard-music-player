type sound = {
  pitches: (int, Bigarray.int16_signed_elt) Tsdl.Sdl.bigarray list;
  looping: bool;
  hold_to_play: bool;
  groups: int list;
  quantization: int;
  mutable playing: bool;
  mutable current_pitch: int;
  mutable buffer_index: int;
}