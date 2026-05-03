// ─────────────────────────────────────────────────────────────────────────────
// StarryUniverse.pde
// 閃爍星空宇宙動態背景 ── Emotional Universe 背景層
// ─────────────────────────────────────────────────────────────────────────────

class StarryUniverse {

  Star[]        stars;
  NebulaPatch[] nebulas;
  ShootingStar  shooting;
  float         shootTimer;

  StarryUniverse() {
    // 三層星星：小 420 / 中 110 / 大 32
    stars = new Star[562];
    int idx = 0;
    for (int i = 0; i < 420; i++) stars[idx++] = new Star(0);
    for (int i = 0; i < 110; i++) stars[idx++] = new Star(1);
    for (int i = 0; i < 32;  i++) stars[idx++] = new Star(2);

    nebulas = new NebulaPatch[7];
    for (int i = 0; i < 7; i++) nebulas[i] = new NebulaPatch();

    shooting   = null;
    shootTimer = random(6, 16);
  }

  void update() {
    for (Star s        : stars)   s.update();
    for (NebulaPatch n : nebulas) n.update();

    shootTimer -= 1.0 / 60.0;
    if (shootTimer <= 0) {
      shooting   = new ShootingStar();
      shootTimer = random(8, 20);
    }
    if (shooting != null) {
      shooting.update();
      if (shooting.dead()) shooting = null;
    }
  }

