# Median: a robust range-band controller that smooths noisy contacts with a
# rolling median. Protocol 2, on the R binding.
#
# It keeps the median of its last five ranges to its target and steers by
# that band: in close it swings wide across the target's line, at range it
# closes on a shallow angle, switching sides every three and a half
# seconds. It fires only inside its band, with shots whose power suits the
# range, led on the target's tracked motion. It steps out across the storm's
# path and keeps to the safe zone in sudden death.
library(clunkyard)

ranges <- numeric()

# Out across the storm's path, on the side away from its centre.
storm_escape <- function(bot, storm) {
  away <- angles$bearing_to(storm$center, bot$me$position)
  drift <- angles$bearing_to(list(x = 0, y = 0, z = 0), storm$velocity)
  if (sqrt(storm$velocity$x^2 + storm$velocity$y^2) < 1) return(away)
  side <- drift + if (angles$angle_diff(away, drift) < 0) -90 else 90
  side + angles$angle_diff(away, side) / 3
}

on_turn <- function(bot) {
  me <- bot$me
  tick <- bot$clock$tick
  three <- bot$match$is_3d
  forces <- bot$match$control == "forces"
  heading <- me$heading
  target <- bot$sensors$nearest
  contact <- !is.null(target)
  if (contact) ranges <<- tail(c(ranges, target$range), 5) else if (length(ranges)) ranges <<- tail(ranges, 3)
  band <- if (length(ranges)) median(ranges) else Inf
  side <- if ((tick %/% 70) %% 2 == 0) 1 else -1
  bearing <- if (contact) target$bearing else heading
  desired <- if (contact) bearing + if (band < 155) 142 * side else 24 * side else heading + 54 * side
  throttle <- if (!contact) .62 else if (band < 118) -.82 else if (band > 430) .9 else .27

  # The storm and sudden death take the wheel; the gun keeps working.
  storm <- bot$nav$storm
  escaping <- !is.null(storm) && storm$margin(me$position) > -70
  if (escaping) { desired <- storm_escape(bot, storm); throttle <- 1 }
  zone <- bot$nav$zone
  if (!is.null(zone) && zone$margin(me$position) < 60) { desired <- angles$bearing_to(me$position, zone$center); throttle <- .8 }
  turn <- angles$clamp(angles$angle_diff(desired, heading) / if (throttle == 1 || throttle == .8) 30 else 74)

  if (contact) {
    power <- bot$gun$power_for_flight_time(target$range, if (band > 300) 1.5 else 1.2)
    aim <- bot$gun$lead(target, power)
    if (is.null(aim)) bot$gun$aim(target$bearing, target$elevation) else bot$gun$aim(aim$heading, aim$pitch)
    now <- bot$gun$aim_now
    on_target <- abs(angles$angle_diff(bot$gun$get("heading"), now$heading)) < 4 && (!three || abs(bot$gun$get("pitch") - now$pitch) < 4)
    if (band > 95 && band < 520 && on_target && bot$gun$can_fire(power, 4)) bot$gun$fire(power)
    bot$scanner$set(heading = target$bearing, pitch = target$elevation, arc = 18)
    bot$status$set("MEDIAN", band)
  } else {
    cue <- bot$tracker$cue
    if (!is.null(cue)) {
      look <- angles$bearing_to(me$position, cue$position)
      bot$scanner$set(heading = look + (tick %% 5 - 2) * min(cue$bearing_error, 15), pitch = 0, arc = 30)
      if (is.null(storm) && is.null(zone)) turn <- angles$clamp(angles$angle_diff(look, heading) / 74)
    } else {
      bot$scanner$set(heading = (heading + tick * 7.4 * side) %% 360, pitch = if (three) 26 * sin(tick / 17) else 0, arc = 52)
    }
    bot$status$set("SAMPLE", tick)
  }

  if (!forces) {
    bot$drive$set(throttle = throttle, turn = turn, pitch_turn = if (three) .1 * side else 0)
    return(invisible())
  }
  velocity <- me$velocity
  spin <- me$angular_velocity
  lift <- 0
  if (three) {
    if (bot$arena$gravity$z != 0) {
      lift <- angles$clamp((bot$arena$ground_height(me$position$x, me$position$y) + 106 - me$position$z) / 105 - velocity$z / 58)
    } else lift <- angles$clamp(-velocity$z / 55 + .04 * side)
  }
  speed <- sqrt(velocity$x^2 + velocity$y^2 + velocity$z^2)
  if (escaping) {
    # Push straight along the way out, whatever the hull's heading.
    out <- angles$direction(desired, 0)
    axes <- me$attitude
    bot$drive$forces(thrust = angles$clamp(out$x * axes$forward$x + out$y * axes$forward$y),
                     strafe = angles$clamp(out$x * axes$right$x + out$y * axes$right$y), lift = lift,
                     yaw_torque = angles$clamp(turn - spin$yaw / 60), pitch_torque = 0, roll_torque = 0, brake = 0)
    return(invisible())
  }
  bot$drive$forces(thrust = throttle, strafe = if (contact && band > 95 && band < 520) .15 * side else .34 * side, lift = lift,
                   yaw_torque = angles$clamp(turn - spin$yaw / 60),
                   pitch_torque = if (three) .08 * side else 0, roll_torque = if (three) -.13 * side else 0,
                   brake = if (speed > 58 || band < 110) .86 else 0)
}

run(robot(on_turn = on_turn))
