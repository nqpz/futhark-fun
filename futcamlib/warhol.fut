include futcamlib.misc
include futcamlib.base
default (f32)

fun intensity (p: pixel): int =
  let (r, g, b) = get_rgb(p)
  in (int r * 2 + int g * 3 + int b) / 6

fun min (x: int) (y: int): int = if x < y then x else y

fun selectColour (colours: [n]pixel) (x: int): pixel =
  let range = 256 / n
  in unsafe colours[min (x/range) (n-1)]

entry warhol(frame : [h][w]pixel) : [h][w]pixel =
  let frame' = quad frame
  let (urows,lrows) = split (h/2) frame'
  let (ul,ur) = split@1 (w/2) urows
  let (ll,lr) = split@1 (w/2) lrows
  let colours_ul = [RGB.blue, RGB.magenta, RGB.orange, RGB.yellow]
  let colours_ur = [RGB.cyan, RGB.pink, RGB.red, RGB.purple, RGB.black]
  let colours_ll = [RGB.orange, RGB.purple, RGB.cyan, RGB.blue]
  let colours_lr = [RGB.magenta, RGB.green, RGB.white, RGB.yellow]
  let ul' = warholColourise colours_ul ul
  let ur' = warholColourise colours_ur ur
  let ll' = warholColourise colours_ll ll
  let lr' = warholColourise colours_lr lr
  let lrows' = concat@1 ll' lr'
  let urows' = concat@1 ul' ur'
  in concat urows' lrows'

fun warholColourise(colours: [n]pixel) (frame: [h][w]pixel): [h][w]pixel =
  map (\row : [w]pixel -> map (selectColour colours) (map intensity row))
      frame
