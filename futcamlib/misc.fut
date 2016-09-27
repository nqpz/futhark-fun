include futcamlib.base
include futcamlib.color
default (f32)

entry quad(frame : [h][w]pixel) : [h][w]pixel =
  let n = 2
  in map (fn y: [w]pixel =>
            map (fn x : pixel => unsafe frame[y%(h/n)*n,x%(w/n)*n])
                (iota w))
         (iota h)

entry invert_rgb(frame : [h][w]pixel) : [h][w]pixel =
  map (fn (row : [w]pixel) : [w]pixel =>
         map (fn (p : pixel) : pixel =>
                let (r, g, b) = get_rgb p
                let r' = 255u32 - r
                let g' = 255u32 - g
                let b' = 255u32 - b
                in set_rgb (r', g', b'))
         row)
  frame

entry balance_white(frame : [h][w]pixel, value_target : f32) : [h][w]pixel =
  let len = h * w
  let pixels = reshape (len) frame
  let value_total =
    reduce (+) 0.0
    (map (fn (p : pixel) : f32 =>
            let (_h, _s, v) = get_hsv p
            in v) pixels)
  let value_current = value_total / f32 len
  let value_diff = value_target - value_current
  let pixels' = map (fn (p : pixel) : pixel =>
                       let (h, s, v) = get_hsv p
                       in set_rgb (hsv_to_rgb (h, s, minf (1.0, v + value_diff)))) pixels
  let frame' = reshape (h, w) pixels'
  in frame'

entry balance_saturation(frame : [h][w]pixel, sat_target : f32) : [h][w]pixel =
  let len = h * w
  let pixels = reshape (len) frame
  let sat_total =
    reduce (+) 0.0
    (map (fn (p : pixel) : f32 =>
            let (_h, s, _v) = get_hsv p
            in s) pixels)
  let sat_current = sat_total / f32 len
  let sat_diff = sat_target - sat_current
  let pixels' = map (fn (p : pixel) : pixel =>
                       let (h, s, v) = get_hsv p
                       in set_rgb (hsv_to_rgb (h, maxf (0.0, minf (1.0, s + sat_diff)), v))) pixels
  let frame' = reshape (h, w) pixels'
  in frame'

entry dim_sides(frame : [h][w]pixel, strength : f32) : [h][w]pixel =
  map (fn (row : [w]pixel, y : i32) : [w]pixel =>
         map (fn (pixel : pixel, x : i32) : pixel =>
                let x_center_closeness = 1.0f32 - f32 (abs (w / 2 - x)) / (f32 (w / 2))
                let y_center_closeness = 1.0f32 - f32 (abs (h / 2 - y)) / (f32 (h / 2))
                let center_closeness = x_center_closeness * y_center_closeness
                let center_closeness' = center_closeness ** strength
                let (r, g, b) = get_rgb(pixel)
                let r' = u32 (f32 r * center_closeness')
                let g' = u32 (f32 g * center_closeness')
                let b' = u32 (f32 b * center_closeness')
                in set_rgb(r', g', b'))
         (zip row (iota w)))
  (zip frame (iota h))

fun closeness_hue(h0 : f32, h1 : f32) : f32 =
  let (h0, h1) = if h1 < h0 then (h1, h0) else (h0, h1)
  let linear = 1.0 - minf (h1 - h0, h0 + 360.0 - h1) / (360.0 / 2.0)
  let force = 3.3
  in linear ** force
  
