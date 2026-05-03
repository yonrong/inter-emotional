// ─────────────────────────────────────────────────────────────────────────────
// EmotionMapper.pde
// 動作向量 → 情感顏色映射（參考 Plutchik 情感輪）
// colorMode: HSB 360 / 100 / 100 / 100
// ─────────────────────────────────────────────────────────────────────────────

class EmotionMapper {

  // ── 五種情感色彩 ──────────────────────────────────────
  final color EXCITED    = color( 15, 92, 100); // 暖橘紅：激動・渴望
  final color JOY        = color( 48, 88, 100); // 金黃：喜悅・驚喜
  final color MELANCHOLY = color(220, 78,  88); // 冷藍：悲傷・平靜・抽離
  final color FEAR       = color(272, 72,  78); // 深紫：恐懼・預期
  final color NEUTRAL    = color(  0,  0,  42); // 灰白：靜止・中性

  // ── 主映射函數 ────────────────────────────────────────
  // instant : 當下幀速度向量
  // avg     : 近期平均速度向量（平滑用）
  color colorFor(PVector instant, PVector avg) {
    float spd = instant.mag();
    if (spd < 0.5) return NEUTRAL;

    // 以平均速度判斷方向（較穩定），速度不足時退用瞬時
    PVector dir = (avg.mag() > 0.25) ? avg : instant;
    float angle = atan2(dir.y, dir.x); // -PI 到 PI

    // 方向 → 情感基色
    // 向上（-PI/2）→ 激動 / 喜悅   向下（+PI/2）→ 憂鬱
    // 向左（±PI）  → 恐懼 / 退縮   向右（0）    → 激動
    color base;
    if      (angle < -PI/4  && angle > -3*PI/4) base = (spd > 8) ? JOY : EXCITED;
    else if (angle >  PI/4  && angle <  3*PI/4) base = MELANCHOLY;
    else if (abs(angle)     >  3*PI/4)           base = FEAR;
    else                                          base = EXCITED;

    // 速度強度決定飽和度（慢 = 接近中性灰）
    float t = constrain(PApplet.map(spd, 0, 18, 0, 1), 0, 1);
    return lerpColorHSB(NEUTRAL, base, t);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 全域 HSB 色彩插值（取最短色相路徑）
// ─────────────────────────────────────────────────────────────────────────────
color lerpColorHSB(color a, color b, float t) {
  float h1 = hue(a),        s1 = saturation(a), v1 = brightness(a);
  float h2 = hue(b),        s2 = saturation(b), v2 = brightness(b);
  float dh = h2 - h1;
  if (dh >  180) dh -= 360;
  if (dh < -180) dh += 360;
  return color((h1 + dh * t + 360) % 360, lerp(s1, s2, t), lerp(v1, v2, t), 100);
}
