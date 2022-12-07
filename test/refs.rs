fn main() {
  let price_grid: f64 = 1.0001;
  let square_root_price_grid: f64 = price_grid.sqrt();
  let ln_square_root_price_grid: f64 = square_root_price_grid.ln();

  let price: f64 = 1200.0;
  let square_root_price: f64 = price.sqrt();

  // println!("{}", square_root_price);

  /*
  let p = _get_sqrt_price_at_slot(1000.0, square_root_price_grid);
  println!("{}", p);

  let p2 = _get_sqrt_price_at_slot(-1000.0, square_root_price_grid);
  println!("{}", p2);

  let p2 = _get_sqrt_price_at_slot(-70904.0, square_root_price_grid);
  println!("{}", p2.powf(2.0));
  */

  let fwefew = _get_sqrt_price_at_slot(25000.0, square_root_price_grid);

  let (amount_a, amount_b) = _calculate_liquidity_under_lying(
    square_root_price_grid,
    10000.0,
    fwefew,
    0.0,
    10000.0,
    20000.0,
    true
  );

  println!("{} {}", amount_a, amount_b);
}

fn _get_slot_at_sqrt_price(square_root_price: f64, ln_square_root_price_grid: f64) -> f64 {
  (square_root_price.ln() / ln_square_root_price_grid).floor()
}

fn _get_sqrt_price_at_slot(slot: f64, square_root_price_grid: f64) -> f64 {
  square_root_price_grid.powf(slot)
}

fn _calculate_liquidity_under_lying(
  square_root_price_grid: f64,
  liquidity: f64,
  sqrt_price_current_slot: f64,
  _current_slot_index: f64,
  lower_slot_index: f64,
  upper_slot_index: f64,
  _should_round_up: bool
) -> (f64, f64) {
  let sqrt_price_upper_slot: f64 = _get_sqrt_price_at_slot(upper_slot_index, square_root_price_grid);
  let sqrt_price_lower_slot: f64 = _get_sqrt_price_at_slot(lower_slot_index, square_root_price_grid);

  let mut amount_a: f64 = 0.0;
  let mut amount_b: f64 = 0.0;

  if sqrt_price_current_slot <= sqrt_price_lower_slot {
      amount_a = liquidity * (1.0 / sqrt_price_lower_slot - 1.0 / sqrt_price_upper_slot);
  } else if sqrt_price_current_slot < sqrt_price_upper_slot {
      amount_a = liquidity * (1.0 / sqrt_price_current_slot - 1.0 / sqrt_price_upper_slot);
      amount_b = liquidity * (sqrt_price_current_slot - sqrt_price_lower_slot);
  } else {
      amount_b = liquidity * (sqrt_price_upper_slot - sqrt_price_lower_slot);
  }

  return (amount_a, amount_b);
}

fn _get_delta_x_to_next_price(
  sqrt_price_current_slot: f64,
  sqrt_price_next_slot: f64,
  liquidity: f64,
  should_round_up: bool,
) -> f64 {
  let raw: f64 = liquidity / sqrt_price_next_slot - liquidity / sqrt_price_current_slot;
  if should_round_up { raw.ceil() } else { raw.floor() }
}

fn _get_delta_y_to_next_price(
  sqrt_price_current_slot: f64,
  sqrt_price_next_slot: f64,
  liquidity: f64,
  should_round_up: bool,
) -> f64 {
  let raw: f64 = liquidity * (sqrt_price_next_slot - sqrt_price_current_slot);
  if should_round_up { raw.ceil() } else { raw.floor() }
}

fn _get_target_price_using_delta_x(
  sqrt_price_current_slot: f64,
  liquidity: f64,
  delta_x: f64
) -> f64 {
  liquidity * sqrt_price_current_slot / (delta_x * sqrt_price_current_slot + liquidity)
}

fn _get_target_price_using_delta_y(
  sqrt_price_current_slot: f64,
  liquidity: f64,
  delta_y: f64
) -> f64 {
    delta_y / liquidity + sqrt_price_current_slot
}