entry hue_focus(frame : [h][w]pixel, hue_focus : f32) : [h][w]pixel =
  let hue_focus = modf(modf (hue_focus, 360.0) + 360.0, 360.0) in
  map (fn (row : [w]pixel) : [w]pixel =>
         map (fn (p : pixel) : pixel =>
                let (h, _s, _v) = get_hsv p
                let c = closeness_hue (h, hue_focus)
                let h' = hue_focus
                let s' = c
                let v' = c
                let (r, g, b) = hsv_to_rgb(h', s', v')
                in set_rgb (r, g, b))
         row)
  frame

fun closeness_value(v0 : f32, v1 : f32) : f32 =
  absf (v1 - v0)
  
entry value_focus(frame : [h][w]pixel, value_focus : f32) : [h][w]pixel =
  map (fn (row : [w]pixel) : [w]pixel =>
         map (fn (p : pixel) : pixel =>
                let (_h, _s, v) = get_hsv p
                let c = closeness_value (v, value_focus)
                let h' = 0.0
                let s' = 0.0
                let v' = c
                let (r, g, b) = hsv_to_rgb(h', s', v')
                in set_rgb (r, g, b))
         row)
  frame

entry saturation_focus(frame : [h][w]pixel, value_focus : f32) : [h][w]pixel =
  map (fn (row : [w]pixel) : [w]pixel =>
         map (fn (p : pixel) : pixel =>
                let (_h, s, _v) = get_hsv p
                let c = closeness_value (s, value_focus)
                let h' = 0.0
                let s' = 0.0
                let v' = c
                let (r, g, b) = hsv_to_rgb(h', s', v')
                in set_rgb (r, g, b))
         row)
  frame

entry merge_colors(frame : [h][w]pixel, group_size : f32) : [h][w]pixel =
  map (fn (row : [w]pixel) : [w]pixel =>
         map (fn (p : pixel) : pixel =>
                let (h, s, v) = get_hsv p
                let h' = f32 (i32 (h / group_size)) * group_size
                let s' = (f32 (i32 ((s * 360.0) / group_size)) * group_size) / 360.0
                let v' = (f32 (i32 ((v * 360.0) / group_size)) * group_size) / 360.0
                let (r, g, b) = hsv_to_rgb(h', s', v')
                in set_rgb (r, g, b))
         row)
  frame

entry equalise_saturation(frame : [h][w]pixel) : [h][w]pixel =
  map (fn (row : [w]pixel) : [w]pixel =>
         map (fn (p : pixel) : pixel =>
                let (h, _s, v) = get_hsv p
                let h' = h
                let s' = 0.5
                let v' = v
                let (r, g, b) = hsv_to_rgb(h', s', v')
                in set_rgb (r, g, b))
         row)
  frame

fun minu (a : u32) (b : u32) : u32 =
  if a < b then a else b
  
fun nth_smallest(xs : [n]u32, nth : i32) : u32 =
  let smallest = reduce minu xs[0] xs
  loop (smallest) = for _i < nth do
    reduce (small_enough smallest) smallest xs
  in smallest

fun small_enough (threshold : u32) (a : u32) (b : u32) : u32 =
  if a < b
  then if a <= threshold
       then b
       else a
  else if b <= threshold
  then a
  else b

fun median(xs : [n]u32) : u32 = nth_smallest(xs, n / 2)

fun safe(x : i32, m : i32) : i32 =
  if x < 0
  then 0
  else if x > m - 1
  then m - 1
  else x
  
entry median_filter(frame : [h][w]pixel, iterations : i32) : [h][w]pixel =
  loop (frame) = for _i < iterations do
    map (fn (y : i32) : [w]pixel =>
           map (fn (x : i32) : pixel =>
                  let um = unsafe frame[safe(y - 1, h)][x]
                  let ur = unsafe frame[safe(y - 1, h)][safe(x + 1, w)]
                  let cr = unsafe frame[y][safe(x + 1, w)]
                  let lr = unsafe frame[safe(y + 1, h)][safe(x + 1, w)]
                  let lm = unsafe frame[safe(y + 1, h)][x]
                  let ll = unsafe frame[safe(y + 1, h)][safe(x - 1, w)]
                  let cl = unsafe frame[y][safe(x - 1, w)]
                  let ul = unsafe frame[safe(y - 1, h)][safe(x - 1, w)]
                  let neighbors = [um, ur, cr, lr, lm, ll, cl, ul]
                  let p = median neighbors
                  in p)
           (iota w))
    (iota h)
  in frame

fun pixel_average (pixels : [n]u32) : u32 =
  let rgbs = map get_rgb pixels
  let (r0, g0, b0) = reduce (fn (a0, b0, c0) (a1, b1, c1) =>
                               (a0 + a1, b0 + b1, c0 + c1)) (0u32, 0u32, 0u32)
                            rgbs
  in set_rgb (r0 / u32 n, g0 / u32 n, b0 / u32 n)

entry simple_blur(frame : [h][w]pixel, iterations : i32) : [h][w]pixel =
  loop (frame) = for _i < iterations do
    map (fn (y : i32) : [w]pixel =>
           map (fn (x : i32) : pixel =>
                  let um = unsafe frame[safe(y - 1, h)][x]
                  let ur = unsafe frame[safe(y - 1, h)][safe(x + 1, w)]
                  let cr = unsafe frame[y][safe(x + 1, w)]
                  let lr = unsafe frame[safe(y + 1, h)][safe(x + 1, w)]
                  let lm = unsafe frame[safe(y + 1, h)][x]
                  let ll = unsafe frame[safe(y + 1, h)][safe(x - 1, w)]
                  let cl = unsafe frame[y][safe(x - 1, w)]
                  let ul = unsafe frame[safe(y - 1, h)][safe(x - 1, w)]
                  let neighbors = [um, ur, cr, lr, lm, ll, cl, ul]
                  let p = pixel_average neighbors
                  in p)
           (iota w))
    (iota h)
  in frame

fun hsv_distance (p0 : pixel) (p1 : pixel) : f32 =
  let (h0, s0, v0) = get_hsv p0
  let (h1, s1, v1) = get_hsv p1
  let (h0, h1) = if h0 < h1
                 then (h0, h1)
                 else (h1, h0)
  let h_diff = minf (h1 - h0, h0 + 360.0 - h1)
  let s_diff = absf (s1 - s0)
  let v_diff = absf (v1 - v0)
  in h_diff * s_diff * v_diff

entry fake_heatmap(frame : [h][w]pixel) : [h][w]pixel =
  map (fn (y : i32) : [w]pixel =>
         map (fn (x : i32) : pixel =>
                let cm = unsafe frame[y][x]
                             
                let um = unsafe frame[safe(y - 1, h)][x]
                let ur = unsafe frame[safe(y - 1, h)][safe(x + 1, w)]
                let cr = unsafe frame[y][safe(x + 1, w)]
                let lr = unsafe frame[safe(y + 1, h)][safe(x + 1, w)]
                let lm = unsafe frame[safe(y + 1, h)][x]
                let ll = unsafe frame[safe(y + 1, h)][safe(x - 1, w)]
                let cl = unsafe frame[y][safe(x - 1, w)]
                let ul = unsafe frame[safe(y - 1, h)][safe(x - 1, w)]
                
                let neighbors = [um, ur, cr, lr, lm, ll, cl, ul]
                let dist_total = reduce (+) 0.0 (map (hsv_distance cm) neighbors)
                let dist_max = 180.0 * 8.0
                let factor_base = dist_total / dist_max
                let factor_rest = 1.0 - factor_base
                
                let (h_in, s_in, v_in) = get_hsv cm
                let (h_out, s_out, v_out) =
                  (h_in,
                   s_in * factor_base + factor_rest,
                   v_in * factor_base + factor_rest)
                let (r_out, g_out, b_out) = hsv_to_rgb (h_out, s_out, v_out)
                in set_rgb (r_out, g_out, b_out))
         (iota w))
  (iota h)

fun insane_blur (insaneness : i32) (frame : [h][w]pixel) (xc : i32) (yc : i32) : pixel =
  let half_insaneness = insaneness / 2
  let x_start = xc - half_insaneness
  let y_start = yc - half_insaneness
  let xs = map (+ x_start) (iota insaneness)
  let ys = map (+ y_start) (iota insaneness)
  in pixel_average (
    map (fn y =>
           pixel_average (map (fn x =>
                                 unsafe frame[safe(y, h)][safe(x, w)])
             xs))
    ys)
  
entry blur_low_color(frame : [h][w]pixel, threshold : f32) : [h][w]pixel =
  map (fn (y : i32) : [w]pixel =>
         map (fn (x : i32) : pixel =>
                let p = unsafe frame[y][x]
                let (_h, s, _v) = get_hsv p
                let p' = if s < threshold
                         then insane_blur 40 frame x y
                         else p
                in p')
         (iota w))
  (iota h)


-- fun max8 (x: u8) (y: u8): u8 = if x < y then y else x

-- entry prefixMax(frame : [h][w]pixel) : [h][w]pixel =
--   map (fn row: [w]pixel =>
--          let rs = row[0:w,0]
--          let gs = row[0:w,1]
--          let bs = row[0:w,2]
--          in transpose ([(scan max8 0u8 rs), (scan max8 0u8 gs), (scan max8 0u8 bs)]))
--    frame
