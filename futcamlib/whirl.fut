include futcamlib.base
default (f32)

fun toSq   (w: int) (x: int): f32 = 2.0*f32 x/f32 w - 1.0
fun fromSq (w: int) (x: f32): int = int ((x+1.0)*f32 w/2.0)
fun sqIndex (frame: [h][w]pixel) ((x,y): (f32,f32)): pixel =
  let x' = fromSq h x
  let y' = fromSq w y
  in if x' >= 0 && x' < h && y' >= 0 && y' < w
     then unsafe frame[x', y']
     else set_rgb(0u32,0u32,0u32)

entry whirl(frame : [h][w]pixel, distortion : f32) : [h][w]pixel =
  map (\x: [w]pixel ->
         map (\y : pixel ->
                let r = sqrt32 (x*x + y*y)
                let a = distortion-r
                let c = cos32 a
                let s = sin32 a
                let x' = x*c-y*s
                let y' = x*s+y*c
                in sqIndex frame (x',y'))
             (map (toSq w) (iota w)))
      (map (toSq h) (iota h))