  // 呼叫前請確保 blendMode(ADD) 已設定
  void render() {
    noStroke();

    // ── 全畫面宇宙底色光氛（確保覆蓋至每個邊角）────────────────────────
    fill(225, 42, 14, 5);
    rect(0, 0, width, height);

    // ── 星雲光斑（最深遠背景）────────────────────────────────────────────
    for (NebulaPatch n : nebulas) n.render();

    // ── 所有星星 ─────────────────────────────────────────────────────────
    for (Star s : stars) s.render();

    // ── 流星 ─────────────────────────────────────────────────────────────
    if (shooting != null) shooting.render();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class Star {

  float x, y, sz;
  float twinklePhase, twinkleSpeed;
  float baseBright, baseAlpha;
  float s;           // 飽和度（固定，決定顏色鮮豔程度）
  float huePhase;    // 當前色相（每幀緩慢遞增，產生彩虹漂移）
  float hueSpeed;    // 色相旋轉速度（每幀度數）
  int   tier;

  Star(int tier) {
    this.tier = tier;
    x = random(-8, width  + 8);
    y = random(-8, height + 8);
    twinklePhase = random(TWO_PI);
    huePhase     = random(360);    // 起點隨機，讓每顆星初始色彩不同

    switch (tier) {
      case 0:  // 小星：輕快色相循環
        sz           = random(0.5, 1.4);
        twinkleSpeed = random(0.018, 0.068);
        baseBright   = random(55, 85);
        baseAlpha    = random(42, 78);
        s            = random(55, 88);    // 中高飽和，顯色鮮豔
        hueSpeed     = random(0.30, 1.0); // 6–20 秒繞一圈
        break;
      case 1:  // 中星：穩重色相循環
        sz           = random(1.4, 2.8);
        twinkleSpeed = random(0.010, 0.038);
        baseBright   = random(70, 96);
        baseAlpha    = random(60, 92);
        s            = random(65, 92);
        hueSpeed     = random(0.15, 0.55); // 10–40 秒繞一圈
        break;
      default: // 大星：壯觀且緩慢的色彩轉換
        sz           = random(2.8, 5.5);
        twinkleSpeed = random(0.005, 0.018);
        baseBright   = random(88, 100);
        baseAlpha    = random(82, 100);
        s            = random(72, 96);
        hueSpeed     = random(0.06, 0.25); // 24–100 秒繞一圈
        break;
    }
  }

  void update() {
    twinklePhase = (twinklePhase + twinkleSpeed) % TWO_PI;
    huePhase     = (huePhase     + hueSpeed)     % 360;    // 色相持續漂移
  }

  void render() {
    float tw     = 0.5 + 0.5 * sin(twinklePhase);
    float bright = baseBright + (100 - baseBright) * tw * 0.48;
    float a      = baseAlpha  + (100 - baseAlpha)  * tw * 0.40;
    float h      = huePhase;   // 當前動態色相

    noStroke();

    if (tier == 2) {
      // 十字衍射光芒（大星專屬）
      fill(h, s * 0.18, 100, a * 0.26 * tw);
      ellipse(x, y, sz * 11, sz * 1.5);
      ellipse(x, y, sz * 1.5, sz * 11);
      fill(h, s * 0.22, bright, a * 0.10 * tw);
      ellipse(x, y, sz * 15, sz * 15);
      fill(h, s * 0.45, bright, a * 0.28 * tw);
      ellipse(x, y, sz * 5.5, sz * 5.5);
    }

    if (tier >= 1) {
      fill(h, s * 0.5, bright, a * 0.22 * tw);
      ellipse(x, y, sz * 4.2, sz * 4.2);
    }

    // 星點核心
    fill(h, s, bright, a);
    ellipse(x, y, sz, sz);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class NebulaPatch {

  float x, y, driftX, driftY, sz, h, phase;

  NebulaPatch() {
    // 初始位置包含邊緣與角落，確保全畫面覆蓋
    x      = random(-200, width  + 200);
    y      = random(-200, height + 200);
    driftX = random(-0.06, 0.06);
    driftY = random(-0.04, 0.04);
    sz     = random(280, 580);
    h      = random(180, 315);
    phase  = random(TWO_PI);
  }

  void update() {
    x += driftX;  y += driftY;
    phase = (phase + 0.0022) % TWO_PI;
    if (x < -sz)         x = width  + sz;
    if (x > width  + sz) x = -sz;
    if (y < -sz)         y = height + sz;
    if (y > height + sz) y = -sz;
  }

  void render() {
    float pulse = 0.5 + 0.5 * sin(phase);
    float a     = 6 + 3 * pulse;
    noStroke();
    fill(h, 62, 40, a * 1.0); ellipse(x, y, sz * 0.38, sz * 0.38);
    fill(h, 50, 35, a * 0.65); ellipse(x, y, sz * 0.70, sz * 0.70);
    fill(h, 38, 28, a * 0.35); ellipse(x, y, sz * 1.00, sz * 1.00);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class ShootingStar {

  float x, y, dx, dy, alpha;
  int   age;
  ArrayList<PVector> trail = new ArrayList<PVector>();
  final int TRAIL_LEN = 28;

  ShootingStar() {
    float angle = random(radians(18), radians(68));
    float speed = random(16, 26);
    dx = cos(angle) * speed;
    dy = sin(angle) * speed;
    if (random(1) < 0.65) { x = random(width * 0.85); y = -10; }
    else                   { x = -10; y = random(height * 0.55); }
    alpha = 0;
    age   = 0;
  }

  void update() {
    trail.add(0, new PVector(x, y));
    if (trail.size() > TRAIL_LEN) trail.remove(trail.size() - 1);
    x += dx;  y += dy;
    age++;
    boolean onScreen = (x >= 0 && x <= width && y >= 0 && y <= height);
    alpha = onScreen ? min(88, alpha + 14) : max(0, alpha - 10);
  }

  void render() {
    noFill();
    for (int i = 1; i < trail.size(); i++) {
      float ratio = (float)i / TRAIL_LEN;
      float a     = alpha * (1.0 - ratio);
      if (a < 2) continue;
      strokeWeight(max(0.3, 2.4 * (1.0 - ratio)));
      stroke(210, 10, 100, a);
      PVector p1 = trail.get(i - 1), p2 = trail.get(i);
      line(p1.x, p1.y, p2.x, p2.y);
    }
    noStroke();
  }

  boolean dead() { return age > 15 && alpha <= 0; }
}
