// ─────────────────────────────────────────────────────────────────────────────
// NeuronNode.pde
// ─────────────────────────────────────────────────────────────────────────────

class NeuronNode {

  int     id;
  PVector pos;
  PVector vel = new PVector();
  boolean alive = true;

  color   eColor;
  float   activation = 0;

  float   alpha     = 0;
  float   fadeSpeed = 2.8;

  // 呼吸動畫：即使靜止也有生命感
  float   breathePhase;

  // 彩虹球色相：每幀自動旋轉，每顆神經元起點隨機
  float   rainbowPhase;

  PVector wanderDest;
  float   wanderCooldown = 0;

  PVector[] velBuf = new PVector[8];
  int       velIdx = 0;

  CopyOnWriteArrayList<PulseRing> rings = new CopyOnWriteArrayList<PulseRing>();

  // 彗星尾跡位置緩衝
  ArrayList<PVector> trailPos = new ArrayList<PVector>();
  final int TRAIL_MAX = 24;

  // ── 建構 ──────────────────────────────────────────────
  NeuronNode(int _id, PVector _pos) {
    id           = _id;
    pos          = _pos.copy();
    eColor       = color(0, 0, 38);
    breathePhase = random(TWO_PI);
    rainbowPhase = random(360);
    for (int i = 0; i < velBuf.length; i++) velBuf[i] = new PVector();
    wanderDest = pos.copy();
    rings.add(new PulseRing(pos.copy(), eColor, 0.4));
  }

  // ── 位置更新 ──────────────────────────────────────────
  void setPosition(PVector p, PVector v) {
    pos.set(p);
    vel.set(v);
    velBuf[velIdx] = v.copy();
    velIdx = (velIdx + 1) % velBuf.length;

    color mapped = emotionMapper.colorFor(v, avgVel());
    eColor = lerpColorHSB(eColor, mapped, 0.07);

    float spd = v.mag();
    activation = lerp(activation, constrain(map(spd, 0, 20, 0, 1), 0, 1), 0.14);
    if (spd > 4.5) pulse(eColor);
  }

  // ── 漫遊（模擬模式）──────────────────────────────────
  void wander() {
    wanderCooldown -= 1.0 / 60.0;
    if (wanderCooldown <= 0) {
      wanderCooldown = random(3, 7);
      wanderDest = new PVector(random(100, width - 100), random(100, height - 100));
    }
    PVector desired = PVector.sub(wanderDest, pos);
    float d = desired.mag();
    if (d > 4) {
      desired.normalize().mult(min(d * 0.025, 2.2));
      vel.lerp(desired, 0.09);
      pos.add(vel);
      eColor = lerpColorHSB(eColor, emotionMapper.colorFor(vel, vel), 0.025);
      activation = lerp(activation, constrain(map(vel.mag(), 0, 2.2, 0, 0.55), 0, 0.55), 0.06);
    } else {
      vel.mult(0.88);
      activation = lerp(activation, 0, 0.02);
    }
  }

  void receivePulse(color c, float strength) {
    eColor = lerpColorHSB(eColor, c, strength * 0.28);
    activation = constrain(activation + strength * 0.38, 0, 1);
    pulse(eColor);
  }

  void pulse(color c) {
    rings.add(new PulseRing(pos.copy(), c, activation));
    activation = constrain(activation + 0.22, 0, 1);
  }

  // ── 更新 ──────────────────────────────────────────────
  void update() {
    if (alive) alpha = min(100, alpha + fadeSpeed);
    else       alpha = max(0,   alpha - fadeSpeed);

    activation   = lerp(activation, 0, 0.007);
    if (alive) activation = max(activation, 0.05);  // Kinect 模式下靜止時仍保持最低激活，確保粒子持續產生
    breathePhase = (breathePhase + 0.018) % TWO_PI;
    rainbowPhase = (rainbowPhase + 1.0)   % 360;    // 約 6 秒一個完整彩虹週期

    // 彗星軌跡：每幀記錄當前位置，保留最近 TRAIL_MAX 幀
    trailPos.add(0, pos.copy());
    if (trailPos.size() > TRAIL_MAX) trailPos.remove(trailPos.size() - 1);

    for (int i = rings.size() - 1; i >= 0; i--) {
      rings.get(i).update();
      if (rings.get(i).dead()) rings.remove(i);
    }
  }

  // ── 渲染 ──────────────────────────────────────────────
  void render() {
    if (alpha < 1) return;

    for (PulseRing r : rings) r.render(alpha);

    float sz      = map(activation, 0, 1, 12, 34);
    float breathe = 0.5 + 0.5 * sin(breathePhase);
    float breatheAmt = (0.12 + breathe * 0.10) * (0.25 + activation * 0.75);
    float rh      = rainbowPhase;  // 當前彩虹色相基準

    // ── 彗星尾跡（從最舊到最新繪製，頭部蓋在最上層）─────────────
    noStroke();
    for (int i = trailPos.size() - 1; i >= 1; i--) {
      float ratio  = (float)i / TRAIL_MAX;               // 0=剛離開頭部，1=最末端
      float tAlpha = alpha * (1.0 - ratio) * 0.72;
      if (tAlpha < 2) continue;
      float tSz  = sz * max(0.10, 1.0 - ratio * 0.90);  // 尺寸由頭往尾遞減
      // 色相：rainbowPhase 每幀 +1°，i 幀前的色相即往回推算
      float tHue = (rainbowPhase - i + 3600) % 360;
      // 外暈光（柔和光暈）
      fill(tHue, 68, 95, tAlpha * 0.28);
      ellipse(trailPos.get(i).x, trailPos.get(i).y, tSz * 3.8, tSz * 3.8);
      // 尾核（飽和彩色）
      fill((tHue + 30) % 360, 92, 100, tAlpha * 0.80);
      ellipse(trailPos.get(i).x, trailPos.get(i).y, tSz, tSz);
    }

    // 呼吸外環 — 彩虹色，偏移 +60° 與主體形成對比
    noFill();
    strokeWeight(0.8);
    stroke((rh + 60) % 360, 82, 100, alpha * breatheAmt);
    ellipse(pos.x, pos.y, sz * (3.2 + breathe * 1.4), sz * (3.2 + breathe * 1.4));

    // 次外環 — 互補色（+180°）
    stroke((rh + 180) % 360, 65, 90, alpha * 0.08);
    ellipse(pos.x, pos.y, sz * 2.2, sz * 2.2);
    noStroke();

    // 8 層彩虹暈光 — 每層錯開 20°，由外到內形成色譜漸層
    for (int layer = 8; layer >= 1; layer--) {
      float layerHue = (rh + layer * 20) % 360;
      fill(layerHue, 88, 96, alpha * 0.032 * layer);
      ellipse(pos.x, pos.y, sz * (1.0 + layer * 1.05), sz * (1.0 + layer * 1.05));
    }

    // 主體 — 完全飽和彩虹色
    fill(rh, 95, 100, alpha * 0.90);
    ellipse(pos.x, pos.y, sz, sz);

    // 核心 — 互補色彩（取代原本白核），高飽和高亮
    fill((rh + 150) % 360, 90, 100, alpha * 0.96);
    ellipse(pos.x, pos.y, sz * 0.30, sz * 0.30);
  }

  PVector avgVel() {
    PVector sum = new PVector();
    for (PVector v : velBuf) sum.add(v);
    return sum.div(velBuf.length);
  }

  boolean isDead() { return !alive && alpha < 1; }
}
